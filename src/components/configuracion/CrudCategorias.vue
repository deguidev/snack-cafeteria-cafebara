<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';

interface Categoria {
  id: string;
  nombre: string;
  slug: string;
  icono: string;
  orden: number;
  activo: boolean;
  created_at: string;
  updated_at: string;
}

// Estado
const categorias = ref<Categoria[]>([]);
const loading = ref(true);
const showModal = ref(false);
const modalMode = ref<'crear' | 'editar'>('crear');
const categoriaEditando = ref<Categoria | null>(null);
const guardando = ref(false);
const mensaje = ref<{ tipo: 'success' | 'error'; texto: string } | null>(null);
const busqueda = ref('');

// Formulario
const form = ref({
  nombre: '',
  slug: '',
  icono: 'mdi:food',
  orden: 0,
  activo: true
});

// Iconos disponibles
const iconosDisponibles = [
  'mdi:food', 'mdi:coffee', 'mdi:cup', 'mdi:leaf', 'mdi:pizza',
  'mdi:hamburger', 'mdi:ice-cream', 'mdi:cake', 'mdi:beer',
  'mdi:fruit-watermelon', 'mdi:food-apple', 'mdi:bread-slice'
];

// Computed
const categoriasFiltradas = computed(() => {
  if (!busqueda.value) return categorias.value;
  const term = busqueda.value.toLowerCase();
  return categorias.value.filter(c => 
    c.nombre.toLowerCase().includes(term) || 
    c.slug.toLowerCase().includes(term)
  );
});

// Cargar categorías
const fetchCategorias = async () => {
  try {
    loading.value = true;
    const { data, error } = await supabase
      .from('categorias')
      .select('*')
      .order('orden');

    if (error) throw error;
    categorias.value = data || [];
  } catch (err) {
    console.error('Error:', err);
    mostrarMensaje('error', 'Error al cargar categorías');
  } finally {
    loading.value = false;
  }
};

// Generar slug
const generarSlug = () => {
  form.value.slug = form.value.nombre
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
};

// Abrir modal para crear
const abrirCrear = () => {
  modalMode.value = 'crear';
  categoriaEditando.value = null;
  form.value = {
    nombre: '',
    slug: '',
    icono: 'mdi:food',
    orden: categorias.value.length + 1,
    activo: true
  };
  showModal.value = true;
};

// Abrir modal para editar
const abrirEditar = (categoria: Categoria) => {
  modalMode.value = 'editar';
  categoriaEditando.value = categoria;
  form.value = {
    nombre: categoria.nombre,
    slug: categoria.slug,
    icono: categoria.icono,
    orden: categoria.orden,
    activo: categoria.activo
  };
  showModal.value = true;
};

// Guardar (crear o editar)
const guardar = async () => {
  if (!form.value.nombre.trim() || !form.value.slug.trim()) {
    mostrarMensaje('error', 'Nombre y slug son requeridos');
    return;
  }

  try {
    guardando.value = true;

    if (modalMode.value === 'crear') {
      const { error } = await supabase
        .from('categorias')
        .insert([{
          nombre: form.value.nombre,
          slug: form.value.slug,
          icono: form.value.icono,
          orden: form.value.orden,
          activo: form.value.activo
        }]);

      if (error) throw error;
      mostrarMensaje('success', 'Categoría creada correctamente');
    } else {
      const { error } = await supabase
        .from('categorias')
        .update({
          nombre: form.value.nombre,
          slug: form.value.slug,
          icono: form.value.icono,
          orden: form.value.orden,
          activo: form.value.activo
        })
        .eq('id', categoriaEditando.value?.id);

      if (error) throw error;
      mostrarMensaje('success', 'Categoría actualizada correctamente');
    }

    showModal.value = false;
    await fetchCategorias();
  } catch (err: any) {
    console.error('Error:', err);
    mostrarMensaje('error', err.message || 'Error al guardar');
  } finally {
    guardando.value = false;
  }
};

// Eliminar
const eliminar = async (categoria: Categoria) => {
  if (!confirm(`¿Eliminar la categoría "${categoria.nombre}"?`)) return;

  try {
    const { error } = await supabase
      .from('categorias')
      .delete()
      .eq('id', categoria.id);

    if (error) throw error;
    mostrarMensaje('success', 'Categoría eliminada');
    await fetchCategorias();
  } catch (err: any) {
    console.error('Error:', err);
    mostrarMensaje('error', err.message || 'Error al eliminar');
  }
};

// Toggle activo
const toggleActivo = async (categoria: Categoria) => {
  try {
    const { error } = await supabase
      .from('categorias')
      .update({ activo: !categoria.activo })
      .eq('id', categoria.id);

    if (error) throw error;
    await fetchCategorias();
  } catch (err) {
    console.error('Error:', err);
  }
};

// Mostrar mensaje
const mostrarMensaje = (tipo: 'success' | 'error', texto: string) => {
  mensaje.value = { tipo, texto };
  setTimeout(() => mensaje.value = null, 3000);
};

