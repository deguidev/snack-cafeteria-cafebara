<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';

interface Restaurante {
  id: string;
  nombre: string;
  direccion: string | null;
  telefono: string | null;
  email: string | null;
  ruc: string | null;
  logo_url: string | null;
  moneda: string;
  simbolo_moneda: string;
  igv_porcentaje: number;
  incluye_igv: boolean;
  horario_apertura: string | null;
  horario_cierre: string | null;
  dias_operacion: string | null;
  facebook_url: string | null;
  instagram_url: string | null;
  whatsapp: string | null;
  activo: boolean;
}

// Estado
const restaurantes = ref<Restaurante[]>([]);
const loading = ref(true);
const showModal = ref(false);
const modalMode = ref<'crear' | 'editar'>('crear');
const restauranteEditando = ref<Restaurante | null>(null);
const guardando = ref(false);
const mensaje = ref<{ tipo: 'success' | 'error'; texto: string } | null>(null);
const busqueda = ref('');

// Formulario
const form = ref({
  nombre: '',
  direccion: '',
  telefono: '',
  email: '',
  ruc: '',
  logo_url: '',
  moneda: 'PEN',
  simbolo_moneda: 'S/',
  igv_porcentaje: 18,
  incluye_igv: true,
  horario_apertura: '08:00',
  horario_cierre: '22:00',
  dias_operacion: 'Lun-Dom',
  facebook_url: '',
  instagram_url: '',
  whatsapp: '',
  activo: true
});

// Computed
const restaurantesFiltrados = computed(() => {
  if (!busqueda.value) return restaurantes.value;
  const term = busqueda.value.toLowerCase();
  return restaurantes.value.filter(r => 
    r.nombre.toLowerCase().includes(term) ||
    r.direccion?.toLowerCase().includes(term)
  );
});

// Cargar restaurantes
const fetchRestaurantes = async () => {
  try {
    loading.value = true;
    const { data, error } = await supabase
      .from('restaurantes')
      .select('*')
      .order('nombre');

    if (error) throw error;
    restaurantes.value = data || [];
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
  restauranteEditando.value = null;
  form.value = {
    nombre: '',
    direccion: '',
    telefono: '',
    email: '',
    ruc: '',
    logo_url: '',
    moneda: 'PEN',
    simbolo_moneda: 'S/',
    igv_porcentaje: 18,
    incluye_igv: true,
    horario_apertura: '08:00',
    horario_cierre: '22:00',
    dias_operacion: 'Lun-Dom',
    facebook_url: '',
    instagram_url: '',
    whatsapp: '',
    activo: true
  };
  showModal.value = true;
};

// Abrir modal para editar
const abrirEditar = (restaurante: Restaurante) => {
  modalMode.value = 'editar';
  restauranteEditando.value = restaurante;
  form.value = {
    nombre: restaurante.nombre || '',
    direccion: restaurante.direccion || '',
    telefono: restaurante.telefono || '',
    email: restaurante.email || '',
    ruc: restaurante.ruc || '',
    logo_url: restaurante.logo_url || '',
    moneda: restaurante.moneda || 'PEN',
    simbolo_moneda: restaurante.simbolo_moneda || 'S/',
    igv_porcentaje: restaurante.igv_porcentaje || 18,
    incluye_igv: restaurante.incluye_igv ?? true,
    horario_apertura: restaurante.horario_apertura || '08:00',
    horario_cierre: restaurante.horario_cierre || '22:00',
    dias_operacion: restaurante.dias_operacion || 'Lun-Dom',
    facebook_url: restaurante.facebook_url || '',
    instagram_url: restaurante.instagram_url || '',
    whatsapp: restaurante.whatsapp || '',
    activo: restaurante.activo ?? true
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
      direccion: form.value.direccion || null,
      telefono: form.value.telefono || null,
      email: form.value.email || null,
      ruc: form.value.ruc || null,
      logo_url: form.value.logo_url || null,
      moneda: form.value.moneda,
      simbolo_moneda: form.value.simbolo_moneda,
      igv_porcentaje: form.value.igv_porcentaje,
      incluye_igv: form.value.incluye_igv,
      horario_apertura: form.value.horario_apertura || null,
      horario_cierre: form.value.horario_cierre || null,
      dias_operacion: form.value.dias_operacion || null,
      facebook_url: form.value.facebook_url || null,
      instagram_url: form.value.instagram_url || null,
      whatsapp: form.value.whatsapp || null,
      activo: form.value.activo
    };

    if (modalMode.value === 'crear') {
      const { error } = await supabase.from('restaurantes').insert([datos]);
      if (error) throw error;
      mostrarMensaje('success', 'Restaurante creado');
    } else {
      const { error } = await supabase.from('restaurantes').update(datos).eq('id', restauranteEditando.value?.id);
      if (error) throw error;
      mostrarMensaje('success', 'Restaurante actualizado');
    }

    showModal.value = false;
    await fetchRestaurantes();
  } catch (err: any) {
    console.error('Error:', err);
    mostrarMensaje('error', err.message || 'Error al guardar');
  } finally {
    guardando.value = false;
  }
};

