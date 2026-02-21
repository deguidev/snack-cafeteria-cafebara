<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';

interface Categoria {
  id: string;
  nombre: string;
}

interface Modificador {
  id: string;
  nombre: string;
  descripcion: string | null;
  tipo: 'extra' | 'sin' | 'sustitucion';
  precio_adicional: number;
  categoria_id: string | null;
  activo: boolean;
  orden: number;
  categorias?: Categoria;
}

// Estado
const modificadores = ref<Modificador[]>([]);
const categorias = ref<Categoria[]>([]);
const loading = ref(true);
const showModal = ref(false);
const modalMode = ref<'crear' | 'editar'>('crear');
const modificadorEditando = ref<Modificador | null>(null);
const guardando = ref(false);
const mensaje = ref<{ tipo: 'success' | 'error'; texto: string } | null>(null);
const busqueda = ref('');
const filtroTipo = ref<string>('');

// Formulario
const form = ref({
  nombre: '',
  descripcion: '',
  tipo: 'extra' as 'extra' | 'sin' | 'sustitucion',
  precio_adicional: 0,
  categoria_id: '',
  activo: true,
  orden: 0
});

// Tipos de modificadores
const tipos = [
  { value: 'extra', label: 'Extra', icon: 'mdi:plus-circle', color: 'green', desc: 'Agrega algo (doble huevo, extra queso)' },
  { value: 'sin', label: 'Sin', icon: 'mdi:minus-circle', color: 'red', desc: 'Quita algo (sin cebolla, sin arroz)' },
  { value: 'sustitucion', label: 'Sustitución', icon: 'mdi:swap-horizontal', color: 'blue', desc: 'Cambia algo (arroz por papa)' }
];

// Computed
const modificadoresFiltrados = computed(() => {
  let resultado = modificadores.value;
  
  if (filtroTipo.value) {
    resultado = resultado.filter(m => m.tipo === filtroTipo.value);
  }
  
  if (busqueda.value) {
    const term = busqueda.value.toLowerCase();
    resultado = resultado.filter(m => 
      m.nombre.toLowerCase().includes(term) ||
      m.descripcion?.toLowerCase().includes(term)
    );
  }
  
  return resultado;
});

// Cargar datos
const fetchData = async () => {
  try {
    loading.value = true;
    
    const [catRes, modRes] = await Promise.all([
      supabase.from('categorias').select('id, nombre').eq('activo', true).order('orden'),
      supabase.from('modificadores').select('*, categorias(id, nombre)').order('tipo').order('orden')
    ]);

    categorias.value = catRes.data || [];
    modificadores.value = modRes.data || [];
  } catch (err) {
    console.error('Error:', err);
    mostrarMensaje('error', 'Error al cargar datos');
  } finally {
    loading.value = false;
  }
};

// Abrir modal para crear
const abrirCrear = () => {
  modalMode.value = 'crear';
  modificadorEditando.value = null;
  form.value = {
    nombre: '',
    descripcion: '',
    tipo: 'extra',
    precio_adicional: 0,
    categoria_id: '',
    activo: true,
    orden: modificadores.value.length + 1
  };
  showModal.value = true;
};

// Abrir modal para editar
const abrirEditar = (modificador: Modificador) => {
  modalMode.value = 'editar';
  modificadorEditando.value = modificador;
  form.value = {
    nombre: modificador.nombre,
    descripcion: modificador.descripcion || '',
    tipo: modificador.tipo,
    precio_adicional: modificador.precio_adicional,
    categoria_id: modificador.categoria_id || '',
    activo: modificador.activo,
    orden: modificador.orden
  };
  showModal.value = true;
};

// Guardar
const guardar = async () => {
  if (!form.value.nombre.trim()) {
    mostrarMensaje('error', 'El nombre es requerido');
    return;
  }

  try {
    guardando.value = true;

    const datos = {
      nombre: form.value.nombre,
      descripcion: form.value.descripcion || null,
      tipo: form.value.tipo,
      precio_adicional: form.value.precio_adicional,
      categoria_id: form.value.categoria_id || null,
      activo: form.value.activo,
      orden: form.value.orden
    };

    if (modalMode.value === 'crear') {
      const { error } = await supabase.from('modificadores').insert([datos]);
      if (error) throw error;
      mostrarMensaje('success', 'Modificador creado');
    } else {
      const { error } = await supabase.from('modificadores').update(datos).eq('id', modificadorEditando.value?.id);
      if (error) throw error;
      mostrarMensaje('success', 'Modificador actualizado');
    }

    showModal.value = false;
    await fetchData();
  } catch (err: any) {
    console.error('Error:', err);
    mostrarMensaje('error', err.message || 'Error al guardar');
  } finally {
    guardando.value = false;
  }
};

