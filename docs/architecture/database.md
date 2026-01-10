# BASE DE DATOS - SUPABASE

Schema completo, RLS policies, y triggers.

**Última actualización:** 6 Enero 2026 | **Schema:** V2 (ticket_categories + ticket_tiers)

---

## 📋 TABLAS

### users

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_provider_id TEXT UNIQUE NOT NULL,  -- Supabase auth.uid()
  
  -- Info personal
  first_name TEXT,
  last_name TEXT,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  
  -- Rol y relación
  role TEXT NOT NULL DEFAULT 'fan',  -- 'fan', 'admin', 'collaborator'
  producer_id UUID REFERENCES producers(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_auth_provider ON users(auth_provider_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_producer ON users(producer_id);
```

**Roles:**
- `fan` - Compra tickets (evio_fan)
- `admin` - Dueño de productora, CRUD completo (evio_admin)
- `collaborator` - Miembro de equipo, permisos limitados (evio_admin)

---

### producers

```sql
CREATE TABLE producers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Info
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  logo_url TEXT,
  description TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### events

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producer_id UUID NOT NULL REFERENCES producers(id) ON DELETE CASCADE,
  
  -- Básico
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  main_artist TEXT NOT NULL,
  lineup JSONB DEFAULT '[]',  -- Array de {name, is_headliner, image_url}
  
  -- Fecha/Hora
  start_datetime TIMESTAMPTZ NOT NULL,
  end_datetime TIMESTAMPTZ,
  
  -- Ubicación
  venue_name TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  
  -- Info adicional
  genre TEXT,
  description TEXT,
  organizer_name TEXT,
  features TEXT[],  -- ['Open Bar', 'VIP Area', ...]
  
  -- Imágenes (sistema de thumbnails)
  image_url TEXT,           -- Imagen croppeada (cuadrada, para cards)
  thumbnail_url TEXT,       -- 300x300 thumbnail para listas
  full_image_url TEXT,      -- Imagen completa (ratio original, para hero)
  video_url TEXT,           -- URL de video (YouTube, Vimeo)
  
  -- Estado
  status TEXT DEFAULT 'draft',  -- 'draft', 'upcoming', 'cancelled'
  is_published BOOLEAN DEFAULT false,
  total_capacity INTEGER,
  show_all_ticket_types BOOLEAN DEFAULT false,  -- Mostrar tandas inactivas
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('draft', 'upcoming', 'cancelled'))
);

CREATE INDEX idx_events_producer ON events(producer_id);
CREATE INDEX idx_events_city ON events(city);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_start_datetime ON events(start_datetime);
CREATE INDEX idx_events_published ON events(is_published) WHERE is_published = true;
```

---

### ticket_categories

Categorías de tickets (General, VIP, Mesa, etc). Un evento tiene múltiples categorías.

```sql
CREATE TABLE ticket_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  description TEXT,
  max_per_purchase INTEGER,  -- Límite por categoría (opcional)
  order_index INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ticket_categories_event ON ticket_categories(event_id);
```

---

### ticket_tiers

Tandas dentro de cada categoría (Early Bird, Regular, Last Minute, etc).

```sql
CREATE TABLE ticket_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES ticket_categories(id) ON DELETE CASCADE,
  
  name TEXT NOT NULL,
  description TEXT,
  price INTEGER NOT NULL,           -- Centavos (5000 = $50.00)
  quantity INTEGER NOT NULL,        -- Stock total
  sold_count INTEGER DEFAULT 0,     -- Vendidos
  order_index INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  
  -- Fechas de venta (opcionales)
  sale_starts_at TIMESTAMPTZ,
  sale_ends_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_price CHECK (price >= 0),
  CONSTRAINT valid_quantity CHECK (quantity > 0),
  CONSTRAINT valid_sold CHECK (sold_count >= 0 AND sold_count <= quantity)
);

