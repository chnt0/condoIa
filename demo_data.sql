-- ============================================================
-- DATOS DEMO — Condominio Las Palmas (condominio_id = 1)
-- Ejecutar: psql -U jandrade2 -d condos_db -f demo_data.sql
--
-- Contraseña de todos los usuarios: admin123
-- Nota: usa residentes existentes del condominio 1
-- ============================================================

BEGIN;

-- ─────────────────────────────────────────
-- 1. GUARDIAS DEMO (si no existen)
-- ─────────────────────────────────────────

INSERT INTO usuarios (username, email, password_hash, nombre_completo, telefono, rol,
                      condominio_id, unidad_habitacional, es_propietario, activo)
VALUES
('guardia.miguel2', 'miguel2.guardia@laspalmas.com',
 '$2a$12$ANmx/kWsB/1V8Mo3zEsD5eW3LDWw5qzt/2fxfntmP3202/Rh3DdqO',
 'Miguel García Ruiz', '5552000010', 'GUARDIA', 1, NULL, false, true),

('guardia.luis2', 'luis2.guardia@laspalmas.com',
 '$2a$12$ANmx/kWsB/1V8Mo3zEsD5eW3LDWw5qzt/2fxfntmP3202/Rh3DdqO',
 'Luis Martínez Ávila', '5552000011', 'GUARDIA', 1, NULL, false, true)

ON CONFLICT (username) DO NOTHING;

-- ─────────────────────────────────────────
-- 2. CUOTAS MENSUALES 2026 ($950/mes)
--    Vencen el último día de cada mes
-- ─────────────────────────────────────────

INSERT INTO cuotas (condominio_id, tipo, concepto, monto, mes, fecha_vencimiento)
VALUES
(1,'MENSUAL','Mantenimiento Enero 2026',    950.00,'2026-01','2026-01-31'),
(1,'MENSUAL','Mantenimiento Febrero 2026',  950.00,'2026-02','2026-02-28'),
(1,'MENSUAL','Mantenimiento Marzo 2026',    950.00,'2026-03','2026-03-31'),
(1,'MENSUAL','Mantenimiento Abril 2026',    950.00,'2026-04','2026-04-30'),
(1,'MENSUAL','Mantenimiento Mayo 2026',     950.00,'2026-05','2026-05-31'),
(1,'MENSUAL','Mantenimiento Junio 2026',    950.00,'2026-06','2026-06-30'),
(1,'MENSUAL','Mantenimiento Julio 2026',    950.00,'2026-07','2026-07-31'),
(1,'MENSUAL','Mantenimiento Agosto 2026',   950.00,'2026-08','2026-08-31'),
(1,'MENSUAL','Mantenimiento Septiembre 2026',950.00,'2026-09','2026-09-30'),
(1,'MENSUAL','Mantenimiento Octubre 2026',  950.00,'2026-10','2026-10-31'),
(1,'MENSUAL','Mantenimiento Noviembre 2026',950.00,'2026-11','2026-11-30'),
(1,'MENSUAL','Mantenimiento Diciembre 2026',950.00,'2026-12','2026-12-31');

-- ─────────────────────────────────────────
-- 3. CUOTA_USUARIOS
--    Toma los primeros 10 residentes del condominio.
--    Residentes 1-8: CONFIRMADO en meses vencidos (Ene-Jun 2026) → buenos pagadores
--    Residentes 9-10: PENDIENTE en todos los meses vencidos → morosos
--    Meses futuros (Jul-Dic): todos PENDIENTE
-- ─────────────────────────────────────────

DO $$
DECLARE
    r_record  RECORD;
    c_record  RECORD;
    r_seq     INT := 0;
    v_estado  VARCHAR;
    es_moroso BOOLEAN;
    es_futuro BOOLEAN;
