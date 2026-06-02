-- V2__create_visitas_table.sql

-- Estado de visita enum
CREATE TYPE estado_visita AS ENUM ('PROGRAMADA', 'COMPLETADA', 'CANCELADA');

-- Tabla de visitas
CREATE TABLE visitas (
    id BIGSERIAL PRIMARY KEY,
    condominio_id BIGINT NOT NULL REFERENCES condominios(id),
    usuario_id BIGINT NOT NULL REFERENCES usuarios(id),
    nombre_visitante VARCHAR(200) NOT NULL,
    telefono_visitante VARCHAR(20),
    fecha_hora_programada TIMESTAMP NOT NULL,
    codigo_qr_hash VARCHAR(500) NOT NULL UNIQUE,
    motivo VARCHAR(500),
    vehiculo_placas VARCHAR(20),
    estado estado_visita NOT NULL DEFAULT 'PROGRAMADA',
    fecha_hora_entrada TIMESTAMP,
    guardia_entrada_id BIGINT REFERENCES usuarios(id),
    notas TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_visitas_condominio ON visitas(condominio_id);
CREATE INDEX idx_visitas_usuario ON visitas(usuario_id);
CREATE INDEX idx_visitas_qr ON visitas(codigo_qr_hash);
CREATE INDEX idx_visitas_fecha ON visitas(fecha_hora_programada);
CREATE INDEX idx_visitas_estado ON visitas(estado);

-- Trigger para updated_at
CREATE TRIGGER update_visitas_updated_at
    BEFORE UPDATE ON visitas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios
COMMENT ON TABLE visitas IS 'Registro de visitas programadas y su estado';
COMMENT ON COLUMN visitas.codigo_qr_hash IS 'Hash único para generar y validar código QR';
COMMENT ON COLUMN visitas.estado IS 'Estado actual: PROGRAMADA, COMPLETADA, CANCELADA';
