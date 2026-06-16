# Casos de Prueba — Sistema de Condominios

**Versión:** 1.0  
**Fecha:** 2026-06-16  
**Ambiente de pruebas:** https://condov.onrender.com (web) / APK (Android)  
**Backend:** https://condoia.onrender.com

---

## Credenciales de prueba

| Usuario | Contraseña | Rol |
|---|---|---|
| `admin` | `admin123` | ADMIN |
| `superadmin` | `admin123` | SUPERADMIN |
| `residente1` | `pass123` | USUARIO (Torre A-101) |
| `guardia1` | `pass123` | GUARDIA |

---

## Convenciones

- ✅ Resultado esperado: éxito
- ❌ Resultado esperado: error / rechazo
- **CP** = Caso de Prueba

---

## 1. AUTENTICACIÓN (todos los roles)

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-AUTH-01 | Login exitoso ADMIN | Ingresar `admin` / `admin123` | Redirige al Dashboard. Se muestra nombre y rol. |
| CP-AUTH-02 | Login exitoso USUARIO | Ingresar `residente1` / `pass123` | Redirige a Inicio. Se muestra tab "Mis Visitas". |
| CP-AUTH-03 | Login exitoso GUARDIA | Ingresar `guardia1` / `pass123` | Redirige a pantalla "Escanear QR". |
| CP-AUTH-04 | Login con contraseña incorrecta | Ingresar `admin` / `wrongpass` | ❌ Mensaje "Credenciales inválidas". No redirige. |
| CP-AUTH-05 | Login con usuario inexistente | Ingresar `noexiste` / `pass123` | ❌ Mensaje "Credenciales inválidas". |
| CP-AUTH-06 | Bloqueo por intentos fallidos | Intentar login incorrecto 5 veces seguidas | ❌ Mensaje "IP bloqueada por 5 minutos". |
| CP-AUTH-07 | Cerrar sesión | Login → clic en "Perfil" → "Cerrar Sesión" | Regresa a pantalla de login. Token eliminado. |
| CP-AUTH-08 | Acceso sin sesión | Ingresar URL directa `/home` sin estar logueado | Redirige a login. |

---

## 2. ROL: ADMIN

### 2.1 Dashboard

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-ADMIN-01 | Ver Dashboard | Muestra tarjetas con conteos: Hoy, Programadas, Completadas, Canceladas. |

### 2.2 Gestión de Usuarios

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-ADMIN-02 | Listar usuarios | Tab "Gestión" | Muestra lista de usuarios del condominio. |
| CP-ADMIN-03 | Crear usuario GUARDIA | Gestión → FAB + → llenar formulario con rol GUARDIA | ✅ Usuario creado. Aparece en la lista. |
| CP-ADMIN-04 | Crear usuario USUARIO | Formulario con rol USUARIO y unidad habitacional | ✅ Usuario creado con unidad asignada. |
| CP-ADMIN-05 | Crear usuario ADMIN | Formulario con rol ADMIN | ❌ Error: ADMIN no puede crear otro ADMIN. |
| CP-ADMIN-06 | Editar usuario existente | Tap en usuario → editar nombre o teléfono → guardar | ✅ Datos actualizados correctamente. |
| CP-ADMIN-07 | Desactivar usuario | Tap en usuario → toggle "Activo" | ✅ Usuario marcado como inactivo. No puede iniciar sesión. |
| CP-ADMIN-08 | Reactivar usuario | Tap en usuario inactivo → toggle "Activo" | ✅ Usuario vuelve a poder iniciar sesión. |
| CP-ADMIN-09 | Crear usuario con email duplicado | Formulario con email ya existente | ❌ Error: "El email ya está en uso". |

### 2.3 Visitas (ADMIN)

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-ADMIN-10 | Ver todas las visitas | Tab "Visitas" | Muestra todas las visitas del condominio con estado. |
| CP-ADMIN-11 | Cancelar visita de cualquier residente | Tap en visita programada → Cancelar | ✅ Visita cambia a estado CANCELADA. |

