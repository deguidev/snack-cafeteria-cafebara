<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';
import confetti from 'canvas-confetti';
import PedidoCard from './PedidoCard.vue';
import PedidoModal from './PedidoModal.vue';

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria_id: string;
  imagen_url?: string;
  disponible: boolean;
}

interface Modificador {
  id: string;
  nombre: string;
  tipo: string;
  precio_adicional: number;
}

interface ItemModificador {
  modificador_id: string;
  nombre_modificador: string;
  precio_adicional: number;
  cantidad: number;
}

interface ItemPedido {
  id: string;
  producto: Producto;
  cantidad: number;
  precio_unitario: number;
  subtotal: number;
  modificadores?: ItemModificador[];
}

interface Pedido {
  id: string;
  numero_pedido: number;
  mesa_numero: number | null;
  nombre_cliente: string | null;
  telefono: string | null;
  direccion: string | null;
  items: ItemPedido[];
  total: number;
  created_at: string;
  estado: 'pendiente' | 'en_preparacion' | 'listo' | 'servido' | 'pagado' | 'entregado' | 'en_camino' | 'cancelado';
  tipo_pedido: 'para_servir' | 'para_llevar' | 'delivery';
  monto_pagado?: number;
}

// Estado
const pedidos = ref<Pedido[]>([]);
const loading = ref(true);
const pedidoSeleccionado = ref<Pedido | null>(null);
const mostrarModal = ref(false);
const montoRecibido = ref<number>(0);

// Filtro de fecha (por defecto hoy)
const fechaSeleccionada = ref(new Date().toISOString().split('T')[0]);

// Formatear fecha para mostrar
const fechaMostrar = computed(() => {
  const fecha = new Date(fechaSeleccionada.value + 'T12:00:00');
  const hoy = new Date();
  const ayer = new Date(hoy);
  ayer.setDate(ayer.getDate() - 1);
  
  if (fechaSeleccionada.value === hoy.toISOString().split('T')[0]) {
    return 'Hoy';
  } else if (fechaSeleccionada.value === ayer.toISOString().split('T')[0]) {
    return 'Ayer';
  }
  return fecha.toLocaleDateString('es-PE', { weekday: 'long', day: 'numeric', month: 'long' });
});

// Cambiar fecha y recargar
const cambiarFecha = (fecha: string) => {
  fechaSeleccionada.value = fecha;
  cargarPedidos();
};

// Cargar pedidos desde Supabase (filtrado por fecha)
const cargarPedidos = async () => {
  try {
    loading.value = true;
    
    // Calcular rango de fecha seleccionada
    const inicioFecha = new Date(fechaSeleccionada.value + 'T00:00:00').toISOString();
    const finFecha = new Date(fechaSeleccionada.value + 'T23:59:59').toISOString();
    
    // Cargar pedidos con sus detalles y productos (filtrado por fecha)
    const { data: pedidosData, error: errorPedidos } = await supabase
      .from('pedidos')
      .select(`
        *,
        pedido_detalle (
          id,
          producto_id,
          cantidad,
          precio_unitario,
          subtotal,
          notas,
          productos (
            id,
            nombre,
            descripcion,
            precio,
            categoria_id,
            imagen_url,
            disponible
          ),
          pedido_detalle_modificadores (
            id,
            modificador_id,
            nombre_modificador,
            tipo,
            precio_adicional,
            cantidad
          )
        )
      `)
      .gte('created_at', inicioFecha)
      .lte('created_at', finFecha)
      .order('created_at', { ascending: false });

    if (errorPedidos) throw errorPedidos;

    // Transformar datos al formato esperado
    pedidos.value = (pedidosData || []).map(pedido => ({
      ...pedido,
      items: (pedido.pedido_detalle || []).map((detalle: any) => ({
        id: detalle.id,
        producto: detalle.productos,
        cantidad: detalle.cantidad,
        precio_unitario: detalle.precio_unitario,
        subtotal: detalle.subtotal,
        // Transformar modificadores al formato esperado por PedidoCard
        modificadores: (detalle.pedido_detalle_modificadores || []).map((mod: any) => ({
          modificador: {
            id: mod.modificador_id,
            nombre: mod.nombre_modificador,
            tipo: mod.tipo || 'extra', // Por defecto 'extra' si no tiene tipo
            precio_adicional: mod.precio_adicional || 0
          },
          cantidad: mod.cantidad || 1
        }))
      }))
    }));

  } catch (err) {
    console.error('Error cargando pedidos:', err);
  } finally {
    loading.value = false;
  }
};

