<script setup lang="ts">
import { ref, computed } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';
import CarritoPedido from './CarritoPedido.vue';

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria: 'comidas' | 'cafes' | 'bebidas' | 'dxn';
  imagen_url?: string;
  disponible: boolean;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
}

// Estado
const categoriaActiva = ref<'comidas' | 'cafes' | 'bebidas' | 'dxn'>('comidas');
const productos = ref<Producto[]>([]);
const pedidoActual = ref<ItemPedido[]>([]);
const loading = ref(true);
const mesaNumero = ref<number | null>(null);
const nombreCliente = ref('');
const mostrarResumen = ref(false);
const mostrarCarrito = ref(true); // Controla visibilidad del menú lateral

// Productos de ejemplo (reemplazar con datos de Supabase)
const productosEjemplo: Producto[] = [
  // Comidas
  {
    id: '1',
    nombre: 'Arroz con Pollo',
    descripcion: 'Delicioso arroz con pollo a la olla con papas y ensalada',
    precio: 15.00,
    categoria: 'comidas',
    disponible: true
  },
  {
    id: '2',
    nombre: 'Lomo Saltado',
    descripcion: 'Carne de res salteada con cebolla, tomate y papas fritas',
    precio: 18.00,
    categoria: 'comidas',
    disponible: true
  },
  {
    id: '3',
    nombre: 'Ají de Gallina',
    descripcion: 'Pollo deshilachado en salsa de ají amarillo con papas',
    precio: 16.00,
    categoria: 'comidas',
    disponible: true
  },
  {
    id: '4',
    nombre: 'Ceviche',
    descripcion: 'Ceviche de pescado fresco con camote y choclo',
    precio: 20.00,
    categoria: 'platos',
    imagen_url: 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=400',
    disponible: true
  },
  {
    id: '4',
    nombre: 'Ají de Gallina',
    descripcion: 'Ají de gallina cremoso con papas y arroz',
    precio: 16.00,
    categoria: 'platos',
    imagen_url: 'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=400',
    disponible: true
  },
  // Bebidas
  {
    id: '5',
    nombre: 'Chicha Morada',
    descripcion: 'Refrescante chicha morada natural',
    precio: 5.00,
    categoria: 'bebidas',
    imagen_url: 'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=400',
    disponible: true
  },
  {
    id: '6',
    nombre: 'Inca Kola',
    descripcion: 'Inca Kola 500ml',
    precio: 4.00,
    categoria: 'bebidas',
    imagen_url: 'https://images.unsplash.com/photo-1581006852262-e4307cf6283a?w=400',
    disponible: true
  },
  {
    id: '7',
    nombre: 'Jugo de Naranja',
    descripcion: 'Jugo de naranja natural recién exprimido',
    precio: 6.00,
    categoria: 'bebidas',
    imagen_url: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400',
    disponible: true
  },
  {
    id: '8',
    nombre: 'Limonada',
    descripcion: 'Limonada helada con hierbabuena',
    precio: 5.50,
    categoria: 'bebidas',
    imagen_url: 'https://images.unsplash.com/photo-1523677011781-c91d1bbe2f9d?w=400',
    disponible: true
  },
  // Cafés
  {
    id: '9',
    nombre: 'Café Americano',
    descripcion: 'Café americano caliente',
    precio: 4.50,
    categoria: 'cafes',
    imagen_url: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400',
    disponible: true
  },
  {
    id: '10',
    nombre: 'Cappuccino',
    descripcion: 'Cappuccino cremoso con espuma de leche',
    precio: 6.00,
    categoria: 'cafes',
    imagen_url: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400',
    disponible: true
  },
  {
    id: '11',
    nombre: 'Latte',
    descripcion: 'Café latte con leche vaporizada',
    precio: 6.50,
    categoria: 'cafes',
    imagen_url: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
    disponible: true
  },
  {
    id: '12',
    nombre: 'Espresso',
    descripcion: 'Espresso doble intenso',
    precio: 5.00,
    categoria: 'cafes',
    imagen_url: 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400',
    disponible: true
  },
  // DXN
  {
    id: '13',
    nombre: 'Ganoderma Coffee',
    descripcion: 'Café con extracto de Ganoderma Lucidum',
    precio: 12.00,
    categoria: 'dxn',
    disponible: true
  },
  {
    id: '14',
    nombre: 'Spirulina',
    descripcion: 'Suplemento de Spirulina en tabletas',
    precio: 45.00,
    categoria: 'dxn',
    disponible: true
  },
  {
    id: '15',
    nombre: 'Morinzhi',
    descripcion: 'Jugo de Noni concentrado',
    precio: 35.00,
    categoria: 'dxn',
    disponible: true
  },
  {
    id: '16',
    nombre: 'Lingzhi Coffee 3 en 1',
    descripcion: 'Café instantáneo con Ganoderma',
    precio: 15.00,
    categoria: 'dxn',
    disponible: true
  },
];

