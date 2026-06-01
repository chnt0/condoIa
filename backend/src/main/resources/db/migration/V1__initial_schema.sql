-- Initial schema for multi-tenant condo management system

-- Create ENUM types
CREATE TYPE rol_usuario AS ENUM ('SUPERADMIN', 'ADMIN', 'USUARIO', 'GUARDIA');
CREATE TYPE plataforma_device AS ENUM ('ANDROID', 'IOS', 'WEB');

-- Table: condominios
CREATE TABLE condominios (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    direccion TEXT,
    num_unidades INTEGER NOT NULL DEFAULT 0,
    configuracion_json JSONB,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Table: usuarios
CREATE TABLE usuarios (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nombre_completo VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    rol rol_usuario NOT NULL DEFAULT 'USUARIO',
    condominio_id BIGINT,
    unidad_habitacional VARCHAR(50),
    es_propietario BOOLEAN NOT NULL DEFAULT FALSE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_condominio FOREIGN KEY (condominio_id) REFERENCES condominios(id)
);

-- Table: device_tokens
CREATE TABLE device_tokens (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL,
    token TEXT NOT NULL,
    plataforma plataforma_device NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_usuarios_condominio_id ON usuarios(condominio_id);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_usuarios_username ON usuarios(username);
CREATE INDEX idx_usuarios_email ON usuarios(email);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for condominios table
CREATE TRIGGER update_condominios_updated_at
    BEFORE UPDATE ON condominios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for usuarios table
CREATE TRIGGER update_usuarios_updated_at
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Seed data: Condominio
INSERT INTO condominios (nombre, direccion, num_unidades, configuracion_json, activo)
VALUES (
    'Residencial Las Palmas',
    'Av. Principal 123, Ciudad',
    50,
    '{"horario_vigilancia": "24/7", "amenidades": ["piscina", "gimnasio", "salon_eventos"]}',
    TRUE
);

-- Seed data: Users
-- Password for both users is "admin123" hashed with BCrypt strength 12
INSERT INTO usuarios (username, email, password_hash, nombre_completo, telefono, rol, condominio_id, activo)
VALUES
(
    'superadmin',
    'superadmin@condos.com',
    '$2a$12$ANmx/kWsB/1V8Mo3zEsD5eW3LDWw5qzt/2fxfntmP3202/Rh3DdqO',
    'Super Administrador',
    '555-0001',
    'SUPERADMIN',
    NULL,
    TRUE
),
(
    'admin',
    'admin@laspalmas.com',
    '$2a$12$ANmx/kWsB/1V8Mo3zEsD5eW3LDWw5qzt/2fxfntmP3202/Rh3DdqO',
    'Administrador Las Palmas',
    '555-0002',
    'ADMIN',
    1,
    TRUE
);
