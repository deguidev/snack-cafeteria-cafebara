<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { Icon } from '@iconify/vue';
import confetti from 'canvas-confetti';

interface Mesa {
  id: string;
  numero: number;
  capacidad: number;
  posicion_x: number;
  posicion_y: number;
  orientacion: 'horizontal' | 'vertical';
  estado: 'disponible' | 'ocupada';
  pedidos?: Pedido[];
  tiempo_ocupado?: Date;
}

interface Pedido {
  id: string;
  producto: string;
  cantidad: number;
  precio: number;
}

// Canvas
const canvasRef = ref<HTMLCanvasElement | null>(null);
const canvasWidth = 1000;
const canvasHeight = 1200;
const cellSize = 120; // Tamaño de cada celda de la cuadrícula (más grande)
const pulseOpacity = ref(1); // Para la animación de parpadeo
const isMobile = ref(false); // Detectar si es móvil

// Detectar tamaño de pantalla
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768;
};

// Datos de ejemplo - 4 mesas según especificación
const mesas = ref<Mesa[]>([
  { 
    id: '1', 
    numero: 1, 
    capacidad: 4, 
    posicion_x: 2, 
    posicion_y: 2, 
    orientacion: 'vertical', 
    estado: 'disponible' 
  },
  { 
    id: '2', 
    numero: 2, 
    capacidad: 4, 
    posicion_x: 5, 
    posicion_y: 2, 
    orientacion: 'horizontal', 
    estado: 'ocupada',
    pedidos: [
      { id: 'p1', producto: 'Arroz con pollo', cantidad: 2, precio: 15.00 },
      { id: 'p2', producto: 'Café', cantidad: 2, precio: 5.00 },
    ],
    tiempo_ocupado: new Date()
  },
  { 
    id: '3', 
    numero: 3, 
    capacidad: 3, 
    posicion_x: 2, 
    posicion_y: 6, 
    orientacion: 'vertical', 
    estado: 'disponible' 
  },
  { 
    id: '4', 
    numero: 4, 
    capacidad: 5, 
    posicion_x: 5, 
    posicion_y: 6, 
    orientacion: 'vertical', 
    estado: 'ocupada',
    pedidos: [
      { id: 'p3', producto: 'Lomo saltado', cantidad: 1, precio: 18.00 },
      { id: 'p4', producto: 'Jugo de naranja', cantidad: 1, precio: 6.00 },
    ],
    tiempo_ocupado: new Date()
  },
]);

const mesaSeleccionada = ref<Mesa | null>(null);
const mostrarModal = ref(false);

const estadisticas = computed(() => ({
  total: mesas.value.length,
  disponibles: mesas.value.filter(m => m.estado === 'disponible').length,
  ocupadas: mesas.value.filter(m => m.estado === 'ocupada').length,
}));

const totalPedido = computed(() => {
  if (!mesaSeleccionada.value?.pedidos) return 0;
  return mesaSeleccionada.value.pedidos.reduce((sum, p) => sum + (p.precio * p.cantidad), 0);
});

// Función para dibujar una silla
const dibujarSilla = (ctx: CanvasRenderingContext2D, x: number, y: number, rotacion: number) => {
  ctx.save();
  ctx.translate(x, y);
  ctx.rotate(rotacion * Math.PI / 180);
  
  // Respaldo de la silla
  ctx.fillStyle = '#6B4423';
  ctx.fillRect(-8, -12, 16, 4);
  
  // Asiento
  ctx.fillStyle = '#8B5A3C';
  ctx.fillRect(-10, -8, 20, 16);
  
  ctx.restore();
};

