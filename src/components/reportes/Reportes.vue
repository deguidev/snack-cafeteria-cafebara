<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';
import { Bar } from 'vue-chartjs';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  BarController,
  PointElement,
  LineElement,
  LineController,
  Title,
  Tooltip,
  Legend
} from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  BarController,
  PointElement,
  LineElement,
  LineController,
  Title,
  Tooltip,
  Legend,
  ChartDataLabels
);

// Colores para las barras del gráfico
//Diego Lipa
const coloresBarras = [
  '#059669', '#0891b2', '#7c3aed', '#db2777', '#ea580c',
  '#16a34a', '#2563eb', '#9333ea', '#e11d48', '#d97706',
  '#14b8a6', '#6366f1', '#c026d3', '#f43f5e', '#f59e0b'
];

interface PedidoReporte {
  id: string;
  numero_pedido: number;
  tipo_pedido: string;
  estado: string;
  total: number;
  created_at: string;
  nombre_cliente: string | null;
  mesa_numero: number | null;
}

interface ProductoVendido {
  nombre: string;
  cantidad: number;
  total: number;
}

interface EstadisticasGenerales {
  ventasTotales: number;
  pedidosTotales: number;
  pedidosPagados: number;
  pedidosPendientes: number;
  pedidosCancelados: number;
  ticketPromedio: number;
  productosVendidos: number;
}

// Estado
const loading = ref(true);
const fechaInicio = ref('');
const fechaFin = ref('');
const pedidos = ref<PedidoReporte[]>([]);
const productosTop = ref<ProductoVendido[]>([]);
const estadisticas = ref<EstadisticasGenerales>({
  ventasTotales: 0,
  pedidosTotales: 0,
  pedidosPagados: 0,
  pedidosPendientes: 0,
  pedidosCancelados: 0,
  ticketPromedio: 0,
  productosVendidos: 0
});

// Datos para el gráfico de ventas por día
const ventasPorDia = ref<{ fecha: string; total: number }[]>([]);

// Datos del gráfico
const chartData = computed(() => {
  const datos = ventasPorDia.value.map(v => v.total);
  const colores = ventasPorDia.value.map((_, i) => coloresBarras[i % coloresBarras.length]);
  
  return {
    labels: ventasPorDia.value.map(v => {
      const fecha = new Date(v.fecha + 'T12:00:00');
      return fecha.toLocaleDateString('es-PE', { day: '2-digit', month: 'short' });
    }),
    datasets: [
      {
        type: 'line' as const,
        label: 'Tendencia',
        data: datos,
        borderColor: '#374151',
        borderWidth: 2,
        pointBackgroundColor: '#374151',
        pointRadius: 4,
        tension: 0.3,
        fill: false,
        order: 0,
        datalabels: {
          display: false
        }
      },
      {
        type: 'bar' as const,
        label: 'Ventas (S/)',
        backgroundColor: colores,
        borderColor: colores.map(c => c),
        borderWidth: 1,
        borderRadius: 6,
        data: datos,
        order: 1
      }
    ]
  };
});

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      display: true,
      position: 'top' as const,
      labels: {
        usePointStyle: true,
        padding: 15
      }
    },
    tooltip: {
      callbacks: {
        label: (context: any) => `S/ ${context.raw.toFixed(2)}`
      }
    },
    datalabels: {
      anchor: 'end' as const,
      align: 'top' as const,
      color: '#374151',
      font: {
        weight: 'bold' as const,
        size: 11
      },
      formatter: (value: number) => `S/${value.toFixed(0)}`,
      display: (context: any) => context.dataset.type === 'bar'
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: {
        callback: (value: any) => `S/ ${value}`
      },
      grid: {
        color: '#e5e7eb'
      }
    },
    x: {
      grid: {
        display: false
      }
    }
  }
};

// Inicializar fechas (hoy)
const inicializarFechas = () => {
  const hoy = new Date();
  const inicioMes = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
  fechaInicio.value = inicioMes.toISOString().split('T')[0];
  fechaFin.value = hoy.toISOString().split('T')[0];
};

