<script setup lang="ts">
import { computed } from 'vue';
import { Icon } from '@iconify/vue';

interface PedidoMesa {
  id: string;
  numero_pedido: number;
  total: number;
  estado: string;
  items: {
    nombre_producto: string;
    cantidad: number;
    precio_unitario: number;
  }[];
}

interface Mesa {
  id: string;
  numero: number;
  capacidad: number;
  posicion_x: number;
  posicion_y: number;
  ancho: number;
  alto: number;
  orientacion: 'horizontal' | 'vertical';
  estado: 'disponible' | 'ocupada' | 'reservada' | 'mantenimiento';
  ubicacion: string;
  activo: boolean;
  pedidos?: PedidoMesa[];
}

const props = withDefaults(defineProps<{
  mesas: Mesa[];
  mesaSeleccionada?: number | null;
  modoSeleccion?: boolean;
  soloDisponibles?: boolean;
  gridCols?: number;
  gridRows?: number;
  compacto?: boolean;
}>(), {
  mesaSeleccionada: null,
  modoSeleccion: false,
  soloDisponibles: false,
  gridCols: 8,
  gridRows: 6,
  compacto: false
});

const emit = defineEmits<{
  'seleccionar-mesa': [mesa: Mesa];
  'ver-detalles': [mesa: Mesa];
}>();

const mesasFiltradas = computed(() => {
  if (props.soloDisponibles) {
    return props.mesas.filter(m => m.estado === 'disponible');
  }
  return props.mesas;
});

const getTotalMesa = (mesa: Mesa) => {
  if (!mesa.pedidos || mesa.pedidos.length === 0) return 0;
  return mesa.pedidos.reduce((sum, p) => sum + p.total, 0);
};

const getCantidadItems = (mesa: Mesa) => {
  if (!mesa.pedidos || mesa.pedidos.length === 0) return 0;
  return mesa.pedidos.reduce((sum, p) => {
    return sum + p.items.reduce((itemSum, item) => itemSum + item.cantidad, 0);
  }, 0);
};

const getMesaGridStyle = (mesa: Mesa) => {
  return {
    gridColumnStart: mesa.posicion_x,
    gridColumnEnd: mesa.posicion_x + mesa.ancho,
    gridRowStart: mesa.posicion_y,
    gridRowEnd: mesa.posicion_y + mesa.alto,
  };
};

const handleClickMesa = (mesa: Mesa) => {
  if (props.modoSeleccion) {
    if (mesa.estado === 'disponible') {
      emit('seleccionar-mesa', mesa);
    }
  } else {
    emit('ver-detalles', mesa);
  }
};

const esMesaSeleccionada = (mesa: Mesa) => {
  return props.mesaSeleccionada === mesa.numero;
};
</script>

