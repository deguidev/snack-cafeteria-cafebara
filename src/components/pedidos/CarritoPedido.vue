<script setup lang="ts">
import { computed, ref } from 'vue';
import { Icon } from '@iconify/vue';

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria: 'bebidas' | 'cafes' | 'platos' | 'postres';
  imagen_url?: string;
  disponible: boolean;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
}

interface Mesa {
  numero: number;
  ubicacion?: string;
  capacidad?: number;
}

// Props
const props = defineProps<{
  pedidoActual: ItemPedido[];
  mesaNumero: number | null;
  nombreCliente: string;
  mostrarCarrito: boolean;
}>();

// Emits
const emit = defineEmits<{
  'update:mesaNumero': [value: number | null];
  'update:nombreCliente': [value: string];
  'update:mostrarCarrito': [value: boolean];
  'agregarProducto': [producto: Producto];
  'quitarProducto': [productoId: string];
  'eliminarProducto': [productoId: string];
  'guardarPedido': [];
  'limpiarPedido': [];
}>();

// Datos de mesas (reemplazar con datos de Supabase cuando esté listo)
const mesasDisponibles = ref<Mesa[]>([
  { numero: 1, ubicacion: 'Interior', capacidad: 4 },
  { numero: 2, ubicacion: 'Interior', capacidad: 4 },
  { numero: 3, ubicacion: 'Interior', capacidad: 2 },
  { numero: 4, ubicacion: 'Terraza', capacidad: 6 },
  { numero: 5, ubicacion: 'Terraza', capacidad: 4 },
  { numero: 6, ubicacion: 'Terraza', capacidad: 2 },
  { numero: 7, ubicación: 'VIP', capacidad: 8 },
  { numero: 8, ubicación: 'VIP', capacidad: 6 },
]);

// Computed
const totalPedido = computed(() => {
  return props.pedidoActual.reduce((sum, item) => sum + (item.producto.precio * item.cantidad), 0);
});

const cantidadTotal = computed(() => {
  return props.pedidoActual.reduce((sum, item) => sum + item.cantidad, 0);
});
</script>

