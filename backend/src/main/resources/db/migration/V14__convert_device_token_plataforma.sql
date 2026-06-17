-- V14__convert_device_token_plataforma.sql
-- Convierte plataforma de device_tokens de enum a VARCHAR para compatibilidad con JPA
ALTER TABLE device_tokens ALTER COLUMN plataforma TYPE VARCHAR(10) USING plataforma::text;
DROP TYPE IF EXISTS plataforma_device CASCADE;
