<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';
import confetti from 'canvas-confetti';
import CarritoPedido from './CarritoPedido.vue';

interface Categoria {
  id: string;
  nombre: string;
  slug: string;
  icono: string;
  orden: number;
  activo: boolean;
}

interface Subcategoria {
  id: string;
  categoria_id: string;
  nombre: string;
  slug: string;
  icono: string;
  orden: number;
  activo: boolean;
}

interface Producto {
  id: string;
  nombre: string;
  descripcion: string;
  precio: number;
  categoria_id: string;
  subcategoria_id: string | null;
  imagen_url?: string;
  disponible: boolean;
  destacado: boolean;
  categorias?: Categoria;
  subcategorias?: Subcategoria;
}

interface Modificador {
  id: string;
  nombre: string;
  descripcion: string | null;
  tipo: 'extra' | 'sin' | 'sustitucion';
  precio_adicional: number;
  categoria_id: string | null;
  activo: boolean;
}

interface ItemModificador {
  modificador: Modificador;
  cantidad: number;
}

interface ItemPedido {
  producto: Producto;
  cantidad: number;
  modificadores?: ItemModificador[];
}

// Estado
const categorias = ref<Categoria[]>([]);
const subcategorias = ref<Subcategoria[]>([]);
const categoriaActiva = ref<string>('');
const subcategoriaActiva = ref<string | null>(null);
const productos = ref<Producto[]>([]);
const pedidoActual = ref<ItemPedido[]>([]);
const loading = ref(true);
const guardandoPedido = ref(false);
const mesaNumero = ref<number | null>(null);
const nombreCliente = ref('');
const mostrarResumen = ref(false);
const mostrarCarrito = ref(false);
const tipoPedido = ref<'para_servir' | 'para_llevar' | 'delivery' | null>('para_servir');
const telefono = ref('');
const direccion = ref('');

// Cargar categorías desde Supabase
const cargarCategorias = async () => {
  try {
    const { data, error } = await supabase
      .from('categorias')
      .select('*')
      .eq('activo', true)
      .order('orden');

    if (error) throw error;
    categorias.value = data || [];
    
    // Seleccionar primera categoría por defecto
    if (categorias.value.length > 0) {
      categoriaActiva.value = categorias.value[0].id;
    }
  } catch (err) {
    console.error('Error cargando categorías:', err);
  }
};

// Cargar subcategorías desde Supabase
const cargarSubcategorias = async () => {
  try {
    const { data, error } = await supabase
      .from('subcategorias')
      .select('*')
      .eq('activo', true)
      .order('orden');

    if (error) throw error;
    subcategorias.value = data || [];
  } catch (err) {
    console.error('Error cargando subcategorías:', err);
  }
};

// Cargar productos desde Supabase
const cargarProductos = async () => {
  try {
    loading.value = true;
    const { data, error } = await supabase
      .from('productos')
      .select(`
        *,
        categorias(id, nombre, slug, icono),
        subcategorias(id, nombre, slug, icono)
      `)
      .eq('disponible', true)
      .order('orden');

    if (error) throw error;
    productos.value = data || [];
  } catch (err) {
    console.error('Error cargando productos:', err);
  } finally {
    loading.value = false;
  }
};

// Cargar todos los datos
const cargarDatos = async () => {
  loading.value = true;
  await Promise.all([
    cargarCategorias(),
    cargarSubcategorias(),
    cargarProductos()
  ]);
  
  // Seleccionar primera subcategoría de la categoría activa
  const subcatsDeCategoriaActiva = subcategoriasFiltradas.value;
  if (subcatsDeCategoriaActiva.length > 0) {
    subcategoriaActiva.value = subcatsDeCategoriaActiva[0].id;
  }
  
  loading.value = false;
};

// Subcategorías filtradas por categoría activa
const subcategoriasFiltradas = computed(() => {
  return subcategorias.value.filter(s => s.categoria_id === categoriaActiva.value);
});

// Verificar si la categoría activa tiene subcategorías
const categoriaActivaTieneSubcategorias = computed(() => {
  return subcategoriasFiltradas.value.length > 0;
});