// Cargar datos del reporte
const cargarReporte = async () => {
  try {
    loading.value = true;
    
    const inicio = new Date(fechaInicio.value).toISOString();
    const fin = new Date(fechaFin.value + 'T23:59:59').toISOString();

    // Cargar pedidos del período
    const { data: pedidosData, error: errorPedidos } = await supabase
      .from('pedidos')
      .select(`
        id,
        numero_pedido,
        tipo_pedido,
        estado,
        total,
        created_at,
        nombre_cliente,
        mesa_numero,
        pedido_detalle (
          cantidad,
          nombre_producto,
          subtotal
        )
      `)
      .gte('created_at', inicio)
      .lte('created_at', fin)
      .order('created_at', { ascending: false });

    if (errorPedidos) throw errorPedidos;

    pedidos.value = pedidosData || [];

    // Calcular estadísticas
    const pedidosPagados = pedidos.value.filter(p => p.estado === 'pagado');
    const pedidosPendientes = pedidos.value.filter(p => !['pagado', 'cancelado'].includes(p.estado));
    const pedidosCancelados = pedidos.value.filter(p => p.estado === 'cancelado');
    
    const ventasTotales = pedidosPagados.reduce((sum, p) => sum + (p.total || 0), 0);
    const ticketPromedio = pedidosPagados.length > 0 ? ventasTotales / pedidosPagados.length : 0;

    // Calcular productos vendidos
    const productosMap = new Map<string, { cantidad: number; total: number }>();
    let totalProductos = 0;

    pedidosPagados.forEach((pedido: any) => {
      const detalles = pedido.pedido_detalle || [];
      detalles.forEach((d: any) => {
        totalProductos += d.cantidad || 0;
        const existing = productosMap.get(d.nombre_producto) || { cantidad: 0, total: 0 };
        productosMap.set(d.nombre_producto, {
          cantidad: existing.cantidad + (d.cantidad || 0),
          total: existing.total + (d.subtotal || 0)
        });
      });
    });

    // Top 10 productos
    productosTop.value = Array.from(productosMap.entries())
      .map(([nombre, data]) => ({ nombre, ...data }))
      .sort((a, b) => b.cantidad - a.cantidad)
      .slice(0, 10);

    // Calcular ventas por día para el gráfico
    const ventasPorDiaMap = new Map<string, number>();
    pedidosPagados.forEach(pedido => {
      const fecha = pedido.created_at.split('T')[0];
      const existing = ventasPorDiaMap.get(fecha) || 0;
      ventasPorDiaMap.set(fecha, existing + (pedido.total || 0));
    });
    
    // Convertir a array y ordenar por fecha
    ventasPorDia.value = Array.from(ventasPorDiaMap.entries())
      .map(([fecha, total]) => ({ fecha, total }))
      .sort((a, b) => a.fecha.localeCompare(b.fecha));

    estadisticas.value = {
      ventasTotales,
      pedidosTotales: pedidos.value.length,
      pedidosPagados: pedidosPagados.length,
      pedidosPendientes: pedidosPendientes.length,
      pedidosCancelados: pedidosCancelados.length,
      ticketPromedio,
      productosVendidos: totalProductos
    };

  } catch (err) {
    console.error('Error cargando reporte:', err);
  } finally {
    loading.value = false;
  }
};

