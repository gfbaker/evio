-- ============================================
-- CORREGIR PERMISOS RLS PARA AVATARS
-- ============================================

-- 1. Verificar estado actual del bucket 'avatars'
SELECT * FROM storage.buckets WHERE id = 'avatars';

-- 2. Asegurar que el bucket sea PÚBLICO
UPDATE storage.buckets
SET public = true
WHERE id = 'avatars';

-- 3. ELIMINAR políticas existentes que puedan estar bloqueando
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;

-- 4. CREAR POLÍTICAS CORRECTAS PARA AVATARS

-- ✅ LECTURA PÚBLICA (cualquiera puede ver avatars)
CREATE POLICY "Public read access for avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- ✅ INSERT: Usuarios autenticados pueden subir SUS avatars
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ✅ UPDATE: Usuarios pueden actualizar SUS avatars
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ✅ DELETE: Usuarios pueden eliminar SUS avatars
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- 5. VERIFICAR QUE LAS POLÍTICAS SE CREARON
-- ============================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%avatar%';

-- ============================================
-- 6. CREAR BUCKET SI NO EXISTE
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- ============================================
-- 7. VERIFICAR ESTRUCTURA DE PATHS
-- ============================================
-- Los avatars deben guardarse como: avatars/{user_id}/{filename}
-- Ejemplo: avatars/abc-123-def/avatar.jpg

-- Ver archivos actuales en el bucket
SELECT 
  name,
  bucket_id,
  owner,
  created_at
FROM storage.objects
WHERE bucket_id = 'avatars'
ORDER BY created_at DESC
LIMIT 10;
