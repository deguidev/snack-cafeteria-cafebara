<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';

interface Categoria {
  id: string;
  nombre: string;
  slug: string;
}

interface Subcategoria {
  id: string;
  categoria_id: string;
  nombre: string;
}

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria_id: string;
  subcategoria_id: string | null;
  imagen_url: string | null;
  disponible: boolean;
  destacado: boolean;
  orden: number;
  categorias?: Categoria;
  subcategorias?: Subcategoria;
}

// Estado
const productos = ref<Producto[]>([]);
const categorias = ref<Categoria[]>([]);
const subcategorias = ref<Subcategoria[]>([]);
const loading = ref(true);
const showModal = ref(false);
const modalMode = ref<'crear' | 'editar'>('crear');
const productoEditando = ref<Producto | null>(null);
const guardando = ref(false);
const mensaje = ref<{ tipo: 'success' | 'error'; texto: string } | null>(null);
const busqueda = ref('');
const filtroCategoria = ref<string>('');

// Formulario
const form = ref({
  nombre: '',
  descripcion: '',
  precio: 0,
  categoria_id: '',
  subcategoria_id: '',
  imagen_url: '',
  disponible: true,
  destacado: false,
  orden: 0
});

// Computed
const productosFiltrados = computed(() => {
  let resultado = productos.value;
  
  if (filtroCategoria.value) {
    resultado = resultado.filter(p => p.categoria_id === filtroCategoria.value);
  }
  
  if (busqueda.value) {
    const term = busqueda.value.toLowerCase();
    resultado = resultado.filter(p => 
      p.nombre.toLowerCase().includes(term) || 
      p.descripcion?.toLowerCase().includes(term)
    );
  }
  
  return resultado;
});

const subcategoriasFiltradas = computed(() => {
  if (!form.value.categoria_id) return [];
  return subcategorias.value.filter(s => s.categoria_id === form.value.categoria_id);
});

