-- V9__convert_rol_to_varchar.sql
-- Convierte columna rol de usuarios de enum custom a VARCHAR

ALTER TABLE usuarios ALTER COLUMN rol TYPE VARCHAR(20) USING rol::text;
DROP TYPE IF EXISTS rol_usuario CASCADE;
