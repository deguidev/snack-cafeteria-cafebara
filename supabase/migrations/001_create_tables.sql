-- =============================================
-- SNACK CAFETERÍA CAFEBARA - TABLAS SUPABASE
-- Base de datos PostgreSQL
-- =============================================

-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- TABLA: categorias
-- Categorías principales de productos
-- =============================================
CREATE TABLE categorias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) NOT NULL UNIQUE, -- 'comidas', 'cafes', 'bebidas', 'dxn'
    icono VARCHAR(100) DEFAULT 'mdi:food',
    orden INT DEFAULT 0,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar categorías iniciales
INSERT INTO categorias (nombre, slug, icono, orden) VALUES
    ('Comidas', 'comidas', 'mdi:food', 1),
    ('Cafés', 'cafes', 'mdi:coffee', 2),
    ('Bebidas', 'bebidas', 'mdi:cup', 3),
    ('DXN', 'dxn', 'mdi:leaf', 4);

-- =============================================
-- TABLA: subcategorias
-- Subcategorías (solo para comidas)
-- =============================================
CREATE TABLE subcategorias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE CASCADE,
    nombre VARCHAR(50) NOT NULL,
    slug VARCHAR(50) NOT NULL, -- 'platos', 'salchipapas', 'sandwich', 'hamburguesas'
    icono VARCHAR(100) DEFAULT 'mdi:food',
    orden INT DEFAULT 0,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(categoria_id, slug)
);

-- Insertar subcategorías de comidas
INSERT INTO subcategorias (categoria_id, nombre, slug, icono, orden)
SELECT id, 'Platos', 'platos', 'mdi:food-variant', 1 FROM categorias WHERE slug = 'comidas'
UNION ALL
SELECT id, 'Salchipapas', 'salchipapas', 'mdi:french-fries', 2 FROM categorias WHERE slug = 'comidas'
UNION ALL
SELECT id, 'Sandwich', 'sandwich', 'mdi:bread-slice', 3 FROM categorias WHERE slug = 'comidas'
UNION ALL
SELECT id, 'Hamburguesas', 'hamburguesas', 'mdi:hamburger', 4 FROM categorias WHERE slug = 'comidas';

-- =============================================
-- TABLA: productos
-- Productos del menú
-- =============================================
CREATE TABLE productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL CHECK (precio >= 0),
    categoria_id UUID NOT NULL REFERENCES categorias(id) ON DELETE RESTRICT,
    subcategoria_id UUID REFERENCES subcategorias(id) ON DELETE SET NULL,
    imagen_url TEXT,
    disponible BOOLEAN DEFAULT true,
    destacado BOOLEAN DEFAULT false,
    orden INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_productos_subcategoria ON productos(subcategoria_id);
CREATE INDEX idx_productos_disponible ON productos(disponible);

-- =============================================
-- TABLA: mesas
-- Mesas del establecimiento con posición visual
-- =============================================
CREATE TABLE mesas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero INT NOT NULL UNIQUE,
    capacidad INT DEFAULT 4,
    
    -- Posición en la grilla visual
    posicion_x INT DEFAULT 1, -- Columna en la grilla
    posicion_y INT DEFAULT 1, -- Fila en la grilla
    ancho INT DEFAULT 2, -- Ancho en celdas de grilla
    alto INT DEFAULT 2, -- Alto en celdas de grilla
    orientacion VARCHAR(20) DEFAULT 'vertical' CHECK (orientacion IN ('horizontal', 'vertical')),
    
    -- Estado y ubicación
    estado VARCHAR(20) DEFAULT 'disponible' CHECK (estado IN ('disponible', 'ocupada', 'reservada', 'mantenimiento')),
    ubicacion VARCHAR(50) DEFAULT 'interior', -- 'interior', 'terraza', etc.
    
    -- Tiempo de ocupación (para calcular duración)
    tiempo_ocupado TIMESTAMPTZ,
    
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar mesas de ejemplo con posiciones
INSERT INTO mesas (numero, capacidad, posicion_x, posicion_y, ancho, alto, orientacion, ubicacion) VALUES
    (1, 4, 1, 1, 2, 2, 'vertical', 'interior'),
    (2, 4, 4, 1, 2, 2, 'horizontal', 'interior'),
    (3, 3, 1, 4, 2, 2, 'vertical', 'interior'),
    (4, 5, 4, 4, 2, 2, 'vertical', 'interior'),
    (5, 6, 7, 1, 2, 2, 'horizontal', 'terraza'),
    (6, 4, 7, 4, 2, 2, 'vertical', 'terraza');

