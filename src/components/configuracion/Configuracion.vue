<script setup lang="ts">
import { Icon } from '@iconify/vue';

// Opciones de configuración basadas en las tablas de la base de datos
const opcionesConfig = [
  {
    id: 'productos',
    titulo: 'Productos',
    subtitulo: 'Gestionar menú',
    icono: 'mdi:food',
    color: 'amber',
    href: '/configuracion/productos'
  },
  {
    id: 'categorias',
    titulo: 'Categorías',
    subtitulo: 'Tipos de productos',
    icono: 'mdi:folder-multiple',
    color: 'blue',
    href: '/configuracion/categorias'
  },
  {
    id: 'subcategorias',
    titulo: 'Subcategorías',
    subtitulo: 'Subdivisiones',
    icono: 'mdi:folder-open',
    color: 'cyan',
    href: '/configuracion/subcategorias'
  },
  {
    id: 'mesas',
    titulo: 'Mesas',
    subtitulo: 'Configurar mesas',
    icono: 'mdi:table-furniture',
    color: 'yellow',
    href: '/configuracion/mesas'
  },
  {
    id: 'modificadores',
    titulo: 'Modificadores',
    subtitulo: 'Extras y sin',
    icono: 'mdi:tune-variant',
    color: 'green',
    href: '/configuracion/modificadores'
  },
  {
    id: 'clientes',
    titulo: 'Clientes',
    subtitulo: 'Base de clientes',
    icono: 'mdi:account-group',
    color: 'orange',
    href: '/configuracion/clientes'
  },
  {
    id: 'restaurante',
    titulo: 'Restaurante',
    subtitulo: 'Datos del local',
    icono: 'mdi:store',
    color: 'purple',
    href: '/configuracion/restaurante'
  },
  {
    id: 'usuarios',
    titulo: 'Usuarios',
    subtitulo: 'Accesos y roles',
    icono: 'mdi:account-key',
    color: 'red',
    href: '/configuracion/usuarios'
  }
];
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-purple-50 via-violet-50 to-indigo-50">
    <!-- Header -->
    <header class="header-container relative overflow-hidden px-4 py-5 shadow-2xl sm:px-6 sm:py-6 lg:px-8">
      <!-- Animated Background -->
      <div class="header-bg"></div>
      <div class="header-particles">
        <div class="particle particle-1"></div>
        <div class="particle particle-2"></div>
        <div class="particle particle-3"></div>
      </div>

      <div class="relative z-10 mx-auto max-w-7xl">
        <div class="header-content flex flex-col items-center gap-4 sm:flex-row sm:gap-6">
          <!-- Botón Volver -->
          <a href="/" class="back-button">
            <Icon icon="mdi:arrow-left" class="h-5 w-5" />
          </a>
          
          <!-- Logo -->
          <div class="logo-container">
            <Icon icon="mdi:cog" class="logo-icon" />
          </div>

          <!-- Title -->
          <div class="title-container text-center sm:text-left">
            <h1 class="page-title">Configuración</h1>
            <p class="page-subtitle">Administra los datos de tu sistema</p>
          </div>
        </div>
      </div>
    </header>

    <!-- Opciones de Configuración -->
    <section class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div class="mb-8 text-center">
        <h2 class="section-title">Panel de Configuración</h2>
        <p class="section-subtitle">Selecciona una opción para gestionar</p>
      </div>
      
      <div class="grid gap-4 grid-cols-2 lg:grid-cols-4">
        <a
          v-for="opcion in opcionesConfig"
          :key="opcion.id"
          :href="opcion.href"
          :class="['action-card', `action-card-${opcion.color}`]"
        >
          <div :class="['action-icon-wrapper', `action-icon-${opcion.color}`]">
            <Icon :icon="opcion.icono" class="action-icon" />
          </div>
          <span class="action-title">{{ opcion.titulo }}</span>
          <span class="action-subtitle">{{ opcion.subtitulo }}</span>
        </a>
      </div>
    </section>

    <!-- Info Section -->
    <section class="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
      <div class="rounded-2xl bg-white p-6 shadow-lg">
        <div class="flex items-start gap-4">
          <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-purple-100">
            <Icon icon="mdi:information" class="h-6 w-6 text-purple-600" />
          </div>
          <div>
            <h3 class="text-lg font-bold text-gray-900">Información</h3>
            <p class="mt-1 text-sm text-gray-600">
              Desde aquí puedes administrar todos los datos maestros de tu sistema: 
              productos, categorías, mesas, modificadores y más. Los cambios se reflejarán 
              inmediatamente en el sistema de pedidos.
            </p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
/* ========== HEADER STYLES ========== */
.header-container {
  background: linear-gradient(135deg, #5b21b6 0%, #7c3aed 50%, #8b5cf6 100%);
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

/* Back Button */
.back-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  color: white;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.back-button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateX(-3px);
}

/* Logo */
.logo-container {
  width: 70px;
  height: 70px;
  background: white;
  border-radius: 18px;
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
  width: 40px;
  height: 40px;
  color: #7c3aed;
}

/* Title */
.title-container {
  animation: fadeIn 0.8s ease-out 0.2s both;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.page-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 10px rgba(0,0,0,0.2);
  margin: 0;
}

@media (min-width: 640px) {
  .page-title { font-size: 2rem; }
}

.page-subtitle {
  font-size: 0.875rem;
  color: rgba(255, 255, 255, 0.85);
  margin-top: 4px;
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

.action-card-cyan { color: #0e7490; }
.action-card-cyan:hover .action-title { color: #0e7490; }
.action-icon-cyan { background: #cffafe; color: #0e7490; }
.action-card-cyan:hover .action-icon-cyan { background: #0e7490; color: white; }

.action-card-yellow { color: #a16207; }
.action-card-yellow:hover .action-title { color: #a16207; }
.action-icon-yellow { background: #fef9c3; color: #a16207; }
.action-card-yellow:hover .action-icon-yellow { background: #a16207; color: white; }

.action-card-green { color: #15803d; }
.action-card-green:hover .action-title { color: #15803d; }
.action-icon-green { background: #dcfce7; color: #15803d; }
.action-card-green:hover .action-icon-green { background: #15803d; color: white; }

.action-card-orange { color: #c2410c; }
.action-card-orange:hover .action-title { color: #c2410c; }
.action-icon-orange { background: #ffedd5; color: #c2410c; }
.action-card-orange:hover .action-icon-orange { background: #c2410c; color: white; }

.action-card-purple { color: #7c3aed; }
.action-card-purple:hover .action-title { color: #7c3aed; }
.action-icon-purple { background: #ede9fe; color: #7c3aed; }
.action-card-purple:hover .action-icon-purple { background: #7c3aed; color: white; }

.action-card-red { color: #dc2626; }
.action-card-red:hover .action-title { color: #dc2626; }
.action-icon-red { background: #fee2e2; color: #dc2626; }
.action-card-red:hover .action-icon-red { background: #dc2626; color: white; }
</style>