// Productos filtrados por categoría y subcategoría
const productosFiltrados = computed(() => {
  let filtered = productos.value.filter(p => p.categoria_id === categoriaActiva.value);
  
  // Si hay subcategorías y una está activa, filtrar por subcategoría
  if (categoriaActivaTieneSubcategorias.value && subcategoriaActiva.value) {
    filtered = filtered.filter(p => p.subcategoria_id === subcategoriaActiva.value);
  }
  
  return filtered;
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

// Total del pedido (incluyendo modificadores)
const totalPedido = computed(() => {
  return pedidoActual.value.reduce((sum, item) => {
    const precioBase = item.producto.precio * item.cantidad;
    const precioModificadores = (item.modificadores || []).reduce(
      (modSum, mod) => modSum + (mod.modificador.precio_adicional * mod.cantidad * item.cantidad), 0
    );
    return sum + precioBase + precioModificadores;
  }, 0);
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
    guardandoPedido.value = true;
    
    console.log('=== INICIANDO GUARDADO DE PEDIDO ===');
    console.log('Pedido actual:', JSON.stringify(pedidoActual.value, null, 2));
    console.log('Tipo de pedido:', tipoPedido.value);
    console.log('Mesa:', mesaNumero.value);
    console.log('Cliente:', nombreCliente.value);
    console.log('Total calculado:', totalPedido.value);
    
    // 1. Crear el pedido principal
    const { data: pedido, error: errorPedido } = await supabase
      .from('pedidos')
      .insert([{
        tipo_pedido: tipoPedido.value,
        mesa_numero: mesaNumero.value,
        nombre_cliente: nombreCliente.value || null,
        telefono: telefono.value || null,
        direccion: direccion.value || null,
        subtotal: totalPedido.value,
        total: totalPedido.value,
        estado: 'pendiente'
      }])
      .select()
      .single();

    if (errorPedido) {
      console.error('Error creando pedido:', errorPedido);
      alert('Error al crear el pedido. Por favor, intenta nuevamente.');
      return;
    }

    // 2. Crear los detalles del pedido y obtener sus IDs
    const detallesParaInsertar = pedidoActual.value.map(item => {
      // Calcular subtotal incluyendo modificadores
      const precioModificadores = (item.modificadores || []).reduce(
        (sum, mod) => sum + (mod.modificador.precio_adicional * mod.cantidad), 0
      );
      const subtotal = (item.producto.precio + precioModificadores) * item.cantidad;
      
      return {
        pedido_id: pedido.id,
        producto_id: item.producto.id,
        nombre_producto: item.producto.nombre,
        cantidad: item.cantidad,
        precio_unitario: item.producto.precio,
        subtotal: subtotal,
        notas: null
      };
    });

    console.log('Detalles a insertar:', JSON.stringify(detallesParaInsertar, null, 2));

    const { data: detallesInsertados, error: errorDetalle } = await supabase
      .from('pedido_detalle')
      .insert(detallesParaInsertar)
      .select();

    console.log('Respuesta de pedido_detalle:', { detallesInsertados, errorDetalle });

    if (errorDetalle || !detallesInsertados) {
      console.error('Error creando detalle:', errorDetalle);
      console.error('Detalles que se intentaron insertar:', detallesParaInsertar);
      await supabase.from('pedidos').delete().eq('id', pedido.id);
      alert(`Error al guardar los productos del pedido: ${errorDetalle?.message || 'Sin detalles'}`);
      return;
    }

    console.log('Detalles insertados exitosamente:', detallesInsertados);

    // 3. Crear los modificadores de cada detalle
    const modificadoresParaInsertar: any[] = [];
    
    pedidoActual.value.forEach((item, index) => {
      if (item.modificadores && item.modificadores.length > 0) {
        const detalleId = detallesInsertados[index].id;
        
        item.modificadores.forEach(mod => {
          modificadoresParaInsertar.push({
            pedido_detalle_id: detalleId,
            modificador_id: mod.modificador.id,
            nombre_modificador: mod.modificador.nombre,
            precio_adicional: mod.modificador.precio_adicional,
            cantidad: mod.cantidad
          });
        });
      }
    });

    if (modificadoresParaInsertar.length > 0) {
      const { error: errorModificadores } = await supabase
        .from('pedido_detalle_modificadores')
        .insert(modificadoresParaInsertar);

      if (errorModificadores) {
        console.error('Error guardando modificadores:', errorModificadores);
        // No es crítico, el pedido ya se guardó
      }
    }

    console.log('Pedido guardado exitosamente:', pedido);
    
    // 🎉 Confetti al guardar pedido
    confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
    setTimeout(() => {
      confetti({ particleCount: 50, angle: 60, spread: 55, origin: { x: 0 } });
      confetti({ particleCount: 50, angle: 120, spread: 55, origin: { x: 1 } });
    }, 250);
    
    // Limpiar formulario
    limpiarPedido();
    
    // Redirigir a página de pedidos después de mostrar confetti
    setTimeout(() => {
      handleRedirectToPedidos();
    }, 1500);
    
  } catch (error) {
    console.error('Error inesperado:', error);
    alert('Ocurrió un error inesperado. Por favor, intenta nuevamente.');
  } finally {
    guardandoPedido.value = false;
  }
};

// Limpiar pedido
const limpiarPedido = () => {
  pedidoActual.value = [];
  mesaNumero.value = null;
  nombreCliente.value = '';
  telefono.value = '';
  direccion.value = '';
  mostrarResumen.value = false;
  mostrarCarrito.value = false;
};

// Cambiar categoría
const cambiarCategoria = (categoriaId: string) => {
  categoriaActiva.value = categoriaId;
  // Seleccionar primera subcategoría de la nueva categoría
  const subcats = subcategorias.value.filter(s => s.categoria_id === categoriaId);
  subcategoriaActiva.value = subcats.length > 0 ? subcats[0].id : null;
};

// Redirigir a página de pedidos
const handleRedirectToPedidos = () => {
  window.location.href = '/pedidos';
};

// Leer parámetros de URL (mesa desde Mesas.vue)
const leerParametrosURL = () => {
  const urlParams = new URLSearchParams(window.location.search);
  const mesaParam = urlParams.get('mesa');
  if (mesaParam) {
    mesaNumero.value = parseInt(mesaParam);
    tipoPedido.value = 'para_servir';
  }
};

// Cargar datos al montar
onMounted(() => {
  leerParametrosURL();
  cargarDatos();
});
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
            @click="cambiarCategoria(categoria.id)"
            class="category-tab"
            :class="{ 'category-tab-active': categoriaActiva === categoria.id }"
          >
            <div class="category-icon-wrapper" :class="{ 'category-icon-active': categoriaActiva === categoria.id }">
              <Icon :icon="categoria.icono || 'mdi:food'" class="category-icon" />
            </div>
            <span class="category-name">{{ categoria.nombre }}</span>
          </button>
        </div>
      </div>

      <!-- Subcategorías (dinámicas según categoría) -->
      <div v-if="subcategoriasFiltradas.length > 0" class="subcategories-container">
        <div class="subcategories-scroll">
          <button
            v-for="sub in subcategoriasFiltradas"
            :key="sub.id"
            @click="subcategoriaActiva = sub.id"
            class="subcategory-tab"
            :class="{ 'subcategory-tab-active': subcategoriaActiva === sub.id }"
          >
            <Icon :icon="sub.icono || 'mdi:tag'" class="subcategory-icon" />
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
          :style="{ animationDelay: `${index * 0.03}s` }"
        >
          <!-- Imagen centrada arriba -->
          <div class="product-image-container">
            <div class="product-image-wrapper">
              <img
                v-if="producto.imagen_url"
                :src="producto.imagen_url"
                :alt="producto.nombre"
                class="product-image"
              />
              <Icon v-else icon="mdi:food" class="product-image-placeholder" />
            </div>
          </div>

          <!-- Info del producto -->
          <div class="product-info">
            <h3 class="product-name">{{ producto.nombre }}</h3>
            <p class="product-description">{{ producto.descripcion }}</p>
            <div class="product-price">S/ {{ producto.precio.toFixed(2) }}</div>
          </div>

          <!-- Botón agregar -->
          <button
            @click="agregarProducto(producto)"
            class="add-button"
          >
            <Icon icon="mdi:cart-plus" class="add-icon" />
            <span>Agregar</span>
          </button>
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
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  width: 100%;
  max-width: 100%;
}

@media (min-width: 768px) {
  .products-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }
}