// Agrupar pedidos por estado con metadata (4 estados principales)
const pedidosAgrupados = computed(() => {
  const estados = [
    { 
      id: 'pendiente', 
      title: 'Pendientes', 
      icon: 'mdi:clock-outline', 
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-50',
      pedidos: pedidos.value.filter(p => p.estado === 'pendiente')
    },
    { 
      id: 'en_preparacion', 
      title: 'En Preparación', 
      icon: 'mdi:chef-hat', 
      color: 'text-blue-600',
      bgColor: 'bg-blue-50',
      pedidos: pedidos.value.filter(p => p.estado === 'en_preparacion')
    },
    { 
      id: 'listo', 
      title: 'Listos', 
      icon: 'mdi:check-circle', 
      color: 'text-green-600',
      bgColor: 'bg-green-50',
      pedidos: pedidos.value.filter(p => p.estado === 'listo')
    },
    { 
      id: 'entregado', 
      title: 'Entregados', 
      icon: 'mdi:hand-okay', 
      color: 'text-emerald-600',
      bgColor: 'bg-emerald-50',
      pedidos: pedidos.value.filter(p => p.estado === 'entregado')
    },
    { 
      id: 'pagado', 
      title: 'Pagados', 
      icon: 'mdi:cash-check', 
      color: 'text-teal-600',
      bgColor: 'bg-teal-50',
      pedidos: pedidos.value.filter(p => p.estado === 'pagado')
    },
    { 
      id: 'cancelado', 
      title: 'Cancelados', 
      icon: 'mdi:close-circle', 
      color: 'text-red-600',
      bgColor: 'bg-red-50',
      pedidos: pedidos.value.filter(p => p.estado === 'cancelado')
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

// Editar pedido - redirigir a AnotarPedido con los datos del pedido
const editarPedido = (pedido: Pedido) => {
  // Guardar el pedido en localStorage para que AnotarPedido lo cargue
  // Los modificadores ya vienen transformados desde cargarPedidos()
  const pedidoParaEditar = {
    id: pedido.id,
    numero_pedido: pedido.numero_pedido,
    mesa_numero: pedido.mesa_numero,
    nombre_cliente: pedido.nombre_cliente,
    telefono: pedido.telefono || '',
    direccion: pedido.direccion || '',
    tipo_pedido: pedido.tipo_pedido,
    items: pedido.items.map(item => ({
      producto: {
        id: item.producto?.id || '',
        nombre: item.producto?.nombre || 'Producto',
        descripcion: item.producto?.descripcion || '',
        precio: item.producto?.precio || 0,
        categoria: item.producto?.categoria_id || '',
        imagen_url: item.producto?.imagen_url || '',
        disponible: item.producto?.disponible ?? true
      },
      cantidad: item.cantidad || 1,
      // Los modificadores ya tienen la estructura correcta desde cargarPedidos
      modificadores: item.modificadores || []
    }))
  };
  localStorage.setItem('pedidoParaEditar', JSON.stringify(pedidoParaEditar));
  window.location.href = '/anotar-pedido';
};

// Procesar pago desde la calculadora inline de PedidoCard
const procesarPagoInline = async (pedidoId: string, montoPagado: number) => {
  try {
    const { error } = await supabase
      .from('pedidos')
      .update({ 
        estado: 'pagado',
        monto_pagado: montoPagado
      })
      .eq('id', pedidoId);

    if (error) throw error;

    // Actualizar localmente
    const pedido = pedidos.value.find(p => p.id === pedidoId);
    if (pedido) {
      pedido.estado = 'pagado';
    }
  } catch (err) {
    console.error('Error procesando pago:', err);
    alert('Error al procesar el pago');
  }
};

// Cambiar estado del pedido
const cambiarEstado = async (pedidoId: string, nuevoEstado: Pedido['estado']) => {
  try {
    const { error } = await supabase
      .from('pedidos')
      .update({ estado: nuevoEstado })
      .eq('id', pedidoId);

    if (error) throw error;

    // Actualizar localmente
    const pedido = pedidos.value.find(p => p.id === pedidoId);
    if (pedido) {
      pedido.estado = nuevoEstado;
    }
  } catch (err) {
    console.error('Error actualizando estado:', err);
    alert('Error al actualizar el estado del pedido');
  }
};

// Obtener color del estado
const getEstadoColor = (estado: Pedido['estado']) => {
  switch (estado) {
    case 'pendiente': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    case 'en_preparacion': return 'bg-blue-100 text-blue-800 border-blue-200';
    case 'listo': return 'bg-green-100 text-green-800 border-green-200';
    case 'servido': return 'bg-purple-100 text-purple-800 border-purple-200';
    case 'pagado': return 'bg-emerald-100 text-emerald-800 border-emerald-200';
    case 'entregado': return 'bg-gray-100 text-gray-800 border-gray-200';
    case 'en_camino': return 'bg-orange-100 text-orange-800 border-orange-200';
    case 'cancelado': return 'bg-red-100 text-red-800 border-red-200';
    default: return 'bg-gray-100 text-gray-800';
  }
};

// Calcular vuelto
const vuelto = computed(() => {
  if (!pedidoSeleccionado.value || !montoRecibido.value) return 0;
  return montoRecibido.value - pedidoSeleccionado.value.total;
});

// Procesar pago (simplificado - solo marca como pagado)
const procesarPago = async () => {
  if (!pedidoSeleccionado.value) return;
  
  try {
    // Actualizar estado a pagado en Supabase
    const { error } = await supabase
      .from('pedidos')
      .update({ 
        estado: 'pagado',
        monto_pagado: pedidoSeleccionado.value.total
      })
      .eq('id', pedidoSeleccionado.value.id);

    if (error) throw error;

    // Actualizar localmente
    const pedido = pedidos.value.find(p => p.id === pedidoSeleccionado.value?.id);
    if (pedido) {
      pedido.estado = 'pagado';
      pedido.monto_pagado = pedido.total;
    }
    
    // 🎉 Confetti al pagar
    confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
    setTimeout(() => {
      confetti({ particleCount: 50, angle: 60, spread: 55, origin: { x: 0 } });
      confetti({ particleCount: 50, angle: 120, spread: 55, origin: { x: 1 } });
    }, 250);
    
    // Cerrar modal después de un breve delay
    setTimeout(() => {
      cerrarModal();
    }, 1500);
  } catch (err) {
    console.error('Error procesando pago:', err);
    alert('Error al procesar el pago');
  }
};

// Eliminar pedido completo (pedido, detalles y modificadores)
const eliminarPedido = async (pedidoId: string) => {
  try {
    // La eliminación en cascada se encarga de pedido_detalle y pedido_detalle_modificadores
    // gracias a ON DELETE CASCADE en las foreign keys
    const { error } = await supabase
      .from('pedidos')
      .delete()
      .eq('id', pedidoId);

    if (error) throw error;

    // Eliminar localmente
    pedidos.value = pedidos.value.filter(p => p.id !== pedidoId);
    
    // Cerrar modal
    cerrarModal();
    
    console.log('Pedido eliminado exitosamente');
  } catch (err) {
    console.error('Error eliminando pedido:', err);
    alert('Error al eliminar el pedido');
  }
};

// Formatear fecha
const formatearFecha = (fecha: string) => {
  const date = new Date(fecha);
  return date.toLocaleString('es-PE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// Cargar pedidos al montar
onMounted(() => {
  cargarPedidos();
});
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-amber-50 via-orange-50 to-yellow-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-amber-900 via-amber-800 to-yellow-800 px-3 py-3 sm:px-4 sm:py-6 shadow-lg sticky top-0 z-10">
      <div class="mx-auto max-w-7xl">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2 sm:gap-4">
            <a href="/" class="flex h-8 w-8 sm:h-10 sm:w-10 items-center justify-center rounded-lg bg-white/20 backdrop-blur-sm transition-colors hover:bg-white/30">
              <Icon icon="mdi:arrow-left" class="h-5 w-5 sm:h-6 sm:w-6 text-white" />
            </a>
            <div>
              <h1 class="text-xl font-bold text-white sm:text-2xl lg:text-3xl">Lista de Pedidos</h1>
              <p class="mt-1 text-xs text-amber-100 sm:text-sm  sm:block">Gestiona los pedidos de la cafetería</p>
            </div>
          </div>
          
          <div class="flex items-center gap-2 sm:gap-3">
            <span class="xs:inline text-xs text-amber-100 sm:text-sm">
              {{ pedidos.length }} pedido{{ pedidos.length !== 1 ? 's' : '' }}
            </span>
            <a 
              href="/anotar-pedido" 
              class="flex items-center gap-1.5 rounded-lg bg-amber-500 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-400 transition-colors sm:px-4 sm:py-2 sm:text-sm"
            >
              <Icon icon="mdi:plus" class="h-4 w-4" />
              <span class="hidden sm:inline">Nuevo Pedido</span>
              <span class="sm:hidden">Nuevo</span>
            </a>
          </div>
        </div>
        
        <!-- Filtro de fecha -->
        <div class="mt-3 flex items-center justify-between gap-3 bg-white/10 rounded-lg px-3 py-2">
          <div class="flex items-center gap-2">
            <Icon icon="mdi:calendar" class="h-5 w-5 text-amber-200" />
            <span class="text-sm font-semibold text-white">{{ fechaMostrar }}</span>
          </div>
          <div class="flex items-center gap-2">
            <button
              @click="cambiarFecha(new Date(new Date(fechaSeleccionada).getTime() - 86400000).toISOString().split('T')[0])"
              class="flex h-8 w-8 items-center justify-center rounded-lg bg-white/20 hover:bg-white/30 transition-colors"
            >
              <Icon icon="mdi:chevron-left" class="h-5 w-5 text-white" />
            </button>
            <input
              type="date"
              :value="fechaSeleccionada"
              @change="cambiarFecha(($event.target as HTMLInputElement).value)"
              class="rounded-lg border-0 bg-white/20 px-3 py-1.5 text-sm text-white placeholder-amber-200 focus:ring-2 focus:ring-white/50"
            />
            <button
              @click="cambiarFecha(new Date(new Date(fechaSeleccionada).getTime() + 86400000).toISOString().split('T')[0])"
              class="flex h-8 w-8 items-center justify-center rounded-lg bg-white/20 hover:bg-white/30 transition-colors"
              :disabled="fechaSeleccionada >= new Date().toISOString().split('T')[0]"
              :class="{ 'opacity-50 cursor-not-allowed': fechaSeleccionada >= new Date().toISOString().split('T')[0] }"
            >
              <Icon icon="mdi:chevron-right" class="h-5 w-5 text-white" />
            </button>
            <button
              v-if="fechaSeleccionada !== new Date().toISOString().split('T')[0]"
              @click="cambiarFecha(new Date().toISOString().split('T')[0])"
              class="ml-2 rounded-lg bg-amber-500 px-3 py-1.5 text-xs font-semibold text-white hover:bg-amber-400 transition-colors"
            >
              Hoy
            </button>
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
              <PedidoCard :pedido="pedido" @ver-detalles="verDetallesPedido" @cambiar-estado="cambiarEstado" @editar-pedido="editarPedido" @procesar-pago="procesarPagoInline" @pago-completado="cargarPedidos" />
            </div>
          </div>
        </div>

        <!-- Mensaje si no hay pedidos -->
        <div v-if="pedidos.length === 0" class="py-12 sm:py-16 text-center">
          <div class="mx-auto w-16 h-16 sm:w-20 sm:h-20 bg-gray-100 rounded-full flex items-center justify-center mb-3 sm:mb-4">
            <Icon icon="mdi:clipboard-list" class="h-8 w-8 sm:h-10 sm:w-10 text-gray-400" />
          </div>
          <p class="text-gray-600 font-medium text-sm sm:text-base">No hay pedidos para {{ fechaMostrar.toLowerCase() }}</p>
          <p class="text-xs text-gray-500 mt-1 sm:text-sm sm:mt-1">Selecciona otra fecha o crea un nuevo pedido</p>
        </div>
      </div>
    </div>

    <!-- PedidoModal Component -->
    <PedidoModal
      :pedidoSeleccionado="pedidoSeleccionado"
      :mostrarModal="mostrarModal"
      :montoRecibido="montoRecibido"
      @cerrarModal="cerrarModal"
      @cambiarEstado="cambiarEstado"
      @procesarPago="procesarPago"
      @eliminarPedido="eliminarPedido"
      @update:montoRecibido="montoRecibido = $event"
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
