<script setup lang="ts">
import { ref, computed } from 'vue';
import { Icon } from '@iconify/vue';

interface Modificador {
  id: string;
  nombre: string;
  descripcion: string | null;
  tipo: 'extra' | 'sin' | 'sustitucion';
  precio_adicional: number;
  categoria_id: string | null;
  activo: boolean;
}

interface ItemModificador {
  modificador: Modificador;
  cantidad: number;
}

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria_id: string;
  subcategoria_id: string | null;
  imagen_url?: string;
  disponible: boolean;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
  modificadores?: ItemModificador[];
}

const props = defineProps<{
  mostrar: boolean;
  item: ItemPedido | null;
  modificadoresDisponibles: Modificador[];
}>();

const emit = defineEmits<{
  'cerrar': [];
  'guardar': [modificadores: ItemModificador[], cantidadAplicar: number];
}>();

// Opción de aplicar a todos o a una cantidad específica
const aplicarATodos = ref(true);
const cantidadAplicar = ref(1);

// Copia local de modificadores seleccionados
const modificadoresSeleccionados = ref<ItemModificador[]>([]);

// Inicializar con los modificadores actuales del item
const inicializarModificadores = () => {
  if (props.item?.modificadores) {
    modificadoresSeleccionados.value = JSON.parse(JSON.stringify(props.item.modificadores));
  } else {
    modificadoresSeleccionados.value = [];
  }
  // Por defecto, aplicar a todos
  aplicarATodos.value = true;
  cantidadAplicar.value = 1;
};

// Incrementar cantidad a aplicar
const incrementarCantidad = () => {
  if (props.item && cantidadAplicar.value < props.item.cantidad) {
    cantidadAplicar.value++;
  }
};

// Decrementar cantidad a aplicar
const decrementarCantidad = () => {
  if (cantidadAplicar.value > 1) {
    cantidadAplicar.value--;
  }
};

// Verificar si el item tiene múltiples unidades
const tieneMultiplesUnidades = computed(() => {
  return (props.item?.cantidad || 0) > 1;
});

// Watch para inicializar cuando se abre el modal
import { watch } from 'vue';
watch(() => props.mostrar, (nuevo) => {
  if (nuevo) {
    inicializarModificadores();
  }
});

// Filtrar modificadores por tipo
const modificadoresExtras = computed(() => 
  props.modificadoresDisponibles.filter(m => m.tipo === 'extra')
);
const modificadoresSin = computed(() => 
  props.modificadoresDisponibles.filter(m => m.tipo === 'sin')
);
const modificadoresSustitucion = computed(() => 
  props.modificadoresDisponibles.filter(m => m.tipo === 'sustitucion')
);

// Verificar si un modificador está seleccionado
const estaSeleccionado = (modificadorId: string) => {
  return modificadoresSeleccionados.value.some(m => m.modificador.id === modificadorId);
};

// Obtener cantidad de un modificador
const getCantidad = (modificadorId: string) => {
  const mod = modificadoresSeleccionados.value.find(m => m.modificador.id === modificadorId);
  return mod?.cantidad || 0;
};

// Agregar modificador
const agregarModificador = (modificador: Modificador) => {
  const existente = modificadoresSeleccionados.value.find(m => m.modificador.id === modificador.id);
  if (existente) {
    existente.cantidad++;
  } else {
    modificadoresSeleccionados.value.push({ modificador, cantidad: 1 });
  }
};

// Quitar modificador
const quitarModificador = (modificadorId: string) => {
  const index = modificadoresSeleccionados.value.findIndex(m => m.modificador.id === modificadorId);
  if (index !== -1) {
    if (modificadoresSeleccionados.value[index].cantidad > 1) {
      modificadoresSeleccionados.value[index].cantidad--;
    } else {
      modificadoresSeleccionados.value.splice(index, 1);
    }
  }
};

// Eliminar modificador completamente
const eliminarModificador = (modificadorId: string) => {
  modificadoresSeleccionados.value = modificadoresSeleccionados.value.filter(
    m => m.modificador.id !== modificadorId
  );
};

