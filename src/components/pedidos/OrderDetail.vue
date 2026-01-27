<script setup lang="ts">
import { ref, computed } from 'vue';
import { Icon } from '@iconify/vue';

interface Producto {
  id: string;
  nombre: string;
  precio: number;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
}

interface Pedido {
  id: string;
  items: ItemPedido[];
  total: number;
  estado: string;
  tipo_pedido: 'para_servir' | 'para_llevar' | 'delivery';
  montoPagado?: number;
}

const props = defineProps<{
  pedidoSeleccionado: Pedido;
}>();

const emit = defineEmits<{
  cambiarEstado: [pedidoId: string, nuevoEstado: string];
  procesarPago: [];
}>();

const montoRecibido = ref(0);

// Estados disponibles según el tipo de pedido
const estadosPorTipo = computed(() => {
  switch (props.pedidoSeleccionado.tipo_pedido) {
    case 'para_servir':
      return [
        { id: 'pendiente', label: 'Pendiente', color: 'yellow' },
        { id: 'en preparacion', label: 'En Preparación', color: 'blue' },
        { id: 'listo', label: 'Listo', color: 'green' },
        { id: 'servido', label: 'Servido', color: 'purple' },
        { id: 'pagado', label: 'Pagado', color: 'emerald' },
        { id: 'entregado', label: 'Entregado', color: 'gray' }
      ];
    case 'para_llevar':
      return [
        { id: 'pendiente', label: 'Pendiente', color: 'yellow' },
        { id: 'en preparacion', label: 'En Preparación', color: 'blue' },
        { id: 'listo', label: 'Listo', color: 'green' },
        { id: 'pagado', label: 'Pagado', color: 'emerald' },
        { id: 'entregado', label: 'Entregado', color: 'gray' }
      ];
    case 'delivery':
      return [
        { id: 'pendiente', label: 'Pendiente', color: 'yellow' },
        { id: 'en preparacion', label: 'En Preparación', color: 'blue' },
        { id: 'listo', label: 'Listo', color: 'green' },
        { id: 'en camino', label: 'En Camino', color: 'orange' },
        { id: 'entregado', label: 'Entregado', color: 'gray' },
        { id: 'pagado', label: 'Pagado', color: 'emerald' }
      ];
    default:
      return [];
  }
});

// Calcular vuelto
const vuelto = computed(() => {
  return Math.max(0, montoRecibido.value - props.pedidoSeleccionado.total);
});

// Determinar si mostrar calculadora de pago
const mostrarCalculadora = computed(() => {
  const estadosConPago = ['servido', 'pagado'];
  
  if (props.pedidoSeleccionado.tipo_pedido === 'para_servir') {
    return estadosConPago.includes(props.pedidoSeleccionado.estado);
  } else if (props.pedidoSeleccionado.tipo_pedido === 'para_llevar') {
    return props.pedidoSeleccionado.estado === 'listo' || props.pedidoSeleccionado.estado === 'pagado';
  } else if (props.pedidoSeleccionado.tipo_pedido === 'delivery') {
    return props.pedidoSeleccionado.estado === 'entregado' || props.pedidoSeleccionado.estado === 'pagado';
  }
  
  return false;
});

const cambiarEstado = (nuevoEstado: string) => {
  emit('cambiarEstado', props.pedidoSeleccionado.id, nuevoEstado);
};

const procesarPago = () => {
  emit('procesarPago');
};
</script>

