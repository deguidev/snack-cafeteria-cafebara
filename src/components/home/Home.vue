<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';

interface Restaurante {
  id: string;
  nombre: string;
  direccion: string;
  telefono: string | null;
  logo_url: string | null;
  ruc: string | null;
  moneda: string;
  activo: boolean;
  horario_apertura: string | null;
  horario_cierre: string | null;
  dias_operacion: string | null;
}

interface User {
  id: string;
  email: string;
  role: 'super_admin' | 'admin' | 'user';
}

interface EstadisticasDia {
  ventasHoy: number;
  pedidosHoy: number;
  productosVendidos: number;
}

const restaurantes = ref<Restaurante[]>([]);
const restaurante = ref<Restaurante | null>(null);
const loading = ref(true);
const user = ref<User | null>(null);
const selectedRestaurantId = ref<string>('');
const showRestaurantModal = ref(false);

// Estadísticas del día
const estadisticas = ref<EstadisticasDia>({
  ventasHoy: 0,
  pedidosHoy: 0,
  productosVendidos: 0
});

// Simular autenticación - en producción usar auth real de Supabase
const currentUser = ref<User>({
  id: '1',
  email: 'admin@cafeteria.com',
  role: 'super_admin' // Cambiar según el usuario real
});

const isSuperAdmin = computed(() => currentUser.value?.role === 'super_admin');

// Formatear horario para mostrar
const formatearHorario = (horario: string | null) => {
  if (!horario) return '';
  // Convertir de formato HH:MM:SS a HH:MM AM/PM
  const [hours, minutes] = horario.split(':');
  const h = parseInt(hours);
  const ampm = h >= 12 ? 'PM' : 'AM';
  const h12 = h % 12 || 12;
  return `${h12}:${minutes} ${ampm}`;
};

const horarioAtencion = computed(() => {
  if (!restaurante.value?.horario_apertura || !restaurante.value?.horario_cierre) return null;
  const apertura = formatearHorario(restaurante.value.horario_apertura);
  const cierre = formatearHorario(restaurante.value.horario_cierre);
  const dias = restaurante.value.dias_operacion || 'Lun-Dom';
  return `${dias} ${apertura} - ${cierre}`;
});

const fetchRestaurantes = async () => {
  try {
    loading.value = true;
    // Cargar el primer restaurante disponible
    const { data, error } = await supabase
      .from('restaurantes')
      .select('*')
      .order('created_at', { ascending: true })
      .limit(1);

    if (error) {
      console.error('Error en consulta:', error);
      throw error;
    }
    
    console.log('Datos restaurante:', data);
    
    if (data && data.length > 0) {
      restaurante.value = data[0];
      restaurantes.value = data;
      selectedRestaurantId.value = data[0].id;
    }
  } catch (err) {
    console.error('Error fetching restaurante:', err);
  } finally {
    loading.value = false;
  }
};

const selectRestaurant = (restaurantId: string) => {
  const selected = restaurantes.value.find(r => r.id === restaurantId);
  if (selected) {
    selectedRestaurantId.value = restaurantId;
    restaurante.value = selected;
    // Guardar selección en localStorage
    localStorage.setItem('selectedRestaurantId', restaurantId);
    // Cerrar modal
    showRestaurantModal.value = false;
  }
};

