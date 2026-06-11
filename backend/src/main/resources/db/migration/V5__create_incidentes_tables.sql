-- V5__create_incidentes_tables.sql

CREATE TYPE categoria_incidente AS ENUM (
    'MANTENIMIENTO', 'SEGURIDAD', 'RUIDO', 'LIMPIEZA', 'OTRO'
);

CREATE TYPE prioridad_incidente AS ENUM ('BAJA', 'MEDIA', 'ALTA');

CREATE TYPE estado_incidente AS ENUM (
    'PENDIENTE', 'EN_PROCESO', 'RESUELTO', 'CANCELADO'
);

CREATE TABLE incidentes (
    id                  BIGSERIAL PRIMARY KEY,
    condominio_id       BIGINT NOT NULL REFERENCES condominios(id),
    usuario_reporta_id  BIGINT NOT NULL REFERENCES usuarios(id),
    categoria           categoria_incidente NOT NULL,
    titulo              VARCHAR(200) NOT NULL,
    descripcion         TEXT NOT NULL,
    ubicacion           VARCHAR(200) NOT NULL,
    prioridad           prioridad_incidente NOT NULL,
    estado              estado_incidente NOT NULL DEFAULT 'PENDIENTE',
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE incidente_comentarios (
    id            BIGSERIAL PRIMARY KEY,
    incidente_id  BIGINT NOT NULL REFERENCES incidentes(id),
    usuario_id    BIGINT NOT NULL REFERENCES usuarios(id),
    comentario    TEXT NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_incidentes_condominio ON incidentes(condominio_id);
CREATE INDEX idx_incidentes_usuario ON incidentes(usuario_reporta_id);
CREATE INDEX idx_incidentes_estado ON incidentes(estado);
CREATE INDEX idx_incidente_comentarios_incidente ON incidente_comentarios(incidente_id);

CREATE TRIGGER update_incidentes_updated_at
    BEFORE UPDATE ON incidentes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