// Función para dibujar una mesa con sillas
const dibujarMesa = (ctx: CanvasRenderingContext2D, mesa: Mesa) => {
  const x = mesa.posicion_x * cellSize;
  const y = mesa.posicion_y * cellSize;
  
  const esHorizontal = mesa.orientacion === 'horizontal';
  // Tamaños más grandes en móvil
  const escala = isMobile.value ? 1.8 : 1.2;
  const ancho = esHorizontal ? 120 * escala : 80 * escala;
  const alto = esHorizontal ? 80 * escala : 120 * escala;
  
  // Color según estado
  let colorMesa = '#D4A574'; // Café claro para disponible
  let colorBorde = '#8B4513'; // Café oscuro
  
  if (mesa.estado === 'ocupada') {
    colorMesa = '#E57373'; // Rojo claro
    colorBorde = '#C62828'; // Rojo oscuro
  }
  
  // Dibujar sombra
  ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
  ctx.fillRect(x + 3, y + 3, ancho, alto);
  
  // Dibujar mesa
  ctx.fillStyle = colorMesa;
  ctx.strokeStyle = colorBorde;
  ctx.lineWidth = 3;
  ctx.fillRect(x, y, ancho, alto);
  ctx.strokeRect(x, y, ancho, alto);
  
  // Textura de madera (líneas)
  ctx.strokeStyle = 'rgba(0, 0, 0, 0.1)';
  ctx.lineWidth = 1;
  for (let i = 0; i < (esHorizontal ? ancho : alto); i += 10) {
    if (esHorizontal) {
      ctx.beginPath();
      ctx.moveTo(x + i, y);
      ctx.lineTo(x + i, y + alto);
      ctx.stroke();
    } else {
      ctx.beginPath();
      ctx.moveTo(x, y + i);
      ctx.lineTo(x + ancho, y + i);
      ctx.stroke();
    }
  }
  
  // Mostrar información DENTRO de la mesa
  if (mesa.estado === 'ocupada' && mesa.pedidos) {
    const totalMesa = mesa.pedidos.reduce((sum, p) => sum + (p.precio * p.cantidad), 0);
    const cantidadPedidos = mesa.pedidos.reduce((sum, p) => sum + p.cantidad, 0);
    
    ctx.fillStyle = '#FFFFFF';
    ctx.textBaseline = 'middle';
    
    // Cantidad de pedidos
    const fontSizePedidos = isMobile.value ? 22 : 16;
    ctx.font = `bold ${fontSizePedidos}px Arial`;
    ctx.fillText(`${cantidadPedidos} pedido${cantidadPedidos > 1 ? 's' : ''}`, x + ancho / 2, y + alto / 2 - 10);
    
    // Precio total
    const fontSizePrecio = isMobile.value ? 28 : 20;
    ctx.font = `bold ${fontSizePrecio}px Arial`;
    ctx.fillText(`S/ ${totalMesa.toFixed(2)}`, x + ancho / 2, y + alto / 2 + 15);
  } else {
    // Si está disponible, mostrar círculo verde parpadeante
    const centerX = x + ancho / 2;
    const centerY = y + alto / 2;
    const radioEscala = isMobile.value ? 1.5 : 1;
    
    // Círculo exterior con opacidad variable (parpadeo)
    ctx.fillStyle = `rgba(34, 197, 94, ${pulseOpacity.value})`; // Verde
    ctx.beginPath();
    ctx.arc(centerX, centerY, 20 * radioEscala, 0, 2 * Math.PI);
    ctx.fill();
    
    // Círculo interior sólido
    ctx.fillStyle = '#22C55E'; // Verde sólido
    ctx.beginPath();
    ctx.arc(centerX, centerY, 12 * radioEscala, 0, 2 * Math.PI);
    ctx.fill();
    
    // Borde blanco
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 2 * radioEscala;
    ctx.stroke();
  }
  
  // Dibujar sillas según capacidad y orientación
  const numSillas = mesa.capacidad;
  const sillasPorLado = Math.ceil(numSillas / 2);
  
  if (esHorizontal) {
    // Sillas arriba y abajo
    const espaciado = ancho / (sillasPorLado + 1);
    for (let i = 0; i < Math.min(sillasPorLado, numSillas); i++) {
      dibujarSilla(ctx, x + espaciado * (i + 1), y - 20, 0);
    }
    for (let i = 0; i < numSillas - sillasPorLado; i++) {
      dibujarSilla(ctx, x + espaciado * (i + 1), y + alto + 20, 180);
    }
  } else {
    // Sillas izquierda y derecha
    const espaciado = alto / (sillasPorLado + 1);
    for (let i = 0; i < Math.min(sillasPorLado, numSillas); i++) {
      dibujarSilla(ctx, x - 20, y + espaciado * (i + 1), -90);
    }
    for (let i = 0; i < numSillas - sillasPorLado; i++) {
      dibujarSilla(ctx, x + ancho + 20, y + espaciado * (i + 1), 90);
    }
  }
  
  // Indicador de ocupado (reloj)
  if (mesa.estado === 'ocupada') {
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(x + ancho - 15, y + 15, 10, 0, 2 * Math.PI);
    ctx.fill();
    ctx.strokeStyle = '#C62828';
    ctx.lineWidth = 2;
    ctx.stroke();
    
    // Manecillas del reloj
    ctx.strokeStyle = '#C62828';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(x + ancho - 15, y + 15);
    ctx.lineTo(x + ancho - 15, y + 10);
    ctx.stroke();
    ctx.beginPath();
    ctx.moveTo(x + ancho - 15, y + 15);
    ctx.lineTo(x + ancho - 11, y + 15);
    ctx.stroke();
  }
  
  // Nombre de mesa ARRIBA (fuera de la mesa) - Se dibuja al final para que quede encima
  ctx.fillStyle = '#4A2511';
  const fontSize = isMobile.value ? 24 : 18;
  ctx.font = `bold ${fontSize}px Arial`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'bottom';
  const offsetY = isMobile.value ? -40 : -30;
  ctx.fillText(`Mesa ${mesa.numero}`, x + ancho / 2, y + offsetY);
};

