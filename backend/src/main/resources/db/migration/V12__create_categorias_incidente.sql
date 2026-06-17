-- V12__create_categorias_incidente.sql
-- Catálogo configurable de categorías de incidentes por condominio

CREATE TABLE categorias_incidente (
    id            BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT NOT NULL REFERENCES condominios(id),
    nombre        VARCHAR(100) NOT NULL,
    activa        BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (condominio_id, nombre)
);

CREATE INDEX idx_categorias_incidente_condominio ON categorias_incidente(condominio_id);

-- Insertar categorías por defecto para cada condominio existente
INSERT INTO categorias_incidente (condominio_id, nombre)
SELECT id, 'Mantenimiento' FROM condominios
UNION ALL
SELECT id, 'Seguridad'     FROM condominios
UNION ALL
SELECT id, 'Ruido'         FROM condominios
UNION ALL
SELECT id, 'Limpieza'      FROM condominios
UNION ALL
SELECT id, 'Otro'          FROM condominios;