### 2.4 Cuotas y Pagos

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-ADMIN-12 | Crear cuota MENSUAL | Tab "Cuotas" → FAB + → tipo MENSUAL, concepto, monto, mes, fecha vencimiento | ✅ Cuota creada. Se genera un registro por cada residente activo. |
| CP-ADMIN-13 | Crear cuota EXTRAORDINARIA | FAB + → tipo EXTRAORDINARIA → seleccionar residentes específicos | ✅ Cuota creada solo para residentes seleccionados. |
| CP-ADMIN-14 | Crear cuota sin monto | Formulario sin monto | ❌ Error de validación. |
| CP-ADMIN-15 | Ver detalle de cuota | Tap en cuota → ver lista de residentes con estado | ✅ Muestra residente, estado (PENDIENTE/REPORTADO/CONFIRMADO/RECHAZADO). |
| CP-ADMIN-16 | Confirmar pago reportado | Detalle cuota → residente con estado REPORTADO → "Confirmar" | ✅ Estado cambia a CONFIRMADO. |
| CP-ADMIN-17 | Rechazar pago reportado | Detalle → estado REPORTADO → "Rechazar" → ingresar motivo | ✅ Estado cambia a RECHAZADO. Motivo visible para residente. |
| CP-ADMIN-18 | Rechazar sin nota | "Rechazar" sin ingresar motivo | ❌ No permite enviar. Campo requerido. |

### 2.5 Paquetes (ADMIN)

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-ADMIN-19 | Ver todos los paquetes | Tab "Paquetes" → Tab "Pendientes" | Muestra todos los paquetes pendientes del condominio. |
| CP-ADMIN-20 | Ver historial de paquetes | Tab "Entregados" | Muestra paquetes ya entregados. |

### 2.6 Incidentes (ADMIN)

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-ADMIN-21 | Ver todos los incidentes | Tab "Incidentes" | Muestra tabs: Pendiente, En Proceso, Resuelto. |
| CP-ADMIN-22 | Cambiar estado a EN PROCESO | Tab "Pendiente" → tap incidente → dropdown "En Proceso" → "Actualizar estado" | ✅ Incidente aparece en tab "En Proceso". |
| CP-ADMIN-23 | Cambiar estado a RESUELTO | Incidente en "En Proceso" → "Resuelto" → actualizar | ✅ Incidente aparece en tab "Resuelto". |
| CP-ADMIN-24 | Comentar en incidente | Detalle de incidente → escribir comentario → enviar | ✅ Comentario aparece con nombre del admin y fecha. |
| CP-ADMIN-25 | Incidente CANCELADO no aparece | Residente cancela su incidente | ✅ No aparece en ningún tab para el ADMIN. |

### 2.7 Notificaciones (ADMIN)

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-ADMIN-26 | Crear aviso para todos | Tab "Avisos" → FAB + → segmento "Todos" → publicar | ✅ Aviso visible para todos los roles. |
| CP-ADMIN-27 | Crear aviso por edificio | FAB + → segmento "Por edificio" → ingresar "Torre A" → publicar | ✅ Solo visible para residentes de Torre A. |
| CP-ADMIN-28 | Crear aviso sin título | Formulario sin título | ❌ Error de validación. |
| CP-ADMIN-29 | Eliminar aviso | Detalle de aviso → ícono de borrar → confirmar | ✅ Aviso eliminado. Ya no aparece en la lista. |

### 2.8 Áreas Comunes (ADMIN)

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-ADMIN-30 | Crear área común | Tab "Áreas" → FAB + → llenar formulario (nombre, horario, duración, máx reservas) | ✅ Área creada y visible en la lista. |
| CP-ADMIN-31 | Editar área | Tap en área → modificar datos → Guardar Cambios | ✅ Datos actualizados. |
| CP-ADMIN-32 | Desactivar área | Switch en área → toggle off | ✅ Área ya no aparece disponible para residentes. |
| CP-ADMIN-33 | Reactivar área | Switch en área inactiva → toggle on | ✅ Área vuelve a estar disponible. |
| CP-ADMIN-34 | Ver todas las reservaciones | Tab "Áreas" → no tiene tab de reservaciones (solo gestión de áreas) | ✅ Lista de áreas con estado activo/inactivo. |