// Guardar y cerrar
const guardarYCerrar = () => {
  // Si aplica a todos, pasar la cantidad total del item; sino, pasar la cantidad seleccionada
  const cantidad = aplicarATodos.value ? (props.item?.cantidad || 1) : cantidadAplicar.value;
  emit('guardar', modificadoresSeleccionados.value, cantidad);
  emit('cerrar');
};

// Cancelar
const cancelar = () => {
  emit('cerrar');
};

// Total adicional por modificadores
const totalAdicional = computed(() => {
  return modificadoresSeleccionados.value.reduce(
    (sum, m) => sum + (m.modificador.precio_adicional * m.cantidad), 0
  );
});
</script>

<template>
  <!-- Backdrop -->
  <Transition name="fade">
    <div 
      v-if="mostrar"
      @click="cancelar"
      class="fixed inset-0 bg-black/50 backdrop-blur-sm z-[200]"
    ></div>
  </Transition>

  <!-- Modal -->
  <Transition name="modal">
    <div 
      v-if="mostrar && item"
      class="fixed inset-4 sm:inset-auto sm:top-1/2 sm:left-1/2 sm:-translate-x-1/2 sm:-translate-y-1/2 sm:w-full sm:max-w-lg bg-white rounded-2xl shadow-2xl z-[201] flex flex-col max-h-[90vh]"
    >
      <!-- Header -->
      <div class="bg-gradient-to-r from-amber-500 to-orange-500 px-4 py-4 rounded-t-2xl">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-bold text-white">Modificadores</h3>
            <p class="text-sm text-amber-100">{{ item.producto.nombre }}</p>
          </div>
          <button
            @click="cancelar"
            class="flex h-8 w-8 items-center justify-center rounded-full bg-white/20 hover:bg-white/30 transition-colors"
          >
            <Icon icon="mdi:close" class="h-5 w-5 text-white" />
          </button>
        </div>
      </div>

      <!-- Contenido scrolleable -->
      <div class="flex-1 overflow-y-auto p-4 space-y-4">
        <!-- Opción: Aplicar a todos o solo a uno (solo si hay múltiples unidades) -->
        <div v-if="tieneMultiplesUnidades" class="bg-blue-50 rounded-xl p-3 border border-blue-200">
          <p class="text-xs font-bold text-blue-800 mb-2 flex items-center gap-1">
            <Icon icon="mdi:information" class="h-4 w-4" />
            Tienes {{ item?.cantidad }} unidades de este producto
          </p>
          <div class="grid grid-cols-2 gap-2">
            <button
              @click="aplicarATodos = true"
              :class="[
                'flex items-center justify-center gap-2 rounded-lg border-2 px-3 py-2 text-xs font-semibold transition-all',
                aplicarATodos 
                  ? 'border-blue-500 bg-blue-100 text-blue-800' 
                  : 'border-gray-300 bg-white text-gray-600 hover:border-blue-300'
              ]"
            >
              <Icon icon="mdi:select-all" class="h-4 w-4" />
              Aplicar a todos ({{ item?.cantidad }})
            </button>
            <button
              @click="aplicarATodos = false"
              :class="[
                'flex items-center justify-center gap-2 rounded-lg border-2 px-3 py-2 text-xs font-semibold transition-all',
                !aplicarATodos 
                  ? 'border-amber-500 bg-amber-100 text-amber-800' 
                  : 'border-gray-300 bg-white text-gray-600 hover:border-amber-300'
              ]"
            >
              <Icon icon="mdi:tune" class="h-4 w-4" />
              Personalizar
            </button>
          </div>
          
          <!-- Selector de cantidad cuando no aplica a todos -->
          <div v-if="!aplicarATodos" class="mt-3 bg-amber-50 rounded-lg p-3 border border-amber-200">
            <p class="text-xs font-semibold text-amber-800 mb-2">¿A cuántas unidades aplicar?</p>
            <div class="flex items-center justify-center gap-3">
              <button
                @click="decrementarCantidad"
                :disabled="cantidadAplicar <= 1"
                class="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-200 text-amber-800 font-bold text-lg transition-all hover:bg-amber-300 active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <Icon icon="mdi:minus" class="h-5 w-5" />
              </button>
              <div class="flex flex-col items-center">
                <span class="text-2xl font-bold text-amber-900">{{ cantidadAplicar }}</span>
                <span class="text-[10px] text-amber-600">de {{ item?.cantidad }}</span>
              </div>
              <button
                @click="incrementarCantidad"
                :disabled="cantidadAplicar >= (item?.cantidad || 1)"
                class="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-200 text-amber-800 font-bold text-lg transition-all hover:bg-amber-300 active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <Icon icon="mdi:plus" class="h-5 w-5" />
              </button>
            </div>
            <p class="mt-2 text-[10px] text-amber-700 text-center">
              Se {{ cantidadAplicar === 1 ? 'separará' : 'separarán' }} {{ cantidadAplicar }} unidad{{ cantidadAplicar > 1 ? 'es' : '' }} con estos modificadores
            </p>
          </div>
        </div>

        <!-- Modificadores seleccionados -->
        <div v-if="modificadoresSeleccionados.length > 0" class="bg-amber-50 rounded-xl p-3">
          <p class="text-xs font-bold text-amber-800 mb-2">Seleccionados:</p>
          <div class="flex flex-wrap gap-2">
            <div
              v-for="mod in modificadoresSeleccionados"
              :key="mod.modificador.id"
              class="flex items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold"
              :class="{
                'bg-green-100 text-green-800': mod.modificador.tipo === 'extra',
                'bg-red-100 text-red-800': mod.modificador.tipo === 'sin',
                'bg-blue-100 text-blue-800': mod.modificador.tipo === 'sustitucion'
              }"
            >
              <span>{{ mod.modificador.nombre }}</span>
              <span v-if="mod.cantidad > 1" class="font-bold">x{{ mod.cantidad }}</span>
              <button
                @click="eliminarModificador(mod.modificador.id)"
                class="ml-1 hover:text-gray-900"
              >
                <Icon icon="mdi:close" class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
          <p v-if="totalAdicional > 0" class="mt-2 text-xs font-semibold text-amber-700">
            Adicional: +S/ {{ totalAdicional.toFixed(2) }}
          </p>
        </div>

        <!-- Extras -->
        <div v-if="modificadoresExtras.length > 0">
          <div class="flex items-center gap-2 mb-2">
            <Icon icon="mdi:plus-circle" class="h-5 w-5 text-green-600" />
            <h4 class="font-bold text-gray-800">Extras</h4>
          </div>
          <div class="grid grid-cols-2 gap-2">
            <button
              v-for="mod in modificadoresExtras"
              :key="mod.id"
              @click="agregarModificador(mod)"
              class="flex items-center justify-between rounded-xl border-2 p-3 text-left transition-all hover:shadow-md active:scale-98"
              :class="estaSeleccionado(mod.id) 
                ? 'border-green-500 bg-green-50' 
                : 'border-gray-200 bg-white hover:border-green-300'"
            >
              <div>
                <p class="text-sm font-semibold text-gray-800">{{ mod.nombre }}</p>
                <p v-if="mod.precio_adicional > 0" class="text-xs text-green-600 font-medium">
                  +S/ {{ mod.precio_adicional.toFixed(2) }}
                </p>
              </div>
              <div v-if="getCantidad(mod.id) > 0" class="flex items-center gap-1">
                <button
                  @click.stop="quitarModificador(mod.id)"
                  class="flex h-6 w-6 items-center justify-center rounded-full bg-red-100 text-red-600 hover:bg-red-200"
                >
                  <Icon icon="mdi:minus" class="h-4 w-4" />
                </button>
                <span class="w-6 text-center text-sm font-bold">{{ getCantidad(mod.id) }}</span>
                <button
                  @click.stop="agregarModificador(mod)"
                  class="flex h-6 w-6 items-center justify-center rounded-full bg-green-100 text-green-600 hover:bg-green-200"
                >
                  <Icon icon="mdi:plus" class="h-4 w-4" />
                </button>
              </div>
              <Icon v-else icon="mdi:plus" class="h-5 w-5 text-gray-400" />
            </button>
          </div>
        </div>

        <!-- Sin ingredientes -->
        <div v-if="modificadoresSin.length > 0">
          <div class="flex items-center gap-2 mb-2">
            <Icon icon="mdi:minus-circle" class="h-5 w-5 text-red-600" />
            <h4 class="font-bold text-gray-800">Sin</h4>
          </div>
          <div class="grid grid-cols-2 gap-2">
            <button
              v-for="mod in modificadoresSin"
              :key="mod.id"
              @click="estaSeleccionado(mod.id) ? eliminarModificador(mod.id) : agregarModificador(mod)"
              class="flex items-center justify-between rounded-xl border-2 p-3 text-left transition-all hover:shadow-md active:scale-98"
              :class="estaSeleccionado(mod.id) 
                ? 'border-red-500 bg-red-50' 
                : 'border-gray-200 bg-white hover:border-red-300'"
            >
              <p class="text-sm font-semibold text-gray-800">{{ mod.nombre }}</p>
              <Icon 
                :icon="estaSeleccionado(mod.id) ? 'mdi:check' : 'mdi:close'" 
                class="h-5 w-5"
                :class="estaSeleccionado(mod.id) ? 'text-red-600' : 'text-gray-400'"
              />
            </button>
          </div>
        </div>

        <!-- Sustituciones -->
        <div v-if="modificadoresSustitucion.length > 0">
          <div class="flex items-center gap-2 mb-2">
            <Icon icon="mdi:swap-horizontal" class="h-5 w-5 text-blue-600" />
            <h4 class="font-bold text-gray-800">Cambios</h4>
          </div>
          <div class="grid grid-cols-2 gap-2">
            <button
              v-for="mod in modificadoresSustitucion"
              :key="mod.id"
              @click="estaSeleccionado(mod.id) ? eliminarModificador(mod.id) : agregarModificador(mod)"
              class="flex items-center justify-between rounded-xl border-2 p-3 text-left transition-all hover:shadow-md active:scale-98"
              :class="estaSeleccionado(mod.id) 
                ? 'border-blue-500 bg-blue-50' 
                : 'border-gray-200 bg-white hover:border-blue-300'"
            >
              <p class="text-sm font-semibold text-gray-800">{{ mod.nombre }}</p>
              <Icon 
                :icon="estaSeleccionado(mod.id) ? 'mdi:check' : 'mdi:swap-horizontal'" 
                class="h-5 w-5"
                :class="estaSeleccionado(mod.id) ? 'text-blue-600' : 'text-gray-400'"
              />
            </button>
          </div>
        </div>
      </div>

      <!-- Footer con botones -->
      <div class="border-t border-gray-200 p-4 bg-gray-50 rounded-b-2xl">
        <div class="flex gap-3">
          <button
            @click="cancelar"
            class="flex-1 rounded-xl border-2 border-gray-300 py-3 text-sm font-semibold text-gray-700 hover:bg-gray-100 transition-colors"
          >
            Cancelar
          </button>
          <button
            @click="guardarYCerrar"
            class="flex-1 rounded-xl bg-amber-500 py-3 text-sm font-bold text-white hover:bg-amber-600 transition-colors flex items-center justify-center gap-2"
          >
            <Icon icon="mdi:check" class="h-5 w-5" />
            Guardar
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
  transform: scale(0.95) translateY(20px);
}
@media (min-width: 640px) {
  .modal-enter-from,
  .modal-leave-to {
    transform: translate(-50%, -50%) scale(0.95);
  }
  .modal-enter-to,
  .modal-leave-from {
    transform: translate(-50%, -50%) scale(1);
  }
}

.active\:scale-98:active {
  transform: scale(0.98);
}
</style>
