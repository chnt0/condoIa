-- V13__add_foto_vehiculo_to_visitas.sql
-- Foto de placa o vehículo para visitas directas registradas por el guardia
ALTER TABLE visitas ADD COLUMN foto_vehiculo TEXT;
-- Tipo de visita: PROGRAMADA=con QR, DIRECTA=registrada por guardia en el momento
ALTER TABLE visitas ADD COLUMN tipo_visita VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA';
