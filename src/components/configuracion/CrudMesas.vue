<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
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
  created_at: string;
}

// Estado
const mesas = ref<Mesa[]>([]);
const loading = ref(true);
const showModal = ref(false);
const modalMode = ref<'crear' | 'editar'>('crear');
const mesaEditando = ref<Mesa | null>(null);
const guardando = ref(false);
const mensaje = ref<{ tipo: 'success' | 'error'; texto: string } | null>(null);
const busqueda = ref('');
const filtroUbicacion = ref<string>('');

// Formulario
const form = ref({
  numero: 1,
  capacidad: 4,
  posicion_x: 1,
  posicion_y: 1,
  ancho: 2,
  alto: 2,
  orientacion: 'vertical' as 'horizontal' | 'vertical',
  estado: 'disponible' as Mesa['estado'],
  ubicacion: 'interior',
  activo: true
});

// Ubicaciones disponibles
const ubicaciones = ['interior', 'terraza', 'segundo_piso', 'vip'];

// Estados disponibles
const estados = [
  { value: 'disponible', label: 'Disponible', color: 'green' },
  { value: 'ocupada', label: 'Ocupada', color: 'red' },
  { value: 'reservada', label: 'Reservada', color: 'yellow' },
  { value: 'mantenimiento', label: 'Mantenimiento', color: 'gray' }
];

// Computed
const mesasFiltradas = computed(() => {
  let resultado = mesas.value;
  
  if (filtroUbicacion.value) {
    resultado = resultado.filter(m => m.ubicacion === filtroUbicacion.value);
  }
  
  if (busqueda.value) {
    const term = busqueda.value.toLowerCase();
    resultado = resultado.filter(m => 
      m.numero.toString().includes(term) ||
      m.ubicacion.toLowerCase().includes(term)
    );
  }
  
  return resultado.sort((a, b) => a.numero - b.numero);
});

const ubicacionesUnicas = computed(() => {
  const ubicacionesSet = new Set(mesas.value.map(m => m.ubicacion));
  return Array.from(ubicacionesSet);
});

// Cargar mesas
const fetchMesas = async () => {
  try {
    loading.value = true;
    const { data, error } = await supabase
      .from('mesas')
      .select('*')
      .order('numero');

    if (error) throw error;
    mesas.value = data || [];
  } catch (err) {
    console.error('Error:', err);
    mostrarMensaje('error', 'Error al cargar mesas');
  } finally {
    loading.value = false;
  }
};

// Abrir modal para crear
const abrirCrear = () => {
  modalMode.value = 'crear';
  mesaEditando.value = null;
  
  // Calcular siguiente número de mesa
  const maxNumero = mesas.value.reduce((max, m) => Math.max(max, m.numero), 0);
  
  form.value = {
    numero: maxNumero + 1,
    capacidad: 4,
    posicion_x: 1,
    posicion_y: 1,
    ancho: 2,
    alto: 2,
    orientacion: 'vertical',
    estado: 'disponible',
    ubicacion: 'interior',
    activo: true
  };
  showModal.value = true;
};

// Abrir modal para editar
const abrirEditar = (mesa: Mesa) => {
  modalMode.value = 'editar';
  mesaEditando.value = mesa;
  form.value = {
    numero: mesa.numero,
    capacidad: mesa.capacidad,
    posicion_x: mesa.posicion_x,
    posicion_y: mesa.posicion_y,
    ancho: mesa.ancho,
    alto: mesa.alto,
    orientacion: mesa.orientacion,
    estado: mesa.estado,
    ubicacion: mesa.ubicacion,
    activo: mesa.activo
  };
  showModal.value = true;
};

// Guardar
const guardar = async () => {
  if (form.value.numero < 1 || form.value.capacidad < 1) {
    mostrarMensaje('error', 'Número y capacidad deben ser mayores a 0');
    return;
  }

  try {
    guardando.value = true;

    const datos = {
      numero: form.value.numero,
      capacidad: form.value.capacidad,
      posicion_x: form.value.posicion_x,
      posicion_y: form.value.posicion_y,
      ancho: form.value.ancho,
      alto: form.value.alto,
      orientacion: form.value.orientacion,
      estado: form.value.estado,
      ubicacion: form.value.ubicacion,
      activo: form.value.activo
    };

    if (modalMode.value === 'crear') {
      const { error } = await supabase.from('mesas').insert([datos]);
      if (error) throw error;
      mostrarMensaje('success', 'Mesa creada');
    } else {
      const { error } = await supabase.from('mesas').update(datos).eq('id', mesaEditando.value?.id);
      if (error) throw error;
      mostrarMensaje('success', 'Mesa actualizada');
    }

    showModal.value = false;
    await fetchMesas();
  } catch (err: any) {
    console.error('Error:', err);
    mostrarMensaje('error', err.message || 'Error al guardar');
  } finally {
    guardando.value = false;
  }
};

