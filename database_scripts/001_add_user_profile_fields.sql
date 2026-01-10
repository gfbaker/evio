-- ============================================
-- MIGRACIÓN: Campos adicionales perfil usuario
-- Fecha: 06 Enero 2026
-- ============================================

-- 1. Agregar nuevas columnas a users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS dni TEXT,
  ADD COLUMN IF NOT EXISTS birth_date DATE,
  ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say'));

-- 2. Crear índice para DNI (debe ser único si existe)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_dni ON users(dni) WHERE dni IS NOT NULL;

-- 3. Trigger para prevenir modificación de DNI y birth_date después del primer set
CREATE OR REPLACE FUNCTION prevent_profile_field_modification()
RETURNS TRIGGER AS $$
BEGIN
  -- Si DNI ya existe y se intenta cambiar → error
  IF OLD.dni IS NOT NULL AND NEW.dni IS DISTINCT FROM OLD.dni THEN
    RAISE EXCEPTION 'El DNI no puede ser modificado una vez establecido';
  END IF;

  -- Si birth_date ya existe y se intenta cambiar → error
  IF OLD.birth_date IS NOT NULL AND NEW.birth_date IS DISTINCT FROM OLD.birth_date THEN
    RAISE EXCEPTION 'La fecha de nacimiento no puede ser modificada una vez establecida';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger
DROP TRIGGER IF EXISTS prevent_profile_field_modification_trigger ON users;
CREATE TRIGGER prevent_profile_field_modification_trigger
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION prevent_profile_field_modification();

-- 4. Comentarios
COMMENT ON COLUMN users.dni IS 'Documento Nacional de Identidad - Solo se puede establecer una vez';
COMMENT ON COLUMN users.birth_date IS 'Fecha de nacimiento - Solo se puede establecer una vez';
COMMENT ON COLUMN users.gender IS 'Género del usuario - Puede ser modificado';