-- =============================================
-- TABLA: pedidos
-- Pedidos realizados
-- =============================================
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    numero_pedido INT NOT NULL DEFAULT 1, -- Número correlativo (se cambiará con ALTER TABLE abajo)
    tipo_pedido VARCHAR(20) NOT NULL CHECK (tipo_pedido IN ('para_servir', 'para_llevar', 'delivery')),
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_preparacion', 'listo', 'entregado', 'pagado', 'cancelado')),
    
    -- Datos del cliente
    nombre_cliente VARCHAR(100),
    telefono VARCHAR(20),
    direccion TEXT, -- Solo para delivery
    
    -- Mesa (solo para 'para_servir')
    mesa_id UUID REFERENCES mesas(id) ON DELETE SET NULL,
    mesa_numero INT, -- Guardamos el número por si se elimina la mesa
    
    -- Totales
    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
    descuento DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    monto_pagado DECIMAL(10, 2) DEFAULT 0,
    
    -- Notas
    notas TEXT,
    
    -- Timestamps
    fecha_pedido TIMESTAMPTZ DEFAULT NOW(),
    fecha_preparacion TIMESTAMPTZ,
    fecha_entrega TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para búsquedas
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_tipo ON pedidos(tipo_pedido);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);
CREATE INDEX idx_pedidos_mesa ON pedidos(mesa_id);

-- =============================================
-- TABLA: pedido_detalle
-- Detalle de productos de cada pedido
-- =============================================
CREATE TABLE pedido_detalle (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE RESTRICT,
    
    -- Datos del producto al momento del pedido (por si cambian precios)
    nombre_producto VARCHAR(100) NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    
    cantidad INT NOT NULL CHECK (cantidad > 0),
    subtotal DECIMAL(10, 2) NOT NULL,
    
    -- Notas especiales del item
    notas TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para búsquedas
CREATE INDEX idx_pedido_detalle_pedido ON pedido_detalle(pedido_id);
CREATE INDEX idx_pedido_detalle_producto ON pedido_detalle(producto_id);

-- =============================================
-- TABLA: modificadores
-- Modificadores/extras disponibles para productos
-- Ej: "Sin cebolla", "Doble huevo", "Extra queso"
-- =============================================
CREATE TABLE modificadores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    
    -- Tipo de modificador
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('extra', 'sin', 'sustitucion')),
    -- extra: agrega algo (doble huevo, extra queso)
    -- sin: quita algo (sin cebolla, sin arroz)
    -- sustitucion: cambia algo (arroz por papa)
    
    -- Precio adicional (puede ser 0 para "sin" o negativo para descuentos)
    precio_adicional DECIMAL(10, 2) DEFAULT 0,
    
    -- Categoría a la que aplica (NULL = aplica a todas)
    categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    
    activo BOOLEAN DEFAULT true,
    orden INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_modificadores_tipo ON modificadores(tipo);
CREATE INDEX idx_modificadores_categoria ON modificadores(categoria_id);

-- Insertar modificadores comunes
INSERT INTO modificadores (nombre, tipo, precio_adicional, descripcion) VALUES
    -- Extras con costo
    ('Huevo extra', 'extra', 2.00, 'Agregar un huevo frito adicional'),
    ('Doble huevo', 'extra', 3.50, 'Agregar dos huevos fritos'),
    ('Doble presa', 'extra', 5.00, 'Porción doble de carne/pollo'),
    ('Extra queso', 'extra', 2.50, 'Porción adicional de queso'),
    ('Extra papas', 'extra', 3.00, 'Porción adicional de papas fritas'),
    ('Huevo a la inglesa', 'extra', 2.00, 'Huevo cocido estilo inglés'),
    ('Tocino extra', 'extra', 3.00, 'Agregar tocino'),
    ('Palta extra', 'extra', 2.50, 'Agregar palta/aguacate'),
    
    -- Modificaciones sin costo (quitar ingredientes)
    ('Sin cebolla', 'sin', 0, 'Sin cebolla'),
    ('Sin arroz', 'sin', 0, 'Sin arroz'),
    ('Sin ensalada', 'sin', 0, 'Sin ensalada'),
    ('Sin ají', 'sin', 0, 'Sin ají/picante'),
    ('Sin mayonesa', 'sin', 0, 'Sin mayonesa'),
    ('Sin tomate', 'sin', 0, 'Sin tomate'),
    ('Sin lechuga', 'sin', 0, 'Sin lechuga'),
    ('Sin sal', 'sin', 0, 'Sin sal'),
    ('Sin cremas', 'sin', 0, 'Sin cremas/salsas'),
    
    -- Sustituciones (generalmente sin costo adicional)
    ('Arroz por papa', 'sustitucion', 0, 'Cambiar arroz por papas'),
    ('Papa por yuca', 'sustitucion', 0, 'Cambiar papa por yuca'),
    ('Pura papa', 'sustitucion', 0, 'Solo papas, sin otros acompañamientos');

