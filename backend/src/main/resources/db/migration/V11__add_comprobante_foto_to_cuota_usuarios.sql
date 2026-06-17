-- V11__add_comprobante_foto_to_cuota_usuarios.sql
-- Almacena la foto del comprobante de pago como base64
ALTER TABLE cuota_usuarios ADD COLUMN comprobante_foto TEXT;