// Función para dibujar todo el canvas
const dibujarCanvas = () => {
  const canvas = canvasRef.value;
  if (!canvas) return;
  
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  
  // Limpiar canvas
  ctx.fillStyle = '#FFF8DC'; // Color crema de fondo
  ctx.fillRect(0, 0, canvasWidth, canvasHeight);
  
  // Dibujar cuadrícula suave
  ctx.strokeStyle = 'rgba(139, 69, 19, 0.1)';
  ctx.lineWidth = 1;
  for (let i = 0; i <= canvasWidth; i += cellSize) {
    ctx.beginPath();
    ctx.moveTo(i, 0);
    ctx.lineTo(i, canvasHeight);
    ctx.stroke();
  }
  for (let i = 0; i <= canvasHeight; i += cellSize) {
    ctx.beginPath();
    ctx.moveTo(0, i);
    ctx.lineTo(canvasWidth, i);
    ctx.stroke();
  }
  
  // Dibujar todas las mesas
  mesas.value.forEach(mesa => {
    dibujarMesa(ctx, mesa);
  });
};

// Manejar click en canvas
const handleCanvasClick = (event: MouseEvent | TouchEvent) => {
  const canvas = canvasRef.value;
  if (!canvas) return;
  
  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;
  
  let clientX: number, clientY: number;
  
  if (event instanceof TouchEvent) {
    clientX = event.touches[0]?.clientX || event.changedTouches[0]?.clientX || 0;
    clientY = event.touches[0]?.clientY || event.changedTouches[0]?.clientY || 0;
  } else {
    clientX = event.clientX;
    clientY = event.clientY;
  }
  
  const x = (clientX - rect.left) * scaleX;
  const y = (clientY - rect.top) * scaleY;
  
  // Buscar mesa clickeada
  for (const mesa of mesas.value) {
    const mx = mesa.posicion_x * cellSize;
    const my = mesa.posicion_y * cellSize;
    const esHorizontal = mesa.orientacion === 'horizontal';
    const ancho = esHorizontal ? 120 : 80;
    const alto = esHorizontal ? 80 : 120;
    
    if (x >= mx && x <= mx + ancho && y >= my && y <= my + alto) {
      mesaSeleccionada.value = mesa;
      mostrarModal.value = true;
      break;
    }
  }
};

const cerrarModal = () => {
  mostrarModal.value = false;
  mesaSeleccionada.value = null;
};