CREATE INDEX idx_ticket_tiers_category ON ticket_tiers(category_id);
CREATE INDEX idx_ticket_tiers_active ON ticket_tiers(is_active) WHERE is_active = true;
```

**Relación:** `Event` → `TicketCategory` → `TicketTier`

---

### tickets

Entradas individuales generadas post-compra.

```sql
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  tier_id UUID NOT NULL REFERENCES ticket_tiers(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  original_owner_id UUID REFERENCES users(id),  -- Para transferencias
  
  -- QR único
  qr_secret TEXT UNIQUE NOT NULL,
  
  -- Estado
  status TEXT DEFAULT 'valid',  -- 'valid', 'used', 'cancelled', 'expired'
  is_invitation BOOLEAN DEFAULT false,
  transfer_allowed BOOLEAN DEFAULT false,
  transfer_count INTEGER DEFAULT 0,
  
  -- Uso
  used_at TIMESTAMPTZ,
  used_by_dni TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('valid', 'used', 'cancelled', 'expired')),
  CONSTRAINT valid_transfer_count CHECK (transfer_count >= 0 AND transfer_count <= 3)
);

CREATE INDEX idx_tickets_owner ON tickets(owner_id);
CREATE INDEX idx_tickets_event ON tickets(event_id);
CREATE INDEX idx_tickets_tier ON tickets(tier_id);
CREATE INDEX idx_tickets_order ON tickets(order_id);
CREATE INDEX idx_tickets_qr ON tickets(qr_secret);
CREATE INDEX idx_tickets_status ON tickets(status);
```

---

### orders

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  
  -- Pago
  status TEXT DEFAULT 'pending',  -- 'pending', 'paid', 'failed', 'refunded', 'cancelled'
  total_amount INTEGER NOT NULL,  -- Centavos
  currency TEXT DEFAULT 'ARS',
  payment_provider TEXT,          -- 'mercadopago', 'mock', etc
  payment_id TEXT,
  
  -- Descuentos
  coupon_id UUID REFERENCES coupons(id),
  discount_amount INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_status CHECK (status IN ('pending', 'paid', 'failed', 'refunded', 'cancelled')),
  CONSTRAINT valid_amount CHECK (total_amount >= 0)
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_event ON orders(event_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_payment ON orders(payment_id) WHERE payment_id IS NOT NULL;
```

---

### order_items

```sql
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  tier_id UUID NOT NULL REFERENCES ticket_tiers(id) ON DELETE CASCADE,
  
  quantity INTEGER NOT NULL,
  unit_price INTEGER NOT NULL,  -- Precio unitario en centavos
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_quantity CHECK (quantity > 0),
  CONSTRAINT valid_price CHECK (unit_price >= 0)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_tier ON order_items(tier_id);
```

---

### coupons

```sql
CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  
  -- Descuento (solo uno)
  discount_type TEXT NOT NULL,  -- 'percent' o 'fixed'
  discount_value INTEGER NOT NULL,  -- 50 = 50% o 5000 = $50
  
  -- Límites
  max_uses INTEGER,
  used_count INTEGER DEFAULT 0,
  
  -- Validez
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_discount_type CHECK (discount_type IN ('percent', 'fixed')),
  CONSTRAINT valid_discount_value CHECK (discount_value > 0)
);

CREATE INDEX idx_coupons_code ON coupons(code);
CREATE INDEX idx_coupons_active ON coupons(is_active) WHERE is_active = true;
```

---

### user_invitations

```sql
CREATE TABLE user_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producer_id UUID NOT NULL REFERENCES producers(id) ON DELETE CASCADE,
  
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  role TEXT NOT NULL,  -- 'admin' o 'collaborator'
  
  status TEXT DEFAULT 'pending',  -- 'pending', 'accepted', 'expired'
  expires_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_role CHECK (role IN ('admin', 'collaborator')),
  CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'expired'))
);

CREATE INDEX idx_user_invitations_email ON user_invitations(email);
CREATE INDEX idx_user_invitations_producer ON user_invitations(producer_id);
```

---

## 🔒 ROW LEVEL SECURITY (RLS)

### users

