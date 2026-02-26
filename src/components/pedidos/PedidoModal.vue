<script setup lang="ts">
import { ref, computed } from 'vue';
import { Icon } from '@iconify/vue';

interface Producto {
  id: string;
  nombre: string;
  descripcion?: string;
  precio: number;
  imagen_url?: string;
}

interface ItemModificador {
  modificador_id?: string;
  nombre_modificador?: string;
  precio_adicional?: number;
  cantidad?: number;
  // Estructura alternativa (transformada)
  modificador?: {
    id: string;
    nombre: string;
    tipo: 'extra' | 'sin' | 'sustitucion';
    precio_adicional: number;
  };
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
  estado: 'pendiente' | 'en_preparacion' | 'listo' | 'entregado' | 'cancelado';
  tipo_pedido: 'para_servir' | 'para_llevar' | 'delivery';
  monto_pagado?: number;
}

const props = defineProps<{
  pedidoSeleccionado: Pedido | null;
  mostrarModal: boolean;
  montoRecibido: number;
}>();

const emit = defineEmits<{
  cerrarModal: [];
  cambiarEstado: [pedidoId: string, nuevoEstado: string];
  procesarPago: [];
  eliminarPedido: [pedidoId: string];
  'update:montoRecibido': [value: number];
}>();

// Estados simplificados: pendiente -> en_preparacion -> listo/entregado
const estadosDisponibles = computed(() => {
  if (!props.pedidoSeleccionado) return [];
  
  const tipo = props.pedidoSeleccionado.tipo_pedido;
  
  // Estados base para todos los tipos
  const estados = [
    { id: 'pendiente', label: 'Pendiente', icon: 'mdi:clock-outline', color: 'yellow' },
    { id: 'en_preparacion', label: 'En Preparación', icon: 'mdi:chef-hat', color: 'blue' },
    { id: 'listo', label: 'Listo', icon: 'mdi:check-circle', color: 'green' },
  ];
  
  // Estado final según tipo
  if (tipo === 'delivery') {
    estados.push({ id: 'entregado', label: 'Entregado', icon: 'mdi:truck-check', color: 'emerald' });
  } else {
    estados.push({ id: 'entregado', label: 'Entregado', icon: 'mdi:hand-okay', color: 'emerald' });
  }
  
  return estados;
});

// Obtener color del estado
const getEstadoColor = (estado: string) => {
  switch (estado) {
    case 'pendiente': return 'bg-yellow-100 text-yellow-800 border-yellow-300';
    case 'en_preparacion': return 'bg-blue-100 text-blue-800 border-blue-300';
    case 'listo': return 'bg-green-100 text-green-800 border-green-300';
    case 'entregado': return 'bg-emerald-100 text-emerald-800 border-emerald-300';
    case 'cancelado': return 'bg-red-100 text-red-800 border-red-300';
    default: return 'bg-gray-100 text-gray-800 border-gray-300';
  }
};