// Cargar estadísticas del día desde Supabase
const fetchEstadisticas = async () => {
  try {
    // Obtener fecha de hoy (inicio y fin del día)
    const hoy = new Date();
    const inicioHoy = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate()).toISOString();
    const finHoy = new Date(hoy.getFullYear(), hoy.getMonth(), hoy.getDate() + 1).toISOString();

    // Obtener pedidos pagados de hoy
    const { data: pedidosHoy, error: errorPedidos } = await supabase
      .from('pedidos')
      .select(`
        id,
        total,
        estado,
        created_at,
        pedido_detalle (
          cantidad
        )
      `)
      .gte('created_at', inicioHoy)
      .lt('created_at', finHoy);

    if (errorPedidos) throw errorPedidos;

    // Calcular estadísticas
    const pedidosPagados = (pedidosHoy || []).filter(p => p.estado === 'pagado');
    const ventasHoy = pedidosPagados.reduce((sum, p) => sum + (p.total || 0), 0);
    const pedidosCount = (pedidosHoy || []).length;
    const productosVendidos = pedidosPagados.reduce((sum, p) => {
      const detalles = p.pedido_detalle || [];
      return sum + detalles.reduce((dSum: number, d: any) => dSum + (d.cantidad || 0), 0);
    }, 0);

    estadisticas.value = {
      ventasHoy,
      pedidosHoy: pedidosCount,
      productosVendidos
    };
  } catch (err) {
    console.error('Error cargando estadísticas:', err);
  }
};

onMounted(() => {
  // Recuperar selección previa
  const savedRestaurantId = localStorage.getItem('selectedRestaurantId');
  if (savedRestaurantId) {
    selectedRestaurantId.value = savedRestaurantId;
  }
  
  fetchRestaurantes();
  fetchEstadisticas();
});
</script>