```sql
CREATE POLICY "Users view own profile" ON users
  FOR SELECT USING (auth.uid()::TEXT = auth_provider_id);

CREATE POLICY "Users update own profile" ON users
  FOR UPDATE USING (auth.uid()::TEXT = auth_provider_id);
```

### producers

```sql
CREATE POLICY "Producers view own" ON producers
  FOR SELECT USING (id IN (
    SELECT producer_id FROM users WHERE auth_provider_id = auth.uid()::TEXT
  ));

CREATE POLICY "Admins manage own" ON producers
  FOR ALL USING (id IN (
    SELECT producer_id FROM users 
    WHERE auth_provider_id = auth.uid()::TEXT AND role = 'admin'
  ));
```

### events

```sql
CREATE POLICY "Anyone view published events" ON events
  FOR SELECT USING (is_published = true);

CREATE POLICY "Producers manage own events" ON events
  FOR ALL USING (producer_id IN (
    SELECT producer_id FROM users WHERE auth_provider_id = auth.uid()::TEXT
  ));
```

### ticket_categories

```sql
CREATE POLICY "Anyone view categories of published events" ON ticket_categories
  FOR SELECT USING (event_id IN (
    SELECT id FROM events WHERE is_published = true
  ));

CREATE POLICY "Producers manage own categories" ON ticket_categories
  FOR ALL USING (event_id IN (
    SELECT id FROM events WHERE producer_id IN (
      SELECT producer_id FROM users WHERE auth_provider_id = auth.uid()::TEXT
    )
  ));
```

### ticket_tiers

```sql
CREATE POLICY "Anyone view tiers of published events" ON ticket_tiers
  FOR SELECT USING (category_id IN (
    SELECT id FROM ticket_categories WHERE event_id IN (
      SELECT id FROM events WHERE is_published = true
    )
  ));

CREATE POLICY "Producers manage own tiers" ON ticket_tiers
  FOR ALL USING (category_id IN (
    SELECT id FROM ticket_categories WHERE event_id IN (
      SELECT id FROM events WHERE producer_id IN (
        SELECT producer_id FROM users WHERE auth_provider_id = auth.uid()::TEXT
      )
    )
  ));
```

### tickets

```sql
CREATE POLICY "Users view own tickets" ON tickets
  FOR SELECT USING (owner_id IN (
    SELECT id FROM users WHERE auth_provider_id = auth.uid()::TEXT
  ));
```

### orders

```sql
CREATE POLICY "Users view own orders" ON orders
  FOR SELECT USING (user_id IN (
    SELECT id FROM users WHERE auth_provider_id = auth.uid()::TEXT
  ));

CREATE POLICY "Users create own orders" ON orders
  FOR INSERT WITH CHECK (user_id IN (
    SELECT id FROM users WHERE auth_provider_id = auth.uid()::TEXT
  ));
```

---

## ⚡ TRIGGERS

### Actualizar sold_count al crear ticket

```sql
CREATE OR REPLACE FUNCTION update_sold_quantity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'valid' THEN
    UPDATE ticket_tiers SET sold_count = sold_count + 1 WHERE id = NEW.tier_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status = 'valid' AND NEW.status = 'cancelled' THEN
    UPDATE ticket_tiers SET sold_count = sold_count - 1 WHERE id = NEW.tier_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_ticket_change
  AFTER INSERT OR UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_sold_quantity();
```

### Actualizar updated_at

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a tablas con updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_producers_updated_at BEFORE UPDATE ON producers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_ticket_categories_updated_at BEFORE UPDATE ON ticket_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_ticket_tiers_updated_at BEFORE UPDATE ON ticket_tiers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Asociar usuario con invitación

```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Buscar invitación pendiente
  UPDATE user_invitations SET status = 'accepted'
  WHERE email = NEW.email AND status = 'pending';
  
  -- Asociar con productor si hay invitación
  UPDATE users SET 
    producer_id = (SELECT producer_id FROM user_invitations WHERE email = NEW.email AND status = 'accepted' LIMIT 1),
    role = (SELECT role FROM user_invitations WHERE email = NEW.email AND status = 'accepted' LIMIT 1)
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_created
  AFTER INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

---

## 📊 QUERIES COMUNES

### Eventos con stats

```sql
SELECT 
  e.*,
  COALESCE(SUM(tt.sold_count), 0) as total_sold,
  COALESCE(MIN(tt.price), 0) as min_price,
  COALESCE(MAX(tt.price), 0) as max_price
