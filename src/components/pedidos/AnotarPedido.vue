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
  subcategoria?: 'platos' | 'salchipapas' | 'sandwich' | 'hamburguesas';
  imagen_url?: string;
  disponible: boolean;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
}

// Estado
const categoriaActiva = ref<'comidas' | 'cafes' | 'bebidas' | 'dxn'>('comidas');
const subcategoriaActiva = ref<'platos' | 'salchipapas' | 'sandwich' | 'hamburguesas' | null>('platos');
const productos = ref<Producto[]>([]);
const pedidoActual = ref<ItemPedido[]>([]);
const loading = ref(true);
const mesaNumero = ref<number | null>(null);
const nombreCliente = ref('');
const mostrarResumen = ref(false);
const mostrarCarrito = ref(false); // Controla visibilidad del menú lateral
const tipoPedido = ref<'para_servir' | 'para_llevar' | 'delivery' | null>('para_servir');
const telefono = ref('');
const direccion = ref('');

// Productos de ejemplo (reemplazar con datos de Supabase)
const productosEjemplo: Producto[] = [
  // Comidas - Platos
  {
    id: '1',
    nombre: 'Arroz con Pollo',
    descripcion: 'Delicioso arroz con pollo a la olla con papas y ensalada',
    precio: 15.00,
    categoria: 'comidas',
    subcategoria: 'platos',
    disponible: true
  },
  {
    id: '2',
    nombre: 'Lomo Saltado',
    descripcion: 'Carne de res salteada con cebolla, tomate y papas fritas',
    precio: 18.00,
    categoria: 'comidas',
    subcategoria: 'platos',
    disponible: true
  },
  {
    id: '3',
    nombre: 'Ají de Gallina',
    descripcion: 'Pollo deshilachado en salsa de ají amarillo con papas',
    precio: 16.00,
    categoria: 'comidas',
    subcategoria: 'platos',
    disponible: true
  },
  {
    id: '4',
    nombre: 'Ceviche',
    descripcion: 'Ceviche de pescado fresco con camote y choclo',
    precio: 20.00,
    categoria: 'comidas',
    subcategoria: 'platos',
    disponible: true
  },
  // Comidas - Salchipapas
  {
    id: '17',
    nombre: 'Salchipapa Clásica',
    descripcion: 'Papas fritas con salchicha, cremas y ensalada',
    precio: 10.00,
    categoria: 'comidas',
    subcategoria: 'salchipapas',
    disponible: true
  },
  {
    id: '18',
    nombre: 'Salchipapa Especial',
    descripcion: 'Papas fritas, salchicha, huevo frito, queso y cremas',
    precio: 14.00,
    categoria: 'comidas',
    subcategoria: 'salchipapas',
    disponible: true
  },
  {
    id: '19',
    nombre: 'Salchipapa Mixta',
    descripcion: 'Papas fritas con salchicha, pollo y carne',
    precio: 16.00,
    categoria: 'comidas',
    subcategoria: 'salchipapas',
    disponible: true
  },
  // Comidas - Sandwich
  {
    id: '20',
    nombre: 'Sandwich de Pollo',
    descripcion: 'Pan con pollo deshilachado, lechuga, tomate y mayonesa',
    precio: 8.00,
    categoria: 'comidas',
    subcategoria: 'sandwich',
    disponible: true
  },
  {
    id: '21',
    nombre: 'Sandwich Triple',
    descripcion: 'Pan triple con jamón, queso, huevo, tomate y palta',
    precio: 10.00,
    categoria: 'comidas',
    subcategoria: 'sandwich',
    disponible: true
  },
  {
    id: '22',
    nombre: 'Sandwich de Lomo',
    descripcion: 'Pan con lomo saltado, cebolla y ají',
    precio: 12.00,
    categoria: 'comidas',
    subcategoria: 'sandwich',
    disponible: true
  },
  // Comidas - Hamburguesas
  {
    id: '23',
    nombre: 'Hamburguesa Clásica',
    descripcion: 'Carne de res, lechuga, tomate, cebolla y papas',
    precio: 12.00,
    categoria: 'comidas',
    subcategoria: 'hamburguesas',
    disponible: true
  },
  {
    id: '24',
    nombre: 'Hamburguesa Doble',
    descripcion: 'Doble carne, doble queso, tocino y papas',
    precio: 18.00,
    categoria: 'comidas',
    subcategoria: 'hamburguesas',
    disponible: true
  },
  {
    id: '25',
    nombre: 'Hamburguesa de Pollo',
    descripcion: 'Pechuga de pollo empanizada, lechuga y mayonesa',
    precio: 14.00,
    categoria: 'comidas',
    subcategoria: 'hamburguesas',
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

// Productos filtrados por categoría y subcategoría
const productosFiltrados = computed(() => {
  let filtered = productos.value.filter(p => p.categoria === categoriaActiva.value);
  
  // Si estamos en comidas y hay subcategoría activa, filtrar por subcategoría
  if (categoriaActiva.value === 'comidas' && subcategoriaActiva.value) {
    filtered = filtered.filter(p => p.subcategoria === subcategoriaActiva.value);
  }
  
  return filtered;
});

// Subcategorías de comidas
const subcategorias = [
  { id: 'platos', nombre: 'Platos', icon: 'mdi:silverware-fork-knife' },
  { id: 'salchipapas', nombre: 'Salchipapas', icon: 'mdi:french-fries' },
  { id: 'sandwich', nombre: 'Sandwich', icon: 'mdi:food-croissant' },
  { id: 'hamburguesas', nombre: 'Hamburguesas', icon: 'mdi:hamburger' },
];

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
  
  // Validación obligatoria del tipo de pedido
  if (!tipoPedido.value) {
    alert('Por favor, selecciona el tipo de pedido (Para Servir, Para Llevar o Delivery)');
    return;
  }
  
  // Validaciones específicas según el tipo de pedido
  if (tipoPedido.value === 'para_servir' && !mesaNumero.value) {
    alert('Para servir en mesa, por favor selecciona una mesa');
    return;
  }
  
  if ((tipoPedido.value === 'para_llevar' || tipoPedido.value === 'delivery') && !nombreCliente.value.trim()) {
    alert('Para llevar o delivery, el nombre del cliente es obligatorio');
    return;
  }
  
  if (tipoPedido.value === 'delivery') {
    if (!telefono.value.trim()) {
      alert('Para delivery, el teléfono es obligatorio');
      return;
    }
    if (!direccion.value.trim()) {
      alert('Para delivery, la dirección es obligatoria');
      return;
    }
  }
  
  try {
    // Preparar datos del pedido
    const pedidoData = {
      tipo_pedido: tipoPedido.value,
      mesa_numero: mesaNumero.value,
      nombre_cliente: nombreCliente.value || null,
      telefono: telefono.value || null,
      direccion: direccion.value || null,
      items: pedidoActual.value.map(item => ({
        producto_id: item.producto.id,
        cantidad: item.cantidad,
        precio_unitario: item.producto.precio,
        subtotal: item.producto.precio * item.cantidad
      })),
      total: totalPedido.value,
      estado: 'pendiente',
      fecha: new Date().toISOString()
    };
    
    // TODO: Descomentar cuando la tabla pedidos esté lista en Supabase
    // const { data, error } = await supabase
    //   .from('pedidos')
    //   .insert([pedidoData])
    //   .select();
    
    // if (error) {
    //   console.error('Error guardando pedido:', error);
    //   alert('Error al guardar el pedido. Por favor, intenta nuevamente.');
    //   return;
    // }
    
    // Simulación exitosa por ahora
    console.log('Pedido guardado exitosamente:', pedidoData);
    
    // Limpiar formulario
    limpiarPedido();
    
    // Redirigir a página de pedidos
    handleRedirectToPedidos();
    
  } catch (error) {
    console.error('Error inesperado:', error);
    alert('Ocurrió un error inesperado. Por favor, intenta nuevamente.');
  }
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

// Redirigir a página de pedidos
const handleRedirectToPedidos = () => {
  window.location.href = '/pedidos';
};
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-amber-50 via-orange-50 to-yellow-50">
    <!-- Header Profesional -->
    <header class="header-container relative overflow-hidden px-4 py-4 shadow-2xl sm:px-6 sm:py-5">
      <!-- Animated Background -->
      <div class="header-bg"></div>
      <div class="header-particles">
        <div class="particle particle-1"></div>
        <div class="particle particle-2"></div>
        <div class="particle particle-3"></div>
      </div>

      <div class="relative z-10 mx-auto max-w-7xl">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3 sm:gap-4">
            <a href="/" class="back-button">
              <Icon icon="mdi:arrow-left" class="h-5 w-5 sm:h-6 sm:w-6 text-white" />
            </a>
            <div class="header-title-container">
              <h1 class="header-title">Anotar Pedido</h1>
              <p class="header-subtitle">Selecciona productos del menú</p>
            </div>
          </div>
          
          <!-- Botón carrito -->
          <button
            @click="mostrarCarrito = !mostrarCarrito"
            class="cart-button"
          >
            <Icon icon="mdi:cart" class="h-5 w-5 sm:h-6 sm:w-6 text-white" />
            <span class="hidden sm:inline font-semibold text-white">Carrito</span>
            <span v-if="cantidadTotal > 0" class="cart-badge">
              {{ cantidadTotal }}
            </span>
          </button>
        </div>
      </div>
    </header>

    <!-- Contenedor principal -->
    <div class="mx-auto max-w-7xl px-4 py-6">
      <!-- Tabs de categorías -->
      <div class="categories-container">
        <div class="categories-grid">
          <button
            v-for="categoria in categorias"
            :key="categoria.id"
            @click="categoriaActiva = categoria.id as any; subcategoriaActiva = categoria.id === 'comidas' ? 'platos' : null"
            class="category-tab"
            :class="{ 'category-tab-active': categoriaActiva === categoria.id }"
          >
            <div class="category-icon-wrapper" :class="{ 'category-icon-active': categoriaActiva === categoria.id }">
              <Icon :icon="categoria.icon" class="category-icon" />
            </div>
            <span class="category-name">{{ categoria.nombre }}</span>
          </button>
        </div>
      </div>

      <!-- Subcategorías de Comidas -->
      <div v-if="categoriaActiva === 'comidas'" class="subcategories-container">
        <div class="subcategories-scroll">
          <button
            v-for="sub in subcategorias"
            :key="sub.id"
            @click="subcategoriaActiva = sub.id as any"
            class="subcategory-tab"
            :class="{ 'subcategory-tab-active': subcategoriaActiva === sub.id }"
          >
            <Icon :icon="sub.icon" class="subcategory-icon" />
            <span>{{ sub.nombre }}</span>
          </button>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-12">
        <div class="loading-spinner"></div>
      </div>

      <!-- Lista de productos -->
      <div v-else class="products-grid">
        <div
          v-for="(producto, index) in productosFiltrados"
          :key="producto.id"
          class="product-card"
          :style="{ animationDelay: `${index * 0.05}s` }"
        >
          <div class="product-header">
            <!-- Imagen -->
            <div class="product-image-wrapper">
              <img
                v-if="producto.imagen_url"
                :src="producto.imagen_url"
                :alt="producto.nombre"
                class="product-image"
              />
              <Icon v-else icon="mdi:food" class="product-image-placeholder" />
            </div>

            <!-- Info del producto -->
            <div class="product-info">
              <h3 class="product-name">{{ producto.nombre }}</h3>
              <p class="product-description">{{ producto.descripcion }}</p>
              <div class="product-price">S/ {{ producto.precio.toFixed(2) }}</div>
            </div>
          </div>

          <!-- Controles de cantidad -->
          <div class="product-actions">
            <button
              @click="agregarProductoConCantidad(producto, 1)"
              class="qty-button"
            >
              <span class="qty-number">1</span>
            </button>
            <button
              @click="agregarProductoConCantidad(producto, 2)"
              class="qty-button"
            >
              <span class="qty-number">2</span>
            </button>
            <button
              @click="agregarProductoConCantidad(producto, 3)"
              class="qty-button"
            >
              <span class="qty-number">3</span>
            </button>
            
            <button
              @click="agregarProducto(producto)"
              class="add-button"
            >
              <Icon icon="mdi:plus" class="h-5 w-5" />
              <span>Agregar</span>
            </button>
          </div>
        </div>

        <!-- Mensaje si no hay productos -->
        <div v-if="productosFiltrados.length === 0" class="empty-state">
          <div class="empty-icon-wrapper">
            <Icon icon="mdi:food-off" class="empty-icon" />
          </div>
          <p class="empty-text">No hay productos en esta categoría</p>
        </div>
      </div>
    </div>

    <!-- Componente del Carrito (sidebar derecho) -->
    <CarritoPedido
      :pedidoActual="pedidoActual"
      :mesaNumero="mesaNumero"
      :nombreCliente="nombreCliente"
      :mostrarCarrito="mostrarCarrito"
      :tipoPedido="tipoPedido"
      :telefono="telefono"
      :direccion="direccion"
      @update:mesaNumero="mesaNumero = $event"
      @update:nombreCliente="nombreCliente = $event"
      @update:mostrarCarrito="mostrarCarrito = $event"
      @update:tipoPedido="tipoPedido = $event"
      @update:telefono="telefono = $event"
      @update:direccion="direccion = $event"
      @agregarProducto="agregarProducto"
      @quitarProducto="quitarProducto"
      @eliminarProducto="eliminarProducto"
      @guardarPedido="guardarPedido"
      @limpiarPedido="limpiarPedido"
      @redirectToPedidos="handleRedirectToPedidos"
    />
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
  width: 80px;
  height: 80px;
  top: -20px;
  left: -20px;
  animation: float1 6s ease-in-out infinite;
}

.particle-2 {
  width: 50px;
  height: 50px;
  bottom: 10px;
  right: 20%;
  animation: float2 8s ease-in-out infinite;
}

.particle-3 {
  width: 30px;
  height: 30px;
  top: 50%;
  right: -10px;
  animation: float3 7s ease-in-out infinite;
}

@keyframes float1 {
  0%, 100% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(15px, 15px) scale(1.1); }
}