<template>
  <div class="min-h-screen bg-linear-to-br from-amber-50 via-orange-50 to-yellow-50">
    <!-- Header / Hero Section -->
    <header class="header-container relative overflow-hidden px-4 py-5 shadow-2xl sm:px-6 sm:py-6 lg:px-8">
      <!-- Animated Background -->
      <div class="header-bg"></div>
      <div class="header-particles">
        <div class="particle particle-1"></div>
        <div class="particle particle-2"></div>
        <div class="particle particle-3"></div>
      </div>

      <div class="relative z-10 mx-auto max-w-7xl">
        <!-- Top Bar con botón cambiar restaurante -->
        <div v-if="isSuperAdmin && restaurantes.length > 1" class="mb-4 flex justify-end">
          <button 
            @click="showRestaurantModal = true"
            class="btn-change-restaurant flex items-center gap-2 rounded-full bg-white/20 px-4 py-2 text-sm font-medium text-white backdrop-blur-sm"
          >
            <Icon icon="mdi:swap-horizontal" class="h-4 w-4" />
            Cambiar Restaurante
          </button>
        </div>

        <div v-if="loading" class="flex items-center justify-center py-6">
          <div class="loading-spinner"></div>
        </div>

        <div v-else-if="restaurante" class="header-content flex flex-col items-center gap-4 text-center sm:gap-5">
          <!-- Logo con animación -->
          <div class="logo-container">
            <img
              v-if="restaurante.logo_url"
              :src="restaurante.logo_url"
              :alt="`Logo de ${restaurante.nombre}`"
              class="h-full w-full object-contain"
            />
            <Icon v-else icon="mdi:coffee" class="logo-icon" />
          </div>

          <!-- Nombre del restaurante -->
          <div class="title-container">
            <h1 class="restaurant-title">
              {{ restaurante.nombre }}
            </h1>
            <p class="restaurant-subtitle">
              Sistema de Gestión Cafetería
            </p>
          </div>

          <!-- Info Badges -->
          <div class="info-badges">
            <div v-if="restaurante.direccion" class="info-badge">
              <Icon icon="mdi:map-marker" class="h-4 w-4" />
              <span>{{ restaurante.direccion }}</span>
            </div>
            <div v-if="horarioAtencion" class="info-badge">
              <Icon icon="mdi:clock-outline" class="h-4 w-4" />
              <span>{{ horarioAtencion }}</span>
            </div>
            <div v-if="restaurante.telefono" class="info-badge">
              <Icon icon="mdi:phone" class="h-4 w-4" />
              <span>{{ restaurante.telefono }}</span>
            </div>
          </div>
        </div>

        <div v-else class="py-6 text-center">
          <p class="text-base text-white">No se encontró información del restaurante</p>
        </div>
      </div>
    </header>

    <!-- Quick Actions -->
    <section class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div class="mb-8 text-center">
        <h2 class="section-title">Panel de Control</h2>
        <p class="section-subtitle">Gestiona tu cafetería de forma eficiente</p>
      </div>
      
      <div class="grid gap-4 grid-cols-2 lg:grid-cols-4">
        <!-- Mesas -->
        <a href="/mesas" class="action-card action-card-amber">
          <div class="action-icon-wrapper action-icon-amber">
            <Icon icon="mdi:table-furniture" class="action-icon" />
          </div>
          <span class="action-title">Mesas</span>
          <span class="action-subtitle">Gestionar mesas</span>
        </a>

        <!-- Anotar Pedido -->
        <a href="/anotar-pedido" class="action-card action-card-blue">
          <div class="action-icon-wrapper action-icon-blue">
            <Icon icon="mdi:notebook-edit" class="action-icon" />
          </div>
          <span class="action-title">Anotar Pedido</span>
          <span class="action-subtitle">Tomar pedidos</span>
        </a>

        <!-- Pedidos -->
        <a href="/pedidos" class="action-card action-card-yellow">
          <div class="action-icon-wrapper action-icon-yellow">
            <Icon icon="mdi:clipboard-list" class="action-icon" />
          </div>
          <span class="action-title">Pedidos</span>
          <span class="action-subtitle">Ver pedidos</span>
        </a>

        <!-- Inventario -->
        <button class="action-card action-card-orange">
          <div class="action-icon-wrapper action-icon-orange">
            <Icon icon="mdi:package-variant" class="action-icon" />
          </div>
          <span class="action-title">Inventario</span>
          <span class="action-subtitle">Gestionar stock</span>
        </button>

        <!-- Reportes -->
        <a href="/reportes" class="action-card action-card-stone">
          <div class="action-icon-wrapper action-icon-stone">
            <Icon icon="mdi:chart-bar" class="action-icon" />
          </div>
          <span class="action-title">Reportes</span>
          <span class="action-subtitle">Ver estadísticas</span>
        </a>

        <!-- Configuración (solo para admin) -->
        <a v-if="isSuperAdmin" href="/configuracion" class="action-card action-card-purple">
          <div class="action-icon-wrapper action-icon-purple">
            <Icon icon="mdi:cog" class="action-icon" />
          </div>
          <span class="action-title">Configuración</span>
          <span class="action-subtitle">Ajustes del sistema</span>
        </a>
      </div>
    </section>

    <!-- Restaurant Selection Modal -->
    <div v-if="showRestaurantModal" class="modal-overlay" @click="showRestaurantModal = false">
      <div class="modal-container" @click.stop>
        <div class="modal-header">
          <h3 class="modal-title">Cambiar Restaurante</h3>
          <button @click="showRestaurantModal = false" class="modal-close">
            <Icon icon="mdi:close" class="h-5 w-5" />
          </button>
        </div>
        
        <div class="modal-body">
          <label class="modal-label">Seleccionar restaurante:</label>
          <select 
            v-model="selectedRestaurantId" 
            @change="selectRestaurant(selectedRestaurantId)"
            class="modal-select"
          >
            <option value="" disabled>-- Seleccionar --</option>
            <option v-for="rest in restaurantes" :key="rest.id" :value="rest.id">
              {{ rest.nombre }} - {{ rest.direccion }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- Stats Section -->
    <section class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div class="rounded-2xl bg-white p-6 shadow-lg sm:p-8">
        <h2 class="mb-6 text-2xl font-bold text-gray-900">Resumen del día</h2>
        <div class="grid gap-6 sm:grid-cols-3">
          <div class="rounded-xl bg-linear-to-br from-amber-50 to-amber-100 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-amber-800">Ventas hoy</p>
                <p class="mt-2 text-3xl font-bold text-amber-900">S/ {{ estadisticas.ventasHoy.toFixed(2) }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-200">
                <Icon icon="mdi:cash-multiple" class="h-6 w-6 text-amber-800" />
              </div>
            </div>
          </div>

          <div class="rounded-xl bg-linear-to-br from-yellow-50 to-yellow-100 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-yellow-800">Pedidos</p>
                <p class="mt-2 text-3xl font-bold text-yellow-900">{{ estadisticas.pedidosHoy }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-yellow-200">
                <Icon icon="mdi:shopping" class="h-6 w-6 text-yellow-800" />
              </div>
            </div>
          </div>

          <div class="rounded-xl bg-linear-to-br from-orange-50 to-orange-100 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-orange-800">Productos vendidos</p>
                <p class="mt-2 text-3xl font-bold text-orange-900">{{ estadisticas.productosVendidos }}</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-orange-200">
                <Icon icon="mdi:package-variant" class="h-6 w-6 text-orange-800" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
/* ========== HEADER STYLES ========== */
.header-container {
  background: linear-gradient(135deg, #78350f 0%, #92400e 50%, #a16207 100%);
  position: relative;
}

.header-bg {
  position: absolute;
  inset: 0;
  background: 
    radial-gradient(circle at 20% 80%, rgba(255,255,255,0.1) 0%, transparent 50%),
    radial-gradient(circle at 80% 20%, rgba(255,255,255,0.08) 0%, transparent 40%);
  animation: bgPulse 8s ease-in-out infinite;
}

@keyframes bgPulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.7; }
}

.header-particles {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
}

.particle {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
}

.particle-1 {
  width: 100px;
  height: 100px;
  top: -20px;
  left: -20px;
  animation: float1 6s ease-in-out infinite;
}

.particle-2 {
  width: 60px;
  height: 60px;
  bottom: 10px;
  right: 20%;
  animation: float2 8s ease-in-out infinite;
}

.particle-3 {
  width: 40px;
  height: 40px;
  top: 50%;
  right: -10px;
  animation: float3 7s ease-in-out infinite;
}

@keyframes float1 {
  0%, 100% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(20px, 20px) scale(1.1); }
}

@keyframes float2 {
  0%, 100% { transform: translate(0, 0) rotate(0deg); }
  50% { transform: translate(-15px, -10px) rotate(180deg); }
}

@keyframes float3 {
  0%, 100% { transform: translate(0, 0); }
  50% { transform: translate(-10px, 15px); }
}

.header-content {
  animation: slideUp 0.6s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Logo */
.logo-container {
  width: 80px;
  height: 80px;
  background: white;
  border-radius: 20px;
  padding: 12px;
  box-shadow: 0 10px 40px rgba(0,0,0,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  animation: logoFloat 3s ease-in-out infinite;
}

@keyframes logoFloat {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-5px); }
}

.logo-icon {
  width: 48px;
  height: 48px;
  color: #92400e;
}

/* Title */
.title-container {
  animation: fadeIn 0.8s ease-out 0.2s both;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.restaurant-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 10px rgba(0,0,0,0.2);
  margin: 0;
}

@media (min-width: 640px) {
  .restaurant-title { font-size: 2.25rem; }
}

.restaurant-subtitle {
  font-size: 0.875rem;
  color: rgba(255, 237, 213, 0.9);
  margin-top: 4px;
}

/* Info Badges */
.info-badges {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  margin-top: 12px;
  animation: fadeIn 0.8s ease-out 0.4s both;
}

.info-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  padding: 8px 14px;
  border-radius: 20px;
  color: white;
  font-size: 0.8rem;
  transition: all 0.3s ease;
}

