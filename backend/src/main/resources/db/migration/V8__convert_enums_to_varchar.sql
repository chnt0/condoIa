-- V8__convert_enums_to_varchar.sql
-- Convierte columnas de tipo enum PostgreSQL personalizado a VARCHAR para
-- compatibilidad con JPA/Hibernate (@Enumerated(EnumType.STRING))

-- visitas
ALTER TABLE visitas ALTER COLUMN estado TYPE VARCHAR(20) USING estado::text;

-- cuotas
ALTER TABLE cuotas ALTER COLUMN tipo TYPE VARCHAR(20) USING tipo::text;

-- cuota_usuarios
ALTER TABLE cuota_usuarios ALTER COLUMN estado TYPE VARCHAR(20) USING estado::text;

-- paquetes
ALTER TABLE paquetes ALTER COLUMN estado TYPE VARCHAR(20) USING estado::text;

-- incidentes
ALTER TABLE incidentes ALTER COLUMN categoria TYPE VARCHAR(20) USING categoria::text;
ALTER TABLE incidentes ALTER COLUMN prioridad TYPE VARCHAR(10) USING prioridad::text;
ALTER TABLE incidentes ALTER COLUMN estado TYPE VARCHAR(20) USING estado::text;

-- notificaciones
ALTER TABLE notificaciones ALTER COLUMN segmento TYPE VARCHAR(20) USING segmento::text;

-- reservaciones
ALTER TABLE reservaciones ALTER COLUMN estado TYPE VARCHAR(20) USING estado::text;

-- usuarios (rol ya es VARCHAR en la V1, verificar)
-- areas_comunes no tiene columnas enum custom

-- Drop tipos custom ya no necesarios (CASCADE elimina defaults y constraints dependientes)
DROP TYPE IF EXISTS estado_visita CASCADE;
DROP TYPE IF EXISTS tipo_cuota CASCADE;
DROP TYPE IF EXISTS estado_pago CASCADE;
DROP TYPE IF EXISTS estado_paquete CASCADE;
DROP TYPE IF EXISTS categoria_incidente CASCADE;
DROP TYPE IF EXISTS prioridad_incidente CASCADE;
DROP TYPE IF EXISTS estado_incidente CASCADE;
DROP TYPE IF EXISTS segmento_notificacion CASCADE;
DROP TYPE IF EXISTS estado_reservacion CASCADE;