const pagarMesa = () => {
  if (mesaSeleccionada.value) {
    const mesa = mesas.value.find(m => m.id === mesaSeleccionada.value?.id);
    if (mesa) {
      // Lanzar confeti
      confetti({
        particleCount: 100,
        spread: 70,
        origin: { y: 0.6 },
        colors: ['#22C55E', '#FCD34D', '#F59E0B', '#FBBF24', '#10B981']
      });
      
      // Confeti adicional desde los lados
      setTimeout(() => {
        confetti({
          particleCount: 50,
          angle: 60,
          spread: 55,
          origin: { x: 0 },
          colors: ['#22C55E', '#FCD34D', '#F59E0B']
        });
        confetti({
          particleCount: 50,
          angle: 120,
          spread: 55,
          origin: { x: 1 },
          colors: ['#22C55E', '#FCD34D', '#F59E0B']
        });
      }, 200);
      
      // Liberar mesa después del confeti
      setTimeout(() => {
        mesa.estado = 'disponible';
        mesa.pedidos = undefined;
        mesa.tiempo_ocupado = undefined;
        dibujarCanvas();
        cerrarModal();
      }, 800);
    }
  }
};

onMounted(() => {
  checkMobile();
  dibujarCanvas();
  
  // Redibujar al cambiar tamaño de ventana
  window.addEventListener('resize', () => {
    checkMobile();
    dibujarCanvas();
  });
  
  // Animación de parpadeo
  let increasing = false;
  setInterval(() => {
    if (increasing) {
      pulseOpacity.value += 0.05;
      if (pulseOpacity.value >= 1) {
        pulseOpacity.value = 1;
        increasing = false;
      }
    } else {
      pulseOpacity.value -= 0.05;
      if (pulseOpacity.value <= 0.3) {
        pulseOpacity.value = 0.3;
        increasing = true;
      }
    }
    dibujarCanvas();
  }, 50);
});
</script>