.info-badge:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: translateY(-2px);
}

/* Change Restaurant Button */
.btn-change-restaurant {
  transition: all 0.3s ease;
  border: 1px solid rgba(255,255,255,0.3);
}

.btn-change-restaurant:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.05);
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
}

/* Loading Spinner */
.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ========== SECTION STYLES ========== */
.section-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 8px;
}

@media (min-width: 640px) {
  .section-title { font-size: 1.875rem; }
}

.section-subtitle {
  color: #6b7280;
  margin-top: 8px;
}

/* ========== ACTION CARDS ========== */
.action-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 20px 16px;
  background: white;
  border-radius: 16px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.08);
  text-decoration: none;
  cursor: pointer;
  border: none;
  position: relative;
  overflow: hidden;
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.action-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: currentColor;
  transform: scaleX(0);
  transition: transform 0.3s ease;
}

.action-card:hover {
  transform: translateY(-8px) scale(1.02);
  box-shadow: 0 20px 40px rgba(0,0,0,0.15);
}

.action-card:hover::before {
  transform: scaleX(1);
}

.action-card:active {
  transform: translateY(-4px) scale(1);
}

.action-icon-wrapper {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.4s ease;
}

.action-card:hover .action-icon-wrapper {
  transform: scale(1.15) rotate(5deg);
}

