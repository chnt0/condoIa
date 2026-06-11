-- V7__create_areas_reservaciones_tables.sql

CREATE TYPE estado_reservacion AS ENUM ('ACTIVA', 'CANCELADA');

CREATE TABLE areas_comunes (
    id                          BIGSERIAL PRIMARY KEY,
    condominio_id               BIGINT NOT NULL REFERENCES condominios(id),
    nombre                      VARCHAR(100) NOT NULL,
    descripcion                 TEXT,
    capacidad                   INT NOT NULL,
    horario_inicio              TIME NOT NULL,
    horario_fin                 TIME NOT NULL,
    duracion_bloque_minutos     INT NOT NULL,
    max_reservas_mes_por_usuario INT NOT NULL,
    anticipacion_minima_horas   INT NOT NULL,
    anticipacion_maxima_dias    INT NOT NULL,
    activa                      BOOLEAN NOT NULL DEFAULT true,
    created_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reservaciones (
    id               BIGSERIAL PRIMARY KEY,
    area_comun_id    BIGINT NOT NULL REFERENCES areas_comunes(id),
    usuario_id       BIGINT NOT NULL REFERENCES usuarios(id),
    fecha_hora_inicio TIMESTAMP NOT NULL,
    fecha_hora_fin   TIMESTAMP NOT NULL,
    estado           estado_reservacion NOT NULL DEFAULT 'ACTIVA',
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_areas_comunes_condominio ON areas_comunes(condominio_id);
CREATE INDEX idx_reservaciones_area ON reservaciones(area_comun_id);
CREATE INDEX idx_reservaciones_usuario ON reservaciones(usuario_id);
CREATE INDEX idx_reservaciones_estado ON reservaciones(estado);
CREATE INDEX idx_reservaciones_inicio ON reservaciones(fecha_hora_inicio);

CREATE TRIGGER update_areas_comunes_updated_at
    BEFORE UPDATE ON areas_comunes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
