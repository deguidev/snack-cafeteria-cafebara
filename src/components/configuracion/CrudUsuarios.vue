<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';

interface Restaurante {
  id: string;
  nombre: string;
}

interface Usuario {
  id: string;
  auth_id: string | null;
  email: string;
  nombre: string;
  apellido: string | null;
  telefono: string | null;
  avatar_url: string | null;
  rol: 'super_admin' | 'admin' | 'cajero' | 'mesero' | 'cocina';
  restaurante_id: string | null;
  activo: boolean;
  ultimo_acceso: string | null;
  restaurantes?: Restaurante;
}

// Estado
const usuarios = ref<Usuario[]>([]);
const restaurantes = ref<Restaurante[]>([]);
const loading = ref(true);
const showModal = ref(false);
const modalMode = ref<'crear' | 'editar'>('crear');
const usuarioEditando = ref<Usuario | null>(null);
const guardando = ref(false);
const mensaje = ref<{ tipo: 'success' | 'error'; texto: string } | null>(null);
const busqueda = ref('');
const filtroRol = ref<string>('');

// Formulario
const form = ref({
  email: '',
  nombre: '',
  apellido: '',
  telefono: '',
  avatar_url: '',
  rol: 'mesero' as Usuario['rol'],
  restaurante_id: '',
  activo: true
});

// Roles disponibles
const roles = [
  { value: 'super_admin', label: 'Super Admin', icon: 'mdi:shield-crown', color: 'purple', desc: 'Acceso total al sistema' },
  { value: 'admin', label: 'Admin', icon: 'mdi:shield-account', color: 'blue', desc: 'Administra un restaurante' },
  { value: 'cajero', label: 'Cajero', icon: 'mdi:cash-register', color: 'green', desc: 'Cobra y ve reportes' },
  { value: 'mesero', label: 'Mesero', icon: 'mdi:account-tie', color: 'amber', desc: 'Toma pedidos' },
  { value: 'cocina', label: 'Cocina', icon: 'mdi:chef-hat', color: 'orange', desc: 'Ve y actualiza pedidos' }
];

// Computed
const usuariosFiltrados = computed(() => {
  let resultado = usuarios.value;
  
  if (filtroRol.value) {
    resultado = resultado.filter(u => u.rol === filtroRol.value);
  }
  
  if (busqueda.value) {
    const term = busqueda.value.toLowerCase();
    resultado = resultado.filter(u => 
      u.nombre.toLowerCase().includes(term) ||
      u.email.toLowerCase().includes(term) ||
      u.apellido?.toLowerCase().includes(term)
    );
  }
  
  return resultado;
});