---

## 3. ROL: USUARIO (Residente)

### 3.1 Visitas

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-USR-01 | Crear visita | Tab "Nueva" → nombre visitante, fecha/hora, motivo → crear | ✅ Visita creada con estado PROGRAMADA. QR generado. |
| CP-USR-02 | Ver mis visitas | Tab "Mis Visitas" | Lista de visitas propias con estado. |
| CP-USR-03 | Ver QR de visita | Tap en visita → ver imagen QR | ✅ Imagen QR visible para mostrar al guardia. |
| CP-USR-04 | Cancelar visita propia | Tap en visita → Cancelar | ✅ Estado cambia a CANCELADA. |
| CP-USR-05 | Crear visita sin nombre de visitante | Formulario sin nombre | ❌ Error de validación. |
| CP-USR-06 | Crear visita con fecha pasada | Fecha anterior a hoy | ❌ Error o comportamiento según validación del sistema. |

### 3.2 Cuotas y Pagos

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-USR-07 | Ver mis cuotas | Tab "Cuotas" | Lista de cuotas con estado: PENDIENTE, REPORTADO, CONFIRMADO, RECHAZADO. |
| CP-USR-08 | Reportar pago | Tap en cuota PENDIENTE → ingresar referencia → "Reportar Pago" | ✅ Estado cambia a REPORTADO. Referencia visible. |
| CP-USR-09 | Re-reportar pago rechazado | Tap en cuota RECHAZADO → ingresar nueva referencia | ✅ Estado vuelve a REPORTADO con nueva referencia. |
| CP-USR-10 | Reportar sin referencia | Formulario sin referencia de pago | ❌ Error: campo requerido. |
| CP-USR-11 | Ver motivo de rechazo | Cuota con estado RECHAZADO | ✅ Muestra nota del admin en rojo antes del formulario. |
| CP-USR-12 | Cuota CONFIRMADA no permite re-reportar | Cuota en estado CONFIRMADO | ❌ Sin botón para reportar. Solo lectura. |

### 3.3 Paquetes

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-USR-13 | Ver mis paquetes | Tab "Paquetes" → Tab "Pendientes" | Muestra paquetes pendientes de recoger. |
| CP-USR-14 | Ver historial de paquetes | Tab "Entregados" | Muestra paquetes ya entregados. |
| CP-USR-15 | No puede registrar paquetes | No hay FAB + en pantalla de paquetes | ✅ Solo lectura. Sin botón de registro. |

### 3.4 Incidentes

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-USR-16 | Reportar incidente | Tab "Incidentes" → FAB + → categoría, prioridad, título, descripción, ubicación | ✅ Incidente creado en estado PENDIENTE. |
| CP-USR-17 | Ver mis incidentes | Tab "Incidentes" | Solo muestra incidentes propios. |
| CP-USR-18 | Cancelar incidente PENDIENTE | Detalle → "Cancelar incidente" → confirmar | ✅ Incidente cancelado. Desaparece de los tabs. |
| CP-USR-19 | Cancelar incidente EN PROCESO | Detalle de incidente en proceso → cancelar | ✅ Permite cancelar. |
| CP-USR-20 | No puede cancelar incidente RESUELTO | Detalle de incidente resuelto | ✅ Sin botón de cancelar. Solo lectura. |
| CP-USR-21 | Comentar en su incidente | Detalle → escribir comentario → enviar | ✅ Comentario aparece con nombre del residente. |
| CP-USR-22 | No puede cambiar estado | Detalle de incidente | ✅ Sin dropdown de estado. Solo ADMIN puede cambiar. |
| CP-USR-23 | Crear incidente sin título | Formulario sin título | ❌ Error de validación. |