// Cargar productos (por ahora usamos datos de ejemplo)
const cargarProductos = async () => {
  try {
    loading.value = true;
    // TODO: Descomentar cuando la tabla productos esté lista
    // const { data, error } = await supabase
    //   .from('productos')
    //   .select('*')
    //   .eq('disponible', true);
    // if (error) throw error;
    // productos.value = data;
    
    // Por ahora usamos datos de ejemplo
    productos.value = productosEjemplo;
  } catch (err) {
    console.error('Error cargando productos:', err);
  } finally {
    loading.value = false;
  }
};

// Productos filtrados por categoría
const productosFiltrados = computed(() => {
  return productos.value.filter(p => p.categoria === categoriaActiva.value);
});

// Agregar producto al pedido
const agregarProducto = (producto: Producto) => {
  const itemExistente = pedidoActual.value.find(item => item.producto.id === producto.id);
  
  if (itemExistente) {
    itemExistente.cantidad++;
  } else {
    pedidoActual.value.push({
      producto,
      cantidad: 1
    });
  }
};

// Agregar producto con cantidad específica
const agregarProductoConCantidad = (producto: Producto, cantidad: number) => {
  const itemExistente = pedidoActual.value.find(item => item.producto.id === producto.id);
  
  if (itemExistente) {
    itemExistente.cantidad += cantidad;
  } else {
    pedidoActual.value.push({
      producto,
      cantidad
    });
  }
};

// Quitar producto del pedido
const quitarProducto = (productoId: string) => {
  const index = pedidoActual.value.findIndex(item => item.producto.id === productoId);
  if (index !== -1) {
    if (pedidoActual.value[index].cantidad > 1) {
      pedidoActual.value[index].cantidad--;
    } else {
      pedidoActual.value.splice(index, 1);
    }
  }
};

// Eliminar producto completamente
const eliminarProducto = (productoId: string) => {
  pedidoActual.value = pedidoActual.value.filter(item => item.producto.id !== productoId);
};

// Total del pedido
const totalPedido = computed(() => {
  return pedidoActual.value.reduce((sum, item) => sum + (item.producto.precio * item.cantidad), 0);
});

// Cantidad total de items
const cantidadTotal = computed(() => {
  return pedidoActual.value.reduce((sum, item) => sum + item.cantidad, 0);
});

// Guardar pedido
const guardarPedido = async () => {
  if (pedidoActual.value.length === 0) {
    alert('Agrega productos al pedido');
    return;
  }
  
  // TODO: Implementar guardado en Supabase
  console.log('Guardando pedido:', {
    mesa: mesaNumero.value,
    cliente: nombreCliente.value,
    items: pedidoActual.value,
    total: totalPedido.value
  });
  
  alert('Pedido guardado exitosamente!');
  limpiarPedido();
};

// Limpiar pedido
const limpiarPedido = () => {
  pedidoActual.value = [];
  mesaNumero.value = null;
  nombreCliente.value = '';
  mostrarResumen.value = false;
};

// Categorías con iconos
const categorias = [
  { id: 'comidas', nombre: 'Comidas', icon: 'mdi:food' },
  { id: 'cafes', nombre: 'Cafés', icon: 'mdi:coffee' },
  { id: 'bebidas', nombre: 'Bebidas', icon: 'mdi:cup' },
  { id: 'dxn', nombre: 'DXN', icon: 'mdi:leaf' },
];