@keyframes float2 {
  0%, 100% { transform: translate(0, 0) rotate(0deg); }
  50% { transform: translate(-10px, -8px) rotate(180deg); }
}

@keyframes float3 {
  0%, 100% { transform: translate(0, 0); }
  50% { transform: translate(-8px, 10px); }
}

.back-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.back-button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateX(-3px);
}

.header-title-container {
  animation: slideIn 0.5s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(-20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.header-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 10px rgba(0,0,0,0.2);
}

@media (min-width: 640px) {
  .header-title { font-size: 1.875rem; }
}

.header-subtitle {
  font-size: 0.75rem;
  color: rgba(255, 237, 213, 0.9);
  margin-top: 2px;
}

@media (min-width: 640px) {
  .header-subtitle { font-size: 0.875rem; }
}

.cart-button {
  position: relative;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255,255,255,0.3);
  transition: all 0.3s ease;
}

.cart-button:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.05);
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
}

.cart-badge {
  position: absolute;
  top: -8px;
  right: -8px;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ef4444;
  color: white;
  font-size: 0.75rem;
  font-weight: 700;
  border-radius: 50%;
  box-shadow: 0 2px 8px rgba(239, 68, 68, 0.5);
  animation: badgePulse 2s ease-in-out infinite;
}

@keyframes badgePulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