BEGIN
    -- Recorrer los primeros 10 USUARIO activos del condominio
    FOR r_record IN
        SELECT id, unidad_habitacional
        FROM usuarios
        WHERE condominio_id = 1 AND rol = 'USUARIO' AND activo = true
        ORDER BY id
        LIMIT 10
    LOOP
        r_seq := r_seq + 1;
        es_moroso := (r_seq >= 9);  -- residentes 9 y 10 son morosos

        -- Recorrer las 12 cuotas 2026 del condominio
        FOR c_record IN
            SELECT id, mes, fecha_vencimiento
            FROM cuotas
            WHERE condominio_id = 1 AND mes LIKE '2026-%'
            ORDER BY mes
        LOOP
            es_futuro := (c_record.fecha_vencimiento > CURRENT_DATE);

            IF es_futuro THEN
                v_estado := 'PENDIENTE';
            ELSIF es_moroso THEN
                v_estado := 'PENDIENTE';
            ELSE
                v_estado := 'CONFIRMADO';
            END IF;

            INSERT INTO cuota_usuarios
                (cuota_id, usuario_id, estado, referencia_pago,
                 notas_usuario, notas_admin,
                 fecha_reporte, fecha_confirmacion)
            VALUES (
                c_record.id,
                r_record.id,
                v_estado,
                CASE WHEN v_estado = 'CONFIRMADO'
                     THEN 'TRF-' || REPLACE(c_record.mes,'-','') || '-' || LPAD(r_record.id::text,3,'0')
                     ELSE NULL END,
                CASE WHEN v_estado = 'CONFIRMADO' THEN 'Transferencia bancaria' ELSE NULL END,
                CASE WHEN v_estado = 'CONFIRMADO' THEN 'Comprobante verificado' ELSE NULL END,
                CASE WHEN v_estado = 'CONFIRMADO'
                     THEN (c_record.fecha_vencimiento - INTERVAL '5 days')::TIMESTAMP
                     ELSE NULL END,
                CASE WHEN v_estado = 'CONFIRMADO'
                     THEN (c_record.fecha_vencimiento - INTERVAL '3 days')::TIMESTAMP
                     ELSE NULL END
            )
            ON CONFLICT (cuota_id, usuario_id) DO NOTHING;

        END LOOP;
    END LOOP;

    RAISE NOTICE 'Cuota_usuarios insertados correctamente';
END $$;

-- ─────────────────────────────────────────
-- 4. ÁREAS COMUNES
-- ─────────────────────────────────────────

INSERT INTO areas_comunes
    (condominio_id, nombre, descripcion, capacidad,
     horario_inicio, horario_fin, duracion_bloque_minutos,
     max_reservas_mes_por_usuario, anticipacion_minima_horas,
     anticipacion_maxima_dias, activa)
VALUES
(1,
 'Alberca',
 'Alberca olímpica con área de descanso y regaderas. Prohibido el uso de flotadores.',
 20,
 '08:00', '21:00',
 60,   -- bloques de 1 hora
 4,    -- máx 4 reservas/mes por residente
 1,    -- 1 hora de anticipación mínima
 30,   -- hasta 30 días adelante
 true),

(1,
 'Salón de Eventos',
 'Salón multiusos con cocina equipada y audio. Capacidad para 60 personas.',
 60,
 '09:00', '23:00',
 120,  -- bloques de 2 horas
 2,    -- máx 2 reservas/mes por residente
 24,   -- 24 horas de anticipación mínima
 60,   -- hasta 60 días adelante
 true)

ON CONFLICT DO NOTHING;

COMMIT;

-- ─────────────────────────────────────────
-- RESUMEN
-- ─────────────────────────────────────────
SELECT '=== RESUMEN DE DATOS DEMO ===' AS info;

SELECT 'Residentes en el condominio' AS descripcion, COUNT(*)::text AS valor
FROM usuarios WHERE condominio_id = 1 AND rol = 'USUARIO' AND activo = true

UNION ALL SELECT 'Cuotas 2026 creadas', COUNT(*)::text
FROM cuotas WHERE condominio_id = 1 AND mes LIKE '2026-%'

UNION ALL SELECT 'Registros individuales (cuota_usuarios)', COUNT(*)::text
FROM cuota_usuarios cu JOIN cuotas c ON c.id = cu.cuota_id
WHERE c.condominio_id = 1 AND c.mes LIKE '2026-%'

UNION ALL SELECT 'Pagos CONFIRMADOS', COUNT(*)::text
FROM cuota_usuarios cu JOIN cuotas c ON c.id = cu.cuota_id
WHERE c.condominio_id = 1 AND c.mes LIKE '2026-%' AND cu.estado = 'CONFIRMADO'

UNION ALL SELECT 'Pagos PENDIENTES (morosos + futuros)', COUNT(*)::text
FROM cuota_usuarios cu JOIN cuotas c ON c.id = cu.cuota_id
WHERE c.condominio_id = 1 AND c.mes LIKE '2026-%' AND cu.estado = 'PENDIENTE'

UNION ALL SELECT 'Deuda vencida ($ monto pendiente antes de hoy)', COALESCE(SUM(c.monto),0)::text
FROM cuota_usuarios cu JOIN cuotas c ON c.id = cu.cuota_id
WHERE c.condominio_id = 1 AND cu.estado = 'PENDIENTE' AND c.fecha_vencimiento < CURRENT_DATE

UNION ALL SELECT 'Áreas comunes', COUNT(*)::text
FROM areas_comunes WHERE condominio_id = 1;
