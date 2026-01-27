<script setup lang="ts">
import { ref, computed } from 'vue';
import { Icon } from '@iconify/vue';
import PedidoCard from './PedidoCard.vue';
import PedidoModal from './PedidoModal.vue';

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria: string;
  imagen_url?: string;
  disponible: boolean;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
}

interface Pedido {
  id: string;
  mesaNumero: number | null;
  nombreCliente: string;
  items: ItemPedido[];
  total: number;
  fecha: string;
  estado: 'pendiente' | 'en preparacion' | 'listo' | 'servido' | 'pagado' | 'entregado' | 'en camino';
  tipo_pedido: 'para_servir' | 'para_llevar' | 'delivery';
  montoPagado?: number;
}

// Estado
const pedidos = ref<Pedido[]>([]);
const loading = ref(true);
const pedidoSeleccionado = ref<Pedido | null>(null);
const mostrarModal = ref(false);
const montoRecibido = ref<number>(0);

// Datos de ejemplo (reemplazar con datos de Supabase)
const pedidosEjemplo: Pedido[] = [
  {
    id: '1',
    mesaNumero: 1,
    nombreCliente: 'Juan Pérez',
    items: [
      {
        producto: {
          id: '1',
          nombre: 'Arroz con Pollo',
          descripcion: 'Delicioso arroz con pollo a la olla',
          precio: 15.00,
          categoria: 'comidas',
          disponible: true
        },
        cantidad: 2
      },
      {
        producto: {
          id: '5',
          nombre: 'Chicha Morada',
          descripcion: 'Refrescante chicha morada natural',
          precio: 5.00,
          categoria: 'bebidas',
          disponible: true
        },
        cantidad: 2
      }
    ],
    total: 40.00,
    fecha: '2024-01-20 12:30',
    estado: 'pendiente',
    tipo_pedido: 'para_servir'
  },
  {
    id: '2',
    mesaNumero: null,
    nombreCliente: 'María García',
    items: [
      {
        producto: {
          id: '9',
          nombre: 'Café Americano',
          descripcion: 'Café americano caliente',
          precio: 4.50,
          categoria: 'cafes',
          disponible: true
        },
        cantidad: 1
      }
    ],
    total: 4.50,
    fecha: '2024-01-20 11:45',
    estado: 'en preparacion',
    tipo_pedido: 'para_llevar'
  },
  {
    id: '3',
    mesaNumero: null,
    nombreCliente: 'Carlos López',
    items: [
      {
        producto: {
          id: '2',
          nombre: 'Lomo Saltado',
          descripcion: 'Carne de res salteada con cebolla',
          precio: 18.00,
          categoria: 'comidas',
          disponible: true
        },
        cantidad: 1
      },
      {
        producto: {
          id: '10',
          nombre: 'Cappuccino',
          descripcion: 'Cappuccino cremoso con espuma',
          precio: 6.00,
          categoria: 'cafes',
          disponible: true
        },
        cantidad: 1
      }
    ],
    total: 24.00,
    fecha: '2024-01-20 10:20',
    estado: 'listo',
    tipo_pedido: 'delivery'
  },
  {
    id: '4',
    mesaNumero: 2,
    nombreCliente: 'Ana Martínez',
    items: [
      {
        producto: {
          id: '3',
          nombre: 'Tallarines Verdes',
          descripcion: 'Tallarines con salsa de albahaca',
          precio: 16.00,
          categoria: 'comidas',
          disponible: true
        },
        cantidad: 1
      }
    ],
    total: 16.00,
    fecha: '2024-01-20 09:30',
    estado: 'servido',
    tipo_pedido: 'para_servir'
  },
  {
    id: '5',
    mesaNumero: null,
    nombreCliente: 'Luis Rodríguez',
    items: [
      {
        producto: {
          id: '7',
          nombre: 'Jugo de Naranja',
          descripcion: 'Jugo natural de naranja',
          precio: 8.00,
          categoria: 'bebidas',
          disponible: true
        },
        cantidad: 2
      }
    ],
    total: 16.00,
    fecha: '2024-01-20 09:00',
    estado: 'pagado',
    tipo_pedido: 'para_llevar',
    montoPagado: 20.00
  },
  {
    id: '6',
    mesaNumero: null,
    nombreCliente: 'Patricia Jiménez',
    items: [
      {
        producto: {
          id: '4',
          nombre: 'Ceviche',
          descripcion: 'Ceviche de pescado fresco',
          precio: 20.00,
          categoria: 'comidas',
          disponible: true
        },
        cantidad: 1
      }
    ],
    total: 20.00,
    fecha: '2024-01-20 08:45',
    estado: 'en camino',
    tipo_pedido: 'delivery'
  }
];