-- =============================================
-- TABLA: producto_modificadores
-- Relación de qué modificadores aplican a qué productos
-- (Opcional: si no existe relación, el modificador aplica a todos)
-- =============================================
CREATE TABLE producto_modificadores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    modificador_id UUID NOT NULL REFERENCES modificadores(id) ON DELETE CASCADE,
    
    -- Precio específico para este producto (NULL = usa precio del modificador)
    precio_especifico DECIMAL(10, 2),
    
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(producto_id, modificador_id)
);

CREATE INDEX idx_producto_modificadores_producto ON producto_modificadores(producto_id);
CREATE INDEX idx_producto_modificadores_modificador ON producto_modificadores(modificador_id);

-- =============================================
-- TABLA: pedido_detalle_modificadores
-- Modificadores aplicados a cada item del pedido
-- =============================================
CREATE TABLE pedido_detalle_modificadores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pedido_detalle_id UUID NOT NULL REFERENCES pedido_detalle(id) ON DELETE CASCADE,
    modificador_id UUID NOT NULL REFERENCES modificadores(id) ON DELETE RESTRICT,
    
    -- Datos al momento del pedido
    nombre_modificador VARCHAR(100) NOT NULL,
    precio_adicional DECIMAL(10, 2) NOT NULL DEFAULT 0,
    cantidad INT DEFAULT 1, -- Por si piden "triple huevo" = 3x huevo extra
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE pedido_detalle_modificadores ADD COLUMN tipo VARCHAR(20);


CREATE INDEX idx_pedido_detalle_mod_detalle ON pedido_detalle_modificadores(pedido_detalle_id);

-- =============================================
-- TABLA: clientes (opcional, para historial)
-- Clientes frecuentes
-- =============================================
CREATE TABLE clientes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) UNIQUE,
    direccion TEXT,
    email VARCHAR(100),
    notas TEXT,
    total_pedidos INT DEFAULT 0,
    total_gastado DECIMAL(12, 2) DEFAULT 0,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clientes_telefono ON clientes(telefono);

-- =============================================
-- FUNCIONES Y TRIGGERS
-- =============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_categorias_updated_at BEFORE UPDATE ON categorias
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subcategorias_updated_at BEFORE UPDATE ON subcategorias
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_productos_updated_at BEFORE UPDATE ON productos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mesas_updated_at BEFORE UPDATE ON mesas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pedidos_updated_at BEFORE UPDATE ON pedidos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clientes_updated_at BEFORE UPDATE ON clientes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modificadores_updated_at BEFORE UPDATE ON modificadores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para calcular total del pedido (incluye modificadores)
CREATE OR REPLACE FUNCTION calcular_total_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido_id UUID;
BEGIN
    -- Obtener el pedido_id según la operación
    IF TG_OP = 'DELETE' THEN
        v_pedido_id := OLD.pedido_id;
    ELSE
        v_pedido_id := NEW.pedido_id;
    END IF;
    
    UPDATE pedidos
    SET subtotal = (
        -- Suma de productos
        SELECT COALESCE(SUM(pd.subtotal), 0)
        FROM pedido_detalle pd
        WHERE pd.pedido_id = v_pedido_id
    ) + (
        -- Suma de modificadores
        SELECT COALESCE(SUM(pdm.precio_adicional * pdm.cantidad), 0)
        FROM pedido_detalle_modificadores pdm
        JOIN pedido_detalle pd ON pdm.pedido_detalle_id = pd.id
        WHERE pd.pedido_id = v_pedido_id
    ),
    total = (
        SELECT COALESCE(SUM(pd.subtotal), 0)
        FROM pedido_detalle pd
        WHERE pd.pedido_id = v_pedido_id
    ) + (
        SELECT COALESCE(SUM(pdm.precio_adicional * pdm.cantidad), 0)
        FROM pedido_detalle_modificadores pdm
        JOIN pedido_detalle pd ON pdm.pedido_detalle_id = pd.id
        WHERE pd.pedido_id = v_pedido_id
    ) - COALESCE(descuento, 0)
    WHERE id = v_pedido_id;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Función para recalcular cuando se agregan modificadores