### 3.5 Notificaciones

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-USR-24 | Ver avisos para todos | Tab "Avisos" | Muestra avisos con segmento "Todos". |
| CP-USR-25 | Ver aviso de su edificio | Residente de Torre A | Muestra avisos de segmento "Torre A" + avisos "Todos". |
| CP-USR-26 | No ve aviso de otro edificio | Residente de Torre B | ✅ No ve avisos segmentados para "Torre A". |
| CP-USR-27 | No puede crear avisos | Tab "Avisos" | ✅ Sin FAB +. Solo lectura. |

### 3.6 Áreas Comunes y Reservaciones

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-USR-28 | Ver áreas disponibles | Tab "Áreas" → Tab "Áreas Disponibles" | Muestra solo áreas activas con horario y duración de bloque. |
| CP-USR-29 | Ver disponibilidad por fecha | Tap en área → elegir fecha en calendario | ✅ Muestra bloques: verde (disponible), gris (ocupado). |
| CP-USR-30 | Reservar bloque disponible | Tap en bloque verde → confirmar | ✅ Reservación creada. Bloque pasa a gris. |
| CP-USR-31 | No puede reservar bloque ocupado | Tap en bloque gris | ❌ Botón deshabilitado. No permite seleccionar. |
| CP-USR-32 | Ver mis reservaciones | Tab "Mis Reservas" | Muestra reservaciones con estado ACTIVA / CANCELADA. |
| CP-USR-33 | Cancelar reservación futura | "Mis Reservas" → tap "Cancelar" → confirmar | ✅ Reservación cambia a CANCELADA. Bloque vuelve a estar disponible. |
| CP-USR-34 | No puede cancelar reservación pasada | Reservación cuya fecha ya pasó | ✅ Sin botón cancelar. Solo lectura. |
| CP-USR-35 | Límite mensual de reservaciones | Intentar reservar más del máximo configurado en el área | ❌ Error: "Has alcanzado el límite mensual". |
| CP-USR-36 | Residente moroso no puede reservar | Residente con cuota PENDIENTE vencida → intentar reservar | ❌ Error: "No puedes realizar reservaciones mientras tengas pagos pendientes vencidos". |
| CP-USR-37 | Anticipación mínima | Intentar reservar un bloque en menos horas de la anticipación mínima | ❌ Error de anticipación. |
| CP-USR-38 | Anticipación máxima | Intentar reservar una fecha mayor a los días máximos configurados | ✅ El calendario no permite seleccionar esa fecha (limitado en el picker). |

---

## 4. ROL: GUARDIA

### 4.1 Escanear QR

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-GRD-01 | Escanear QR válido | Tab "Escanear" → escanear QR de visita PROGRAMADA | ✅ Mensaje "Entrada registrada". Visita pasa a COMPLETADA. |
| CP-GRD-02 | Escanear QR ya usado | Escanear QR de visita COMPLETADA | ❌ Mensaje "Esta visita ya fue registrada anteriormente". |
| CP-GRD-03 | Escanear QR cancelado | QR de visita CANCELADA | ❌ Mensaje "Esta visita fue cancelada". |
| CP-GRD-04 | Ingresar código manualmente | Campo manual → escribir código QR → validar | ✅ Mismo resultado que escaneo físico. |
| CP-GRD-05 | Código QR inválido | Ingresar texto aleatorio | ❌ Mensaje "Código QR inválido". |

### 4.2 Paquetes