/* ========== CATEGORIES ========== */
.categories-container {
  margin-bottom: 24px;
  animation: fadeInUp 0.5s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.categories-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  padding: 10px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08);
}

.category-tab {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding: 8px 6px;
  border-radius: 10px;
  background: #f9fafb;
  border: 2px solid transparent;
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

@media (min-width: 640px) {
  .categories-grid {
    gap: 12px;
    padding: 16px;
  }
  
  .category-tab {
    gap: 8px;
    padding: 14px 12px;
  }
}

.category-tab:hover {
  background: #fef3c7;
  border-color: #fbbf24;
  transform: translateY(-4px);
}

.category-tab-active {
  background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
  border-color: #f59e0b;
  box-shadow: 0 4px 15px rgba(245, 158, 11, 0.3);
  transform: translateY(-4px) scale(1.02);
}

.category-icon-wrapper {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #e5e7eb;
  transition: all 0.3s ease;
}

@media (min-width: 640px) {
  .category-icon-wrapper {
    width: 44px;
    height: 44px;
  }
}

.category-tab:hover .category-icon-wrapper {
  background: #fbbf24;
}

.category-icon-active {
  background: #f59e0b !important;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.4);
}

.category-icon {
  width: 16px;
  height: 16px;
  color: #6b7280;
  transition: all 0.3s ease;
}

@media (min-width: 640px) {
  .category-icon {
    width: 22px;
    height: 22px;
  }
}

.category-tab:hover .category-icon,
.category-icon-active .category-icon {
  color: white;
}

.category-name {
  font-size: 0.65rem;
  font-weight: 600;
  color: #374151;
  transition: color 0.3s ease;
}

@media (min-width: 640px) {
  .category-name {
    font-size: 0.875rem;
  }
}

.category-tab-active .category-name {
  color: #92400e;
}

/* ========== SUBCATEGORIES ========== */
.subcategories-container {
  margin-bottom: 16px;
  animation: fadeInUp 0.4s ease-out;
}

.subcategories-scroll {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 4px;
  -webkit-overflow-scrolling: touch;
  scrollbar-width: none;
}

.subcategories-scroll::-webkit-scrollbar {
  display: none;
}

.subcategory-tab {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  border-radius: 20px;
  background: white;
  border: 2px solid #e5e7eb;
  font-size: 0.75rem;
  font-weight: 600;
  color: #6b7280;
  white-space: nowrap;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0,0,0,0.05);
}

