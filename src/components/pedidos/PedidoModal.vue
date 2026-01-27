<script setup lang="ts">
import { ref, computed } from 'vue';
import { Icon } from '@iconify/vue';
import OrderDetail from './OrderDetail.vue';

interface Pedido {
  id: string;
  mesaNumero: number | null;
  nombreCliente: string;
  items: any[];
  total: number;
  fecha: string;
  estado: string;
  tipo_pedido: 'para_servir' | 'para_llevar' | 'delivery';
  montoPagado?: number;
}

const props = defineProps<{
  pedidoSeleccionado: Pedido | null;
  mostrarModal: boolean;
}>();

const emit = defineEmits<{
  cerrarModal: [];
  cambiarEstado: [pedidoId: string, nuevoEstado: string];
  procesarPago: [];
}>();

// Obtener color del estado
const getEstadoColor = (estado: string) => {
  switch (estado) {
    case 'pendiente': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
    case 'en preparacion': return 'bg-blue-100 text-blue-800 border-blue-200';
    case 'listo': return 'bg-green-100 text-green-800 border-green-200';
    case 'servido': return 'bg-purple-100 text-purple-800 border-purple-200';
    case 'pagado': return 'bg-emerald-100 text-emerald-800 border-emerald-200';
    case 'entregado': return 'bg-gray-100 text-gray-800 border-gray-200';
    case 'en camino': return 'bg-orange-100 text-orange-800 border-orange-200';
    default: return 'bg-gray-100 text-gray-800';
  }
};

// Obtener tipo de pedido display
const getTipoPedidoDisplay = (tipo: string) => {
  switch (tipo) {
    case 'para_servir': return { icon: '🍽️', label: 'Para Servir' };
    case 'para_llevar': return { icon: '🥡', label: 'Para Llevar' };
    case 'delivery': return { icon: '🏠', label: 'Delivery' };
    default: return { icon: '📋', label: 'Pedido' };
  }
};

const cerrarModal = () => {
  emit('cerrarModal');
};

const cambiarEstado = (pedidoId: string, nuevoEstado: string) => {
  emit('cambiarEstado', pedidoId, nuevoEstado);
};

const procesarPago = () => {
  emit('procesarPago');
};
</script>

<template>
  <Transition name="fade">
    <div
      v-if="mostrarModal"
      @click="cerrarModal"
      class="fixed inset-0 bg-black/40 backdrop-blur-sm z-100"
    ></div>
  </Transition>

  <Transition name="slide">
    <div
      v-if="mostrarModal && pedidoSeleccionado"
      class="fixed right-0 top-0 bottom-0 w-full sm:w-[500px] bg-white shadow-2xl z-101 overflow-hidden"
    >
      <div class="flex h-full flex-col">
        <!-- Header del modal -->
        <div class="bg-linear-to-r from-amber-600 to-orange-600 p-4 text-white shadow-lg">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-bold">Detalles del Pedido #{{ pedidoSeleccionado.id }}</h3>
              <p class="text-xs opacity-90 mt-1">{{ pedidoSeleccionado.fecha }}</p>
            </div>
            <button
              @click="cerrarModal"
              class="flex h-9 w-9 items-center justify-center rounded-full bg-white/20 transition-colors hover:bg-white/30"
            >
              <Icon icon="mdi:close" class="h-6 w-6" />
            </button>
          </div>
        </div>

        <!-- Contenido del modal -->
        <div class="flex-1 overflow-y-auto p-4 space-y-4">
          <!-- Información del cliente y mesa -->
          <div class="bg-gray-50 rounded-lg p-4 space-y-3">
            <div class="flex items-center gap-2">
              <Icon icon="mdi:table-furniture" class="h-4 w-4 text-amber-600" />
              <span class="text-sm font-semibold text-gray-700">
                Mesa {{ pedidoSeleccionado.mesaNumero || 'Sin asignar' }}
              </span>
            </div>
            <div class="flex items-center gap-2">
              <Icon icon="mdi:account" class="h-4 w-4 text-amber-600" />
              <span class="text-sm text-gray-700">
                {{ pedidoSeleccionado.nombreCliente || 'Cliente no especificado' }}
              </span>
            </div>
            <div class="flex items-center gap-2">
              <Icon icon="mdi:clipboard-check" class="h-4 w-4 text-amber-600" />
              <span class="text-sm text-gray-700">
                {{ getTipoPedidoDisplay(pedidoSeleccionado.tipo_pedido).icon }} 
                {{ getTipoPedidoDisplay(pedidoSeleccionado.tipo_pedido).label }}
              </span>
            </div>
            <div class="flex items-center gap-2">
              <Icon icon="mdi:tag" class="h-4 w-4 text-amber-600" />
              <span :class="`text-xs font-semibold px-2 py-1 rounded-full border ${getEstadoColor(pedidoSeleccionado.estado)}`">
                {{ pedidoSeleccionado.estado.charAt(0).toUpperCase() + pedidoSeleccionado.estado.slice(1) }}
              </span>
            </div>
          </div>

          <!-- OrderDetail Component -->
          <OrderDetail
            :pedidoSeleccionado="pedidoSeleccionado"
            @cambiarEstado="cambiarEstado"
            @procesarPago="procesarPago"
          />
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
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

.slide-enter-from {
  transform: translateX(100%);
}

.slide-leave-to {
  transform: translateX(100%);
}
</style>
