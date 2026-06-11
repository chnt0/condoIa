-- V6__create_notificaciones_table.sql

CREATE TYPE segmento_notificacion AS ENUM ('TODOS', 'EDIFICIO_X');

CREATE TABLE notificaciones (
    id                BIGSERIAL PRIMARY KEY,
    condominio_id     BIGINT NOT NULL REFERENCES condominios(id),
    admin_creador_id  BIGINT NOT NULL REFERENCES usuarios(id),
    titulo            VARCHAR(200) NOT NULL,
    mensaje           TEXT NOT NULL,
    segmento          segmento_notificacion NOT NULL,
    edificio          VARCHAR(50),
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notificaciones_condominio ON notificaciones(condominio_id);
CREATE INDEX idx_notificaciones_created ON notificaciones(created_at DESC);
