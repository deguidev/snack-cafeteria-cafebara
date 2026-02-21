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
  numero_pedido: number;
  mesa_numero: number | null;
  nombre_cliente: string | null;
  items: ItemPedido[];
  total: number;
  created_at: string;
  estado: 'pendiente' | 'en_preparacion' | 'listo' | 'servido' | 'pagado' | 'entregado' | 'en_camino' | 'cancelado';
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

const getTipoPedidoDisplay = (tipo: string) => {
  switch (tipo) {
    case 'para_servir': return { icon: '🍽️', label: 'Mesa' };
    case 'para_llevar': return { icon: '🥡', label: 'Llevar' };
    case 'delivery': return { icon: '🏠', label: 'Delivery' };
    default: return { icon: '📋', label: 'Pedido' };
  }
};

const formatearFecha = (fecha: string) => {
  const date = new Date(fecha);
  return date.toLocaleString('es-PE', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

const formatearEstado = (estado: string) => {
  return estado.replace(/_/g, ' ');
};
</script>

<template>
  <div class="p-4">
    <!-- Header del pedido -->
    <div class="flex items-start justify-between mb-3">
      <div class="flex-1">
        <div class="flex items-center flex-wrap gap-2 mb-2">
          <span class="text-base font-bold text-gray-900">Pedido #{{ pedido.numero_pedido }}</span>
          <span class="text-xs font-semibold px-2 py-0.5 rounded-full bg-gray-100 text-gray-700 border border-gray-200">
            {{ getTipoPedidoDisplay(pedido.tipo_pedido).icon }} {{ getTipoPedidoDisplay(pedido.tipo_pedido).label }}
          </span>
          <span :class="`text-xs font-semibold px-2 py-0.5 rounded-full border ${getEstadoColor(pedido.estado)}`">
            {{ formatearEstado(pedido.estado).charAt(0).toUpperCase() + formatearEstado(pedido.estado).slice(1) }}
          </span>
        </div>
        <div class="flex items-center flex-wrap gap-3 text-xs text-gray-500">
          <div v-if="pedido.tipo_pedido === 'para_servir'" class="flex items-center gap-1">
            <Icon icon="mdi:table-furniture" class="h-3.5 w-3.5 text-amber-600" />
            <span class="font-semibold">Mesa {{ pedido.mesa_numero || '-' }}</span>
          </div>
          <div class="flex items-center gap-1">
            <Icon icon="mdi:account" class="h-3.5 w-3.5" />
            {{ pedido.nombre_cliente || 'Sin cliente' }}
          </div>
          <div class="flex items-center gap-1">
            <Icon icon="mdi:clock-outline" class="h-3.5 w-3.5" />
            {{ formatearFecha(pedido.created_at) }}
          </div>
        </div>
      </div>
    </div>

    <!-- Lista de productos -->
    <div class="bg-gray-50 rounded-lg p-3 mb-3">
      <div class="space-y-2">
        <div 
          v-for="(item, index) in pedido.items" 
          :key="index"
          class="flex items-center justify-between text-sm"
        >
          <div class="flex items-center gap-2 flex-1 min-w-0">
            <span class="flex-shrink-0 w-5 h-5 flex items-center justify-center rounded-full bg-amber-100 text-amber-800 text-xs font-bold">
              {{ item.cantidad }}
            </span>
            <span class="text-gray-800 font-medium truncate">{{ item.producto.nombre }}</span>
          </div>
          <div class="flex items-center gap-3 flex-shrink-0 ml-2">
            <span class="text-xs text-gray-500">S/{{ item.producto.precio.toFixed(2) }} c/u</span>
            <span class="text-sm font-bold text-gray-900">S/{{ (item.producto.precio * item.cantidad).toFixed(2) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer con total y botón -->
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        <span class="text-xs text-gray-500">{{ pedido.items.length }} producto{{ pedido.items.length !== 1 ? 's' : '' }}</span>
      </div>
      <div class="flex items-center gap-3">
        <div class="text-right">
          <span class="text-xs text-gray-500">Total</span>
          <p class="text-lg font-bold text-amber-600">S/ {{ pedido.total.toFixed(2) }}</p>
        </div>
        <button
          @click="emit('ver-detalles', pedido)"
          class="flex items-center gap-1 px-3 py-2 text-xs font-semibold rounded-lg bg-amber-500 text-white hover:bg-amber-600 transition-colors shadow-sm"
        >
          <Icon icon="mdi:eye" class="h-4 w-4" />
          Ver detalles
        </button>
      </div>
    </div>
  </div>
</template>