// Cargar productos al montar
cargarProductos();
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-amber-50 via-orange-50 to-yellow-50">
    <!-- Header igual a Mesas -->
    <header class="bg-gradient-to-r from-amber-900 via-amber-800 to-yellow-800 px-4 py-6 shadow-lg">
      <div class="mx-auto max-w-7xl">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <a href="/" class="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 backdrop-blur-sm transition-colors hover:bg-white/30">
              <Icon icon="mdi:arrow-left" class="h-6 w-6 text-white" />
            </a>
            <div>
              <h1 class="text-2xl font-bold text-white sm:text-3xl">Anotar Pedido</h1>
              <p class="mt-1 text-sm text-amber-100">Selecciona productos del menú</p>
            </div>
          </div>
          
          <!-- Botón carrito -->
          <button
            @click="mostrarCarrito = !mostrarCarrito"
            class="relative flex items-center gap-2 rounded-lg bg-white/20 px-4 py-2.5 backdrop-blur-sm transition-colors hover:bg-white/30"
          >
            <Icon icon="mdi:cart" class="h-6 w-6 text-white" />
            <span class="hidden sm:inline font-semibold text-white">Carrito</span>
            <span v-if="cantidadTotal > 0" class="absolute -top-2 -right-2 flex h-6 w-6 items-center justify-center rounded-full bg-red-500 text-xs font-bold shadow-lg animate-pulse">
              {{ cantidadTotal }}
            </span>
          </button>
        </div>
      </div>
    </header>

    <!-- Contenedor principal -->
    <div class="mx-auto max-w-7xl px-4 py-6">
      <!-- Tabs de categorías - Full Width Profesional -->
      <div class="mb-6">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 rounded-xl bg-white p-3 shadow-lg border border-gray-200">
          <button
            v-for="categoria in categorias"
            :key="categoria.id"
            @click="categoriaActiva = categoria.id as any"
            class="flex items-center justify-center gap-2.5 rounded-lg px-6 py-4 text-sm font-bold transition-all duration-200 border-2"
            :class="[
              categoriaActiva === categoria.id
                ? 'bg-amber-100 text-amber-900 border-amber-500 shadow-md scale-105'
                : 'bg-gray-50 text-gray-700 border-gray-300 hover:border-amber-400 hover:bg-amber-50 hover:scale-102'
            ]"
          >
            <Icon 
              :icon="categoria.icon" 
              class="h-6 w-6"
              :class="[
                categoriaActiva === categoria.id
                  ? 'text-amber-900'
                  : 'text-gray-600'
              ]"
            />
            <span class="text-base">{{ categoria.nombre }}</span>
          </button>
        </div>
      </div>

      <!-- Lista de productos compacta -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="h-10 w-10 animate-spin rounded-full border-4 border-amber-600 border-t-transparent"></div>
      </div>

      <div v-else class="space-y-4">
            <!-- Producto card mejorado para móvil -->
            <div
              v-for="producto in productosFiltrados"
              :key="producto.id"
              class="rounded-lg bg-white p-3 shadow-md border border-gray-200 transition-all active:scale-98 active:shadow-lg"
            >
              <div class="flex items-center gap-2.5 mb-2.5">
                <!-- Imagen redonda -->
                <div class="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-full bg-gradient-to-br from-amber-100 to-orange-100 ring-2 ring-amber-200">
                  <img
                    v-if="producto.imagen_url"
                    :src="producto.imagen_url"
                    :alt="producto.nombre"
                    class="h-full w-full object-cover"
                  />
                  <Icon v-else icon="mdi:food" class="h-7 w-7 text-amber-700" />
                </div>

                <!-- Info del producto -->
                <div class="flex-1 min-w-0">
                  <h3 class="text-sm font-bold text-gray-900 leading-tight">{{ producto.nombre }}</h3>
                  <p class="text-xs text-gray-500 mt-0.5 truncate">{{ producto.descripcion }}</p>
                  <div class="mt-1 flex items-center gap-2">
                    <span class="text-xl font-bold text-amber-600">S/ {{ producto.precio.toFixed(2) }}</span>
                  </div>
                </div>
              </div>

              <!-- Controles de cantidad - Full width para móvil -->
              <div class="flex gap-1.5">
                <!-- Botones de cantidad rápida -->
                <button
                  @click="agregarProductoConCantidad(producto, 1)"
                  class="flex-1 flex items-center justify-center gap-1 rounded-md bg-amber-100 text-amber-800 py-2.5 text-xs font-bold transition-all active:bg-amber-600 active:text-white active:scale-95"
                >
                  <Icon icon="mdi:numeric-1-circle" class="h-4 w-4" />
                  <span>×1</span>
                </button>
                <button
                  @click="agregarProductoConCantidad(producto, 2)"
                  class="flex-1 flex items-center justify-center gap-1 rounded-md bg-amber-100 text-amber-800 py-2.5 text-xs font-bold transition-all active:bg-amber-600 active:text-white active:scale-95"
                >
                  <Icon icon="mdi:numeric-2-circle" class="h-4 w-4" />
                  <span>×2</span>
                </button>
                <button
                  @click="agregarProductoConCantidad(producto, 3)"
                  class="flex-1 flex items-center justify-center gap-1 rounded-md bg-amber-100 text-amber-800 py-2.5 text-xs font-bold transition-all active:bg-amber-600 active:text-white active:scale-95"
                >
                  <Icon icon="mdi:numeric-3-circle" class="h-4 w-4" />
                  <span>×3</span>
                </button>
                
                <!-- Botón agregar principal -->
                <button
                  @click="agregarProducto(producto)"
                  class="flex-1 flex items-center justify-center gap-1.5 rounded-md bg-green-600 py-2.5 text-xs font-bold text-white transition-all active:bg-green-700 active:scale-95 shadow-sm"
                >
                  <Icon icon="mdi:plus-circle" class="h-4 w-4" />
                  <span>Agregar</span>
                </button>
              </div>
            </div>

        <!-- Mensaje si no hay productos -->
        <div v-if="productosFiltrados.length === 0" class="py-12 text-center">
          <Icon icon="mdi:food-off" class="mx-auto h-12 w-12 text-gray-400" />
          <p class="mt-3 text-gray-600">No hay productos en esta categoría</p>
        </div>
      </div>
    </div>

    <!-- Componente del Carrito (sidebar derecho) -->
    <CarritoPedido
      :pedidoActual="pedidoActual"
      :mesaNumero="mesaNumero"
      :nombreCliente="nombreCliente"
      :mostrarCarrito="mostrarCarrito"
      @update:mesaNumero="mesaNumero = $event"
      @update:nombreCliente="nombreCliente = $event"
      @update:mostrarCarrito="mostrarCarrito = $event"
      @agregarProducto="agregarProducto"
      @quitarProducto="quitarProducto"
      @eliminarProducto="eliminarProducto"
      @guardarPedido="guardarPedido"
      @limpiarPedido="limpiarPedido"
    />
  </div>
</template>

<style scoped>
/* Animaciones y estilos adicionales */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