// Cargar datos
const fetchData = async () => {
  try {
    loading.value = true;
    
    const [catRes, subRes, prodRes] = await Promise.all([
      supabase.from('categorias').select('id, nombre, slug').eq('activo', true).order('orden'),
      supabase.from('subcategorias').select('id, categoria_id, nombre').eq('activo', true).order('orden'),
      supabase.from('productos').select('*, categorias(id, nombre), subcategorias(id, nombre)').order('orden')
    ]);

    categorias.value = catRes.data || [];
    subcategorias.value = subRes.data || [];
    productos.value = prodRes.data || [];
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
  productoEditando.value = null;
  form.value = {
    nombre: '',
    descripcion: '',
    precio: 0,
    categoria_id: filtroCategoria.value || (categorias.value[0]?.id || ''),
    subcategoria_id: '',
    imagen_url: '',
    disponible: true,
    destacado: false,
    orden: productos.value.length + 1
  };
  showModal.value = true;
};

// Abrir modal para editar
const abrirEditar = (producto: Producto) => {
  modalMode.value = 'editar';
  productoEditando.value = producto;
  form.value = {
    nombre: producto.nombre,
    descripcion: producto.descripcion || '',
    precio: producto.precio,
    categoria_id: producto.categoria_id,
    subcategoria_id: producto.subcategoria_id || '',
    imagen_url: producto.imagen_url || '',
    disponible: producto.disponible,
    destacado: producto.destacado,
    orden: producto.orden
  };
  showModal.value = true;
};

// Guardar
const guardar = async () => {
  if (!form.value.nombre.trim() || !form.value.categoria_id || form.value.precio < 0) {
    mostrarMensaje('error', 'Nombre, categoría y precio son requeridos');
    return;
  }

  try {
    guardando.value = true;

    const datos = {
      nombre: form.value.nombre,
      descripcion: form.value.descripcion || null,
      precio: form.value.precio,
      categoria_id: form.value.categoria_id,
      subcategoria_id: form.value.subcategoria_id || null,
      imagen_url: form.value.imagen_url || null,
      disponible: form.value.disponible,
      destacado: form.value.destacado,
      orden: form.value.orden
    };

    if (modalMode.value === 'crear') {
      const { error } = await supabase.from('productos').insert([datos]);
      if (error) throw error;
      mostrarMensaje('success', 'Producto creado');
    } else {
      const { error } = await supabase.from('productos').update(datos).eq('id', productoEditando.value?.id);
      if (error) throw error;
      mostrarMensaje('success', 'Producto actualizado');
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
const eliminar = async (producto: Producto) => {
  if (!confirm(`¿Eliminar "${producto.nombre}"?`)) return;

  try {
    const { error } = await supabase.from('productos').delete().eq('id', producto.id);
    if (error) throw error;
    mostrarMensaje('success', 'Producto eliminado');
    await fetchData();
  } catch (err: any) {
    mostrarMensaje('error', err.message || 'Error al eliminar');
  }
};

// Toggle disponible
const toggleDisponible = async (producto: Producto) => {
  try {
    const { error } = await supabase
      .from('productos')
      .update({ disponible: !producto.disponible })
      .eq('id', producto.id);

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

onMounted(fetchData);
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-amber-600 to-amber-700 px-4 py-4 shadow-lg sticky top-0 z-40">
      <div class="max-w-7xl mx-auto">
        <div class="flex items-center gap-3">
          <a href="/configuracion" class="flex items-center justify-center w-10 h-10 rounded-xl bg-white/20 text-white hover:bg-white/30 transition-colors">
            <Icon icon="mdi:arrow-left" class="w-5 h-5" />
          </a>
          <div class="flex-1">
            <h1 class="text-xl font-bold text-white">Productos</h1>
            <p class="text-amber-100 text-sm">{{ productos.length }} registros</p>
          </div>
          <button
            @click="abrirCrear"
            class="flex items-center gap-2 bg-white text-amber-600 px-4 py-2 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all active:scale-95"
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
        <!-- Filtro por categoría -->
        <div class="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
          <button
            @click="filtroCategoria = ''"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors',
              !filtroCategoria ? 'bg-amber-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            Todos
          </button>
          <button
            v-for="cat in categorias"
            :key="cat.id"
            @click="filtroCategoria = cat.id"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors',
              filtroCategoria === cat.id ? 'bg-amber-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            {{ cat.nombre }}
          </button>
        </div>
        
        <!-- Buscador -->
        <div class="relative">
          <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            v-model="busqueda"
            type="text"
            placeholder="Buscar producto..."
            class="w-full pl-10 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-amber-500 focus:outline-none transition-colors"
          />
        </div>
      </div>
    </div>

    <!-- Lista -->
    <div class="px-4 py-4 max-w-7xl mx-auto">
      <!-- Loading -->
      <div v-if="loading" class="flex justify-center py-12">
        <div class="w-10 h-10 border-4 border-amber-200 border-t-amber-600 rounded-full animate-spin"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="productosFiltrados.length === 0" class="text-center py-12">
        <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <Icon icon="mdi:food-off" class="w-10 h-10 text-gray-300" />
        </div>
        <p class="text-gray-500 font-medium">No hay productos</p>
        <button @click="abrirCrear" class="mt-4 text-amber-600 font-semibold">+ Crear producto</button>
      </div>

      <!-- Grid -->
      <div v-else class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <div
          v-for="producto in productosFiltrados"
          :key="producto.id"
          class="bg-white rounded-2xl shadow-sm border-2 border-gray-100 overflow-hidden hover:shadow-md hover:border-amber-200 transition-all"
        >
          <!-- Imagen -->
          <div class="h-32 bg-gradient-to-br from-amber-50 to-orange-50 flex items-center justify-center relative">
            <img
              v-if="producto.imagen_url"
              :src="producto.imagen_url"
              :alt="producto.nombre"
              class="w-full h-full object-cover"
            />
            <Icon v-else icon="mdi:food" class="w-12 h-12 text-amber-300" />
            
            <!-- Badge destacado -->
            <span v-if="producto.destacado" class="absolute top-2 right-2 bg-amber-500 text-white text-xs font-bold px-2 py-1 rounded-full">
              ⭐ Destacado
            </span>
            
            <!-- Badge no disponible -->
            <div v-if="!producto.disponible" class="absolute inset-0 bg-black/50 flex items-center justify-center">
              <span class="bg-red-500 text-white text-xs font-bold px-3 py-1 rounded-full">No disponible</span>
            </div>
          </div>

          <!-- Info -->
          <div class="p-4">
            <div class="flex items-start justify-between gap-2 mb-2">
              <div class="flex-1 min-w-0">
                <h3 class="font-bold text-gray-900 truncate">{{ producto.nombre }}</h3>
                <p class="text-xs text-amber-600 font-medium">{{ producto.categorias?.nombre }}</p>
              </div>
              <span class="text-lg font-bold text-green-600 shrink-0">S/ {{ producto.precio.toFixed(2) }}</span>
            </div>
            
            <p v-if="producto.descripcion" class="text-xs text-gray-500 line-clamp-2 mb-3">{{ producto.descripcion }}</p>

            <!-- Acciones -->
            <div class="flex items-center justify-between pt-3 border-t">
              <button
                @click="toggleDisponible(producto)"
                :class="[
                  'text-xs font-semibold px-3 py-1.5 rounded-lg transition-colors',
                  producto.disponible ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                ]"
              >
                {{ producto.disponible ? 'Disponible' : 'No disponible' }}
              </button>
              <div class="flex gap-2">
                <button
                  @click="abrirEditar(producto)"
                  class="p-2 rounded-lg bg-amber-100 text-amber-600 hover:bg-amber-200 transition-colors"
                >
                  <Icon icon="mdi:pencil" class="w-4 h-4" />
                </button>
                <button
                  @click="eliminar(producto)"
                  class="p-2 rounded-lg bg-red-100 text-red-600 hover:bg-red-200 transition-colors"
                >
                  <Icon icon="mdi:delete" class="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <Transition name="modal">
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-end sm:items-center justify-center">
        <div class="absolute inset-0 bg-black/50" @click="showModal = false"></div>
        
        <div class="relative w-full sm:max-w-lg bg-white rounded-t-3xl sm:rounded-2xl shadow-2xl max-h-[90vh] overflow-hidden">
          <div class="flex items-center justify-between p-4 border-b bg-gray-50">
            <h2 class="text-lg font-bold text-gray-900">
              {{ modalMode === 'crear' ? 'Nuevo Producto' : 'Editar Producto' }}
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
                placeholder="Ej: Lomo Saltado"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-amber-500 focus:outline-none"
              />
            </div>

            <!-- Descripción -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Descripción</label>
              <textarea
                v-model="form.descripcion"
                rows="2"
                placeholder="Descripción del producto..."
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-amber-500 focus:outline-none resize-none"
              ></textarea>
            </div>

            <!-- Precio -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Precio *</label>
              <div class="relative">
                <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-semibold">S/</span>
                <input
                  v-model.number="form.precio"
                  type="number"
                  step="0.50"
                  min="0"
                  placeholder="0.00"
                  class="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-amber-500 focus:outline-none"
                />
              </div>
            </div>

            <!-- Categoría y Subcategoría -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-1">Categoría *</label>
                <select
                  v-model="form.categoria_id"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-amber-500 focus:outline-none"
                >
                  <option value="">Seleccionar...</option>
                  <option v-for="cat in categorias" :key="cat.id" :value="cat.id">
                    {{ cat.nombre }}
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-1">Subcategoría</label>
                <select
                  v-model="form.subcategoria_id"
                  :disabled="!form.categoria_id"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-amber-500 focus:outline-none disabled:bg-gray-100"
                >
                  <option value="">Ninguna</option>
                  <option v-for="sub in subcategoriasFiltradas" :key="sub.id" :value="sub.id">
                    {{ sub.nombre }}
                  </option>
                </select>
              </div>
            </div>

            <!-- URL Imagen -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">URL de imagen</label>
              <input
                v-model="form.imagen_url"
                type="url"
                placeholder="https://..."
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-amber-500 focus:outline-none"
              />
            </div>

            <!-- Switches -->
            <div class="grid grid-cols-2 gap-3">
              <div class="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <span class="text-sm font-medium text-gray-700">Disponible</span>
                <button
                  @click="form.disponible = !form.disponible"
                  :class="[
                    'w-12 h-7 rounded-full transition-colors relative',
                    form.disponible ? 'bg-green-500' : 'bg-gray-300'
                  ]"
                >
                  <span
                    :class="[
                      'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                      form.disponible ? 'left-[22px]' : 'left-0.5'
                    ]"
                  ></span>
                </button>
              </div>
              <div class="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <span class="text-sm font-medium text-gray-700">Destacado</span>
                <button
                  @click="form.destacado = !form.destacado"
                  :class="[
                    'w-12 h-7 rounded-full transition-colors relative',
                    form.destacado ? 'bg-amber-500' : 'bg-gray-300'
                  ]"
                >
                  <span
                    :class="[
                      'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                      form.destacado ? 'left-[22px]' : 'left-0.5'
                    ]"
                  ></span>
                </button>
              </div>
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
              class="flex-1 py-3 rounded-xl bg-amber-600 text-white font-semibold hover:bg-amber-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
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