// Formatear fecha
const formatearFecha = (fecha: string) => {
  return new Date(fecha).toLocaleString('es-PE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// Obtener color del estado
const getEstadoColor = (estado: string) => {
  switch (estado) {
    case 'pagado': return 'bg-teal-100 text-teal-800';
    case 'pendiente': return 'bg-yellow-100 text-yellow-800';
    case 'en_preparacion': return 'bg-blue-100 text-blue-800';
    case 'listo': return 'bg-green-100 text-green-800';
    case 'entregado': return 'bg-emerald-100 text-emerald-800';
    case 'cancelado': return 'bg-red-100 text-red-800';
    default: return 'bg-gray-100 text-gray-800';
  }
};

// Formatear estado
const formatearEstado = (estado: string) => {
  return estado.replace(/_/g, ' ').toUpperCase();
};

// Obtener tipo pedido display
const getTipoPedidoIcon = (tipo: string) => {
  switch (tipo) {
    case 'para_servir': return 'mdi:silverware-fork-knife';
    case 'para_llevar': return 'mdi:shopping-outline';
    case 'delivery': return 'mdi:moped';
    default: return 'mdi:clipboard-list';
  }
};

onMounted(() => {
  inicializarFechas();
  cargarReporte();
});
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-stone-50 via-gray-50 to-slate-100">
    <!-- Header -->
    <header class="bg-gradient-to-r from-stone-800 via-stone-700 to-gray-700 px-4 py-6 shadow-lg">
      <div class="mx-auto max-w-7xl">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <a href="/" class="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 backdrop-blur-sm transition-colors hover:bg-white/30">
              <Icon icon="mdi:arrow-left" class="h-6 w-6 text-white" />
            </a>
            <div>
              <h1 class="text-2xl font-bold text-white sm:text-3xl">Reportes</h1>
              <p class="mt-1 text-sm text-stone-200">Estadísticas y análisis de ventas</p>
            </div>
          </div>
          <div class="flex h-12 w-12 items-center justify-center rounded-full bg-white/20">
            <Icon icon="mdi:chart-bar" class="h-6 w-6 text-white" />
          </div>
        </div>
      </div>
    </header>

    <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
      <!-- Filtros de fecha -->
      <div class="mb-6 rounded-xl bg-white p-4 shadow-md">
        <div class="flex flex-wrap items-end gap-4">
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-1">Fecha inicio</label>
            <input
              v-model="fechaInicio"
              type="date"
              class="rounded-lg border-2 border-gray-200 px-3 py-2 text-sm focus:border-stone-500 focus:outline-none"
            />
          </div>
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-1">Fecha fin</label>
            <input
              v-model="fechaFin"
              type="date"
              class="rounded-lg border-2 border-gray-200 px-3 py-2 text-sm focus:border-stone-500 focus:outline-none"
            />
          </div>
          <button
            @click="cargarReporte"
            class="flex items-center gap-2 rounded-lg bg-stone-700 px-4 py-2 text-sm font-semibold text-white hover:bg-stone-800 transition-colors"
          >
            <Icon icon="mdi:magnify" class="h-4 w-4" />
            Buscar
          </button>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-4 border-stone-200 border-t-stone-600"></div>
      </div>

      <div v-else>
        <!-- Estadísticas generales -->
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">
          <div class="rounded-xl bg-gradient-to-br from-teal-500 to-emerald-600 p-5 text-white shadow-lg">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium opacity-90">Ventas Totales</p>
                <p class="mt-1 text-2xl font-bold">S/ {{ estadisticas.ventasTotales.toFixed(2) }}</p>
              </div>
              <Icon icon="mdi:cash-multiple" class="h-10 w-10 opacity-80" />
            </div>
          </div>

          <div class="rounded-xl bg-gradient-to-br from-blue-500 to-indigo-600 p-5 text-white shadow-lg">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium opacity-90">Pedidos Pagados</p>
                <p class="mt-1 text-2xl font-bold">{{ estadisticas.pedidosPagados }}</p>
              </div>
              <Icon icon="mdi:check-circle" class="h-10 w-10 opacity-80" />
            </div>
          </div>

          <div class="rounded-xl bg-gradient-to-br from-amber-500 to-orange-600 p-5 text-white shadow-lg">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium opacity-90">Ticket Promedio</p>
                <p class="mt-1 text-2xl font-bold">S/ {{ estadisticas.ticketPromedio.toFixed(2) }}</p>
              </div>
              <Icon icon="mdi:receipt" class="h-10 w-10 opacity-80" />
            </div>
          </div>

          <div class="rounded-xl bg-gradient-to-br from-purple-500 to-violet-600 p-5 text-white shadow-lg">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium opacity-90">Productos Vendidos</p>
                <p class="mt-1 text-2xl font-bold">{{ estadisticas.productosVendidos }}</p>
              </div>
              <Icon icon="mdi:package-variant" class="h-10 w-10 opacity-80" />
            </div>
          </div>
        </div>

        <!-- Resumen de estados -->
        <div class="grid gap-4 sm:grid-cols-3 mb-6">
          <div class="rounded-xl bg-white p-4 shadow-md border-l-4 border-yellow-500">
            <div class="flex items-center gap-3">
              <Icon icon="mdi:clock-outline" class="h-8 w-8 text-yellow-600" />
              <div>
                <p class="text-sm text-gray-600">Pendientes</p>
                <p class="text-xl font-bold text-gray-900">{{ estadisticas.pedidosPendientes }}</p>
              </div>
            </div>
          </div>
          <div class="rounded-xl bg-white p-4 shadow-md border-l-4 border-teal-500">
            <div class="flex items-center gap-3">
              <Icon icon="mdi:check-decagram" class="h-8 w-8 text-teal-600" />
              <div>
                <p class="text-sm text-gray-600">Pagados</p>
                <p class="text-xl font-bold text-gray-900">{{ estadisticas.pedidosPagados }}</p>
              </div>
            </div>
          </div>
          <div class="rounded-xl bg-white p-4 shadow-md border-l-4 border-red-500">
            <div class="flex items-center gap-3">
              <Icon icon="mdi:close-circle" class="h-8 w-8 text-red-600" />
              <div>
                <p class="text-sm text-gray-600">Cancelados</p>
                <p class="text-xl font-bold text-gray-900">{{ estadisticas.pedidosCancelados }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Gráfico de ventas por día -->
        <div class="rounded-xl bg-white p-6 shadow-md mb-6">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <Icon icon="mdi:chart-bar" class="h-5 w-5 text-emerald-600" />
            Ventas por Día
          </h3>
          <div v-if="ventasPorDia.length === 0" class="text-center py-8 text-gray-500">
            No hay datos de ventas para mostrar
          </div>
          <div v-else class="h-72">
            <Bar :data="chartData" :options="chartOptions" />
          </div>
        </div>

        <div class="grid gap-6 lg:grid-cols-2">
          <!-- Top Productos -->
          <div class="rounded-xl bg-white p-6 shadow-md">
            <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
              <Icon icon="mdi:trophy" class="h-5 w-5 text-amber-500" />
              Top 10 Productos
            </h3>
            <div v-if="productosTop.length === 0" class="text-center py-8 text-gray-500">
              No hay datos de productos
            </div>
            <div v-else class="space-y-3">
              <div
                v-for="(producto, index) in productosTop"
                :key="producto.nombre"
                class="flex items-center justify-between p-3 rounded-lg bg-gray-50"
              >
                <div class="flex items-center gap-3">
                  <span class="flex h-7 w-7 items-center justify-center rounded-full bg-amber-100 text-amber-800 text-sm font-bold">
                    {{ index + 1 }}
                  </span>
                  <span class="font-medium text-gray-800">{{ producto.nombre }}</span>
                </div>
                <div class="text-right">
                  <p class="text-sm font-bold text-gray-900">{{ producto.cantidad }} uds</p>
                  <p class="text-xs text-gray-500">S/ {{ producto.total.toFixed(2) }}</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Últimos pedidos -->
          <div class="rounded-xl bg-white p-6 shadow-md">
            <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
              <Icon icon="mdi:history" class="h-5 w-5 text-blue-500" />
              Últimos Pedidos
            </h3>
            <div v-if="pedidos.length === 0" class="text-center py-8 text-gray-500">
              No hay pedidos en este período
            </div>
            <div v-else class="space-y-2 max-h-96 overflow-y-auto">
              <div
                v-for="pedido in pedidos.slice(0, 15)"
                :key="pedido.id"
                class="flex items-center justify-between p-3 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors"
              >
                <div class="flex items-center gap-3">
                  <Icon :icon="getTipoPedidoIcon(pedido.tipo_pedido)" class="h-5 w-5 text-gray-500" />
                  <div>
                    <p class="font-semibold text-gray-800">#{{ pedido.numero_pedido }}</p>
                    <p class="text-xs text-gray-500">{{ formatearFecha(pedido.created_at) }}</p>
                  </div>
                </div>
                <div class="text-right">
                  <p class="font-bold text-gray-900">S/ {{ pedido.total.toFixed(2) }}</p>
                  <span :class="['text-xs px-2 py-0.5 rounded-full font-semibold', getEstadoColor(pedido.estado)]">
                    {{ formatearEstado(pedido.estado) }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tabla completa de pedidos -->
        <div class="mt-6 rounded-xl bg-white p-6 shadow-md">
          <h3 class="text-lg font-bold text-gray-900 mb-4 flex items-center gap-2">
            <Icon icon="mdi:table" class="h-5 w-5 text-stone-500" />
            Detalle de Pedidos ({{ pedidos.length }})
          </h3>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b-2 border-gray-200">
                  <th class="text-left py-3 px-2 font-semibold text-gray-700">#</th>
                  <th class="text-left py-3 px-2 font-semibold text-gray-700">Fecha</th>
                  <th class="text-left py-3 px-2 font-semibold text-gray-700">Tipo</th>
                  <th class="text-left py-3 px-2 font-semibold text-gray-700">Cliente/Mesa</th>
                  <th class="text-left py-3 px-2 font-semibold text-gray-700">Estado</th>
                  <th class="text-right py-3 px-2 font-semibold text-gray-700">Total</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="pedido in pedidos"
                  :key="pedido.id"
                  class="border-b border-gray-100 hover:bg-gray-50"
                >
                  <td class="py-3 px-2 font-semibold">{{ pedido.numero_pedido }}</td>
                  <td class="py-3 px-2 text-gray-600">{{ formatearFecha(pedido.created_at) }}</td>
                  <td class="py-3 px-2">
                    <Icon :icon="getTipoPedidoIcon(pedido.tipo_pedido)" class="h-5 w-5 text-gray-500" />
                  </td>
                  <td class="py-3 px-2 text-gray-600">
                    {{ pedido.tipo_pedido === 'para_servir' ? `Mesa ${pedido.mesa_numero}` : (pedido.nombre_cliente || '-') }}
                  </td>
                  <td class="py-3 px-2">
                    <span :class="['text-xs px-2 py-1 rounded-full font-semibold', getEstadoColor(pedido.estado)]">
                      {{ formatearEstado(pedido.estado) }}
                    </span>
                  </td>
                  <td class="py-3 px-2 text-right font-bold">S/ {{ pedido.total.toFixed(2) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