.subcategory-tab:hover {
  border-color: #f59e0b;
  color: #92400e;
  background: #fffbeb;
}

.subcategory-tab-active {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  border-color: #f59e0b;
  color: white;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.3);
}

.subcategory-icon {
  width: 16px;
  height: 16px;
}

@media (min-width: 640px) {
  .subcategory-tab {
    padding: 10px 18px;
    font-size: 0.8rem;
    gap: 8px;
  }
  
  .subcategory-icon {
    width: 18px;
    height: 18px;
  }
}

/* ========== LOADING ========== */
.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #fef3c7;
  border-top-color: #f59e0b;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ========== PRODUCTS GRID ========== */
.products-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.product-card {
  background: white;
  border-radius: 16px;
  padding: 16px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.08);
  border: 1px solid #f3f4f6;
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  animation: cardFadeIn 0.5s ease-out both;
}

@keyframes cardFadeIn {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.product-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 30px rgba(0,0,0,0.12);
  border-color: #fbbf24;
}

.product-card:active {
  transform: scale(0.98);
}

.product-header {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 14px;
}

.product-image-wrapper {
  width: 64px;
  height: 64px;
  flex-shrink: 0;
  border-radius: 50%;
  overflow: hidden;
  background: linear-gradient(135deg, #fef3c7 0%, #fed7aa 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(245, 158, 11, 0.2);
  transition: all 0.3s ease;
}

.product-card:hover .product-image-wrapper {
  transform: scale(1.1) rotate(5deg);
}

.product-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-image-placeholder {
  width: 32px;
  height: 32px;
  color: #92400e;
}

.product-info {
  flex: 1;
  min-width: 0;
}

.product-name {
  font-size: 1rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 4px;
  line-height: 1.3;
}

.product-description {
  font-size: 0.75rem;
  color: #6b7280;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.product-price {
  font-size: 1.25rem;
  font-weight: 800;
  color: #f59e0b;
  margin-top: 6px;
}

/* ========== PRODUCT ACTIONS ========== */
.product-actions {
  display: flex;
  gap: 8px;
}

.qty-button {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px 8px;
  border-radius: 10px;
  background: #fef3c7;
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.qty-button:hover {
  background: #fde68a;
  transform: translateY(-2px);
}

.qty-button:active {
  background: #f59e0b;
  transform: scale(0.95);
}

.qty-button:active .qty-number {
  color: white;
}

.qty-number {
  font-size: 1rem;
  font-weight: 700;
  color: #92400e;
  transition: color 0.2s ease;
}

.add-button {
  flex: 1.5;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 12px 16px;
  border-radius: 10px;
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  color: white;
  font-weight: 700;
  font-size: 0.875rem;
  border: none;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(34, 197, 94, 0.3);
  transition: all 0.3s ease;
}

.add-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(34, 197, 94, 0.4);
}

.add-button:active {
  transform: scale(0.95);
}

/* ========== EMPTY STATE ========== */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 48px 24px;
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.empty-icon-wrapper {
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f3f4f6;
  border-radius: 50%;
  margin-bottom: 16px;
}

.empty-icon {
  width: 40px;
  height: 40px;
  color: #9ca3af;
}

.empty-text {
  font-size: 1rem;
  color: #6b7280;
}

/* ========== LINE CLAMP ========== */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
