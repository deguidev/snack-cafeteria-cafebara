<script setup lang="ts">
import { ref, watch } from 'vue';
import { Icon } from '@iconify/vue';
import { supabase } from '../../lib/supabaseClient';
import MesasGrid from './MesasGrid.vue';

interface PedidoMesa {
  id: string;
  numero_pedido: number;
  total: number;
  estado: string;
  items: {
    nombre_producto: string;
    cantidad: number;
    precio_unitario: number;
  }[];
}

interface Mesa {
  id: string;
  numero: number;
  capacidad: number;
  posicion_x: number;
  posicion_y: number;
  ancho: number;
  alto: number;
  orientacion: 'horizontal' | 'vertical';
  estado: 'disponible' | 'ocupada' | 'reservada' | 'mantenimiento';
  ubicacion: string;
  activo: boolean;
  pedidos?: PedidoMesa[];
}

const props = defineProps<{
  visible: boolean;
  mesaSeleccionada?: number | null;
}>();

const emit = defineEmits<{
  'cerrar': [];
  'seleccionar': [mesaNumero: number];
}>();

const mesas = ref<Mesa[]>([]);
const loading = ref(true);

const cargarMesas = async () => {
  try {
    loading.value = true;
    
    // Cargar mesas
    const { data: mesasData, error: errorMesas } = await supabase
      .from('mesas')
      .select('*')
      .eq('activo', true)
      .order('numero');

    if (errorMesas) throw errorMesas;

    // Cargar pedidos activos (no pagados ni cancelados) por mesa
    const { data: pedidosData, error: errorPedidos } = await supabase
      .from('pedidos')
      .select(`
        id,
        numero_pedido,
        mesa_numero,
        total,
        estado,
        pedido_detalle (
          nombre_producto,
          cantidad,
          precio_unitario
        )
      `)
      .eq('tipo_pedido', 'para_servir')
      .not('estado', 'in', '("pagado","cancelado")');

    if (errorPedidos) throw errorPedidos;

    // Mapear mesas con sus pedidos
    mesas.value = (mesasData || []).map(mesa => {
      const pedidosMesa = (pedidosData || []).filter(p => p.mesa_numero === mesa.numero);
      const tienePedidos = pedidosMesa.length > 0;
      
      return {
        ...mesa,
        estado: tienePedidos ? 'ocupada' : mesa.estado,
        pedidos: pedidosMesa.map(p => ({
          id: p.id,
          numero_pedido: p.numero_pedido,
          total: p.total,
          estado: p.estado,
          items: p.pedido_detalle || []
        }))
      };
    });
  } catch (err) {
    console.error('Error cargando mesas:', err);
  } finally {
    loading.value = false;
  }
};

const handleSeleccionarMesa = (mesa: Mesa) => {
  emit('seleccionar', mesa.numero);
  emit('cerrar');
};

// Recargar mesas cuando se abre el modal
watch(() => props.visible, (newVal) => {
  if (newVal) {
    cargarMesas();
  }
}, { immediate: true });
</script>

<template>
  <Transition name="modal">
    <div
      v-if="visible"
      class="fixed inset-0 z-[200] flex items-center justify-center bg-black/50 p-4"
      @click.self="emit('cerrar')"
    >
      <div class="w-full max-w-4xl max-h-[90vh] overflow-hidden rounded-2xl bg-white shadow-2xl flex flex-col">
        <!-- Header -->
        <div class="flex items-center justify-between border-b border-gray-200 bg-gradient-to-r from-amber-600 to-amber-700 px-6 py-4">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-white/20">
              <Icon icon="mdi:table-furniture" class="h-6 w-6 text-white" />
            </div>
            <div>
              <h2 class="text-xl font-bold text-white">Seleccionar Mesa</h2>
              <p class="text-sm text-amber-100">Elige una mesa disponible</p>
            </div>
          </div>
          <button
            @click="emit('cerrar')"
            class="flex h-8 w-8 items-center justify-center rounded-full text-white/80 transition-colors hover:bg-white/20 hover:text-white"
          >
            <Icon icon="mdi:close" class="h-6 w-6" />
          </button>
        </div>

        <!-- Contenido -->
        <div class="flex-1 overflow-auto p-4">
          <div v-if="loading" class="flex items-center justify-center py-12">
            <Icon icon="mdi:loading" class="h-8 w-8 animate-spin text-amber-600" />
            <span class="ml-2 text-gray-600">Cargando mesas...</span>
          </div>
          
          <MesasGrid
            v-else
            :mesas="mesas"
            :mesa-seleccionada="mesaSeleccionada"
            :modo-seleccion="true"
            :compacto="true"
            @seleccionar-mesa="handleSeleccionarMesa"
          />
        </div>

        <!-- Footer -->
        <div class="border-t border-gray-200 bg-gray-50 px-6 py-3 flex justify-end">
          <button
            @click="emit('cerrar')"
            class="px-4 py-2 text-sm font-semibold text-gray-700 bg-gray-200 rounded-lg hover:bg-gray-300 transition-colors"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: all 0.2s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
.modal-enter-from > div,
.modal-leave-to > div {
  transform: scale(0.95);
}
</style>
