<script setup lang="ts">
import { Icon } from '@iconify/vue';

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
}

interface Props {
  pedido: Pedido;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  'ver-detalles': [pedido: Pedido];
  'cambiar-estado': [pedidoId: string, estado: Pedido['estado']];
}>();

const getEstadoColor = (estado: Pedido['estado']) => {
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

const getTipoPedidoDisplay = (tipo: string) => {
  switch (tipo) {
    case 'para_servir': return { icon: '🍽️', label: 'Mesa' };
    case 'para_llevar': return { icon: '🥡', label: 'Llevar' };
    case 'delivery': return { icon: '🏠', label: 'Delivery' };
    default: return { icon: '📋', label: 'Pedido' };
  }
};
</script>

<template>
  <div class="p-4">
    <div class="flex items-center justify-between">
      <div class="flex-1">
        <div class="flex items-center gap-3 mb-2">
          <span class="text-sm font-bold text-gray-900">Pedido #{{ pedido.id }}</span>
          <span class="text-xs font-semibold px-2 py-1 rounded-full bg-gray-100 text-gray-700 border border-gray-200">
            {{ getTipoPedidoDisplay(pedido.tipo_pedido).icon }} {{ getTipoPedidoDisplay(pedido.tipo_pedido).label }}
          </span>
          <span :class="`text-xs font-semibold px-2 py-1 rounded-full border ${getEstadoColor(pedido.estado)}`">
            {{ pedido.estado.charAt(0).toUpperCase() + pedido.estado.slice(1) }}
          </span>
        </div>
        <div class="flex items-center gap-4 text-xs text-gray-600">
          <div v-if="pedido.tipo_pedido === 'para_servir'" class="flex items-center gap-1">
            <Icon icon="mdi:table-furniture" class="h-3 w-3" />
            Mesa {{ pedido.mesaNumero || 'N/A' }}
          </div>
          <div class="flex items-center gap-1">
            <Icon icon="mdi:account" class="h-3 w-3" />
            {{ pedido.nombreCliente || 'Sin cliente' }}
          </div>
          <div class="flex items-center gap-1">
            <Icon icon="mdi:clock" class="h-3 w-3" />
            {{ pedido.fecha }}
          </div>
        </div>
        <div class="mt-2 text-xs text-gray-500">
          {{ pedido.items.length }} producto{{ pedido.items.length !== 1 ? 's' : '' }}
        </div>
      </div>
      <div class="flex flex-col items-end gap-2">
        <span class="text-lg font-bold text-amber-600">S/ {{ pedido.total.toFixed(2) }}</span>
        <button
          @click="emit('ver-detalles', pedido)"
          class="flex items-center gap-1 px-3 py-1.5 text-xs font-semibold rounded-lg bg-amber-100 text-amber-800 hover:bg-amber-200 transition-colors"
        >
          <Icon icon="mdi:eye" class="h-3 w-3" />
          Ver detalles
        </button>
      </div>
    </div>
  </div>
</template>