<template>
  <div class="relative overflow-auto rounded-lg border-2 border-amber-200 bg-gradient-to-br from-amber-50 to-orange-50 p-3">
    <div 
      class="restaurant-grid relative mx-auto"
      :style="{
        display: 'grid',
        gridTemplateColumns: `repeat(${gridCols}, minmax(${compacto ? '60px' : '80px'}, 1fr))`,
        gridTemplateRows: `repeat(${gridRows}, minmax(${compacto ? '60px' : '80px'}, 1fr))`,
        gap: compacto ? '4px' : '8px',
        minHeight: compacto ? '300px' : '400px'
      }"
    >
      <!-- Celdas de fondo de la grilla -->
      <template v-for="row in gridRows" :key="`row-${row}`">
        <div
          v-for="col in gridCols"
          :key="`cell-${row}-${col}`"
          class="grid-cell border border-dashed border-gray-300 bg-white/30 rounded"
          :style="{
            gridColumn: col,
            gridRow: row
          }"
        ></div>
      </template>

      <!-- Mesas posicionadas en la grilla -->
      <div
        v-for="mesa in mesasFiltradas"
        :key="mesa.id"
        @click="handleClickMesa(mesa)"
        class="mesa-card group relative rounded-xl border-4 p-2 shadow-lg transition-all duration-300 hover:scale-105 hover:shadow-2xl hover:z-10"
        :class="[
          mesa.estado === 'disponible'
            ? esMesaSeleccionada(mesa)
              ? 'border-amber-500 bg-gradient-to-br from-amber-100 to-amber-200 ring-4 ring-amber-400'
              : 'border-green-500 bg-gradient-to-br from-green-100 to-emerald-200 cursor-pointer'
            : modoSeleccion
              ? 'border-gray-400 bg-gradient-to-br from-gray-100 to-gray-200 opacity-50 cursor-not-allowed'
              : 'border-red-500 bg-gradient-to-br from-red-100 to-rose-200 cursor-pointer'
        ]"
        :style="getMesaGridStyle(mesa)"
      >
        <!-- Número de mesa -->
        <div 
          class="absolute -top-2.5 left-1/2 -translate-x-1/2 rounded-full px-2 py-0.5 text-xs font-bold text-white shadow-md"
          :class="esMesaSeleccionada(mesa) ? 'bg-amber-600' : 'bg-amber-800'"
        >
          {{ mesa.numero }}
        </div>

        <!-- Indicador de estado -->
        <div class="absolute right-1 top-1">
          <div
            class="flex h-5 w-5 items-center justify-center rounded-full shadow-md"
            :class="[
              mesa.estado === 'disponible' 
                ? esMesaSeleccionada(mesa) ? 'bg-amber-500' : 'bg-green-500' 
                : 'bg-red-500'
            ]"
          >
            <Icon
              :icon="esMesaSeleccionada(mesa) ? 'mdi:check-bold' : mesa.estado === 'disponible' ? 'mdi:check-bold' : 'mdi:clock-outline'"
              class="h-3 w-3 text-white"
            />
          </div>
        </div>

        <!-- Contenido de la mesa -->
        <div class="flex h-full flex-col items-center justify-center pt-1">
          <!-- Mesa disponible -->
          <div v-if="mesa.estado === 'disponible'" class="text-center">
            <div v-if="!compacto" class="relative mx-auto mb-1">
              <div v-if="!esMesaSeleccionada(mesa)" class="absolute inset-0 animate-ping rounded-full bg-green-400 opacity-75"></div>
              <div 
                class="relative flex h-8 w-8 items-center justify-center rounded-full shadow-lg"
                :class="esMesaSeleccionada(mesa) ? 'bg-amber-500' : 'bg-green-500'"
              >
                <Icon :icon="esMesaSeleccionada(mesa) ? 'mdi:check-circle' : 'mdi:check-circle'" class="h-5 w-5 text-white" />
              </div>
            </div>
            <p :class="['text-xs font-semibold', esMesaSeleccionada(mesa) ? 'text-amber-700' : 'text-green-700']">
              {{ esMesaSeleccionada(mesa) ? 'Seleccionada' : 'Libre' }}
            </p>
            <p class="text-[10px] text-gray-600">
              <Icon icon="mdi:account-multiple" class="inline h-3 w-3" />
              {{ mesa.capacidad }}
            </p>
          </div>

          <!-- Mesa ocupada -->
          <div v-else class="w-full text-center">
            <div v-if="!compacto" class="mb-1 flex items-center justify-center gap-1">
              <Icon icon="mdi:food" class="h-4 w-4 text-red-600" />
              <span class="text-xs font-semibold text-gray-700">
                {{ getCantidadItems(mesa) }}
              </span>
            </div>
            <div class="rounded bg-white/90 px-1.5 py-1 shadow-sm">
              <p class="text-xs font-bold text-red-600">S/ {{ getTotalMesa(mesa).toFixed(2) }}</p>
            </div>
            <p class="mt-0.5 text-[10px] text-gray-600">
              <Icon icon="mdi:account-multiple" class="inline h-3 w-3" />
              {{ mesa.capacidad }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Leyenda -->
    <div class="mt-3 flex flex-wrap items-center justify-center gap-3 text-xs">
      <div class="flex items-center gap-1.5">
        <div class="h-3 w-3 rounded border-2 border-green-500 bg-green-100"></div>
        <span class="text-gray-600">Disponible</span>
      </div>
      <div v-if="!soloDisponibles" class="flex items-center gap-1.5">
        <div class="h-3 w-3 rounded border-2 border-red-500 bg-red-100"></div>
        <span class="text-gray-600">Ocupada</span>
      </div>
      <div v-if="mesaSeleccionada" class="flex items-center gap-1.5">
        <div class="h-3 w-3 rounded border-2 border-amber-500 bg-amber-100"></div>
        <span class="text-gray-600">Seleccionada</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.grid-cell {
  min-height: 60px;
}

.mesa-card {
  min-height: 100%;
}
</style>
