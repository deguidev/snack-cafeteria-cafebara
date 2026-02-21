<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { Icon } from '@iconify/vue';
import confetti from 'canvas-confetti';
import { supabase } from '../../lib/supabaseClient';

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
  tiempo_ocupado?: string;
}

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

// Configuración de la grilla
const GRID_COLS = 8;
const GRID_ROWS = 6;

// Mesas desde Supabase
const mesas = ref<Mesa[]>([]);
const loading = ref(true);

// Cargar mesas desde Supabase
const cargarMesas = async () => {
  try {
    loading.value = true;
    
    // Cargar mesas
    const { data: mesasData, error: errorMesas } = await supabase
      .from('mesas')
      .select('*')
      .eq('activo', true)
      .order('numero');

    if (errorMesas) throw errorMesas;

    // Cargar pedidos activos (no pagados ni cancelados) por mesa
    const { data: pedidosData, error: errorPedidos } = await supabase
      .from('pedidos')
      .select(`
        id,
        numero_pedido,
        mesa_numero,
        total,
        estado,
        pedido_detalle (
          nombre_producto,
          cantidad,
          precio_unitario
        )
      `)
      .eq('tipo_pedido', 'para_servir')
      .not('estado', 'in', '("pagado","cancelado")');

    if (errorPedidos) throw errorPedidos;

    // Mapear mesas con sus pedidos
    mesas.value = (mesasData || []).map(mesa => {
      const pedidosMesa = (pedidosData || []).filter(p => p.mesa_numero === mesa.numero);
      const tienePedidos = pedidosMesa.length > 0;
      
      return {
        ...mesa,
        estado: tienePedidos ? 'ocupada' : mesa.estado,
        pedidos: pedidosMesa.map(p => ({
          id: p.id,
          numero_pedido: p.numero_pedido,
          total: p.total,
          estado: p.estado,
          items: p.pedido_detalle || []
        }))
      };
    });
  } catch (err) {
    console.error('Error cargando mesas:', err);
  } finally {
    loading.value = false;
  }
};

const mesaSeleccionada = ref<Mesa | null>(null);
const mostrarModal = ref(false);

const estadisticas = computed(() => ({
  total: mesas.value.length,
  disponibles: mesas.value.filter(m => m.estado === 'disponible').length,
  ocupadas: mesas.value.filter(m => m.estado === 'ocupada').length,
}));

const totalPedido = computed(() => {
  if (!mesaSeleccionada.value?.pedidos || mesaSeleccionada.value.pedidos.length === 0) return 0;
  return mesaSeleccionada.value.pedidos.reduce((sum, p) => sum + p.total, 0);
});

const seleccionarMesa = (mesa: Mesa) => {
  // Si la mesa está disponible, redirigir a AnotarPedido con el número de mesa
  if (mesa.estado === 'disponible') {
    window.location.href = `/anotar-pedido?mesa=${mesa.numero}`;
    return;
  }
  
  // Si tiene pedidos, mostrar el modal con los detalles
  mesaSeleccionada.value = mesa;
  mostrarModal.value = true;
};

const cerrarModal = () => {
  mostrarModal.value = false;
  mesaSeleccionada.value = null;
};

const pagarMesa = () => {
  if (mesaSeleccionada.value) {
    const mesa = mesas.value.find(m => m.id === mesaSeleccionada.value?.id);
    if (mesa) {
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
      setTimeout(() => {
        mesa.estado = 'disponible';
        mesa.pedidos = undefined;
        mesa.tiempo_ocupado = undefined;
        cerrarModal();
      }, 800);
    }
  }
};

const getTotalMesa = (mesa: Mesa) => {
  if (!mesa.pedidos || mesa.pedidos.length === 0) return 0;
  return mesa.pedidos.reduce((sum, p) => sum + p.total, 0);
};

const getCantidadPedidos = (mesa: Mesa) => {
  if (!mesa.pedidos || mesa.pedidos.length === 0) return 0;
  return mesa.pedidos.reduce((sum, p) => {
    return sum + p.items.reduce((itemSum, item) => itemSum + item.cantidad, 0);
  }, 0);
};