// Eliminar
const eliminar = async (mesa: Mesa) => {
  if (!confirm(`¿Eliminar la mesa ${mesa.numero}?`)) return;

  try {
    const { error } = await supabase.from('mesas').delete().eq('id', mesa.id);
    if (error) throw error;
    mostrarMensaje('success', 'Mesa eliminada');
    await fetchMesas();
  } catch (err: any) {
    mostrarMensaje('error', err.message || 'Error al eliminar');
  }
};

// Cambiar estado
const cambiarEstado = async (mesa: Mesa, nuevoEstado: Mesa['estado']) => {
  try {
    const { error } = await supabase
      .from('mesas')
      .update({ estado: nuevoEstado })
      .eq('id', mesa.id);

    if (error) throw error;
    await fetchMesas();
  } catch (err) {
    console.error('Error:', err);
  }
};

// Mostrar mensaje
const mostrarMensaje = (tipo: 'success' | 'error', texto: string) => {
  mensaje.value = { tipo, texto };
  setTimeout(() => mensaje.value = null, 3000);
};

// Color del estado
const getEstadoColor = (estado: string) => {
  const colores: Record<string, string> = {
    disponible: 'bg-green-100 text-green-700 border-green-300',
    ocupada: 'bg-red-100 text-red-700 border-red-300',
    reservada: 'bg-yellow-100 text-yellow-700 border-yellow-300',
    mantenimiento: 'bg-gray-100 text-gray-700 border-gray-300'
  };
  return colores[estado] || colores.disponible;
};