.action-icon {
  width: 28px;
  height: 28px;
  transition: all 0.3s ease;
}

.action-title {
  font-weight: 600;
  color: #1f2937;
  font-size: 0.9rem;
  transition: color 0.3s ease;
}

.action-subtitle {
  font-size: 0.75rem;
  color: #9ca3af;
}

/* Card Color Variants */
.action-card-amber { color: #92400e; }
.action-card-amber:hover .action-title { color: #92400e; }
.action-icon-amber { background: #fef3c7; color: #92400e; }
.action-card-amber:hover .action-icon-amber { background: #92400e; color: white; }

.action-card-blue { color: #1e40af; }
.action-card-blue:hover .action-title { color: #1e40af; }
.action-icon-blue { background: #dbeafe; color: #1e40af; }
.action-card-blue:hover .action-icon-blue { background: #1e40af; color: white; }

.action-card-yellow { color: #a16207; }
.action-card-yellow:hover .action-title { color: #a16207; }
.action-icon-yellow { background: #fef9c3; color: #a16207; }
.action-card-yellow:hover .action-icon-yellow { background: #a16207; color: white; }

.action-card-orange { color: #c2410c; }
.action-card-orange:hover .action-title { color: #c2410c; }
.action-icon-orange { background: #ffedd5; color: #c2410c; }
.action-card-orange:hover .action-icon-orange { background: #c2410c; color: white; }

.action-card-stone { color: #57534e; }
.action-card-stone:hover .action-title { color: #57534e; }
.action-icon-stone { background: #f5f5f4; color: #57534e; }
.action-card-stone:hover .action-icon-stone { background: #57534e; color: white; }

.action-card-purple { color: #7c3aed; }
.action-card-purple:hover .action-title { color: #7c3aed; }
.action-icon-purple { background: #ede9fe; color: #7c3aed; }
.action-card-purple:hover .action-icon-purple { background: #7c3aed; color: white; }

/* ========== MODAL STYLES ========== */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  animation: fadeIn 0.2s ease;
}

.modal-container {
  margin: 16px;
  width: 100%;
  max-width: 400px;
  background: white;
  border-radius: 20px;
  padding: 24px;
  box-shadow: 0 25px 50px rgba(0,0,0,0.25);
  animation: modalSlide 0.3s ease;
}

@keyframes modalSlide {
  from {
    opacity: 0;
    transform: scale(0.95) translateY(20px);
  }
  to {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.modal-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #1f2937;
}

.modal-close {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: #f3f4f6;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.2s ease;
}

.modal-close:hover {
  background: #e5e7eb;
  color: #1f2937;
}

.modal-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.modal-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
}

.modal-select {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  font-size: 1rem;
  color: #1f2937;
  background: white;
  cursor: pointer;
  transition: all 0.2s ease;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%236b7280'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
  background-size: 20px;
}

.modal-select:focus {
  outline: none;
  border-color: #92400e;
  box-shadow: 0 0 0 3px rgba(146, 64, 14, 0.1);
}

.modal-select:hover {
  border-color: #d1d5db;
}
</style>