<template>
  <div class="min-h-screen bg-linear-to-br from-amber-50 via-orange-50 to-yellow-50">
    <!-- Header -->
    <header class="bg-linear-to-r from-amber-900 via-amber-800 to-yellow-800 px-4 py-6 shadow-lg sm:px-6 lg:px-8">
      <div class="mx-auto max-w-7xl">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <a href="/" class="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 backdrop-blur-sm transition-colors hover:bg-white/30">
              <Icon icon="mdi:arrow-left" class="h-6 w-6 text-white" />
            </a>
            <div>
              <h1 class="text-2xl font-bold text-white sm:text-3xl">Gestión de Mesas</h1>
              <p class="mt-1 text-sm text-amber-100">Distribución física del restaurante</p>
            </div>
          </div>
        </div>
      </div>
    </header>

    <!-- Estadísticas -->
    <section class="mx-auto max-w-7xl px-4 py-3 sm:px-6 lg:px-8">
      <div class="grid gap-4 sm:grid-cols-3">
        <div class="rounded-xl bg-white p-4 shadow-md">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-600">Total Mesas</p>
              <p class="mt-1 text-2xl font-bold text-gray-900">{{ estadisticas.total }}</p>
            </div>
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
              <Icon icon="mdi:table-furniture" class="h-6 w-6 text-amber-800" />
            </div>
          </div>
        </div>

        <div class="rounded-xl bg-white p-4 shadow-md">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-600">Disponibles</p>
              <p class="mt-1 text-2xl font-bold text-green-600">{{ estadisticas.disponibles }}</p>
            </div>
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
              <Icon icon="mdi:check-circle" class="h-6 w-6 text-green-600" />
            </div>
          </div>
        </div>

        <div class="rounded-xl bg-white p-4 shadow-md">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-gray-600">Ocupadas</p>
              <p class="mt-1 text-2xl font-bold text-red-600">{{ estadisticas.ocupadas }}</p>
            </div>
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-red-100">
              <Icon icon="mdi:account-group" class="h-6 w-6 text-red-600" />
            </div>
          </div>
        </div>
      </div>
    </section>


    <!-- Canvas de Mesas -->
    <section class="mx-auto max-w-7xl px-4 pb-6 sm:px-6 lg:px-8">
      <div class="overflow-auto rounded-xl bg-white shadow-xl" :class="isMobile ? 'p-2' : 'p-4 border-2 border-amber-200'">
        <canvas
          ref="canvasRef"
          :width="canvasWidth"
          :height="canvasHeight"
          @click="handleCanvasClick"
          @touchend.prevent="handleCanvasClick"
          class="cursor-pointer rounded-lg"
          :class="!isMobile ? 'border-2 border-amber-200' : ''"
        ></canvas>
      </div>
    </section>

    <!-- Modal de Detalle de Mesa -->
    <div
      v-if="mostrarModal && mesaSeleccionada"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      @click.self="cerrarModal"
    >
      <div class="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl">
        <!-- Header del Modal -->
        <div class="flex items-center justify-between border-b border-gray-200 pb-4">
          <div class="flex items-center gap-3">
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-amber-100">
              <Icon icon="mdi:table-furniture" class="h-6 w-6 text-amber-800" />
            </div>
            <div>
              <h2 class="text-2xl font-bold text-gray-900">Mesa {{ mesaSeleccionada.numero }}</h2>
              <p class="text-sm text-gray-600">{{ mesaSeleccionada.capacidad }} personas</p>
            </div>
          </div>
          <button
            @click="cerrarModal"
            class="flex h-8 w-8 items-center justify-center rounded-full text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600"
          >
            <Icon icon="mdi:close" class="h-6 w-6" />
          </button>
        </div>

        <!-- Estado -->
        <div class="mt-4">
          <div class="flex items-center gap-2">
            <span class="text-sm font-medium text-gray-600">Estado:</span>
            <span
              :class="[
                'rounded-full px-3 py-1 text-sm font-semibold',
                mesaSeleccionada.estado === 'disponible'
                  ? 'bg-green-100 text-green-800'
                  : 'bg-red-100 text-red-800'
              ]"
            >
              {{ mesaSeleccionada.estado === 'disponible' ? 'Disponible' : 'Ocupada' }}
            </span>
          </div>
        </div>

        <!-- Pedidos (si está ocupada) -->
        <div v-if="mesaSeleccionada.estado === 'ocupada' && mesaSeleccionada.pedidos" class="mt-6">
          <h3 class="mb-3 text-lg font-semibold text-gray-900">Pedido Actual</h3>
          <div class="space-y-2 rounded-lg bg-gray-50 p-4">
            <div
              v-for="pedido in mesaSeleccionada.pedidos"
              :key="pedido.id"
              class="flex items-center justify-between border-b border-gray-200 pb-2 last:border-0 last:pb-0"
            >
              <div class="flex items-center gap-3">
                <span class="flex h-6 w-6 items-center justify-center rounded-full bg-amber-100 text-xs font-bold text-amber-800">
                  {{ pedido.cantidad }}
                </span>
                <span class="font-medium text-gray-700">{{ pedido.producto }}</span>
              </div>
              <span class="font-semibold text-gray-900">S/ {{ (pedido.precio * pedido.cantidad).toFixed(2) }}</span>
            </div>
            
            <!-- Total -->
            <div class="mt-4 flex items-center justify-between border-t-2 border-amber-800 pt-3">
              <span class="text-lg font-bold text-gray-900">Total:</span>
              <span class="text-2xl font-bold text-amber-800">S/ {{ totalPedido.toFixed(2) }}</span>
            </div>
          </div>
        </div>

        <!-- Información adicional -->
        <div class="mt-6 grid grid-cols-2 gap-4 rounded-lg bg-amber-50 p-4">
          <div>
            <p class="text-xs font-medium text-amber-800">Orientación</p>
            <p class="mt-1 text-sm font-semibold text-gray-900">
              {{ mesaSeleccionada.orientacion === 'horizontal' ? 'Horizontal' : 'Vertical' }}
            </p>
          </div>
          <div>
            <p class="text-xs font-medium text-amber-800">Posición</p>
            <p class="mt-1 text-sm font-semibold text-gray-900">
              ({{ mesaSeleccionada.posicion_x }}, {{ mesaSeleccionada.posicion_y }})
            </p>
          </div>
        </div>

        <!-- Acciones -->
        <div class="mt-6 flex gap-3">
          <button
            v-if="mesaSeleccionada.estado === 'ocupada'"
            @click="pagarMesa"
            class="flex-1 rounded-lg bg-green-600 px-4 py-3 font-semibold text-white transition-colors hover:bg-green-700"
          >
            <Icon icon="mdi:cash-check" class="mr-2 inline h-5 w-5" />
            Pagar
          </button>
          <button
            @click="cerrarModal"
            class="flex-1 rounded-lg bg-gray-200 px-4 py-3 font-semibold text-gray-700 transition-colors hover:bg-gray-300"
          >
            Cerrar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
canvas {
  display: block;
  max-width: 100%;
  height: auto;
}
</style>