CREATE OR REPLACE FUNCTION calcular_total_por_modificador()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido_id UUID;
BEGIN
    -- Obtener el pedido_id a través del pedido_detalle
    IF TG_OP = 'DELETE' THEN
        SELECT pedido_id INTO v_pedido_id FROM pedido_detalle WHERE id = OLD.pedido_detalle_id;
    ELSE
        SELECT pedido_id INTO v_pedido_id FROM pedido_detalle WHERE id = NEW.pedido_detalle_id;
    END IF;
    
    UPDATE pedidos
    SET subtotal = (
        SELECT COALESCE(SUM(pd.subtotal), 0)
        FROM pedido_detalle pd
        WHERE pd.pedido_id = v_pedido_id
    ) + (
        SELECT COALESCE(SUM(pdm.precio_adicional * pdm.cantidad), 0)
        FROM pedido_detalle_modificadores pdm
        JOIN pedido_detalle pd ON pdm.pedido_detalle_id = pd.id
        WHERE pd.pedido_id = v_pedido_id
    ),
    total = (
        SELECT COALESCE(SUM(pd.subtotal), 0)
        FROM pedido_detalle pd
        WHERE pd.pedido_id = v_pedido_id
    ) + (
        SELECT COALESCE(SUM(pdm.precio_adicional * pdm.cantidad), 0)
        FROM pedido_detalle_modificadores pdm
        JOIN pedido_detalle pd ON pdm.pedido_detalle_id = pd.id
        WHERE pd.pedido_id = v_pedido_id
    ) - COALESCE(descuento, 0)
    WHERE id = v_pedido_id;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para recalcular total cuando se agregan/modifican items
CREATE TRIGGER recalcular_total_pedido
AFTER INSERT OR UPDATE OR DELETE ON pedido_detalle
    FOR EACH ROW EXECUTE FUNCTION calcular_total_pedido();

-- Trigger para recalcular total cuando se agregan/modifican modificadores
CREATE TRIGGER recalcular_total_por_modificador
AFTER INSERT OR UPDATE OR DELETE ON pedido_detalle_modificadores
    FOR EACH ROW EXECUTE FUNCTION calcular_total_por_modificador();

-- =============================================
-- VISTAS ÚTILES
-- =============================================

-- Vista de productos con categoría y subcategoría
CREATE VIEW v_productos_completos AS
SELECT 
    p.id,
    p.nombre,
    p.descripcion,
    p.precio,
    p.imagen_url,
    p.disponible,
    p.destacado,
    c.slug AS categoria,
    c.nombre AS categoria_nombre,
    s.slug AS subcategoria,
    s.nombre AS subcategoria_nombre
FROM productos p
JOIN categorias c ON p.categoria_id = c.id
LEFT JOIN subcategorias s ON p.subcategoria_id = s.id
WHERE p.disponible = true
ORDER BY c.orden, s.orden, p.orden;

-- Vista de pedidos del día
CREATE VIEW v_pedidos_hoy AS
SELECT 
    p.*,
    (
        SELECT json_agg(json_build_object(
            'id', pi.id,
            'nombre', pi.nombre_producto,
            'cantidad', pi.cantidad,
            'precio_unitario', pi.precio_unitario,
            'subtotal', pi.subtotal
        ))
        FROM pedido_detalle pi
        WHERE pi.pedido_id = p.id
    ) AS items
FROM pedidos p
WHERE DATE(p.fecha_pedido) = CURRENT_DATE
ORDER BY p.fecha_pedido DESC;

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- Habilitar para producción
-- =============================================

-- Por ahora deshabilitado para desarrollo
-- ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE pedido_detalle ENABLE ROW LEVEL SECURITY;

-- =============================================
-- DATOS DE EJEMPLO - PRODUCTOS
-- =============================================