// Función para obtener el estilo de posición de cada mesa en la grilla
const getMesaGridStyle = (mesa: Mesa) => {
  return {
    gridColumnStart: mesa.posicion_x,
    gridColumnEnd: mesa.posicion_x + mesa.ancho,
    gridRowStart: mesa.posicion_y,
    gridRowEnd: mesa.posicion_y + mesa.alto,
  };
};

// Cargar mesas al montar
onMounted(() => {
  cargarMesas();
});
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-amber-50 via-orange-50 to-yellow-50">
    <header class="bg-gradient-to-r from-amber-900 via-amber-800 to-yellow-800 px-4 py-6 shadow-lg">
      <div class="mx-auto max-w-7xl">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <a href="/" class="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 backdrop-blur-sm transition-colors hover:bg-white/30">
              <Icon icon="mdi:arrow-left" class="h-6 w-6 text-white" />
            </a>
            <div>
              <h1 class="text-2xl font-bold text-white sm:text-3xl">Gestión de Mesas</h1>
              <p class="mt-1 text-sm text-amber-100">Plano del restaurante</p>
            </div>
          </div>
        </div>
      </div>
    </header>

    <section class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
      <div class="grid gap-4 sm:grid-cols-3">
        <div class="rounded-xl bg-white p-4 shadow-md">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-600">Total Mesas</p>
              <p class="mt-1 text-2xl font-bold text-gray-900">{{ estadisticas.total }}</p>
            </div>
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
              <Icon icon="mdi:table-furniture" class="h-6 w-6 text-amber-800" />
            </div>
          </div>
        </div>

        <div class="rounded-xl bg-white p-4 shadow-md">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-600">Disponibles</p>
              <p class="mt-1 text-2xl font-bold text-green-600">{{ estadisticas.disponibles }}</p>
            </div>
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
              <Icon icon="mdi:check-circle" class="h-6 w-6 text-green-600" />
            </div>
          </div>
        </div>

        <div class="rounded-xl bg-white p-4 shadow-md">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-600">Ocupadas</p>
              <p class="mt-1 text-2xl font-bold text-red-600">{{ estadisticas.ocupadas }}</p>
            </div>
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-red-100">
              <Icon icon="mdi:account-group" class="h-6 w-6 text-red-600" />
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Grilla de Mesas con Posicionamiento 2D -->
    <section class="mx-auto max-w-7xl px-4 pb-8 sm:px-6 lg:px-8">
      <div class="rounded-xl bg-white p-4 shadow-xl sm:p-8">
        <div class="mb-4 flex items-center justify-between">
          <h2 class="text-lg font-semibold text-gray-800">
            <Icon icon="mdi:floor-plan" class="inline h-5 w-5 mr-2" />
            Plano del Restaurante
          </h2>
          <div class="text-sm text-gray-500">
            Grilla: {{ GRID_COLS }} × {{ GRID_ROWS }}
          </div>
        </div>
        
        <!-- Contenedor de la grilla con patrón de fondo -->
        <div class="relative overflow-auto rounded-lg border-2 border-amber-200 bg-gradient-to-br from-amber-50 to-orange-50 p-4">
          <div 
            class="restaurant-grid relative mx-auto"
            :style="{
              display: 'grid',
              gridTemplateColumns: `repeat(${GRID_COLS}, minmax(80px, 1fr))`,
              gridTemplateRows: `repeat(${GRID_ROWS}, minmax(80px, 1fr))`,
              gap: '8px',
              minHeight: '500px'
            }"
          >
            <!-- Celdas de fondo de la grilla -->
            <template v-for="row in GRID_ROWS" :key="`row-${row}`">
              <div
                v-for="col in GRID_COLS"
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
              v-for="mesa in mesas"
              :key="mesa.id"
              @click="seleccionarMesa(mesa)"
              class="mesa-card group relative cursor-pointer rounded-xl border-4 p-3 shadow-lg transition-all duration-300 hover:scale-105 hover:shadow-2xl hover:z-10"
              :class="[
                mesa.estado === 'disponible'
                  ? 'border-green-500 bg-gradient-to-br from-green-100 to-emerald-200'
                  : 'border-red-500 bg-gradient-to-br from-red-100 to-rose-200'
              ]"
              :style="getMesaGridStyle(mesa)"
            >
              <!-- Número de mesa -->
              <div class="absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-amber-800 px-3 py-1 text-xs font-bold text-white shadow-md">
                Mesa {{ mesa.numero }}
              </div>

              <!-- Indicador de estado -->
              <div class="absolute right-2 top-2">
                <div
                  class="flex h-6 w-6 items-center justify-center rounded-full shadow-md"
                  :class="mesa.estado === 'disponible' ? 'bg-green-500' : 'bg-red-500'"
                >
                  <Icon
                    :icon="mesa.estado === 'disponible' ? 'mdi:check-bold' : 'mdi:clock-outline'"
                    class="h-4 w-4 text-white"
                  />
                </div>
              </div>

              <!-- Contenido de la mesa -->
              <div class="flex h-full flex-col items-center justify-center pt-2">
                <!-- Mesa disponible -->
                <div v-if="mesa.estado === 'disponible'" class="text-center">
                  <div class="relative mx-auto mb-2">
                    <div class="absolute inset-0 animate-ping rounded-full bg-green-400 opacity-75"></div>
                    <div class="relative flex h-12 w-12 items-center justify-center rounded-full bg-green-500 shadow-lg">
                      <Icon icon="mdi:check-circle" class="h-8 w-8 text-white" />
                    </div>
                  </div>
                  <p class="text-xs font-semibold text-green-700">Disponible</p>
                  <p class="mt-1 text-xs text-gray-600">
                    <Icon icon="mdi:account-multiple" class="inline h-3 w-3" />
                    {{ mesa.capacidad }} personas
                  </p>
                </div>

                <!-- Mesa ocupada -->
                <div v-else class="w-full text-center">
                  <div class="mb-2 flex items-center justify-center gap-1">
                    <Icon icon="mdi:food" class="h-5 w-5 text-red-600" />
                    <span class="text-sm font-semibold text-gray-700">
                      {{ getCantidadPedidos(mesa) }} pedido{{ getCantidadPedidos(mesa) > 1 ? 's' : '' }}
                    </span>
                  </div>
                  <div class="rounded-lg bg-white/90 px-3 py-2 shadow-md">
                    <p class="text-xs text-gray-600">Total</p>
                    <p class="text-lg font-bold text-red-600">S/ {{ getTotalMesa(mesa).toFixed(2) }}</p>
                  </div>
                  <p class="mt-1 text-xs text-gray-600">
                    <Icon icon="mdi:account-multiple" class="inline h-3 w-3" />
                    {{ mesa.capacidad }} personas
                  </p>
                </div>
              </div>

              <!-- Indicador de orientación -->
              <div class="absolute bottom-1 left-1">
                <div class="rounded-full bg-white/80 px-1.5 py-0.5 text-xs font-medium text-gray-600 shadow">
                  <Icon
                    :icon="mesa.orientacion === 'horizontal' ? 'mdi:arrow-left-right' : 'mdi:arrow-up-down'"
                    class="inline h-3 w-3"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Leyenda -->
        <div class="mt-4 flex flex-wrap items-center justify-center gap-4 text-sm">
          <div class="flex items-center gap-2">
            <div class="h-4 w-4 rounded border-2 border-green-500 bg-green-100"></div>
            <span class="text-gray-600">Disponible</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="h-4 w-4 rounded border-2 border-red-500 bg-red-100"></div>
            <span class="text-gray-600">Ocupada</span>
          </div>
          <div class="flex items-center gap-2">
            <Icon icon="mdi:information-outline" class="h-4 w-4 text-gray-500" />
            <span class="text-gray-500">Click en una mesa para ver detalles</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Modal de Detalle de Mesa -->
    <div
      v-if="mostrarModal && mesaSeleccionada"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      @click.self="cerrarModal"
    >
      <div class="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl">
        <div class="flex items-center justify-between border-b border-gray-200 pb-4">
          <div class="flex items-center gap-3">
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
              <Icon icon="mdi:table-furniture" class="h-6 w-6 text-amber-800" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-gray-900">Mesa {{ mesaSeleccionada.numero }}</h2>
              <p class="text-sm text-gray-600">{{ mesaSeleccionada.capacidad }} personas</p>
            </div>
          </div>
          <button
            @click="cerrarModal"
            class="flex h-8 w-8 items-center justify-center rounded-full text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
          >
            <Icon icon="mdi:close" class="h-6 w-6" />
          </button>
        </div>

        <div class="mt-4">
          <div class="flex items-center gap-2">
            <span class="text-sm font-medium text-gray-600">Estado:</span>
            <span
              :class="[
                'rounded-full px-3 py-1 text-sm font-semibold',
                mesaSeleccionada.estado === 'disponible'
                  ? 'bg-green-100 text-green-800'
                  : 'bg-red-100 text-red-800'
              ]"
            >
              {{ mesaSeleccionada.estado === 'disponible' ? 'Disponible' : 'Ocupada' }}
            </span>
          </div>
        </div>

        <div v-if="mesaSeleccionada.estado === 'ocupada' && mesaSeleccionada.pedidos" class="mt-6">
          <h3 class="mb-3 text-lg font-semibold text-gray-900">Pedido Actual</h3>
          <div class="space-y-2 rounded-lg bg-gray-50 p-4">
            <div
              v-for="pedido in mesaSeleccionada.pedidos"
              :key="pedido.id"
              class="flex items-center justify-between border-b border-gray-200 pb-2 last:border-0 last:pb-0"
            >
              <div class="flex items-center gap-3">
                <span class="flex h-6 w-6 items-center justify-center rounded-full bg-amber-100 text-xs font-bold text-amber-800">
                  {{ pedido.cantidad }}
                </span>
                <span class="font-medium text-gray-700">{{ pedido.producto }}</span>
              </div>
              <span class="font-semibold text-gray-900">S/ {{ (pedido.precio * pedido.cantidad).toFixed(2) }}</span>
            </div>
            
            <div class="mt-4 flex items-center justify-between border-t-2 border-amber-800 pt-3">
              <span class="text-lg font-bold text-gray-900">Total:</span>
              <span class="text-2xl font-bold text-amber-800">S/ {{ totalPedido.toFixed(2) }}</span>
            </div>
          </div>
        </div>

        <div class="mt-6 grid grid-cols-2 gap-4 rounded-lg bg-amber-50 p-4">
          <div>
            <p class="text-xs font-medium text-amber-800">Posición</p>
            <p class="mt-1 text-sm font-semibold text-gray-900">
              ({{ mesaSeleccionada.posicion_x }}, {{ mesaSeleccionada.posicion_y }})
            </p>
          </div>
          <div>
            <p class="text-xs font-medium text-amber-800">Tamaño</p>
            <p class="mt-1 text-sm font-semibold text-gray-900">
              {{ mesaSeleccionada.ancho }} × {{ mesaSeleccionada.alto }}
            </p>
          </div>
        </div>

        <div class="mt-6 flex gap-3">
          <button
            v-if="mesaSeleccionada.estado === 'ocupada'"
            @click="pagarMesa"
            class="flex-1 rounded-lg bg-green-600 px-4 py-3 font-semibold text-white transition-colors hover:bg-green-700"
          >
            <Icon icon="mdi:cash-check" class="mr-2 inline h-5 w-5" />
            Pagar
          </button>
          <button
            @click="cerrarModal"
            class="flex-1 rounded-lg bg-gray-200 px-4 py-3 font-semibold text-gray-700 transition-colors hover:bg-gray-300"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.grid-cell {
  min-height: 80px;
}

.mesa-card {
  min-height: 100%;
}

@media (max-width: 640px) {
  .restaurant-grid {
    font-size: 0.75rem;
  }
}
</style>
