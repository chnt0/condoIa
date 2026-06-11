-- V4__create_paquetes_table.sql

CREATE TYPE estado_paquete AS ENUM ('PENDIENTE', 'ENTREGADO');

CREATE TABLE paquetes (
    id                      BIGSERIAL PRIMARY KEY,
    condominio_id           BIGINT NOT NULL REFERENCES condominios(id),
    usuario_destinatario_id BIGINT NOT NULL REFERENCES usuarios(id),
    descripcion             VARCHAR(500) NOT NULL,
    notas                   TEXT,
    fecha_hora_llegada      TIMESTAMP NOT NULL,
    guardia_registro_id     BIGINT NOT NULL REFERENCES usuarios(id),
    estado                  estado_paquete NOT NULL DEFAULT 'PENDIENTE',
    fecha_hora_entrega      TIMESTAMP,
    guardia_entrega_id      BIGINT REFERENCES usuarios(id),
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_paquetes_condominio ON paquetes(condominio_id);
CREATE INDEX idx_paquetes_destinatario ON paquetes(usuario_destinatario_id);
CREATE INDEX idx_paquetes_estado ON paquetes(estado);

CREATE TRIGGER update_paquetes_updated_at
    BEFORE UPDATE ON paquetes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