/* ========== PRODUCT CARD - MOBILE FIRST ========== */
.product-card {
  background: white;
  border-radius: 16px;
  padding: 10px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.06);
  border: 1px solid #f3f4f6;
  transition: all 0.3s ease;
  animation: cardFadeIn 0.4s ease-out both;
  min-width: 0;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

@media (min-width: 768px) {
  .product-card {
    padding: 16px;
    box-shadow: 0 4px 15px rgba(0,0,0,0.08);
  }
}

@keyframes cardFadeIn {
  from {
    opacity: 0;
    transform: translateY(15px) scale(0.97);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.product-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 20px rgba(0,0,0,0.1);
  border-color: #fbbf24;
}

.product-card:active {
  transform: scale(0.97);
}

/* ========== PRODUCT IMAGE ========== */
.product-image-container {
  width: 100%;
  display: flex;
  justify-content: center;
  margin-bottom: 8px;
}

.product-image-wrapper {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  overflow: hidden;
  background: linear-gradient(135deg, #fef3c7 0%, #fed7aa 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 3px 10px rgba(245, 158, 11, 0.25);
  transition: all 0.3s ease;
  border: 2px solid #fde68a;
}

@media (min-width: 768px) {
  .product-image-wrapper {
    width: 72px;
    height: 72px;
  }
}

.product-card:hover .product-image-wrapper {
  transform: scale(1.08);
  box-shadow: 0 6px 16px rgba(245, 158, 11, 0.35);
}

.product-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-image-placeholder {
  width: 28px;
  height: 28px;
  color: #92400e;
}

@media (min-width: 768px) {
  .product-image-placeholder {
    width: 36px;
    height: 36px;
  }
}

/* ========== PRODUCT INFO ========== */
.product-info {
  width: 100%;
  margin-bottom: 10px;
}

.product-name {
  font-size: 0.8rem;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 4px;
  line-height: 1.25;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  white-space: normal;
  min-height: 2rem;
}

@media (min-width: 768px) {
  .product-name {
    font-size: 0.95rem;
    margin-bottom: 6px;
    min-height: 2.4rem;
  }
}

.product-description {
  font-size: 0.65rem;
  color: #6b7280;
  line-height: 1.3;
  margin-bottom: 6px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
}

@media (min-width: 768px) {
  .product-description {
    font-size: 0.75rem;
    margin-bottom: 8px;
  }
}

.product-price {
  font-size: 1.1rem;
  font-weight: 800;
  color: #f59e0b;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2px;
}

@media (min-width: 768px) {
  .product-price {
    font-size: 1.3rem;
  }
}

/* ========== ADD BUTTON ========== */
.add-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 8px;
  border-radius: 12px;
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  color: white;
  font-weight: 700;
  font-size: 0.8rem;
  border: none;
  cursor: pointer;
  box-shadow: 0 3px 10px rgba(34, 197, 94, 0.3);
  transition: all 0.25s ease;
}

@media (min-width: 768px) {
  .add-button {
    padding: 12px 16px;
    font-size: 0.9rem;
  }
}

.add-button:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 16px rgba(34, 197, 94, 0.4);
}

.add-button:active {
  transform: scale(0.96);
}

.add-icon {
  width: 18px;
  height: 18px;
}

@media (min-width: 768px) {
  .add-icon {
    width: 20px;
    height: 20px;
  }
}

@media (min-width: 768px) {
  .add-button {
    gap: 6px;
    padding: 12px 16px;
    font-size: 0.875rem;
  }
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