<template>
  <!-- Backdrop overlay - Cubre toda la pantalla -->
  <Transition name="fade">
    <div 
      v-if="mostrarCarrito"
      @click="emit('update:mostrarCarrito', false)"
      class="fixed inset-0 bg-black/40 backdrop-blur-sm z-[100]"
    ></div>
  </Transition>

  <!-- Menú lateral del carrito (sidebar derecho) - Se sobrepone a TODO -->
  <Transition name="slide">
    <div 
      v-if="mostrarCarrito"
      class="fixed right-0 top-0 bottom-0 w-full sm:w-96 bg-white shadow-2xl z-[101] overflow-hidden"
    >
      <div class="flex h-full flex-col">
      <!-- Header del sidebar -->
      <div class="bg-gradient-to-r from-amber-600 to-orange-600 p-4 text-white shadow-lg">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-white/20">
              <Icon icon="mdi:cart" class="h-6 w-6" />
            </div>
            <div>
              <h2 class="text-lg font-bold">Carrito de Pedido</h2>
              <p class="text-xs opacity-90">{{ cantidadTotal }} item{{ cantidadTotal !== 1 ? 's' : '' }}</p>
            </div>
          </div>
          <button
            @click="emit('update:mostrarCarrito', false)"
            class="flex h-9 w-9 items-center justify-center rounded-full bg-white/20 transition-colors hover:bg-white/30 active:scale-95"
          >
            <Icon icon="mdi:close" class="h-6 w-6" />
          </button>
        </div>
      </div>

      <!-- Información de mesa y cliente -->
      <div class="border-b border-gray-200 bg-gray-50 p-4 space-y-3">
        <div>
          <label class="mb-1.5 flex items-center gap-2 text-xs font-bold text-gray-700">
            <Icon icon="mdi:table-furniture" class="h-4 w-4 text-amber-600" />
            Asignar Mesa
          </label>
          <select
            :value="mesaNumero || ''"
            @change="emit('update:mesaNumero', ($event.target as HTMLSelectElement).value ? Number(($event.target as HTMLSelectElement).value) : null)"
            class="w-full rounded-lg border-2 border-gray-300 px-3 py-2.5 text-sm font-semibold focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-200 appearance-none bg-white cursor-pointer"
          >
            <option value="" disabled>Selecciona una mesa</option>
            <option v-for="mesa in mesasDisponibles" :key="mesa.numero" :value="mesa.numero">
              Mesa {{ mesa.numero }} {{ mesa.ubicacion ? `- ${mesa.ubicacion}` : '' }} {{ mesa.capacidad ? `(${mesa.capacidad} personas)` : '' }}
            </option>
          </select>
        </div>
        <div>
          <label class="mb-1.5 flex items-center gap-2 text-xs font-bold text-gray-700">
            <Icon icon="mdi:account" class="h-4 w-4 text-amber-600" />
            Cliente (opcional)
          </label>
          <input
            :value="nombreCliente"
            @input="emit('update:nombreCliente', ($event.target as HTMLInputElement).value)"
            type="text"
            placeholder="Nombre del cliente"
            class="w-full rounded-lg border-2 border-gray-300 px-3 py-2.5 text-sm focus:border-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-200"
          />
        </div>
      </div>

      <!-- Lista de productos en el pedido (scrollable) -->
      <div class="flex-1 overflow-y-auto p-4 space-y-2">
        <div v-if="pedidoActual.length === 0" class="flex flex-col items-center justify-center py-16 text-center">
          <div class="mb-4 flex h-20 w-20 items-center justify-center rounded-full bg-gray-100">
            <Icon icon="mdi:cart-outline" class="h-12 w-12 text-gray-300" />
          </div>
          <p class="text-sm font-semibold text-gray-600">Carrito vacío</p>
          <p class="mt-1 text-xs text-gray-400">Agrega productos desde el menú</p>
        </div>

        <div
          v-for="item in pedidoActual"
          :key="item.producto.id"
          class="flex items-center gap-3 rounded-lg border-2 border-gray-200 bg-white p-3 shadow-sm transition-all hover:border-amber-300 hover:shadow-md"
        >
          <!-- Info del producto -->
          <div class="flex-1 min-w-0">
            <p class="text-sm font-bold text-gray-900 truncate">{{ item.producto.nombre }}</p>
            <p class="text-xs text-gray-500 mt-0.5">S/ {{ item.producto.precio.toFixed(2) }} c/u</p>
            <p class="text-sm font-bold text-amber-700 mt-1">S/ {{ (item.producto.precio * item.cantidad).toFixed(2) }}</p>
          </div>

          <!-- Controles de cantidad -->
          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-1.5">
              <button
                @click="emit('quitarProducto', item.producto.id)"
                class="flex h-8 w-8 items-center justify-center rounded-lg bg-red-500 text-white transition-all hover:bg-red-600 active:scale-90"
              >
                <Icon icon="mdi:minus" class="h-4 w-4" />
              </button>
              <span class="w-8 text-center text-sm font-bold text-gray-900">{{ item.cantidad }}</span>
              <button
                @click="emit('agregarProducto', item.producto)"
                class="flex h-8 w-8 items-center justify-center rounded-lg bg-green-500 text-white transition-all hover:bg-green-600 active:scale-90"
              >
                <Icon icon="mdi:plus" class="h-4 w-4" />
              </button>
            </div>
            <button
              @click="emit('eliminarProducto', item.producto.id)"
              class="flex items-center justify-center gap-1 rounded-md bg-gray-100 px-2 py-1 text-xs font-semibold text-red-600 transition-colors hover:bg-red-50 active:scale-95"
            >
              <Icon icon="mdi:delete" class="h-3 w-3" />
              Eliminar
            </button>
          </div>
        </div>
      </div>

      <!-- Footer con total y botones -->
      <div class="border-t-2 border-gray-200 bg-white">
        <!-- Total -->
        <div class="bg-gradient-to-r from-amber-600 to-orange-600 p-4 text-white">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs font-semibold opacity-90">TOTAL A PAGAR</p>
              <p class="text-xs opacity-75 mt-0.5">{{ cantidadTotal }} producto{{ cantidadTotal !== 1 ? 's' : '' }}</p>
            </div>
            <div class="text-right">
              <p class="text-3xl font-bold">S/ {{ totalPedido.toFixed(2) }}</p>
            </div>
          </div>
        </div>

        <!-- Botones de acción -->
        <div class="grid grid-cols-2 gap-3 p-4">
          <button
            @click="emit('limpiarPedido')"
            :disabled="pedidoActual.length === 0"
            class="flex items-center justify-center gap-2 rounded-lg border-2 border-gray-300 bg-white px-4 py-3 text-sm font-bold text-gray-700 transition-all hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-50 active:scale-95"
          >
            <Icon icon="mdi:refresh" class="h-5 w-5" />
            Limpiar
          </button>
          
          <button
            @click="emit('guardarPedido')"
            :disabled="pedidoActual.length === 0"
            class="flex items-center justify-center gap-2 rounded-lg bg-green-600 px-4 py-3 text-sm font-bold text-white shadow-lg transition-all hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-50 active:scale-95"
          >
            <Icon icon="mdi:check-circle" class="h-5 w-5" />
            Guardar
          </button>
        </div>
      </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
/* Animación del backdrop */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Animación del sidebar */
.slide-enter-active,
.slide-leave-active {
  transition: transform 0.3s ease;
}

.slide-enter-from,
.slide-leave-to {
  transform: translateX(100%);
}
</style>