FROM events e
LEFT JOIN ticket_categories tc ON e.id = tc.event_id
LEFT JOIN ticket_tiers tt ON tc.id = tt.category_id AND tt.is_active = true
WHERE e.producer_id = $1
GROUP BY e.id
ORDER BY e.start_datetime DESC;
```

### Categorías con tiers de un evento

```sql
SELECT 
  tc.*,
  COALESCE(
    json_agg(tt ORDER BY tt.order_index) FILTER (WHERE tt.id IS NOT NULL),
    '[]'
  ) as tiers
FROM ticket_categories tc
LEFT JOIN ticket_tiers tt ON tc.id = tt.category_id
WHERE tc.event_id = $1
GROUP BY tc.id
ORDER BY tc.order_index;
```

### Tickets de un usuario

```sql
SELECT 
  t.*,
  e.title as event_title,
  e.start_datetime,
  e.image_url,
  tt.name as tier_name,
  tt.price as tier_price
FROM tickets t
JOIN events e ON t.event_id = e.id
JOIN ticket_tiers tt ON t.tier_id = tt.id
WHERE t.owner_id = $1 AND t.status = 'valid'
ORDER BY e.start_datetime ASC;
```

---

## 🔧 FUNCIONES RPC

### create_order_safe (compra atómica)

```sql
CREATE OR REPLACE FUNCTION create_order_safe(
  p_user_id UUID,
  p_event_id UUID,
  p_items JSONB,  -- [{tier_id, quantity, unit_price}]
  p_total_amount INTEGER
) RETURNS UUID AS $$
DECLARE
  v_order_id UUID;
  v_item JSONB;
  v_tier_id UUID;
  v_quantity INTEGER;
  v_available INTEGER;
BEGIN
  -- Validar disponibilidad
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_tier_id := (v_item->>'tier_id')::UUID;
    v_quantity := (v_item->>'quantity')::INTEGER;
    
    SELECT (quantity - sold_count) INTO v_available
    FROM ticket_tiers WHERE id = v_tier_id FOR UPDATE;
    
    IF v_available < v_quantity THEN
      RAISE EXCEPTION 'Insufficient stock for tier %', v_tier_id;
    END IF;
  END LOOP;
  
  -- Crear orden
  INSERT INTO orders (id, user_id, event_id, total_amount, status)
  VALUES (gen_random_uuid(), p_user_id, p_event_id, p_total_amount, 'paid')
  RETURNING id INTO v_order_id;
  
  -- Crear items y tickets
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
    v_tier_id := (v_item->>'tier_id')::UUID;
    v_quantity := (v_item->>'quantity')::INTEGER;
    
    INSERT INTO order_items (order_id, tier_id, quantity, unit_price)
    VALUES (v_order_id, v_tier_id, v_quantity, (v_item->>'unit_price')::INTEGER);
    
    FOR i IN 1..v_quantity LOOP
      INSERT INTO tickets (event_id, tier_id, order_id, owner_id, qr_secret, status)
      VALUES (p_event_id, v_tier_id, v_order_id, p_user_id, gen_random_uuid()::TEXT, 'valid');
    END LOOP;
  END LOOP;
  
  RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 📐 DIAGRAMA DE RELACIONES

```
producers
    │
    └─── users (producer_id)
    │
    └─── events (producer_id)
              │
              ├─── ticket_categories (event_id)
              │         │
              │         └─── ticket_tiers (category_id)
              │                   │
              │                   └─── tickets (tier_id)
              │                   │
              │                   └─── order_items (tier_id)
              │
              └─── orders (event_id)
                       │
                       └─── order_items (order_id)
                       │
                       └─── tickets (order_id)
```