// Cargar pedidos
const cargarPedidos = async () => {
  try {
    loading.value = true;
    // TODO: Descomentar cuando la tabla pedidos esté lista
    // const { data, error } = await supabase
    //   .from('pedidos')
    //   .select('*')
    //   .order('fecha', { ascending: false });
    // if (error) throw error;
    // pedidos.value = data;
    
    // Por ahora usamos datos de ejemplo
    pedidos.value = pedidosEjemplo;
  } catch (err) {
    console.error('Error cargando pedidos:', err);
  } finally {
    loading.value = false;
  }
};

// Agrupar pedidos por estado con metadata
const pedidosAgrupados = computed(() => {
  const estados = [
    { 
      id: 'pendiente', 
      title: 'Pendientes', 
      icon: 'mdi:clock', 
      color: 'text-yellow-600',
      pedidos: pedidos.value.filter(p => p.estado === 'pendiente')
    },
    { 
      id: 'en preparacion', 
      title: 'En Preparación', 
      icon: 'mdi:chef-hat', 
      color: 'text-blue-600',
      pedidos: pedidos.value.filter(p => p.estado === 'en preparacion')
    },
    { 
      id: 'listo', 
      title: 'Listos para Entregar', 
      icon: 'mdi:check-circle', 
      color: 'text-green-600',
      pedidos: pedidos.value.filter(p => p.estado === 'listo')
    },
    { 
      id: 'servido', 
      title: 'Servidos', 
      icon: 'mdi:room-service', 
      color: 'text-purple-600',
      pedidos: pedidos.value.filter(p => p.estado === 'servido')
    },
    { 
      id: 'en camino', 
      title: 'En Camino', 
      icon: 'mdi:truck-fast', 
      color: 'text-orange-600',
      pedidos: pedidos.value.filter(p => p.estado === 'en camino')
    },
    { 
      id: 'pagado', 
      title: 'Pagados', 
      icon: 'mdi:cash-check', 
      color: 'text-emerald-600',
      pedidos: pedidos.value.filter(p => p.estado === 'pagado')
    },
    { 
      id: 'entregado', 
      title: 'Entregados', 
      icon: 'mdi:package-variant-closed', 
      color: 'text-gray-600',
      pedidos: pedidos.value.filter(p => p.estado === 'entregado')
    }
  ];
  
  return estados.filter(estado => estado.pedidos.length > 0);
});

// Abrir modal con detalles del pedido
const verDetallesPedido = (pedido: Pedido) => {
  pedidoSeleccionado.value = pedido;
  mostrarModal.value = true;
  // Resetear monto recibido al abrir modal
  montoRecibido.value = 0;
};

// Cerrar modal
const cerrarModal = () => {
  mostrarModal.value = false;
  pedidoSeleccionado.value = null;
};

// Cambiar estado del pedido
const cambiarEstado = (pedidoId: string, nuevoEstado: Pedido['estado']) => {
  const pedido = pedidos.value.find(p => p.id === pedidoId);
  if (pedido) {
    pedido.estado = nuevoEstado;
    // TODO: Actualizar en Supabase
  }
};

// Obtener color del estado
const getEstadoColor = (estado: Pedido['estado']) => {
  switch (estado) {
    case 'pendiente': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    case 'en preparacion': return 'bg-blue-100 text-blue-800 border-blue-200';
    case 'listo': return 'bg-green-100 text-green-800 border-green-200';
    case 'servido': return 'bg-purple-100 text-purple-800 border-purple-200';
    case 'pagado': return 'bg-emerald-100 text-emerald-800 border-emerald-200';
    case 'entregado': return 'bg-gray-100 text-gray-800 border-gray-200';
    default: return 'bg-gray-100 text-gray-800';
  }
};

// Calcular vuelto
const vuelto = computed(() => {
  if (!pedidoSeleccionado.value || !montoRecibido.value) return 0;
  return montoRecibido.value - pedidoSeleccionado.value.total;
});

// Procesar pago
const procesarPago = () => {
  if (!pedidoSeleccionado.value || montoRecibido.value < pedidoSeleccionado.value.total) {
    return;
  }
  
  cambiarEstado(pedidoSeleccionado.value.id, 'pagado');
  
  // Actualizar monto pagado
  const pedido = pedidos.value.find(p => p.id === pedidoSeleccionado.value?.id);
  if (pedido) {
    pedido.montoPagado = montoRecibido.value;
  }
  
  // Resetear monto recibido
  montoRecibido.value = 0;
  
  // Cerrar modal después de un breve delay para mostrar confirmación
  setTimeout(() => {
    cerrarModal();
  }, 1000);
};