-- Insertar productos de ejemplo
DO $$
DECLARE
    cat_comidas UUID;
    cat_cafes UUID;
    cat_bebidas UUID;
    cat_dxn UUID;
    sub_platos UUID;
    sub_salchipapas UUID;
    sub_sandwich UUID;
    sub_hamburguesas UUID;
BEGIN
    -- Obtener IDs de categorías
    SELECT id INTO cat_comidas FROM categorias WHERE slug = 'comidas';
    SELECT id INTO cat_cafes FROM categorias WHERE slug = 'cafes';
    SELECT id INTO cat_bebidas FROM categorias WHERE slug = 'bebidas';
    SELECT id INTO cat_dxn FROM categorias WHERE slug = 'dxn';
    
    -- Obtener IDs de subcategorías
    SELECT id INTO sub_platos FROM subcategorias WHERE slug = 'platos';
    SELECT id INTO sub_salchipapas FROM subcategorias WHERE slug = 'salchipapas';
    SELECT id INTO sub_sandwich FROM subcategorias WHERE slug = 'sandwich';
    SELECT id INTO sub_hamburguesas FROM subcategorias WHERE slug = 'hamburguesas';
    
    -- COMIDAS - PLATOS
    INSERT INTO productos (nombre, descripcion, precio, categoria_id, subcategoria_id) VALUES
    ('Arroz con Pollo', 'Delicioso arroz con pollo a la olla con papas y ensalada', 15.00, cat_comidas, sub_platos),
    ('Lomo Saltado', 'Carne de res salteada con cebolla, tomate y papas fritas', 18.00, cat_comidas, sub_platos),
    ('Ají de Gallina', 'Pollo deshilachado en salsa de ají amarillo con papas', 16.00, cat_comidas, sub_platos),
    ('Ceviche', 'Ceviche de pescado fresco con camote y choclo', 20.00, cat_comidas, sub_platos);
    
    -- COMIDAS - SALCHIPAPAS
    INSERT INTO productos (nombre, descripcion, precio, categoria_id, subcategoria_id) VALUES
    ('Salchipapa Clásica', 'Papas fritas con salchicha, cremas y ensalada', 10.00, cat_comidas, sub_salchipapas),
    ('Salchipapa Especial', 'Papas fritas, salchicha, huevo frito, queso y cremas', 14.00, cat_comidas, sub_salchipapas),
    ('Salchipapa Mixta', 'Papas fritas con salchicha, pollo y carne', 16.00, cat_comidas, sub_salchipapas);
    
    -- COMIDAS - SANDWICH
    INSERT INTO productos (nombre, descripcion, precio, categoria_id, subcategoria_id) VALUES
    ('Sandwich de Pollo', 'Pan con pollo deshilachado, lechuga, tomate y mayonesa', 8.00, cat_comidas, sub_sandwich),
    ('Sandwich Triple', 'Pan triple con jamón, queso, huevo, tomate y palta', 10.00, cat_comidas, sub_sandwich),
    ('Sandwich de Lomo', 'Pan con lomo saltado, cebolla y ají', 12.00, cat_comidas, sub_sandwich);
    
    -- COMIDAS - HAMBURGUESAS
    INSERT INTO productos (nombre, descripcion, precio, categoria_id, subcategoria_id) VALUES
    ('Hamburguesa Clásica', 'Carne de res, lechuga, tomate, cebolla y papas', 12.00, cat_comidas, sub_hamburguesas),
    ('Hamburguesa Doble', 'Doble carne, doble queso, tocino y papas', 18.00, cat_comidas, sub_hamburguesas),
    ('Hamburguesa de Pollo', 'Pechuga de pollo empanizada, lechuga y mayonesa', 14.00, cat_comidas, sub_hamburguesas);
    
    -- BEBIDAS
    INSERT INTO productos (nombre, descripcion, precio, categoria_id, imagen_url) VALUES
    ('Chicha Morada', 'Refrescante chicha morada natural', 5.00, cat_bebidas, 'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=400'),
    ('Inca Kola', 'Inca Kola 500ml', 4.00, cat_bebidas, 'https://images.unsplash.com/photo-1581006852262-e4307cf6283a?w=400'),
    ('Jugo de Naranja', 'Jugo de naranja natural recién exprimido', 6.00, cat_bebidas, 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400'),
    ('Limonada', 'Limonada helada con hierbabuena', 5.50, cat_bebidas, 'https://images.unsplash.com/photo-1523677011781-c91d1bbe2f9d?w=400');
    
    -- CAFÉS
    INSERT INTO productos (nombre, descripcion, precio, categoria_id, imagen_url) VALUES
    ('Café Americano', 'Café americano caliente', 4.50, cat_cafes, 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400'),
    ('Cappuccino', 'Cappuccino cremoso con espuma de leche', 6.00, cat_cafes, 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400'),
    ('Latte', 'Café latte con leche vaporizada', 6.50, cat_cafes, 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400'),
    ('Espresso', 'Espresso doble intenso', 5.00, cat_cafes, 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400');
    
    -- DXN
    INSERT INTO productos (nombre, descripcion, precio, categoria_id) VALUES
    ('Ganoderma Coffee', 'Café con extracto de Ganoderma Lucidum', 12.00, cat_dxn),
    ('Spirulina', 'Suplemento de Spirulina en tabletas', 45.00, cat_dxn),
    ('Morinzhi', 'Jugo de Noni concentrado', 35.00, cat_dxn),
    ('Lingzhi Coffee 3 en 1', 'Café instantáneo con Ganoderma', 15.00, cat_dxn);
    
END $$;

-- =============================================
-- COMENTARIOS FINALES
-- =============================================
COMMENT ON TABLE categorias IS 'Categorías principales: comidas, cafes, bebidas, dxn';
COMMENT ON TABLE subcategorias IS 'Subcategorías de comidas: platos, salchipapas, sandwich, hamburguesas';
COMMENT ON TABLE productos IS 'Productos del menú con precios y disponibilidad';
COMMENT ON TABLE mesas IS 'Mesas del establecimiento';
COMMENT ON TABLE pedidos IS 'Pedidos realizados con tipo: para_servir, para_llevar, delivery';
COMMENT ON TABLE pedido_detalle IS 'Detalle de cada pedido con precio al momento de la compra';
COMMENT ON TABLE clientes IS 'Clientes frecuentes para historial y delivery';
COMMENT ON TABLE modificadores IS 'Modificadores/extras para productos: sin cebolla, doble huevo, etc.';
COMMENT ON TABLE producto_modificadores IS 'Relación de qué modificadores aplican a qué productos';
COMMENT ON TABLE pedido_detalle_modificadores IS 'Modificadores aplicados a cada item del pedido';

-- =============================================
-- TABLA: restaurantes
-- Información del restaurante/local
-- =============================================
CREATE TABLE restaurantes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    telefono VARCHAR(20),
    email VARCHAR(100),
    ruc VARCHAR(20),
    logo_url TEXT,
    
    -- Configuración
    moneda VARCHAR(10) DEFAULT 'PEN',
    simbolo_moneda VARCHAR(5) DEFAULT 'S/',
    igv_porcentaje DECIMAL(5, 2) DEFAULT 18.00,
    incluye_igv BOOLEAN DEFAULT true,
    
    -- Horarios
    horario_apertura TIME DEFAULT '08:00',
    horario_cierre TIME DEFAULT '22:00',
    dias_operacion VARCHAR(50) DEFAULT 'Lun-Dom',
    
    -- Redes sociales
    facebook_url TEXT,
    instagram_url TEXT,
    whatsapp VARCHAR(20),
    
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insertar restaurante por defecto
INSERT INTO restaurantes (nombre, direccion, telefono, ruc) VALUES
    ('Snack Cafetería Cafebara', 'Av. Principal 123, Lima', '999-888-777', '20123456789');

-- =============================================
-- TABLA: usuarios
-- Usuarios del sistema con roles
-- =============================================
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Datos de autenticación (vinculado a Supabase Auth)
    auth_id UUID UNIQUE, -- ID de auth.users de Supabase
    email VARCHAR(100) NOT NULL UNIQUE,
    
    -- Datos personales
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100),
    telefono VARCHAR(20),
    avatar_url TEXT,
    
    -- Rol y permisos
    rol VARCHAR(20) NOT NULL DEFAULT 'mesero' CHECK (rol IN ('super_admin', 'admin', 'cajero', 'mesero', 'cocina')),
    -- super_admin: acceso total, puede gestionar múltiples restaurantes
    -- admin: acceso total a un restaurante
    -- cajero: puede cobrar y ver reportes
    -- mesero: puede tomar pedidos
    -- cocina: puede ver y actualizar estado de pedidos
    
    -- Restaurante asignado
    restaurante_id UUID REFERENCES restaurantes(id) ON DELETE SET NULL,
    
    -- Estado
    activo BOOLEAN DEFAULT true,
    ultimo_acceso TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_usuarios_restaurante ON usuarios(restaurante_id);
CREATE INDEX idx_usuarios_auth ON usuarios(auth_id);

-- Insertar usuario admin por defecto
INSERT INTO usuarios (email, nombre, apellido, rol) VALUES
    ('admin@cafeteria.com', 'Administrador', 'Sistema', 'super_admin');

-- =============================================
-- TRIGGER: Actualizar updated_at para nuevas tablas
-- =============================================
CREATE TRIGGER update_restaurantes_updated_at
    BEFORE UPDATE ON restaurantes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuarios_updated_at
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- RLS: Políticas de seguridad para restaurantes y usuarios
-- =============================================
ALTER TABLE restaurantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

-- Políticas para restaurantes (lectura pública, escritura solo admin)
CREATE POLICY "Restaurantes visibles para todos" ON restaurantes
    FOR SELECT USING (true);

CREATE POLICY "Solo admins pueden modificar restaurantes" ON restaurantes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE usuarios.auth_id = auth.uid() 
            AND usuarios.rol IN ('super_admin', 'admin')
        )
    );

-- Políticas para usuarios
CREATE POLICY "Usuarios pueden ver su propio perfil" ON usuarios
    FOR SELECT USING (auth_id = auth.uid() OR EXISTS (
        SELECT 1 FROM usuarios u 
        WHERE u.auth_id = auth.uid() 
        AND u.rol IN ('super_admin', 'admin')
    ));

CREATE POLICY "Solo admins pueden gestionar usuarios" ON usuarios
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM usuarios 
            WHERE usuarios.auth_id = auth.uid() 
            AND usuarios.rol IN ('super_admin', 'admin')
        )
    );