<template>
  <div>
    <!-- Productos del Pedido -->
    <div>
      <h4 class="text-sm font-bold text-gray-900 mb-3">Productos del Pedido</h4>
      <div class="space-y-2">
        <div
          v-for="item in pedidoSeleccionado.items"
          :key="item.producto.id"
          class="flex items-center justify-between p-3 bg-white border border-gray-200 rounded-lg"
        >
          <div class="flex-1">
            <p class="text-sm font-semibold text-gray-900">{{ item.producto.nombre }}</p>
            <p class="text-xs text-gray-500">S/ {{ item.producto.precio.toFixed(2) }} c/u</p>
          </div>
          <div class="text-right">
            <p class="text-sm font-bold text-gray-900">×{{ item.cantidad }}</p>
            <p class="text-sm font-bold text-amber-600">S/ {{ (item.producto.precio * item.cantidad).toFixed(2) }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Total -->
    <div class="bg-linear-to-r from-amber-600 to-orange-600 rounded-lg p-4 text-white">
      <div class="flex items-center justify-between">
        <span class="text-sm font-semibold">TOTAL A PAGAR</span>
        <span class="text-2xl font-bold">S/ {{ pedidoSeleccionado.total.toFixed(2) }}</span>
      </div>
    </div>

    <!-- Calculadora de Pago -->
    <div v-if="mostrarCalculadora" class="bg-linear-to-br from-emerald-50 to-teal-50 border-2 border-emerald-200 rounded-xl p-4 space-y-3">
      <h4 class="text-sm font-bold text-gray-900 flex items-center gap-2">
        <Icon icon="mdi:calculator" class="h-4 w-4 text-emerald-600" />
        Calculadora de Pago
      </h4>
      
      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="text-xs font-semibold text-gray-700 block mb-1">Monto Recibido:</label>
          <input
            v-model.number="montoRecibido"
            type="number"
            step="0.01"
            min="0"
            placeholder="0.00"
            class="w-full px-3 py-2 border-2 border-emerald-300 rounded-lg text-sm font-bold focus:border-emerald-500 focus:outline-none"
            :disabled="pedidoSeleccionado.estado === 'pagado'"
          />
        </div>
        <div>
          <label class="text-xs font-semibold text-gray-700 block mb-1">Vuelto:</label>
          <div class="w-full px-3 py-2 bg-emerald-100 border-2 border-emerald-300 rounded-lg text-sm font-bold text-emerald-800">
            S/ {{ vuelto.toFixed(2) }}
          </div>
        </div>
      </div>

      <div v-if="pedidoSeleccionado.estado === 'pagado'" class="bg-emerald-100 border border-emerald-300 rounded-lg p-3">
        <div class="flex items-center justify-between">
          <span class="text-sm font-semibold text-emerald-800">Pagado:</span>
          <span class="text-sm font-bold text-emerald-800">S/ {{ pedidoSeleccionado.montoPagado?.toFixed(2) || '0.00' }}</span>
        </div>
      </div>

      <button
        v-if="pedidoSeleccionado.estado !== 'pagado' && montoRecibido >= pedidoSeleccionado.total"
        @click="procesarPago"
        class="w-full bg-emerald-600 text-white py-3 px-4 rounded-lg font-bold text-lg shadow-lg hover:bg-emerald-700 transition-all duration-200 active:scale-95"
      >
        <Icon icon="mdi:cash-check" class="h-5 w-5 inline mr-2" />
        PAGADO
      </button>
    </div>

    <!-- Acciones de Estado -->
    <div class="space-y-2">
      <label class="text-xs font-bold text-gray-700">Cambiar Estado:</label>
      <div class="grid grid-cols-2 gap-2">
        <button
          v-for="estado in estadosPorTipo"
          :key="estado.id"
          @click="cambiarEstado(estado.id)"
          :disabled="pedidoSeleccionado.estado === estado.id"
          :class="[
            'px-3 py-2 text-xs font-semibold rounded-lg border-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors',
            estado.color === 'yellow' && 'border-yellow-200 bg-yellow-50 text-yellow-800 hover:bg-yellow-100',
            estado.color === 'blue' && 'border-blue-200 bg-blue-50 text-blue-800 hover:bg-blue-100',
            estado.color === 'green' && 'border-green-200 bg-green-50 text-green-800 hover:bg-green-100',
            estado.color === 'purple' && 'border-purple-200 bg-purple-50 text-purple-800 hover:bg-purple-100',
            estado.color === 'emerald' && 'border-emerald-200 bg-emerald-50 text-emerald-800 hover:bg-emerald-100',
            estado.color === 'orange' && 'border-orange-200 bg-orange-50 text-orange-800 hover:bg-orange-100',
            estado.color === 'gray' && 'border-gray-200 bg-gray-50 text-gray-800 hover:bg-gray-100'
          ]"
        >
          {{ estado.label }}
        </button>
      </div>
    </div>
  </div>
</template>