// Cargar pedidos al montar
cargarPedidos();
</script>

<template>
  <div class="min-h-screen bg-linear-to-br from-amber-50 via-orange-50 to-yellow-50">
    <!-- Header -->
    <header class="bg-linear-to-r from-amber-900 via-amber-800 to-yellow-800 px-3 py-3 sm:px-4 sm:py-6 shadow-lg sticky top-0 z-10">
      <div class="mx-auto max-w-7xl">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2 sm:gap-4">
            <a href="/" class="flex h-8 w-8 sm:h-10 sm:w-10 items-center justify-center rounded-lg bg-white/20 backdrop-blur-sm transition-colors hover:bg-white/30">
              <Icon icon="mdi:arrow-left" class="h-5 w-5 sm:h-6 sm:w-6 text-white" />
            </a>
            <div>
              <h1 class="text-xl font-bold text-white sm:text-2xl lg:text-3xl">Lista de Pedidos</h1>
              <p class="mt-1 text-xs text-amber-100 sm:text-sm hidden sm:block">Gestiona los pedidos de la cafetería</p>
            </div>
          </div>
          
          <div class="flex items-center gap-2">
            <span class="hidden xs:inline text-xs text-amber-100 sm:text-sm">
              Total: {{ pedidos.length }} pedido{{ pedidos.length !== 1 ? 's' : '' }}
            </span>
          </div>
        </div>
      </div>
    </header>

    <!-- Contenedor principal -->
    <div class="mx-auto max-w-7xl px-2 py-4 sm:px-4 sm:py-6">
      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-8 sm:py-12">
        <div class="h-8 w-8 sm:h-10 sm:w-10 animate-spin rounded-full border-4 border-amber-600 border-t-transparent"></div>
      </div>

      <!-- Lista de pedidos por estado (Single Loop) -->
      <div v-else class="space-y-4 sm:space-y-6">
        <!-- Single loop over grouped states -->
        <div v-for="estadoGroup in pedidosAgrupados" :key="estadoGroup.id" class="space-y-3 sm:space-y-4">
          <div class="flex items-center gap-2 mb-3 sm:mb-4">
            <Icon :icon="estadoGroup.icon" :class="`h-4 w-4 sm:h-5 sm:w-5 ${estadoGroup.color}`" />
            <h2 class="text-base font-bold text-gray-900 sm:text-lg">
              {{ estadoGroup.title }} ({{ estadoGroup.pedidos.length }})
            </h2>
          </div>
          <div class="space-y-2 sm:space-y-3">
            <div
              v-for="pedido in estadoGroup.pedidos"
              :key="pedido.id"
              class="bg-white rounded-lg sm:rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-all duration-200 overflow-hidden"
              :class="{ 'opacity-75': estadoGroup.id === 'entregado' }"
            >
              <PedidoCard :pedido="pedido" @ver-detalles="verDetallesPedido" @cambiar-estado="cambiarEstado" />
            </div>
          </div>
        </div>

        <!-- Mensaje si no hay pedidos -->
        <div v-if="pedidos.length === 0" class="py-12 sm:py-16 text-center">
          <div class="mx-auto w-16 h-16 sm:w-20 sm:h-20 bg-gray-100 rounded-full flex items-center justify-center mb-3 sm:mb-4">
            <Icon icon="mdi:clipboard-list" class="h-8 w-8 sm:h-10 sm:w-10 text-gray-400" />
          </div>
          <p class="text-gray-600 font-medium text-sm sm:text-base">No hay pedidos registrados</p>
          <p class="text-xs text-gray-500 mt-1 sm:text-sm sm:mt-1">Los pedidos aparecerán aquí cuando se creen</p>
        </div>
      </div>
    </div>

    <!-- PedidoModal Component -->
    <PedidoModal
      :pedidoSeleccionado="pedidoSeleccionado"
      :mostrarModal="mostrarModal"
      @cerrarModal="cerrarModal"
      @cambiarEstado="cambiarEstado"
      @procesarPago="procesarPago"
    />
  </div>
</template>

<style scoped>
/* Animaciones */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}

.slide-enter-from,
.slide-leave-to {
  transform: translateX(100%);
}
</style>