// Eliminar
const eliminar = async (restaurante: Restaurante) => {
  if (!confirm(`¿Eliminar "${restaurante.nombre}"?`)) return;

  try {
    const { error } = await supabase.from('restaurantes').delete().eq('id', restaurante.id);
    if (error) throw error;
    mostrarMensaje('success', 'Restaurante eliminado');
    await fetchRestaurantes();
  } catch (err: any) {
    mostrarMensaje('error', err.message || 'Error al eliminar');
  }
};

// Toggle activo
const toggleActivo = async (restaurante: Restaurante) => {
  try {
    const { error } = await supabase
      .from('restaurantes')
      .update({ activo: !restaurante.activo })
      .eq('id', restaurante.id);

    if (error) throw error;
    await fetchRestaurantes();
  } catch (err) {
    console.error('Error:', err);
  }
};

// Mostrar mensaje
const mostrarMensaje = (tipo: 'success' | 'error', texto: string) => {
  mensaje.value = { tipo, texto };
  setTimeout(() => mensaje.value = null, 3000);
};

onMounted(fetchRestaurantes);
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-purple-600 to-purple-700 px-4 py-4 shadow-lg sticky top-0 z-40">
      <div class="max-w-7xl mx-auto">
        <div class="flex items-center gap-3">
          <a href="/configuracion" class="flex items-center justify-center w-10 h-10 rounded-xl bg-white/20 text-white hover:bg-white/30 transition-colors">
            <Icon icon="mdi:arrow-left" class="w-5 h-5" />
          </a>
          <div class="flex-1">
            <h1 class="text-xl font-bold text-white">Restaurantes</h1>
            <p class="text-purple-100 text-sm">{{ restaurantes.length }} registros</p>
          </div>
          <button
            @click="abrirCrear"
            class="flex items-center gap-2 bg-white text-purple-600 px-4 py-2 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all active:scale-95"
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
      <div class="max-w-7xl mx-auto">
        <div class="relative">
          <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            v-model="busqueda"
            type="text"
            placeholder="Buscar restaurante..."
            class="w-full pl-10 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none transition-colors"
          />
        </div>
      </div>
    </div>

    <!-- Lista -->
    <div class="px-4 py-4 max-w-7xl mx-auto">
      <!-- Loading -->
      <div v-if="loading" class="flex justify-center py-12">
        <div class="w-10 h-10 border-4 border-purple-200 border-t-purple-600 rounded-full animate-spin"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="restaurantesFiltrados.length === 0" class="text-center py-12">
        <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <Icon icon="mdi:store" class="w-10 h-10 text-gray-300" />
        </div>
        <p class="text-gray-500 font-medium">No hay restaurantes</p>
        <button @click="abrirCrear" class="mt-4 text-purple-600 font-semibold">+ Crear restaurante</button>
      </div>

      <!-- Grid -->
      <div v-else class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <div
          v-for="rest in restaurantesFiltrados"
          :key="rest.id"
          class="bg-white rounded-2xl shadow-sm border-2 border-gray-100 overflow-hidden hover:shadow-md hover:border-purple-200 transition-all"
        >
          <div class="p-4">
            <!-- Logo y nombre -->
            <div class="flex items-center gap-3 mb-3">
              <div class="w-14 h-14 rounded-xl bg-purple-100 flex items-center justify-center overflow-hidden shrink-0">
                <img v-if="rest.logo_url" :src="rest.logo_url" alt="" class="w-full h-full object-cover" />
                <Icon v-else icon="mdi:store" class="w-7 h-7 text-purple-400" />
              </div>
              <div class="flex-1 min-w-0">
                <h3 class="font-bold text-gray-900 truncate">{{ rest.nombre }}</h3>
                <p v-if="rest.direccion" class="text-xs text-gray-500 truncate">{{ rest.direccion }}</p>
              </div>
              <button
                @click="toggleActivo(rest)"
                :class="[
                  'w-12 h-7 rounded-full transition-colors relative shrink-0',
                  rest.activo ? 'bg-green-500' : 'bg-gray-300'
                ]"
              >
                <span
                  :class="[
                    'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                    rest.activo ? 'left-[22px]' : 'left-0.5'
                  ]"
                ></span>
              </button>
            </div>

            <!-- Info -->
            <div class="space-y-1 text-xs text-gray-500">
              <p v-if="rest.telefono" class="flex items-center gap-1">
                <Icon icon="mdi:phone" class="w-3 h-3" /> {{ rest.telefono }}
              </p>
              <p v-if="rest.email" class="flex items-center gap-1 truncate">
                <Icon icon="mdi:email" class="w-3 h-3" /> {{ rest.email }}
              </p>
              <p v-if="rest.ruc" class="flex items-center gap-1">
                <Icon icon="mdi:card-account-details" class="w-3 h-3" /> RUC: {{ rest.ruc }}
              </p>
            </div>

            <!-- Horario -->
            <div class="mt-3 flex items-center gap-2 text-xs">
              <span class="bg-purple-100 text-purple-700 px-2 py-1 rounded-full font-semibold">
                {{ rest.horario_apertura || '08:00' }} - {{ rest.horario_cierre || '22:00' }}
              </span>
              <span class="text-gray-400">{{ rest.dias_operacion || 'Lun-Dom' }}</span>
            </div>
          </div>

          <!-- Acciones -->
          <div class="px-4 py-3 bg-gray-50 flex items-center justify-end gap-2 border-t">
            <button
              @click="abrirEditar(rest)"
              class="flex-1 p-2 rounded-lg bg-purple-100 text-purple-600 hover:bg-purple-200 transition-colors flex items-center justify-center gap-1"
            >
              <Icon icon="mdi:pencil" class="w-4 h-4" />
              <span class="text-xs font-semibold">Editar</span>
            </button>
            <button
              @click="eliminar(rest)"
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
              {{ modalMode === 'crear' ? 'Nuevo Restaurante' : 'Editar Restaurante' }}
            </h2>
            <button @click="showModal = false" class="p-2 rounded-full hover:bg-gray-200 transition-colors">
              <Icon icon="mdi:close" class="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <div class="p-4 space-y-4 overflow-y-auto max-h-[60vh]">
            <!-- Nombre -->
            <div>
              <label class="text-sm font-semibold text-gray-700 mb-1">Nombre *</label>
              <input
                v-model="form.nombre"
                type="text"
                placeholder="Nombre del restaurante"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
              />
            </div>

            <!-- Dirección -->
            <div>
              <label class="text-sm font-semibold text-gray-700 mb-1">Dirección</label>
              <textarea
                v-model="form.direccion"
                rows="2"
                placeholder="Dirección completa..."
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none resize-none"
              ></textarea>
            </div>

            <!-- Teléfono y Email -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-sm font-semibold text-gray-700 mb-1">Teléfono</label>
                <input
                  v-model="form.telefono"
                  type="tel"
                  placeholder="999-888-777"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="text-sm font-semibold text-gray-700 mb-1">Email</label>
                <input
                  v-model="form.email"
                  type="email"
                  placeholder="correo@ejemplo.com"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
                />
              </div>
            </div>

            <!-- RUC -->
            <div>
              <label class="text-sm font-semibold text-gray-700 mb-1">RUC</label>
              <input
                v-model="form.ruc"
                type="text"
                placeholder="20123456789"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
              />
            </div>

            <!-- Logo URL -->
            <div>
              <label class="text-sm font-semibold text-gray-700 mb-1">URL del logo</label>
              <input
                v-model="form.logo_url"
                type="url"
                placeholder="https://..."
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
              />
            </div>

            <!-- Moneda y símbolo -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-sm font-semibold text-gray-700 mb-1">Moneda</label>
                <select
                  v-model="form.moneda"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
                >
                  <option value="PEN">PEN - Sol</option>
                  <option value="USD">USD - Dólar</option>
                </select>
              </div>
              <div>
                <label class="text-sm font-semibold text-gray-700 mb-1">Símbolo</label>
                <input
                  v-model="form.simbolo_moneda"
                  type="text"
                  placeholder="S/"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
                />
              </div>
            </div>

            <!-- IGV -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-sm font-semibold text-gray-700 mb-1">IGV (%)</label>
                <input
                  v-model.number="form.igv_porcentaje"
                  type="number"
                  step="0.01"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
                />
              </div>
              <div class="flex items-center">
                <div class="flex items-center justify-between p-3 bg-gray-50 rounded-xl w-full">
                  <span class="text-sm font-medium text-gray-700">Incluye IGV</span>
                  <button
                    @click="form.incluye_igv = !form.incluye_igv"
                    :class="[
                      'w-12 h-7 rounded-full transition-colors relative',
                      form.incluye_igv ? 'bg-green-500' : 'bg-gray-300'
                    ]"
                  >
                    <span
                      :class="[
                        'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                        form.incluye_igv ? 'left-[22px]' : 'left-0.5'
                      ]"
                    ></span>
                  </button>
                </div>
              </div>
            </div>

            <!-- Horarios -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="text-sm font-semibold text-gray-700 mb-1">Apertura</label>
                <input
                  v-model="form.horario_apertura"
                  type="time"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="text-sm font-semibold text-gray-700 mb-1">Cierre</label>
                <input
                  v-model="form.horario_cierre"
                  type="time"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
                />
              </div>
            </div>

            <!-- Días -->
            <div>
              <label class="text-sm font-semibold text-gray-700 mb-1">Días de operación</label>
              <input
                v-model="form.dias_operacion"
                type="text"
                placeholder="Lun-Dom"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
              />
            </div>

            <!-- Redes sociales -->
            <div>
              <label class="text-sm font-semibold text-gray-700 mb-1">WhatsApp</label>
              <input
                v-model="form.whatsapp"
                type="tel"
                placeholder="+51 999 888 777"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-purple-500 focus:outline-none"
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
              class="flex-1 py-3 rounded-xl bg-purple-600 text-white font-semibold hover:bg-purple-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
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