-- =============================================
-- ALTER TABLE: Cambiar numero_pedido de SERIAL a INT
-- Para que el trigger pueda asignar el número diario
-- =============================================
--ALTER TABLE pedidos ALTER COLUMN numero_pedido DROP DEFAULT;
--ALTER TABLE pedidos ALTER COLUMN numero_pedido SET DATA TYPE INT;
--ALTER TABLE pedidos ALTER COLUMN numero_pedido SET DEFAULT 1;

-- =============================================
-- FUNCIÓN: Número de pedido diario
-- Reinicia a 1 cada día
-- =============================================
CREATE OR REPLACE FUNCTION get_next_numero_pedido_diario()
RETURNS INTEGER AS $$
DECLARE
    next_num INTEGER;
BEGIN
    -- Obtener el máximo número de pedido del día actual
    SELECT COALESCE(MAX(numero_pedido), 0) + 1 INTO next_num
    FROM pedidos
    WHERE DATE(created_at AT TIME ZONE 'America/Lima') = DATE(NOW() AT TIME ZONE 'America/Lima');
    
    RETURN next_num;
END;
$$ LANGUAGE plpgsql;

-- Trigger para asignar número de pedido diario automáticamente
CREATE OR REPLACE FUNCTION set_numero_pedido_diario()
RETURNS TRIGGER AS $$
BEGIN
    NEW.numero_pedido := get_next_numero_pedido_diario();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger (eliminar si existe)
DROP TRIGGER IF EXISTS trigger_set_numero_pedido ON pedidos;
CREATE TRIGGER trigger_set_numero_pedido
    BEFORE INSERT ON pedidos
    FOR EACH ROW
    EXECUTE FUNCTION set_numero_pedido_diario();

-- Índice único para garantizar que numero_pedido sea único por día
CREATE UNIQUE INDEX IF NOT EXISTS idx_pedidos_numero_fecha_unico 
ON pedidos (numero_pedido, DATE(created_at AT TIME ZONE 'America/Lima'));

-- =============================================
-- COMENTARIOS PARA NUEVAS TABLAS
-- =============================================
COMMENT ON TABLE restaurantes IS 'Información del restaurante: nombre, dirección, configuración fiscal';
COMMENT ON TABLE usuarios IS 'Usuarios del sistema con roles: super_admin, admin, cajero, mesero, cocina';