onMounted(fetchCategorias);
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-blue-600 to-blue-700 px-4 py-4 shadow-lg sticky top-0 z-40">
      <div class="max-w-7xl mx-auto">
        <div class="flex items-center gap-3">
          <a href="/configuracion" class="flex items-center justify-center w-10 h-10 rounded-xl bg-white/20 text-white hover:bg-white/30 transition-colors">
            <Icon icon="mdi:arrow-left" class="w-5 h-5" />
          </a>
          <div class="flex-1">
            <h1 class="text-xl font-bold text-white">Categorías</h1>
            <p class="text-blue-100 text-sm">{{ categorias.length }} registros</p>
          </div>
          <button
            @click="abrirCrear"
            class="flex items-center gap-2 bg-white text-blue-600 px-4 py-2 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all active:scale-95"
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

    <!-- Buscador -->
    <div class="px-4 py-4 bg-white border-b sticky top-[72px] z-30">
      <div class="max-w-7xl mx-auto">
        <div class="relative">
          <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            v-model="busqueda"
            type="text"
            placeholder="Buscar categoría..."
            class="w-full pl-10 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-blue-500 focus:outline-none transition-colors"
          />
        </div>
      </div>
    </div>

    <!-- Lista -->
    <div class="px-4 py-4 max-w-7xl mx-auto">
      <!-- Loading -->
      <div v-if="loading" class="flex justify-center py-12">
        <div class="w-10 h-10 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="categoriasFiltradas.length === 0" class="text-center py-12">
        <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <Icon icon="mdi:folder-open-outline" class="w-10 h-10 text-gray-300" />
        </div>
        <p class="text-gray-500 font-medium">No hay categorías</p>
        <button @click="abrirCrear" class="mt-4 text-blue-600 font-semibold">+ Crear primera categoría</button>
      </div>

      <!-- Grid de cards -->
      <div v-else class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <div
          v-for="categoria in categoriasFiltradas"
          :key="categoria.id"
          class="bg-white rounded-2xl shadow-sm border-2 border-gray-100 overflow-hidden hover:shadow-md hover:border-blue-200 transition-all"
        >
          <!-- Card Header -->
          <div class="p-4 flex items-center gap-3">
            <div class="w-12 h-12 rounded-xl bg-blue-100 flex items-center justify-center shrink-0">
              <Icon :icon="categoria.icono" class="w-6 h-6 text-blue-600" />
            </div>
            <div class="flex-1 min-w-0">
              <h3 class="font-bold text-gray-900 truncate">{{ categoria.nombre }}</h3>
              <p class="text-sm text-gray-500">{{ categoria.slug }}</p>
            </div>
            <button
              @click="toggleActivo(categoria)"
              :class="[
                'w-12 h-7 rounded-full transition-colors relative',
                categoria.activo ? 'bg-green-500' : 'bg-gray-300'
              ]"
            >
              <span
                :class="[
                  'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                  categoria.activo ? 'left-[22px]' : 'left-0.5'
                ]"
              ></span>
            </button>
          </div>

          <!-- Card Footer -->
          <div class="px-4 py-3 bg-gray-50 flex items-center justify-between border-t">
            <span class="text-xs text-gray-500">Orden: {{ categoria.orden }}</span>
            <div class="flex gap-2">
              <button
                @click="abrirEditar(categoria)"
                class="p-2 rounded-lg bg-blue-100 text-blue-600 hover:bg-blue-200 transition-colors"
              >
                <Icon icon="mdi:pencil" class="w-4 h-4" />
              </button>
              <button
                @click="eliminar(categoria)"
                class="p-2 rounded-lg bg-red-100 text-red-600 hover:bg-red-200 transition-colors"
              >
                <Icon icon="mdi:delete" class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <Transition name="modal">
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black/50" @click="showModal = false"></div>
        
        <!-- Modal Content -->
        <div class="relative w-full sm:max-w-md bg-white rounded-t-3xl sm:rounded-2xl shadow-2xl max-h-[90vh] overflow-hidden">
          <!-- Modal Header -->
          <div class="flex items-center justify-between p-4 border-b bg-gray-50">
            <h2 class="text-lg font-bold text-gray-900">
              {{ modalMode === 'crear' ? 'Nueva Categoría' : 'Editar Categoría' }}
            </h2>
            <button @click="showModal = false" class="p-2 rounded-full hover:bg-gray-200 transition-colors">
              <Icon icon="mdi:close" class="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <!-- Modal Body -->
          <div class="p-4 space-y-4 overflow-y-auto max-h-[60vh]">
            <!-- Nombre -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Nombre *</label>
              <input
                v-model="form.nombre"
                @input="generarSlug"
                type="text"
                placeholder="Ej: Comidas"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <!-- Slug -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Slug *</label>
              <input
                v-model="form.slug"
                type="text"
                placeholder="Ej: comidas"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-blue-500 focus:outline-none"
              />
            </div>

            <!-- Icono -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">Icono</label>
              <div class="grid grid-cols-6 gap-2">
                <button
                  v-for="icono in iconosDisponibles"
                  :key="icono"
                  @click="form.icono = icono"
                  :class="[
                    'p-3 rounded-xl border-2 transition-all',
                    form.icono === icono ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
                  ]"
                >
                  <Icon :icon="icono" class="w-6 h-6 mx-auto" :class="form.icono === icono ? 'text-blue-600' : 'text-gray-600'" />
                </button>
              </div>
            </div>

            <!-- Orden -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Orden</label>
              <input
                v-model.number="form.orden"
                type="number"
                min="0"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-blue-500 focus:outline-none"
              />
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

          <!-- Modal Footer -->
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
              class="flex-1 py-3 rounded-xl bg-blue-600 text-white font-semibold hover:bg-blue-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
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
/* Animación del mensaje */
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s ease;
}
.slide-down-enter-from,
.slide-down-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}

/* Animación del modal */
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