| ID | Descripción | Pasos | Resultado esperado |
|---|---|---|---|
| CP-GRD-06 | Registrar paquete | Tab "Paquetes" → FAB + → buscar residente por unidad → descripción → registrar | ✅ Paquete registrado. Aparece en tab "Pendientes". |
| CP-GRD-07 | Buscar residente por unidad | Campo de búsqueda → escribir "Torre A" | ✅ Filtra residentes cuya unidad contiene "Torre A". |
| CP-GRD-08 | Registrar sin descripción | Formulario sin descripción | ❌ Error de validación. |
| CP-GRD-09 | Registrar sin destinatario | Sin seleccionar residente → registrar | ❌ Mensaje "Selecciona un residente destinatario". |
| CP-GRD-10 | Marcar paquete como entregado | Tab "Pendientes" → botón "Entregar" en paquete | ✅ Paquete pasa a tab "Entregados". |
| CP-GRD-11 | Ver historial de entregados | Tab "Entregados" | Muestra paquetes entregados con fecha. |

### 4.3 Visitas (GUARDIA)

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-GRD-12 | Ver visitas de hoy | Tab "Hoy" | Muestra visitas programadas para el día actual. |
| CP-GRD-13 | Ver historial de visitas | Tab "Historial" | Muestra todas las visitas del condominio. |

### 4.4 Notificaciones

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-GRD-14 | Ver avisos | Tab "Avisos" | Muestra todos los avisos del condominio (sin filtro de edificio). |
| CP-GRD-15 | No puede crear avisos | Tab "Avisos" | ✅ Sin FAB +. Solo lectura. |

---

## 5. PRUEBAS DE SEGURIDAD

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-SEC-01 | GUARDIA intenta crear cuota | Postman: `POST /api/cuotas` con token de GUARDIA | ❌ 403 Forbidden |
| CP-SEC-02 | USUARIO intenta ver todos los usuarios | `GET /api/usuarios` con token de USUARIO | ❌ 403 Forbidden |
| CP-SEC-03 | USUARIO intenta cancelar incidente de otro | `DELETE /api/incidentes/{id_ajeno}` | ❌ 401/403 No autorizado |
| CP-SEC-04 | USUARIO intenta confirmar pago | `PUT /api/cuotas/{id}/confirmar` con token de USUARIO | ❌ 403 Forbidden |
| CP-SEC-05 | Request sin token | Cualquier endpoint sin `Authorization` header | ❌ 401 Unauthorized |
| CP-SEC-06 | Token expirado | Esperar 1 hora → hacer request | ❌ 401 Unauthorized. App debe pedir nuevo login. |
| CP-SEC-07 | GUARDIA intenta ver incidentes | `GET /api/incidentes` con token de GUARDIA | ❌ 403 Forbidden |
| CP-SEC-08 | USUARIO intenta reservar área inactiva | Área desactivada por ADMIN | ❌ Error: "El área no está disponible". |

---

## 6. PRUEBAS DE DATOS EDGE CASES

| ID | Descripción | Resultado esperado |
|---|---|---|
| CP-EDGE-01 | Dos usuarios intentan reservar el mismo bloque simultáneamente | Solo uno debe ganar | ✅ El segundo recibe error "Este bloque horario ya está reservado". |
| CP-EDGE-02 | Crear cuota MENSUAL sin residentes activos | Condominio sin usuarios USUARIO activos | ✅ Cuota creada con 0 registros de residente. |
| CP-EDGE-03 | Crear cuota EXTRAORDINARIA sin usuarioIds | Body sin `usuarioIds` | ❌ Error: "Se requiere al menos un usuario destinatario". |
| CP-EDGE-04 | Aviso sin segmento | Body sin campo `segmento` | ❌ Error de validación. |
| CP-EDGE-05 | Login con campos vacíos | Username y password vacíos | ❌ Error de validación o credenciales inválidas. |

---

## 7. FUNCIONALIDADES PENDIENTES (fuera de scope actual)

Las siguientes funcionalidades **no están implementadas** y deben marcarse como N/A en QA:

- Foto de paquete al registrar
- Foto de incidente al reportar
- Foto de área común
- Notificaciones push (Firebase)
- Segmentos MOROSOS y PROPIETARIOS en avisos
- Cambiar contraseña desde la app
- Perfil editable (nombre, teléfono)
- Recibos PDF de pagos
- Escáner QR en web (solo funciona en app móvil)