// Eliminar
const eliminar = async (modificador: Modificador) => {
  if (!confirm(`¿Eliminar "${modificador.nombre}"?`)) return;

  try {
    const { error } = await supabase.from('modificadores').delete().eq('id', modificador.id);
    if (error) throw error;
    mostrarMensaje('success', 'Modificador eliminado');
    await fetchData();
  } catch (err: any) {
    mostrarMensaje('error', err.message || 'Error al eliminar');
  }
};

// Toggle activo
const toggleActivo = async (modificador: Modificador) => {
  try {
    const { error } = await supabase
      .from('modificadores')
      .update({ activo: !modificador.activo })
      .eq('id', modificador.id);

    if (error) throw error;
    await fetchData();
  } catch (err) {
    console.error('Error:', err);
  }
};

// Mostrar mensaje
const mostrarMensaje = (tipo: 'success' | 'error', texto: string) => {
  mensaje.value = { tipo, texto };
  setTimeout(() => mensaje.value = null, 3000);
};

// Obtener color del tipo
const getTipoColor = (tipo: string) => {
  const colores: Record<string, string> = {
    extra: 'bg-green-100 text-green-700 border-green-300',
    sin: 'bg-red-100 text-red-700 border-red-300',
    sustitucion: 'bg-blue-100 text-blue-700 border-blue-300'
  };
  return colores[tipo] || colores.extra;
};

const getTipoIcon = (tipo: string) => {
  const iconos: Record<string, string> = {
    extra: 'mdi:plus-circle',
    sin: 'mdi:minus-circle',
    sustitucion: 'mdi:swap-horizontal'
  };
  return iconos[tipo] || iconos.extra;
};

