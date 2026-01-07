<script setup lang="ts">
import { ref, onMounted } from 'vue';
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
}

const restaurante = ref<Restaurante | null>(null);
const loading = ref(true);

const fetchRestauranteInfo = async () => {
  try {
    loading.value = true;
    const { data, error } = await supabase
      .from('restaurantes')
      .select('*')
      .eq('activo', true)
      .limit(1)
      .single();

    if (error) throw error;
    restaurante.value = data;
  } catch (err) {
    console.error('Error fetching restaurante:', err);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchRestauranteInfo();
});
</script>

<template>
  <div class="min-h-screen bg-linear-to-br from-amber-50 via-orange-50 to-yellow-50">
    <!-- Header / Hero Section -->
    <header class="relative overflow-hidden bg-linear-to-r from-amber-900 via-amber-800 to-yellow-800 px-4 py-8 shadow-lg sm:px-6 sm:py-12 lg:px-8">
      <!-- Decorative elements -->
      <div class="absolute inset-0 opacity-10">
        <div class="absolute -left-4 -top-4 h-32 w-32 rounded-full bg-white blur-2xl"></div>
        <div class="absolute -bottom-8 -right-8 h-40 w-40 rounded-full bg-white blur-3xl"></div>
      </div>

      <div class="relative mx-auto max-w-7xl">
        <div v-if="loading" class="flex items-center justify-center py-8">
          <div class="h-12 w-12 animate-spin rounded-full border-4 border-white border-t-transparent"></div>
        </div>

        <div v-else-if="restaurante" class="flex flex-col items-center gap-6 text-center sm:gap-8">
          <!-- Logo -->
          <div class="flex h-24 w-24 items-center justify-center overflow-hidden rounded-2xl bg-white p-4 shadow-xl sm:h-32 sm:w-32">
            <img
              v-if="restaurante.logo_url"
              :src="restaurante.logo_url"
              :alt="`Logo de ${restaurante.nombre}`"
              class="h-full w-full object-contain"
            />
            <Icon v-else icon="mdi:coffee" class="h-16 w-16 text-amber-800 sm:h-20 sm:w-20" />
          </div>

          <!-- Nombre del restaurante -->
          <div>
            <h1 class="text-4xl font-bold text-white drop-shadow-lg sm:text-5xl lg:text-6xl">
              {{ restaurante.nombre }}
            </h1>
            <p class="mt-3 text-lg text-amber-100 sm:text-xl">
              Bienvenido a nuestro sistema de gestión
            </p>
          </div>

          <!-- Info Cards -->
          <div class="mt-4 grid w-full max-w-2xl gap-4 sm:grid-cols-2">
            <!-- Dirección -->
            <div class="rounded-xl bg-white/20 p-4 backdrop-blur-sm">
              <div class="flex items-start gap-3 text-left">
                <Icon icon="mdi:map-marker" class="mt-1 h-6 w-6 shrink-0 text-white" />
                <div>
                  <p class="text-sm font-medium text-amber-100">Dirección</p>
                  <p class="mt-1 text-white">{{ restaurante.direccion }}</p>
                </div>
              </div>
            </div>

            <!-- Teléfono -->
            <div v-if="restaurante.telefono" class="rounded-xl bg-white/20 p-4 backdrop-blur-sm">
              <div class="flex items-start gap-3 text-left">
                <Icon icon="mdi:phone" class="mt-1 h-6 w-6 shrink-0 text-white" />
                <div>
                  <p class="text-sm font-medium text-amber-100">Teléfono</p>
                  <p class="mt-1 text-white">{{ restaurante.telefono }}</p>
                </div>
              </div>
            </div>

            <!-- RUC -->
            <div v-if="restaurante.ruc" class="rounded-xl bg-white/20 p-4 backdrop-blur-sm">
              <div class="flex items-start gap-3 text-left">
                <Icon icon="mdi:file-document" class="mt-1 h-6 w-6 shrink-0 text-white" />
                <div>
                  <p class="text-sm font-medium text-amber-100">RUC</p>
                  <p class="mt-1 text-white">{{ restaurante.ruc }}</p>
                </div>
              </div>
            </div>

            <!-- Moneda -->
            <div class="rounded-xl bg-white/20 p-4 backdrop-blur-sm">
              <div class="flex items-start gap-3 text-left">
                <Icon icon="mdi:currency-usd" class="mt-1 h-6 w-6 shrink-0 text-white" />
                <div>
                  <p class="text-sm font-medium text-amber-100">Moneda</p>
                  <p class="mt-1 text-white">{{ restaurante.moneda }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div v-else class="py-8 text-center">
          <p class="text-lg text-white">No se encontró información del restaurante</p>
        </div>
      </div>
    </header>

    <!-- Quick Actions -->
    <section class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <!-- Mesas -->
        <a href="/mesas" class="group flex flex-col items-center gap-3 rounded-xl bg-white p-6 shadow-md transition-all hover:shadow-xl hover:-translate-y-1">
          <div class="flex h-16 w-16 items-center justify-center rounded-full bg-amber-100 text-amber-800 transition-colors group-hover:bg-amber-800 group-hover:text-white">
            <Icon icon="mdi:table-furniture" class="h-8 w-8" />
          </div>
          <span class="font-semibold text-gray-900">Mesas</span>
        </a>

        <!-- Pedidos -->
        <button class="group flex flex-col items-center gap-3 rounded-xl bg-white p-6 shadow-md transition-all hover:shadow-xl hover:-translate-y-1">
          <div class="flex h-16 w-16 items-center justify-center rounded-full bg-yellow-100 text-yellow-800 transition-colors group-hover:bg-yellow-800 group-hover:text-white">
            <Icon icon="mdi:clipboard-list" class="h-8 w-8" />
          </div>
          <span class="font-semibold text-gray-900">Pedidos</span>
        </button>

        <!-- Inventario -->
        <button class="group flex flex-col items-center gap-3 rounded-xl bg-white p-6 shadow-md transition-all hover:shadow-xl hover:-translate-y-1">
          <div class="flex h-16 w-16 items-center justify-center rounded-full bg-orange-100 text-orange-800 transition-colors group-hover:bg-orange-800 group-hover:text-white">
            <Icon icon="mdi:package-variant" class="h-8 w-8" />
          </div>
          <span class="font-semibold text-gray-900">Inventario</span>
        </button>

        <!-- Reportes -->
        <button class="group flex flex-col items-center gap-3 rounded-xl bg-white p-6 shadow-md transition-all hover:shadow-xl hover:-translate-y-1">
          <div class="flex h-16 w-16 items-center justify-center rounded-full bg-stone-100 text-stone-800 transition-colors group-hover:bg-stone-800 group-hover:text-white">
            <Icon icon="mdi:chart-bar" class="h-8 w-8" />
          </div>
          <span class="font-semibold text-gray-900">Reportes</span>
        </button>
      </div>
    </section>

    <!-- Stats Section -->
    <section class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div class="rounded-2xl bg-white p-6 shadow-lg sm:p-8">
        <h2 class="mb-6 text-2xl font-bold text-gray-900">Resumen del día</h2>
        <div class="grid gap-6 sm:grid-cols-3">
          <div class="rounded-xl bg-linear-to-br from-amber-50 to-amber-100 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-amber-800">Ventas hoy</p>
                <p class="mt-2 text-3xl font-bold text-amber-900">S/ 0.00</p>
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
                <p class="mt-2 text-3xl font-bold text-yellow-900">0</p>
              </div>
              <div class="flex h-12 w-12 items-center justify-center rounded-full bg-yellow-200">
                <Icon icon="mdi:shopping" class="h-6 w-6 text-yellow-800" />
              </div>
            </div>
          </div>

          <div class="rounded-xl bg-linear-to-br from-orange-50 to-orange-100 p-6">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-orange-800">Productos</p>
                <p class="mt-2 text-3xl font-bold text-orange-900">0</p>
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
/* Animaciones adicionales si es necesario */
</style>
