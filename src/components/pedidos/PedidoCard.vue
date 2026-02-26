<script setup lang="ts">
import { ref, computed } from 'vue';
import { Icon } from '@iconify/vue';
import confetti from 'canvas-confetti';

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria: string;
  imagen_url?: string;
  disponible: boolean;
}

interface Modificador {
  id: string;
  nombre: string;
  tipo: 'extra' | 'sin' | 'sustitucion';
  precio_adicional: number;
}

interface ItemModificador {
  modificador: Modificador;
  cantidad: number;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
  modificadores?: ItemModificador[];
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
  'editar-pedido': [pedido: Pedido];
  'procesar-pago': [pedidoId: string, montoPagado: number];
  'pago-completado': [];
}>();

// Estado para calculadora inline
const mostrarCalculadora = ref(false);
const montoRecibido = ref(0);
const procesandoPago = ref(false);

// Vuelto calculado
const vuelto = computed(() => {
  return Math.max(0, montoRecibido.value - props.pedido.total);
});

// Toggle calculadora
const toggleCalculadora = () => {
  mostrarCalculadora.value = !mostrarCalculadora.value;
  if (mostrarCalculadora.value) {
    montoRecibido.value = 0;
  }
};

// Procesar pago con confetti y loading
const procesarPago = async () => {
  procesandoPago.value = true;
  
  // Emitir evento para actualizar en BD
  emit('procesar-pago', props.pedido.id, montoRecibido.value);
  
  // Mostrar confetti
  confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
  setTimeout(() => {
    confetti({
      particleCount: 50,
      angle: 60,
      spread: 55,
      origin: { x: 0 },
    });
    confetti({
      particleCount: 50,
      angle: 120,
      spread: 55,
      origin: { x: 1 },
    });
  }, 200);
  
  // Esperar un momento para mostrar el loading y luego refrescar
  setTimeout(() => {
    mostrarCalculadora.value = false;
    montoRecibido.value = 0;
    procesandoPago.value = false;
    emit('pago-completado');
  }, 1000);
};

// Obtener color del modificador según tipo
const getModificadorColor = (tipo: string) => {
  switch (tipo) {
    case 'extra': return 'bg-green-100 text-green-700';
    case 'sin': return 'bg-red-100 text-red-700';
    case 'sustitucion': return 'bg-blue-100 text-blue-700';
    default: return 'bg-gray-100 text-gray-700';
  }
};

// Obtener prefijo del modificador
const getModificadorPrefijo = (tipo: string) => {
  switch (tipo) {
    case 'extra': return '+';
    case 'sin': return 'Sin';
    case 'sustitucion': return '↔';
    default: return '';
  }
};

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
          class="text-sm"
        >
          <div class="flex items-center justify-between">
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
          <!-- Modificadores del producto -->
          <div v-if="item.modificadores && item.modificadores.length > 0" class="ml-7 mt-1 flex flex-wrap gap-1">
            <span
              v-for="mod in item.modificadores"
              :key="mod.modificador.id"
              :class="[
                'inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[10px] font-medium',
                getModificadorColor(mod.modificador.tipo)
              ]"
            >
              <span>{{ getModificadorPrefijo(mod.modificador.tipo) }}</span>
              <span>{{ mod.modificador.nombre }}</span>
              <span v-if="mod.cantidad > 1">x{{ mod.cantidad }}</span>
              <span v-if="mod.modificador.precio_adicional > 0" class="opacity-75">+S/{{ mod.modificador.precio_adicional.toFixed(2) }}</span>
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Calculadora inline (se muestra al hacer clic en pagar) -->
    <Transition name="slide-down">
      <div v-if="mostrarCalculadora && pedido.estado !== 'pagado'" class="bg-emerald-50 border-t border-emerald-200 p-3 space-y-2">
        <div class="flex items-center gap-2">
          <div class="flex-1">
            <label class="text-[10px] font-semibold text-gray-600 block mb-0.5">Recibido:</label>
            <input
              v-model.number="montoRecibido"
              type="number"
              step="0.01"
              min="0"
              placeholder="0.00"
              class="w-full px-2 py-1.5 border border-emerald-300 rounded text-sm font-bold focus:border-emerald-500 focus:outline-none"
            />
          </div>
          <div class="flex-1">
            <label class="text-[10px] font-semibold text-gray-600 block mb-0.5">Vuelto:</label>
            <div class="w-full px-2 py-1.5 bg-emerald-100 border border-emerald-300 rounded text-sm font-bold text-emerald-800">
              S/ {{ vuelto.toFixed(2) }}
            </div>
          </div>
        </div>
        <div class="flex gap-2">
          <button
            @click="toggleCalculadora"
            :disabled="procesandoPago"
            class="flex-1 px-2 py-1.5 text-xs font-semibold rounded bg-gray-200 text-gray-700 hover:bg-gray-300 transition-colors disabled:opacity-50"
          >
            Cancelar
          </button>
          <button
            @click="procesarPago"
            :disabled="procesandoPago || montoRecibido < pedido.total"
            class="flex-1 px-2 py-1.5 text-xs font-bold rounded bg-emerald-600 text-white hover:bg-emerald-700 transition-colors flex items-center justify-center gap-1 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Icon v-if="procesandoPago" icon="mdi:loading" class="h-4 w-4 animate-spin" />
            <Icon v-else icon="mdi:check" class="h-4 w-4" />
            {{ procesandoPago ? 'Procesando...' : 'Pagar' }}
          </button>
        </div>
      </div>
    </Transition>

    <!-- Footer con total y botón -->
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        <span class="text-xs text-gray-500">{{ pedido.items.length }} producto{{ pedido.items.length !== 1 ? 's' : '' }}</span>
      </div>
      <div class="flex items-center gap-2">
        <div class="text-right">
          <span class="text-xs text-gray-500">Total</span>
          <p class="text-lg font-bold text-amber-600">S/ {{ pedido.total.toFixed(2) }}</p>
        </div>
        <button
          v-if="pedido.estado !== 'pagado'"
          @click="emit('editar-pedido', pedido)"
          class="flex items-center gap-1 px-2 py-2 text-xs font-semibold rounded-lg bg-amber-800 text-white hover:bg-amber-900 transition-colors shadow-sm"
          title="Editar pedido"
        >
          <Icon icon="mdi:pencil" class="h-4 w-4" />
        </button>
        <button
          v-if="pedido.estado === 'pendiente'"
          @click="emit('cambiar-estado', pedido.id, 'entregado')"
          class="flex items-center gap-1 px-2 py-2 text-xs font-semibold rounded-lg bg-blue-600 text-white hover:bg-blue-700 transition-colors shadow-sm"
          title="Marcar como entregado"
        >
          <Icon icon="mdi:hand-okay" class="h-4 w-4" />
        </button>
        <button
          v-if="pedido.estado === 'entregado'"
          @click="toggleCalculadora"
          :class="[
            'flex items-center gap-1 px-2 py-2 text-xs font-semibold rounded-lg transition-colors shadow-sm',
            mostrarCalculadora ? 'bg-emerald-700 text-white' : 'bg-emerald-600 text-white hover:bg-emerald-700'
          ]"
          title="Pagar pedido"
        >
          <Icon icon="mdi:cash-register" class="h-4 w-4" />
        </button>
        <button
          @click="emit('ver-detalles', pedido)"
          class="flex items-center gap-1 px-2 py-2 text-xs font-semibold rounded-lg bg-amber-500 text-white hover:bg-amber-600 transition-colors shadow-sm"
          title="Ver detalles"
        >
          <Icon icon="mdi:eye" class="h-4 w-4" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.2s ease;
}
.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>