onMounted(fetchData);
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-green-600 to-green-700 px-4 py-4 shadow-lg sticky top-0 z-40">
      <div class="max-w-7xl mx-auto">
        <div class="flex items-center gap-3">
          <a href="/configuracion" class="flex items-center justify-center w-10 h-10 rounded-xl bg-white/20 text-white hover:bg-white/30 transition-colors">
            <Icon icon="mdi:arrow-left" class="w-5 h-5" />
          </a>
          <div class="flex-1">
            <h1 class="text-xl font-bold text-white">Modificadores</h1>
            <p class="text-green-100 text-sm">{{ modificadores.length }} registros</p>
          </div>
          <button
            @click="abrirCrear"
            class="flex items-center gap-2 bg-white text-green-600 px-4 py-2 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all active:scale-95"
          >
            <Icon icon="mdi:plus" class="w-5 h-5" />
            <span class="hidden sm:inline">Nuevo</span>
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
        <!-- Filtro por tipo -->
        <div class="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
          <button
            @click="filtroTipo = ''"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors',
              !filtroTipo ? 'bg-green-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            Todos
          </button>
          <button
            v-for="tipo in tipos"
            :key="tipo.value"
            @click="filtroTipo = tipo.value"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors flex items-center gap-2',
              filtroTipo === tipo.value ? 'bg-green-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            <Icon :icon="tipo.icon" class="w-4 h-4" />
            {{ tipo.label }}
          </button>
        </div>
        
        <!-- Buscador -->
        <div class="relative">
          <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            v-model="busqueda"
            type="text"
            placeholder="Buscar modificador..."
            class="w-full pl-10 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-green-500 focus:outline-none transition-colors"
          />
        </div>
      </div>
    </div>

    <!-- Lista -->
    <div class="px-4 py-4 max-w-7xl mx-auto">
      <!-- Loading -->
      <div v-if="loading" class="flex justify-center py-12">
        <div class="w-10 h-10 border-4 border-green-200 border-t-green-600 rounded-full animate-spin"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="modificadoresFiltrados.length === 0" class="text-center py-12">
        <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <Icon icon="mdi:tune-variant" class="w-10 h-10 text-gray-300" />
        </div>
        <p class="text-gray-500 font-medium">No hay modificadores</p>
        <button @click="abrirCrear" class="mt-4 text-green-600 font-semibold">+ Crear modificador</button>
      </div>

      <!-- Grid -->
      <div v-else class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <div
          v-for="mod in modificadoresFiltrados"
          :key="mod.id"
          class="bg-white rounded-2xl shadow-sm border-2 border-gray-100 overflow-hidden hover:shadow-md hover:border-green-200 transition-all"
        >
          <div class="p-4">
            <!-- Header con tipo -->
            <div class="flex items-center gap-3 mb-3">
              <div :class="['w-10 h-10 rounded-xl flex items-center justify-center', getTipoColor(mod.tipo)]">
                <Icon :icon="getTipoIcon(mod.tipo)" class="w-5 h-5" />
              </div>
              <div class="flex-1 min-w-0">
                <h3 class="font-bold text-gray-900 truncate">{{ mod.nombre }}</h3>
                <span :class="['text-xs font-semibold px-2 py-0.5 rounded-full', getTipoColor(mod.tipo)]">
                  {{ mod.tipo }}
                </span>
              </div>
              <button
                @click="toggleActivo(mod)"
                :class="[
                  'w-12 h-7 rounded-full transition-colors relative shrink-0',
                  mod.activo ? 'bg-green-500' : 'bg-gray-300'
                ]"
              >
                <span
                  :class="[
                    'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                    mod.activo ? 'left-[22px]' : 'left-0.5'
                  ]"
                ></span>
              </button>
            </div>

            <!-- Descripción -->
            <p v-if="mod.descripcion" class="text-xs text-gray-500 mb-2 line-clamp-2">{{ mod.descripcion }}</p>

            <!-- Precio -->
            <div class="flex items-center justify-between">
              <span v-if="mod.precio_adicional > 0" class="text-sm font-bold text-green-600">
                +S/ {{ mod.precio_adicional.toFixed(2) }}
              </span>
              <span v-else-if="mod.precio_adicional < 0" class="text-sm font-bold text-red-600">
                -S/ {{ Math.abs(mod.precio_adicional).toFixed(2) }}
              </span>
              <span v-else class="text-sm text-gray-400">Sin costo</span>
              
              <span v-if="mod.categorias" class="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
                {{ mod.categorias.nombre }}
              </span>
            </div>
          </div>

          <!-- Acciones -->
          <div class="px-4 py-3 bg-gray-50 flex items-center justify-end gap-2 border-t">
            <button
              @click="abrirEditar(mod)"
              class="p-2 rounded-lg bg-green-100 text-green-600 hover:bg-green-200 transition-colors"
            >
              <Icon icon="mdi:pencil" class="w-4 h-4" />
            </button>
            <button
              @click="eliminar(mod)"
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
              {{ modalMode === 'crear' ? 'Nuevo Modificador' : 'Editar Modificador' }}
            </h2>
            <button @click="showModal = false" class="p-2 rounded-full hover:bg-gray-200 transition-colors">
              <Icon icon="mdi:close" class="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <div class="p-4 space-y-4 overflow-y-auto max-h-[60vh]">
            <!-- Nombre -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Nombre *</label>
              <input
                v-model="form.nombre"
                type="text"
                placeholder="Ej: Doble huevo"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-green-500 focus:outline-none"
              />
            </div>

            <!-- Descripción -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Descripción</label>
              <textarea
                v-model="form.descripcion"
                rows="2"
                placeholder="Descripción opcional..."
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-green-500 focus:outline-none resize-none"
              ></textarea>
            </div>

            <!-- Tipo -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">Tipo *</label>
              <div class="grid grid-cols-3 gap-2">
                <button
                  v-for="tipo in tipos"
                  :key="tipo.value"
                  @click="form.tipo = tipo.value as any"
                  :class="[
                    'p-3 rounded-xl border-2 flex flex-col items-center gap-1 transition-all',
                    form.tipo === tipo.value ? `border-${tipo.color}-500 bg-${tipo.color}-50` : 'border-gray-200 hover:border-gray-300'
                  ]"
                >
                  <Icon :icon="tipo.icon" :class="['w-6 h-6', form.tipo === tipo.value ? `text-${tipo.color}-600` : 'text-gray-500']" />
                  <span class="text-xs font-semibold" :class="form.tipo === tipo.value ? `text-${tipo.color}-700` : 'text-gray-600'">{{ tipo.label }}</span>
                </button>
              </div>
              <p class="text-xs text-gray-500 mt-2">{{ tipos.find(t => t.value === form.tipo)?.desc }}</p>
            </div>

            <!-- Precio adicional -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Precio adicional</label>
              <div class="relative">
                <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-semibold">S/</span>
                <input
                  v-model.number="form.precio_adicional"
                  type="number"
                  step="0.50"
                  placeholder="0.00"
                  class="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-green-500 focus:outline-none"
                />
              </div>
              <p class="text-xs text-gray-500 mt-1">Usa 0 para sin costo, negativo para descuentos</p>
            </div>

            <!-- Categoría -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Aplica a categoría</label>
              <select
                v-model="form.categoria_id"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-green-500 focus:outline-none"
              >
                <option value="">Todas las categorías</option>
                <option v-for="cat in categorias" :key="cat.id" :value="cat.id">
                  {{ cat.nombre }}
                </option>
              </select>
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
              class="flex-1 py-3 rounded-xl bg-green-600 text-white font-semibold hover:bg-green-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
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

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
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