// Cargar datos
const fetchData = async () => {
  try {
    loading.value = true;
    
    const [restRes, userRes] = await Promise.all([
      supabase.from('restaurantes').select('id, nombre').eq('activo', true),
      supabase.from('usuarios').select('*, restaurantes(id, nombre)').order('nombre')
    ]);

    restaurantes.value = restRes.data || [];
    usuarios.value = userRes.data || [];
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
  usuarioEditando.value = null;
  form.value = {
    email: '',
    nombre: '',
    apellido: '',
    telefono: '',
    avatar_url: '',
    rol: 'mesero',
    restaurante_id: restaurantes.value[0]?.id || '',
    activo: true
  };
  showModal.value = true;
};

// Abrir modal para editar
const abrirEditar = (usuario: Usuario) => {
  modalMode.value = 'editar';
  usuarioEditando.value = usuario;
  form.value = {
    email: usuario.email,
    nombre: usuario.nombre,
    apellido: usuario.apellido || '',
    telefono: usuario.telefono || '',
    avatar_url: usuario.avatar_url || '',
    rol: usuario.rol,
    restaurante_id: usuario.restaurante_id || '',
    activo: usuario.activo
  };
  showModal.value = true;
};

// Guardar
const guardar = async () => {
  if (!form.value.email.trim() || !form.value.nombre.trim()) {
    mostrarMensaje('error', 'Email y nombre son requeridos');
    return;
  }

  try {
    guardando.value = true;

    const datos = {
      email: form.value.email,
      nombre: form.value.nombre,
      apellido: form.value.apellido || null,
      telefono: form.value.telefono || null,
      avatar_url: form.value.avatar_url || null,
      rol: form.value.rol,
      restaurante_id: form.value.restaurante_id || null,
      activo: form.value.activo
    };

    if (modalMode.value === 'crear') {
      const { error } = await supabase.from('usuarios').insert([datos]);
      if (error) throw error;
      mostrarMensaje('success', 'Usuario creado');
    } else {
      const { error } = await supabase.from('usuarios').update(datos).eq('id', usuarioEditando.value?.id);
      if (error) throw error;
      mostrarMensaje('success', 'Usuario actualizado');
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
const eliminar = async (usuario: Usuario) => {
  if (!confirm(`¿Eliminar a "${usuario.nombre}"?`)) return;

  try {
    const { error } = await supabase.from('usuarios').delete().eq('id', usuario.id);
    if (error) throw error;
    mostrarMensaje('success', 'Usuario eliminado');
    await fetchData();
  } catch (err: any) {
    mostrarMensaje('error', err.message || 'Error al eliminar');
  }
};

// Toggle activo
const toggleActivo = async (usuario: Usuario) => {
  try {
    const { error } = await supabase
      .from('usuarios')
      .update({ activo: !usuario.activo })
      .eq('id', usuario.id);

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

// Obtener info del rol
const getRolInfo = (rol: string) => {
  return roles.find(r => r.value === rol) || roles[3];
};

const getRolColor = (rol: string) => {
  const colores: Record<string, string> = {
    super_admin: 'bg-purple-100 text-purple-700',
    admin: 'bg-blue-100 text-blue-700',
    cajero: 'bg-green-100 text-green-700',
    mesero: 'bg-amber-100 text-amber-700',
    cocina: 'bg-orange-100 text-orange-700'
  };
  return colores[rol] || colores.mesero;
};

onMounted(fetchData);
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Header -->
    <header class="bg-gradient-to-r from-red-600 to-red-700 px-4 py-4 shadow-lg sticky top-0 z-40">
      <div class="max-w-7xl mx-auto">
        <div class="flex items-center gap-3">
          <a href="/configuracion" class="flex items-center justify-center w-10 h-10 rounded-xl bg-white/20 text-white hover:bg-white/30 transition-colors">
            <Icon icon="mdi:arrow-left" class="w-5 h-5" />
          </a>
          <div class="flex-1">
            <h1 class="text-xl font-bold text-white">Usuarios</h1>
            <p class="text-red-100 text-sm">{{ usuarios.length }} registros</p>
          </div>
          <button
            @click="abrirCrear"
            class="flex items-center gap-2 bg-white text-red-600 px-4 py-2 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all active:scale-95"
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
        <!-- Filtro por rol -->
        <div class="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
          <button
            @click="filtroRol = ''"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors',
              !filtroRol ? 'bg-red-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            Todos
          </button>
          <button
            v-for="rol in roles"
            :key="rol.value"
            @click="filtroRol = rol.value"
            :class="[
              'px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors flex items-center gap-2',
              filtroRol === rol.value ? 'bg-red-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            ]"
          >
            <Icon :icon="rol.icon" class="w-4 h-4" />
            {{ rol.label }}
          </button>
        </div>
        
        <!-- Buscador -->
        <div class="relative">
          <Icon icon="mdi:magnify" class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            v-model="busqueda"
            type="text"
            placeholder="Buscar usuario..."
            class="w-full pl-10 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-red-500 focus:outline-none transition-colors"
          />
        </div>
      </div>
    </div>

    <!-- Lista -->
    <div class="px-4 py-4 max-w-7xl mx-auto">
      <!-- Loading -->
      <div v-if="loading" class="flex justify-center py-12">
        <div class="w-10 h-10 border-4 border-red-200 border-t-red-600 rounded-full animate-spin"></div>
      </div>

      <!-- Empty -->
      <div v-else-if="usuariosFiltrados.length === 0" class="text-center py-12">
        <div class="w-20 h-20 mx-auto mb-4 rounded-full bg-gray-100 flex items-center justify-center">
          <Icon icon="mdi:account-group" class="w-10 h-10 text-gray-300" />
        </div>
        <p class="text-gray-500 font-medium">No hay usuarios</p>
        <button @click="abrirCrear" class="mt-4 text-red-600 font-semibold">+ Crear usuario</button>
      </div>

      <!-- Grid -->
      <div v-else class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        <div
          v-for="usuario in usuariosFiltrados"
          :key="usuario.id"
          class="bg-white rounded-2xl shadow-sm border-2 border-gray-100 overflow-hidden hover:shadow-md hover:border-red-200 transition-all"
        >
          <div class="p-4">
            <!-- Avatar y nombre -->
            <div class="flex items-center gap-3 mb-3">
              <div class="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden shrink-0">
                <img v-if="usuario.avatar_url" :src="usuario.avatar_url" alt="" class="w-full h-full object-cover" />
                <Icon v-else icon="mdi:account" class="w-6 h-6 text-gray-400" />
              </div>
              <div class="flex-1 min-w-0">
                <h3 class="font-bold text-gray-900 truncate">{{ usuario.nombre }} {{ usuario.apellido }}</h3>
                <p class="text-xs text-gray-500 truncate">{{ usuario.email }}</p>
              </div>
              <button
                @click="toggleActivo(usuario)"
                :class="[
                  'w-12 h-7 rounded-full transition-colors relative shrink-0',
                  usuario.activo ? 'bg-green-500' : 'bg-gray-300'
                ]"
              >
                <span
                  :class="[
                    'absolute top-0.5 w-6 h-6 rounded-full bg-white shadow transition-transform',
                    usuario.activo ? 'left-[22px]' : 'left-0.5'
                  ]"
                ></span>
              </button>
            </div>

            <!-- Rol -->
            <div class="flex items-center gap-2 mb-2">
              <span :class="['text-xs font-semibold px-2 py-1 rounded-full flex items-center gap-1', getRolColor(usuario.rol)]">
                <Icon :icon="getRolInfo(usuario.rol).icon" class="w-3 h-3" />
                {{ getRolInfo(usuario.rol).label }}
              </span>
              <span v-if="usuario.restaurantes" class="text-xs text-gray-500 truncate">
                {{ usuario.restaurantes.nombre }}
              </span>
            </div>

            <!-- Teléfono -->
            <p v-if="usuario.telefono" class="text-xs text-gray-500 flex items-center gap-1">
              <Icon icon="mdi:phone" class="w-3 h-3" />
              {{ usuario.telefono }}
            </p>
          </div>

          <!-- Acciones -->
          <div class="px-4 py-3 bg-gray-50 flex items-center justify-end gap-2 border-t">
            <button
              @click="abrirEditar(usuario)"
              class="flex-1 p-2 rounded-lg bg-red-100 text-red-600 hover:bg-red-200 transition-colors flex items-center justify-center gap-1"
            >
              <Icon icon="mdi:pencil" class="w-4 h-4" />
              <span class="text-xs font-semibold">Editar</span>
            </button>
            <button
              @click="eliminar(usuario)"
              class="p-2 rounded-lg bg-gray-100 text-gray-600 hover:bg-gray-200 transition-colors"
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
              {{ modalMode === 'crear' ? 'Nuevo Usuario' : 'Editar Usuario' }}
            </h2>
            <button @click="showModal = false" class="p-2 rounded-full hover:bg-gray-200 transition-colors">
              <Icon icon="mdi:close" class="w-5 h-5 text-gray-500" />
            </button>
          </div>

          <div class="p-4 space-y-4 overflow-y-auto max-h-[60vh]">
            <!-- Email -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Email *</label>
              <input
                v-model="form.email"
                type="email"
                placeholder="correo@ejemplo.com"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-red-500 focus:outline-none"
              />
            </div>

            <!-- Nombre y Apellido -->
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-1">Nombre *</label>
                <input
                  v-model="form.nombre"
                  type="text"
                  placeholder="Juan"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-red-500 focus:outline-none"
                />
              </div>
              <div>
                <label class="block text-sm font-semibold text-gray-700 mb-1">Apellido</label>
                <input
                  v-model="form.apellido"
                  type="text"
                  placeholder="Pérez"
                  class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-red-500 focus:outline-none"
                />
              </div>
            </div>

            <!-- Teléfono -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Teléfono</label>
              <input
                v-model="form.telefono"
                type="tel"
                placeholder="999-888-777"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-red-500 focus:outline-none"
              />
            </div>

            <!-- Rol -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">Rol *</label>
              <div class="grid grid-cols-2 gap-2">
                <button
                  v-for="rol in roles"
                  :key="rol.value"
                  @click="form.rol = rol.value as any"
                  :class="[
                    'p-3 rounded-xl border-2 flex items-center gap-2 transition-all text-left',
                    form.rol === rol.value ? 'border-red-500 bg-red-50' : 'border-gray-200 hover:border-gray-300'
                  ]"
                >
                  <Icon :icon="rol.icon" :class="['w-5 h-5', form.rol === rol.value ? 'text-red-600' : 'text-gray-500']" />
                  <div>
                    <span class="text-sm font-semibold block" :class="form.rol === rol.value ? 'text-red-700' : 'text-gray-700'">{{ rol.label }}</span>
                    <span class="text-[10px] text-gray-500">{{ rol.desc }}</span>
                  </div>
                </button>
              </div>
            </div>

            <!-- Restaurante -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">Restaurante</label>
              <select
                v-model="form.restaurante_id"
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-red-500 focus:outline-none"
              >
                <option value="">Sin asignar</option>
                <option v-for="rest in restaurantes" :key="rest.id" :value="rest.id">
                  {{ rest.nombre }}
                </option>
              </select>
            </div>

            <!-- Avatar URL -->
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-1">URL de avatar</label>
              <input
                v-model="form.avatar_url"
                type="url"
                placeholder="https://..."
                class="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-red-500 focus:outline-none"
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
              class="flex-1 py-3 rounded-xl bg-red-600 text-white font-semibold hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
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
