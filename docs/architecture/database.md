# BASE DE DATOS - SUPABASE

Schema completo, RLS policies, y triggers.

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
  role TEXT NOT NULL DEFAULT 'fan',  -- 'fan', 'producer', 'admin'
  producer_id UUID REFERENCES producers(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_auth_provider ON users(auth_provider_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_producer ON users(producer_id);
```

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
  lineup JSONB DEFAULT '[]',  -- Array de {name, is_headliner}
  
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
  image_url TEXT,
  
  -- Estado
  status TEXT DEFAULT 'draft',  -- 'draft', 'upcoming', 'cancelled'
  is_published BOOLEAN DEFAULT false,
  total_capacity INTEGER,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('draft', 'upcoming', 'cancelled'))
);

CREATE INDEX idx_events_producer ON events(producer_id);
CREATE INDEX idx_events_city ON events(city);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_start_datetime ON events(start_datetime);
CREATE INDEX idx_events_published ON events(is_published) WHERE is_published = true;
```

---

### ticket_types

```sql
CREATE TABLE ticket_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  
  -- Info
  name TEXT NOT NULL,
  price INTEGER NOT NULL,  -- Centavos
  
  -- Cantidades
  total_quantity INTEGER NOT NULL,
  sold_quantity INTEGER DEFAULT 0,
  
  -- Límites
  max_per_purchase INTEGER,  -- NULL = sin límite
  
  -- Fechas de venta
  sale_start_at TIMESTAMPTZ,
  sale_end_at TIMESTAMPTZ,
  
  -- Estado
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER,  -- Para ordenar en UI
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_price CHECK (price > 0),
  CONSTRAINT valid_quantity CHECK (total_quantity > 0),
  CONSTRAINT valid_sold CHECK (sold_quantity >= 0 AND sold_quantity <= total_quantity),
  CONSTRAINT valid_max_per_purchase CHECK (max_per_purchase IS NULL OR max_per_purchase > 0)
);

CREATE INDEX idx_ticket_types_event ON ticket_types(event_id);
CREATE INDEX idx_ticket_types_active ON ticket_types(is_active) WHERE is_active = true;
```

---

### tickets

```sql
CREATE TABLE tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  ticket_type_id UUID NOT NULL REFERENCES ticket_types(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- QR único
  qr_secret TEXT UNIQUE NOT NULL,
  
  -- Estado
  status TEXT DEFAULT 'valid',  -- 'valid', 'used', 'cancelled'
  used_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('valid', 'used', 'cancelled'))
);

CREATE INDEX idx_tickets_owner ON tickets(owner_id);
CREATE INDEX idx_tickets_event ON tickets(event_id);
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
  status TEXT DEFAULT 'pending',  -- 'pending', 'paid', 'failed'
  total_amount INTEGER NOT NULL,  -- Centavos
  payment_id TEXT,  -- MercadoPago ID
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_status CHECK (status IN ('pending', 'paid', 'failed')),
  CONSTRAINT valid_amount CHECK (total_amount > 0)
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
  ticket_type_id UUID NOT NULL REFERENCES ticket_types(id) ON DELETE CASCADE,
  
  -- Detalles al momento de compra
  quantity INTEGER NOT NULL,
  price INTEGER NOT NULL,  -- Precio unitario en centavos
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_quantity CHECK (quantity > 0),
  CONSTRAINT valid_price CHECK (price > 0)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_ticket_type ON order_items(ticket_type_id);
```

---

### coupons

```sql
CREATE TABLE coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Código
  code TEXT UNIQUE NOT NULL,
  
  -- Descuento (solo uno debe estar presente)
  discount_percent INTEGER,  -- 50 = 50% off
  discount_fixed INTEGER,    -- 1000 centavos = $10 off
  
  -- Límites
  max_uses INTEGER,
  used_count INTEGER DEFAULT 0,
  
  -- Validez
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_discount CHECK (
    (discount_percent IS NOT NULL AND discount_fixed IS NULL) OR
    (discount_percent IS NULL AND discount_fixed IS NOT NULL)
  ),
  CONSTRAINT valid_percent CHECK (
    discount_percent IS NULL OR 
    (discount_percent > 0 AND discount_percent <= 100)
  ),
  CONSTRAINT valid_fixed CHECK (
    discount_fixed IS NULL OR discount_fixed > 0
  ),
  CONSTRAINT valid_uses CHECK (
    used_count >= 0 AND (max_uses IS NULL OR used_count <= max_uses)
  )
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
  
  -- Info del invitado
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  role TEXT NOT NULL,  -- 'producer' o 'admin'
  
  -- Estado
  status TEXT DEFAULT 'pending',  -- 'pending', 'accepted', 'expired'
  expires_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_role CHECK (role IN ('producer', 'admin')),
  CONSTRAINT valid_status CHECK (status IN ('pending', 'accepted', 'expired'))
);

CREATE INDEX idx_user_invitations_email ON user_invitations(email);
CREATE INDEX idx_user_invitations_producer ON user_invitations(producer_id);
CREATE INDEX idx_user_invitations_status ON user_invitations(status);
```

---

## 🔒 ROW LEVEL SECURITY (RLS)

### users

```sql
-- Users ven solo su perfil
CREATE POLICY "Users view own profile" ON users
  FOR SELECT USING (auth.uid()::TEXT = auth_provider_id);

-- Users actualizan solo su perfil
CREATE POLICY "Users update own profile" ON users
  FOR UPDATE USING (auth.uid()::TEXT = auth_provider_id);
```

---

### producers

```sql
-- Productores ven solo su productora
CREATE POLICY "Producers view own" ON producers
  FOR SELECT USING (id IN (
    SELECT producer_id FROM users 
    WHERE auth_provider_id = auth.uid()::TEXT
  ));

-- Admins editan su productora
CREATE POLICY "Admins update own" ON producers
  FOR UPDATE USING (id IN (
    SELECT producer_id FROM users 
    WHERE auth_provider_id = auth.uid()::TEXT 
    AND role = 'admin'
  ));
```

---

### events

```sql
-- Eventos públicos visibles para todos
CREATE POLICY "Anyone view published events" ON events
  FOR SELECT USING (is_published = true);

-- Productores gestionan sus eventos
CREATE POLICY "Producers manage own events" ON events
  FOR ALL USING (producer_id IN (
    SELECT producer_id FROM users 
    WHERE auth_provider_id = auth.uid()::TEXT
  ));
```

---

### ticket_types

```sql
-- Todos ven ticket types de eventos publicados
CREATE POLICY "Anyone view published ticket types" ON ticket_types
  FOR SELECT USING (event_id IN (
    SELECT id FROM events WHERE is_published = true
  ));

-- Productores gestionan ticket types de sus eventos
CREATE POLICY "Producers manage own ticket types" ON ticket_types
  FOR ALL USING (event_id IN (
    SELECT id FROM events 
    WHERE producer_id IN (
      SELECT producer_id FROM users 
      WHERE auth_provider_id = auth.uid()::TEXT
    )
  ));
```

---

### tickets

```sql
-- Users ven solo sus tickets
CREATE POLICY "Users view own tickets" ON tickets
  FOR SELECT USING (owner_id IN (
    SELECT id FROM users 
    WHERE auth_provider_id = auth.uid()::TEXT
  ));
```

---

### orders

```sql
-- Users ven solo sus orders
CREATE POLICY "Users view own orders" ON orders
  FOR SELECT USING (user_id IN (
    SELECT id FROM users 
    WHERE auth_provider_id = auth.uid()::TEXT
  ));

-- Users crean sus orders
CREATE POLICY "Users create own orders" ON orders
  FOR INSERT WITH CHECK (user_id IN (
    SELECT id FROM users 
    WHERE auth_provider_id = auth.uid()::TEXT
  ));
```

---

## ⚡ TRIGGERS

### Asociar usuario con invitación

```sql
CREATE OR REPLACE FUNCTION associate_user_with_invitation()
RETURNS TRIGGER AS $$
BEGIN
  -- Buscar invitación pendiente con este email
  UPDATE user_invitations
  SET status = 'accepted'
  WHERE email = NEW.email 
    AND status = 'pending';
  
  -- Asociar usuario con productor de la invitación
  UPDATE users
  SET producer_id = (
    SELECT producer_id FROM user_invitations 
    WHERE email = NEW.email AND status = 'accepted'
    LIMIT 1
  ),
  role = (
    SELECT role FROM user_invitations 
    WHERE email = NEW.email AND status = 'accepted'
    LIMIT 1
  )
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_user_created
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION associate_user_with_invitation();
```

---

### Actualizar updated_at

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a todas las tablas con updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_producers_updated_at
  BEFORE UPDATE ON producers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_ticket_types_updated_at
  BEFORE UPDATE ON ticket_types
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

## 📊 QUERIES COMUNES

### Eventos con stats

```sql
SELECT 
  e.*,
  COALESCE(SUM(tt.sold_quantity), 0) as sold_count,
  COALESCE(MIN(tt.price), 0) as min_price,
  COALESCE(MAX(tt.price), 0) as max_price
FROM events e
LEFT JOIN ticket_types tt ON e.id = tt.event_id AND tt.is_active = true
WHERE e.producer_id = $1
GROUP BY e.id
ORDER BY e.start_datetime DESC;
```

---

### Tickets de un usuario

```sql
SELECT 
  t.*,
  e.title as event_title,
  e.start_datetime,
  tt.name as ticket_type_name
FROM tickets t
JOIN events e ON t.event_id = e.id
JOIN ticket_types tt ON t.ticket_type_id = tt.id
WHERE t.owner_id = $1 
  AND t.status = 'valid'
ORDER BY e.start_datetime ASC;
```

---

### Orders de un usuario

```sql
SELECT 
  o.*,
  e.title as event_title,
  e.image_url as event_image,
  ARRAY_AGG(
    json_build_object(
      'ticket_type_id', oi.ticket_type_id,
      'quantity', oi.quantity,
      'price', oi.price
    )
  ) as items
FROM orders o
JOIN events e ON o.event_id = e.id
LEFT JOIN order_items oi ON o.id = oi.order_id
WHERE o.user_id = $1
GROUP BY o.id, e.title, e.image_url
ORDER BY o.created_at DESC;
```

---

## 🚀 MIGRATIONS

### Script inicial

```sql
-- Ejecutar en orden:
1. CREATE TABLE producers;
2. CREATE TABLE users;
3. CREATE TABLE user_invitations;
4. CREATE TABLE events;
5. CREATE TABLE ticket_types;
6. CREATE TABLE tickets;
7. CREATE TABLE orders;
8. CREATE TABLE order_items;
9. CREATE TABLE coupons;

-- Luego:
10. CREATE POLICIES (RLS);
11. CREATE TRIGGERS;
12. CREATE INDEXES;
```

---

## 🔧 MANTENIMIENTO

### Limpiar invitaciones expiradas

```sql
UPDATE user_invitations
SET status = 'expired'
WHERE status = 'pending' 
  AND expires_at IS NOT NULL 
  AND expires_at < NOW();
```

---

### Calcular sold_quantity

```sql
-- Si sold_quantity está desincronizado
UPDATE ticket_types tt
SET sold_quantity = (
  SELECT COUNT(*) 
  FROM tickets t 
  WHERE t.ticket_type_id = tt.id 
    AND t.status != 'cancelled'
);
```