// Obtener tipo de pedido display
const getTipoPedidoDisplay = (tipo: string) => {
  switch (tipo) {
    case 'para_servir': return { icon: 'mdi:silverware-fork-knife', label: 'Para Servir', color: 'text-purple-600' };
    case 'para_llevar': return { icon: 'mdi:shopping-outline', label: 'Para Llevar', color: 'text-orange-600' };
    case 'delivery': return { icon: 'mdi:moped', label: 'Delivery', color: 'text-blue-600' };
    default: return { icon: 'mdi:clipboard-list', label: 'Pedido', color: 'text-gray-600' };
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

// Formatear estado para mostrar
const formatearEstado = (estado: string) => {
  return estado.replace(/_/g, ' ');
};

// Calcular vuelto
const vuelto = computed(() => {
  if (!props.pedidoSeleccionado) return 0;
  return Math.max(0, props.montoRecibido - props.pedidoSeleccionado.total);
});

// Calcular total de items
const totalItems = computed(() => {
  if (!props.pedidoSeleccionado) return 0;
  return props.pedidoSeleccionado.items.reduce((sum, item) => sum + item.cantidad, 0);
});

const cerrarModal = () => {
  emit('cerrarModal');
};

const cambiarEstado = (nuevoEstado: string) => {
  if (props.pedidoSeleccionado) {
    emit('cambiarEstado', props.pedidoSeleccionado.id, nuevoEstado);
  }
};

const procesarPago = () => {
  emit('procesarPago');
};

const eliminarPedido = () => {
  if (props.pedidoSeleccionado && confirm('¿Estás seguro de eliminar este pedido? Esta acción no se puede deshacer.')) {
    emit('eliminarPedido', props.pedidoSeleccionado.id);
  }
};

// Helpers para modificadores (soporta ambas estructuras)
const getModNombre = (mod: ItemModificador) => mod.modificador?.nombre || mod.nombre_modificador || '';
const getModCantidad = (mod: ItemModificador) => mod.cantidad || 1;
const getModPrecio = (mod: ItemModificador) => mod.modificador?.precio_adicional ?? mod.precio_adicional ?? 0;
const getModTipo = (mod: ItemModificador) => mod.modificador?.tipo || 'extra';
const getModId = (mod: ItemModificador) => mod.modificador?.id || mod.modificador_id || '';

// Colores según tipo de modificador
const getModificadorColor = (tipo: string) => {
  switch (tipo) {
    case 'extra': return 'bg-green-100 text-green-700';
    case 'sin': return 'bg-red-100 text-red-700';
    case 'sustitucion': return 'bg-blue-100 text-blue-700';
    default: return 'bg-gray-100 text-gray-700';
  }
};

const getModificadorPrefijo = (tipo: string) => {
  switch (tipo) {
    case 'extra': return '+';
    case 'sin': return 'Sin';
    case 'sustitucion': return '↔';
    default: return '+';
  }
};

const updateMontoRecibido = (value: number) => {
  emit('update:montoRecibido', value);
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
      class="fixed right-0 top-0 bottom-0 w-full sm:w-[480px] bg-white shadow-2xl z-101 overflow-hidden flex flex-col"
    >
      <!-- Header del modal -->
      <div class="bg-gradient-to-r from-amber-600 to-orange-600 p-4 text-white shadow-lg shrink-0">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-bold">Pedido #{{ pedidoSeleccionado.numero_pedido }}</h3>
            <p class="text-xs opacity-90 mt-1">{{ formatearFecha(pedidoSeleccionado.created_at) }}</p>
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
        <!-- Info del pedido -->
        <div class="bg-gray-50 rounded-xl p-4">
          <div class="grid grid-cols-2 gap-3">
            <!-- Tipo de pedido -->
            <div class="flex items-center gap-2">
              <Icon :icon="getTipoPedidoDisplay(pedidoSeleccionado.tipo_pedido).icon" 
                    :class="['h-5 w-5', getTipoPedidoDisplay(pedidoSeleccionado.tipo_pedido).color]" />
              <span class="text-sm font-semibold text-gray-700">
                {{ getTipoPedidoDisplay(pedidoSeleccionado.tipo_pedido).label }}
              </span>
            </div>
            
            <!-- Mesa (solo para servir) -->
            <div v-if="pedidoSeleccionado.tipo_pedido === 'para_servir'" class="flex items-center gap-2">
              <Icon icon="mdi:table-furniture" class="h-5 w-5 text-amber-600" />
              <span class="text-sm font-semibold text-gray-700">
                Mesa {{ pedidoSeleccionado.mesa_numero || '-' }}
              </span>
            </div>
            
            <!-- Cliente -->
            <div class="flex items-center gap-2">
              <Icon icon="mdi:account" class="h-5 w-5 text-gray-500" />
              <span class="text-sm text-gray-700">
                {{ pedidoSeleccionado.nombre_cliente || 'Sin nombre' }}
              </span>
            </div>
            
            <!-- Teléfono (delivery) -->
            <div v-if="pedidoSeleccionado.tipo_pedido === 'delivery' && pedidoSeleccionado.telefono" class="flex items-center gap-2">
              <Icon icon="mdi:phone" class="h-5 w-5 text-gray-500" />
              <span class="text-sm text-gray-700">{{ pedidoSeleccionado.telefono }}</span>
            </div>
          </div>
          
          <!-- Dirección (delivery) -->
          <div v-if="pedidoSeleccionado.tipo_pedido === 'delivery' && pedidoSeleccionado.direccion" 
               class="mt-3 pt-3 border-t border-gray-200">
            <div class="flex items-start gap-2">
              <Icon icon="mdi:map-marker" class="h-5 w-5 text-red-500 shrink-0 mt-0.5" />
              <span class="text-sm text-gray-700">{{ pedidoSeleccionado.direccion }}</span>
            </div>
          </div>
          
          <!-- Estado actual -->
          <div class="mt-3 pt-3 border-t border-gray-200 flex items-center justify-between">
            <span class="text-xs font-semibold text-gray-500">Estado actual:</span>
            <span :class="['text-xs font-bold px-3 py-1 rounded-full border', getEstadoColor(pedidoSeleccionado.estado)]">
              {{ formatearEstado(pedidoSeleccionado.estado).toUpperCase() }}
            </span>
          </div>
        </div>

        <!-- Productos del Pedido -->
        <div class="bg-gray-50 rounded-lg p-3">
          <div class="space-y-2">
            <div 
              v-for="item in pedidoSeleccionado.items" 
              :key="item.id"
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
                  <span class="text-xs text-gray-500">S/{{ item.precio_unitario.toFixed(2) }} c/u</span>
                  <span class="text-sm font-bold text-gray-900">S/{{ item.subtotal.toFixed(2) }}</span>
                </div>
              </div>
              <!-- Modificadores del producto -->
              <div v-if="item.modificadores && item.modificadores.length > 0" class="ml-7 mt-1 flex flex-wrap gap-1">
                <span
                  v-for="mod in item.modificadores"
                  :key="getModId(mod)"
                  :class="[
                    'inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[10px] font-medium',
                    getModificadorColor(getModTipo(mod))
                  ]"
                >
                  <span>{{ getModificadorPrefijo(getModTipo(mod)) }}</span>
                  <span>{{ getModNombre(mod) }}</span>
                  <span v-if="getModCantidad(mod) > 1">x{{ getModCantidad(mod) }}</span>
                  <span v-if="getModPrecio(mod) > 0" class="opacity-75">+S/{{ (getModPrecio(mod) * getModCantidad(mod)).toFixed(2) }}</span>
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Total -->
        <div class="bg-gradient-to-r from-amber-600 to-orange-600 rounded-xl p-4 text-white">
          <div class="flex items-center justify-between">
            <div>
              <span class="text-xs font-semibold opacity-90">TOTAL A PAGAR</span>
              <p class="text-xs opacity-75">{{ totalItems }} producto{{ totalItems !== 1 ? 's' : '' }}</p>
            </div>
            <span class="text-2xl font-bold">S/ {{ pedidoSeleccionado.total.toFixed(2) }}</span>
          </div>
        </div>

        <!-- Mensaje de pedido pagado -->
        <div v-if="pedidoSeleccionado.estado === 'pagado'" class="bg-teal-50 border-2 border-teal-200 rounded-xl p-4">
          <div class="flex items-center gap-3">
            <Icon icon="mdi:check-decagram" class="h-8 w-8 text-teal-600" />
            <div>
              <h4 class="text-sm font-bold text-teal-800">Pedido Pagado</h4>
              <p class="text-xs text-teal-600">Este pedido ya fue completado y pagado.</p>
            </div>
          </div>
        </div>

        <!-- Calculadora de Pago + Botón PAGADO (solo si no está pagado) -->
        <div v-if="pedidoSeleccionado.estado !== 'pagado'" class="bg-gradient-to-br from-emerald-50 to-teal-50 border-2 border-emerald-200 rounded-xl p-4 space-y-3">
          <h4 class="text-sm font-bold text-gray-900 flex items-center gap-2">
            <Icon icon="mdi:calculator" class="h-4 w-4 text-emerald-600" />
            Calculadora de Pago (opcional)
          </h4>
          
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-xs font-semibold text-gray-700 block mb-1">Monto Recibido:</label>
              <input
                :value="montoRecibido"
                @input="updateMontoRecibido(Number(($event.target as HTMLInputElement).value))"
                type="number"
                step="0.01"
                min="0"
                placeholder="0.00"
                class="w-full px-3 py-2 border-2 border-emerald-300 rounded-lg text-sm font-bold focus:border-emerald-500 focus:outline-none"
              />
            </div>
            <div>
              <label class="text-xs font-semibold text-gray-700 block mb-1">Vuelto:</label>
              <div class="w-full px-3 py-2 bg-emerald-100 border-2 border-emerald-300 rounded-lg text-sm font-bold text-emerald-800">
                S/ {{ vuelto.toFixed(2) }}
              </div>
            </div>
          </div>

          <button
            @click="procesarPago"
            class="w-full bg-emerald-600 text-white py-4 px-4 rounded-xl font-bold text-lg shadow-lg hover:bg-emerald-700 transition-all duration-200 active:scale-95 flex items-center justify-center gap-2"
          >
            <Icon icon="mdi:cash-check" class="h-6 w-6" />
            PAGAR
          </button>
        </div>

        <!-- Botón eliminar pedido (no mostrar si ya está pagado) -->
        <button
          v-if="pedidoSeleccionado.estado !== 'pagado'"
          @click="eliminarPedido"
          class="w-full flex items-center justify-center gap-2 py-3 px-4 border-2 border-red-400 bg-red-100 text-red-800 rounded-lg font-bold text-sm hover:bg-red-200 transition-colors"
        >
          <Icon icon="mdi:delete" class="h-5 w-5" />
          Eliminar Pedido
        </button>
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