onMounted(fetchMesas);
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-yellow-600 to-yellow-700 px-4 py-4 shadow-lg sticky top-0 z-40">
      <div class="max-w-7xl mx-auto">
        <div class="flex items-center gap-3">
          <a href="/configuracion" class="flex items-center justify-center w-10 h-10 rounded-xl bg-white/20 text-white hover:bg-white/30 transition-colors">
            <Icon icon="mdi:arrow-left" class="w-5 h-5" />
          </a>
          <div class="flex-1">
            <h1 class="text-xl font-bold text-white">Mesas</h1>
            <p class="text-yellow-100 text-sm">{{ mesas.length }} mesas</p>
          </div>
          <button
            @click="abrirCrear"
            class="flex items-center gap-2 bg-white text-yellow-600 px-4 py-2 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all active:scale-95"
          >
            <Icon icon="mdi:plus" class="w-5 h-5" />
            <span class="hidden sm:inline">Nueva</span>
          </button>
        </div>
      </div>
    </header>

    <!-- Mensaje -->
    <Transition name="slide-down">
      <div v-if="mensaje" class="fixed top-20 left-4 right-4 z-50 max-w-md mx-auto">
        <div
          :class="[
            'p-4 rounded-xl shadow-lg flex items-center gap-3',
            mensaje.tipo === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
          ]"
        >
          <Icon :icon="mensaje.tipo === 'success' ? 'mdi:check-circle' : 'mdi:alert-circle'" class="w-6 h-6 shrink-0" />
          <span class="font-medium">{{ mensaje.texto }}</span>
        </div>
      </div>
    </Transition>

    <!-- Filtros -->
    <div class="px-4 py-4 bg-white border-b sticky top-[72px] z-30">
      <div class="max-w-7xl mx-auto space-y-3">
        <!-- Filtro por ubicación -->
        <div class="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
          <button
            @click="filtroUbicacion = ''"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors',
              !filtroUbicacion ? 'bg-yellow-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            Todas
          </button>
          <button
            v-for="ubi in ubicacionesUnicas"
            :key="ubi"
            @click="filtroUbicacion = ubi"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors capitalize',
              filtroUbicacion === ubi ? 'bg-yellow-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            {{ ubi.replace('_', ' ') }}
          </button>
        </div>
        
        <!-- Buscador -->
        <div class="relative">
          <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            v-model="busqueda"
            type="text"
            placeholder="Buscar mesa..."
            class="w-full pl-10 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-yellow-500 focus:outline-none transition-colors"
          />
        </div>
      </div>
    </div>

    <!-- Lista -->
    <div class="px-4 py-4 max-w-7xl mx-auto">
      <!-- Loading -->
      <div v-if="loading" class="flex justify-center py-12">
        <div class="w-10 h-10 border-4 border-yellow-200 border-t-yellow-600 rounded-full animate-spin"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="mesasFiltradas.length === 0" class="text-center py-12">
        <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <Icon icon="mdi:table-furniture" class="w-10 h-10 text-gray-300" />
        </div>
        <p class="text-gray-500 font-medium">No hay mesas</p>
        <button @click="abrirCrear" class="mt-4 text-yellow-600 font-semibold">+ Crear mesa</button>
      </div>

      <!-- Grid -->
      <div v-else class="grid gap-3 grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6">
        <div
          v-for="mesa in mesasFiltradas"
          :key="mesa.id"
          class="bg-white rounded-2xl shadow-sm border-2 border-gray-100 overflow-hidden hover:shadow-md hover:border-yellow-200 transition-all"
        >
          <!-- Número de mesa grande -->
          <div class="p-4 text-center">
            <div class="w-16 h-16 mx-auto rounded-2xl bg-yellow-100 flex items-center justify-center mb-2">
              <span class="text-2xl font-bold text-yellow-700">{{ mesa.numero }}</span>
            </div>
            <p class="text-xs text-gray-500 capitalize">{{ mesa.ubicacion.replace('_', ' ') }}</p>
            <p class="text-xs text-gray-400">{{ mesa.capacidad }} personas</p>
          </div>

          <!-- Estado -->
          <div class="px-3 pb-3">
            <select
              :value="mesa.estado"
              @change="cambiarEstado(mesa, ($event.target as HTMLSelectElement).value as Mesa['estado'])"
              :class="[
                'w-full px-3 py-2 rounded-lg text-xs font-semibold border-2 transition-colors cursor-pointer',
                getEstadoColor(mesa.estado)
              ]"
            >
              <option v-for="est in estados" :key="est.value" :value="est.value">
                {{ est.label }}
              </option>
            </select>
          </div>

          <!-- Acciones -->
          <div class="px-3 pb-3 flex gap-2">
            <button
              @click="abrirEditar(mesa)"
              class="flex-1 p-2 rounded-lg bg-yellow-100 text-yellow-600 hover:bg-yellow-200 transition-colors flex items-center justify-center gap-1"
            >
              <Icon icon="mdi:pencil" class="w-4 h-4" />
              <span class="text-xs font-semibold">Editar</span>
            </button>
            <button
              @click="eliminar(mesa)"
              class="p-2 rounded-lg bg-red-100 text-red-600 hover:bg-red-200 transition-colors"
            >
              <Icon icon="mdi:delete" class="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <Transition name="modal">
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
        <div class="absolute inset-0 bg-black/50" @click="showModal = false"></div>
        
        <div class="relative w-full sm:max-w-md bg-white rounded-t-3xl sm:rounded-2xl shadow-2xl max-h-[90vh] overflow-hidden">
          <div class="flex items-center justify-between p-4 border-b bg-gray-50">
            <h2 class="text-lg font-bold text-gray-900">
              {{ modalMode === 'crear' ? 'Nueva Mesa' : 'Editar Mesa' }}
            </h2>
            <button @click="showModal = false" class="p-2 rounded-full hover:bg-gray-200 transition-colors">
              <Icon icon="mdi:close" class="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <div class="p-4 space-y-4 overflow-y-auto max-h-[60vh]">
            <!-- Número y Capacidad -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-1">Número *</label>
                <input
                  v-model.number="form.numero"
                  type="number"
                  min="1"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-yellow-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-1">Capacidad *</label>
                <input
                  v-model.number="form.capacidad"
                  type="number"
                  min="1"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-yellow-500 focus:outline-none"
                />
              </div>
            </div>

            <!-- Ubicación -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Ubicación</label>
              <select
                v-model="form.ubicacion"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-yellow-500 focus:outline-none"
              >
                <option v-for="ubi in ubicaciones" :key="ubi" :value="ubi" class="capitalize">
                  {{ ubi.replace('_', ' ') }}
                </option>
              </select>
            </div>

            <!-- Estado -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Estado</label>
              <select
                v-model="form.estado"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-yellow-500 focus:outline-none"
              >
                <option v-for="est in estados" :key="est.value" :value="est.value">
                  {{ est.label }}
                </option>
              </select>
            </div>

            <!-- Posición en grilla -->
            <div class="p-3 bg-gray-50 rounded-xl">
              <p class="text-sm font-semibold text-gray-700 mb-3">Posición en grilla</p>
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="block text-xs text-gray-500 mb-1">Columna (X)</label>
                  <input
                    v-model.number="form.posicion_x"
                    type="number"
                    min="1"
                    class="w-full px-3 py-2 rounded-lg border-2 border-gray-200 focus:border-yellow-500 focus:outline-none text-sm"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-500 mb-1">Fila (Y)</label>
                  <input
                    v-model.number="form.posicion_y"
                    type="number"
                    min="1"
                    class="w-full px-3 py-2 rounded-lg border-2 border-gray-200 focus:border-yellow-500 focus:outline-none text-sm"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-500 mb-1">Ancho</label>
                  <input
                    v-model.number="form.ancho"
                    type="number"
                    min="1"
                    class="w-full px-3 py-2 rounded-lg border-2 border-gray-200 focus:border-yellow-500 focus:outline-none text-sm"
                  />
                </div>
                <div>
                  <label class="block text-xs text-gray-500 mb-1">Alto</label>
                  <input
                    v-model.number="form.alto"
                    type="number"
                    min="1"
                    class="w-full px-3 py-2 rounded-lg border-2 border-gray-200 focus:border-yellow-500 focus:outline-none text-sm"
                  />
                </div>
              </div>
            </div>

            <!-- Orientación -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">Orientación</label>
              <div class="grid grid-cols-2 gap-3">
                <button
                  @click="form.orientacion = 'vertical'"
                  :class="[
                    'p-3 rounded-xl border-2 flex flex-col items-center gap-2 transition-all',
                    form.orientacion === 'vertical' ? 'border-yellow-500 bg-yellow-50' : 'border-gray-200 hover:border-gray-300'
                  ]"
                >
                  <div class="w-6 h-10 bg-yellow-400 rounded"></div>
                  <span class="text-xs font-semibold" :class="form.orientacion === 'vertical' ? 'text-yellow-700' : 'text-gray-600'">Vertical</span>
                </button>
                <button
                  @click="form.orientacion = 'horizontal'"
                  :class="[
                    'p-3 rounded-xl border-2 flex flex-col items-center gap-2 transition-all',
                    form.orientacion === 'horizontal' ? 'border-yellow-500 bg-yellow-50' : 'border-gray-200 hover:border-gray-300'
                  ]"
                >
                  <div class="w-10 h-6 bg-yellow-400 rounded"></div>
                  <span class="text-xs font-semibold" :class="form.orientacion === 'horizontal' ? 'text-yellow-700' : 'text-gray-600'">Horizontal</span>
                </button>
              </div>
            </div>

            <!-- Activo -->
            <div class="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
              <span class="font-medium text-gray-700">Activo</span>
              <button
                @click="form.activo = !form.activo"
                :class="[
                  'w-12 h-7 rounded-full transition-colors relative',
                  form.activo ? 'bg-green-500' : 'bg-gray-300'
                ]"
              >
                <span
                  :class="[
                    'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                    form.activo ? 'left-[22px]' : 'left-0.5'
                  ]"
                ></span>
              </button>
            </div>
          </div>

          <div class="p-4 border-t bg-gray-50 flex gap-3">
            <button
              @click="showModal = false"
              class="flex-1 py-3 rounded-xl border-2 border-gray-300 font-semibold text-gray-700 hover:bg-gray-100 transition-colors"
            >
              Cancelar
            </button>
            <button
              @click="guardar"
              :disabled="guardando"
              class="flex-1 py-3 rounded-xl bg-yellow-600 text-white font-semibold hover:bg-yellow-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              <Icon v-if="guardando" icon="mdi:loading" class="w-5 h-5 animate-spin" />
              {{ guardando ? 'Guardando...' : 'Guardar' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s ease;
}
.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}

.modal-enter-active,
.modal-leave-active {
  transition: all 0.3s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
.modal-enter-from > div:last-child,
.modal-leave-to > div:last-child {
  transform: translateY(100%);
}
@media (min-width: 640px) {
  .modal-enter-from > div:last-child,
  .modal-leave-to > div:last-child {
    transform: scale(0.95);
  }
}
</style>
