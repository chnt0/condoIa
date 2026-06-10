-- V3__create_pagos_tables.sql

CREATE TYPE tipo_cuota AS ENUM ('MENSUAL', 'EXTRAORDINARIA');
CREATE TYPE estado_pago AS ENUM ('PENDIENTE', 'REPORTADO', 'CONFIRMADO', 'RECHAZADO');

CREATE TABLE cuotas (
    id              BIGSERIAL PRIMARY KEY,
    condominio_id   BIGINT NOT NULL REFERENCES condominios(id),
    tipo            tipo_cuota NOT NULL,
    concepto        VARCHAR(255) NOT NULL,
    monto           NUMERIC(10,2) NOT NULL,
    mes             VARCHAR(7),
    fecha_vencimiento DATE NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cuota_usuarios (
    id                  BIGSERIAL PRIMARY KEY,
    cuota_id            BIGINT NOT NULL REFERENCES cuotas(id),
    usuario_id          BIGINT NOT NULL REFERENCES usuarios(id),
    estado              estado_pago NOT NULL DEFAULT 'PENDIENTE',
    referencia_pago     VARCHAR(255),
    notas_usuario       TEXT,
    notas_admin         TEXT,
    fecha_reporte       TIMESTAMP,
    fecha_confirmacion  TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cuota_id, usuario_id)
);

CREATE INDEX idx_cuotas_condominio ON cuotas(condominio_id);
CREATE INDEX idx_cuota_usuarios_cuota ON cuota_usuarios(cuota_id);
CREATE INDEX idx_cuota_usuarios_usuario ON cuota_usuarios(usuario_id);
CREATE INDEX idx_cuota_usuarios_estado ON cuota_usuarios(estado);

CREATE TRIGGER update_cuotas_updated_at
    BEFORE UPDATE ON cuotas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cuota_usuarios_updated_at
    BEFORE UPDATE ON cuota_usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
