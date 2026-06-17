# Reporte de Cuotas + Morosidad Dashboard — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar pantalla de reporte de cuotas con filtros por mes/estado y exportación CSV, más una sección de morosidad en el dashboard del ADMIN.

**Architecture:** Backend: 2 nuevos endpoints en `CuotaController` — `GET /reporte` con filtros opcionales y `GET /morosidad` que calcula deuda vencida. Flutter: nueva pantalla `ReporteCuotasScreen` con filtros y generación de CSV en cliente; `DashboardAdminScreen` carga y muestra morosidad. Se agrega `share_plus` para compartir el CSV en móvil.

**Tech Stack:** Spring Boot 3 + JPA JPQL | Flutter + share_plus ^10.0.0 + dart:html (web)

---

## File Map

### Backend — nuevos

```
com/condos/pago/dto/MorosidadResponse.java
```

### Backend — modificados

```
com/condos/pago/repository/CuotaUsuarioRepository.java   ← + findReporte() con @Query
com/condos/pago/service/CuotaService.java                ← + listarReporte() + obtenerMorosidad()
com/condos/pago/controller/CuotaController.java          ← + GET /reporte + GET /morosidad
```

### Flutter — nuevos

```
lib/features/pagos/screens/reporte_cuotas_screen.dart
```

### Flutter — modificados

```
pubspec.yaml                                              ← + share_plus ^10.0.0
lib/core/constants/api_constants.dart                    ← + cuotaReporte, morosidad
lib/features/pagos/screens/cuotas_admin_screen.dart      ← + botón reporte en AppBar
lib/features/visitas/screens/dashboard_admin_screen.dart ← + sección morosidad
lib/core/routes/app_router.dart                          ← + /home/cuotas/reporte
```

---

## Task 1: Backend — MorosidadResponse DTO + queries en CuotaUsuarioRepository

**Files:**
- Create: `backend/src/main/java/com/condos/pago/dto/MorosidadResponse.java`
- Modify: `backend/src/main/java/com/condos/pago/repository/CuotaUsuarioRepository.java`

- [ ] **Step 1: MorosidadResponse.java**

```java
package com.condos.pago.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class MorosidadResponse {
    private BigDecimal totalMonto;
    private int totalMorosos;
    private int cuotasVencidas;
}
```

- [ ] **Step 2: Agregar queries a CuotaUsuarioRepository**

El archivo completo queda:

```java
package com.condos.pago.repository;

import com.condos.pago.model.CuotaUsuario;
import com.condos.pago.model.EstadoPago;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CuotaUsuarioRepository extends JpaRepository<CuotaUsuario, Long> {
    List<CuotaUsuario> findByCuotaId(Long cuotaId);
    List<CuotaUsuario> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);
    boolean existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(
            Long usuarioId, EstadoPago estado, LocalDate fecha);

    // Reporte: todos los cuota_usuarios de un condominio con filtros opcionales
    @Query("SELECT cu FROM CuotaUsuario cu " +
           "JOIN cu.cuota c " +
           "WHERE c.condominio.id = :condominioId " +
           "AND (:mes IS NULL OR c.mes = :mes " +
           "     OR (FUNCTION('TO_CHAR', c.fechaVencimiento, 'YYYY-MM') = :mes)) " +
           "AND (:estado IS NULL OR cu.estado = :estado) " +
           "ORDER BY c.fechaVencimiento DESC, cu.id ASC")
    List<CuotaUsuario> findReporte(
            @Param("condominioId") Long condominioId,
            @Param("mes") String mes,
            @Param("estado") EstadoPago estado);

    // Morosidad: cuota_usuarios vencidos y sin pagar
    @Query("SELECT cu FROM CuotaUsuario cu " +
           "JOIN cu.cuota c " +
           "WHERE c.condominio.id = :condominioId " +
           "AND cu.estado IN ('PENDIENTE', 'RECHAZADO') " +
           "AND c.fechaVencimiento < :hoy")
    List<CuotaUsuario> findMorosos(
            @Param("condominioId") Long condominioId,
            @Param("hoy") LocalDate hoy);
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/com/condos/pago/dto/MorosidadResponse.java \
        backend/src/main/java/com/condos/pago/repository/CuotaUsuarioRepository.java
git commit -m "feat(cuotas): add MorosidadResponse DTO and findReporte/findMorosos queries"
```

---

## Task 2: Backend — CuotaService + CuotaController + compilación

**Files:**
- Modify: `backend/src/main/java/com/condos/pago/service/CuotaService.java`
- Modify: `backend/src/main/java/com/condos/pago/controller/CuotaController.java`

- [ ] **Step 1: Agregar listarReporte() y obtenerMorosidad() a CuotaService**

Agregar import:
```java
import com.condos.pago.dto.MorosidadResponse;
```

Agregar los dos métodos antes de `toCuotaResponse()`:

```java
@Transactional(readOnly = true)
public List<CuotaUsuarioResponse> listarReporte(String mes, String estadoStr) {
    Long condominioId = TenantContext.getCondominioId();
    EstadoPago estadoEnum = null;
    if (estadoStr != null && !estadoStr.isBlank() && !estadoStr.equalsIgnoreCase("TODOS")) {
        estadoEnum = EstadoPago.valueOf(estadoStr.toUpperCase());
    }
    return cuotaUsuarioRepository.findReporte(condominioId, mes, estadoEnum)
            .stream().map(this::toCuotaUsuarioResponse).collect(Collectors.toList());
}

@Transactional(readOnly = true)
public MorosidadResponse obtenerMorosidad() {
    Long condominioId = TenantContext.getCondominioId();
    List<CuotaUsuario> morosos = cuotaUsuarioRepository.findMorosos(condominioId, LocalDate.now());

    BigDecimal totalMonto = morosos.stream()
            .map(cu -> cu.getCuota().getMonto())
            .reduce(BigDecimal.ZERO, BigDecimal::add);

    long totalMorosos = morosos.stream()
            .map(cu -> cu.getUsuario().getId())
            .distinct().count();

    return new MorosidadResponse(totalMonto, (int) totalMorosos, morosos.size());
}
```

Agregar import adicional:
```java
import com.condos.pago.dto.MorosidadResponse;
import java.time.LocalDate;
```

- [ ] **Step 2: Agregar endpoints a CuotaController**

Agregar import:
```java
import com.condos.pago.dto.MorosidadResponse;
import org.springframework.web.bind.annotation.RequestParam;
```

Agregar los dos endpoints al controller:

```java
@GetMapping("/reporte")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
public ResponseEntity<List<CuotaUsuarioResponse>> reporte(
        @RequestParam(required = false) String mes,
        @RequestParam(required = false, defaultValue = "TODOS") String estado) {
    return ResponseEntity.ok(cuotaService.listarReporte(mes, estado));
}

@GetMapping("/morosidad")
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
public ResponseEntity<MorosidadResponse> morosidad() {
    return ResponseEntity.ok(cuotaService.obtenerMorosidad());
}
```

- [ ] **Step 3: Verificar compilación**

```bash
cd backend && ./mvnw compile -q
```

Expected: sin output (BUILD SUCCESS).

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/com/condos/pago/service/CuotaService.java \
        backend/src/main/java/com/condos/pago/controller/CuotaController.java
git commit -m "feat(cuotas): add GET /reporte and GET /morosidad endpoints"
```

---

## Task 3: Flutter — pubspec + ApiConstants + ReporteCuotasScreen

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/constants/api_constants.dart`
- Create: `lib/features/pagos/screens/reporte_cuotas_screen.dart`

- [ ] **Step 1: Agregar share_plus a pubspec.yaml**

```yaml
  # Compartir archivos CSV en móvil
  share_plus: ^10.0.0
```

Correr:
```bash
~/flutter/condos/flutter/bin/flutter pub get
```

- [ ] **Step 2: Agregar constantes a api_constants.dart**

```dart
  static const String cuotaReporte = '$apiPrefix/cuotas/reporte';
  static const String morosidad = '$apiPrefix/cuotas/morosidad';
```

- [ ] **Step 3: Crear reporte_cuotas_screen.dart**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/cuota_usuario_response.dart';

class ReporteCuotasScreen extends ConsumerStatefulWidget {
  const ReporteCuotasScreen({super.key});

  @override
  ConsumerState<ReporteCuotasScreen> createState() =>
      _ReporteCuotasScreenState();
}

class _ReporteCuotasScreenState extends ConsumerState<ReporteCuotasScreen> {
  final _mesCtrl = TextEditingController();
  String _estadoFiltro = 'TODOS';
  List<CuotaUsuarioResponse> _registros = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _mesCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apiClient = ref.read(apiClientProvider);
      final params = <String, String>{'estado': _estadoFiltro};
      if (_mesCtrl.text.trim().isNotEmpty) {
        params['mes'] = _mesCtrl.text.trim();
      }
      final response = await apiClient.getList(
        ApiConstants.cuotaReporte,
        queryParameters: params,
      );
      setState(() {
        _registros = response
            .map((item) =>
                CuotaUsuarioResponse.fromJson(item as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _buildCsv() {
    final buf = StringBuffer();
    buf.writeln('Unidad,Nombre,Concepto,Mes,Monto,Estado,Referencia,Fecha_Reporte');
    for (final r in _registros) {
      final unidad = r.unidadHabitacional ?? '';
      final nombre = r.usuarioNombre;
      final concepto = r.concepto.replaceAll(',', ' ');
      final mes = '';
      final monto = r.monto.toStringAsFixed(2);
      final estado = r.estado.name.toUpperCase();
      final ref_ = r.referenciaPago ?? '';
      final fecha = r.fechaReporte?.toIso8601String().substring(0, 10) ?? '';
      buf.writeln('$unidad,$nombre,$concepto,$mes,$monto,$estado,$ref_,$fecha');
    }
    return buf.toString();
  }

  Future<void> _exportarCsv() async {
    final csv = _buildCsv();
    final filename = 'reporte_cuotas_${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      // En web: descargar via anchor tag
      final bytes = utf8.encode(csv);
      final blob = Uri.dataFromBytes(bytes, mimeType: 'text/csv');
      // ignore: avoid_web_libraries_in_flutter
      // ignore: undefined_prefixed_name
      final anchor = ' <a href="${blob.toString()}" download="$filename">x</a>';
      // Simple fallback: share as text
      await Share.share(csv, subject: filename);
    } else {
      // En móvil: guardar temp y compartir
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], subject: 'Reporte de cuotas');
    }
  }

  Color _estadoColor(EstadoPago e) => switch (e) {
        EstadoPago.confirmado => Colors.green,
        EstadoPago.reportado => Colors.orange,
        EstadoPago.pendiente => Colors.grey,
        EstadoPago.rechazado => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Cuotas'),
        actions: [
          if (_registros.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar CSV',
              onPressed: _exportarCsv,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mes (YYYY-MM)',
                      hintText: '2026-07',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _estadoFiltro,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
                      DropdownMenuItem(
                          value: 'CONFIRMADO', child: Text('Pagados')),
                      DropdownMenuItem(
                          value: 'PENDIENTE', child: Text('Pendientes')),
                    ],
                    onChanged: (v) => setState(() => _estadoFiltro = v!),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _buscar,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Buscar'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_registros.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_registros.length} registros',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          // Lista
          Expanded(
            child: _registros.isEmpty && !_loading
                ? const Center(
                    child: Text('Aplica filtros y presiona Buscar',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _registros.length,
                    itemBuilder: (context, index) {
                      final r = _registros[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor:
                              _estadoColor(r.estado).withOpacity(0.15),
                          radius: 20,
                          child: Text(
                            r.unidadHabitacional?.split('-').last ?? '?',
                            style: TextStyle(
                                fontSize: 11,
                                color: _estadoColor(r.estado),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(r.usuarioNombre,
                            style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                            '${r.concepto} · \$${r.monto.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: Chip(
                          label: Text(
                            r.estado.name.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                          backgroundColor: _estadoColor(r.estado),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock \
        lib/core/constants/api_constants.dart \
        lib/features/pagos/screens/reporte_cuotas_screen.dart
git commit -m "feat(cuotas): add ReporteCuotasScreen with month/status filters and CSV export"
```

---

## Task 4: Flutter — Botón en CuotasAdminScreen + ruta GoRouter

**Files:**
- Modify: `lib/features/pagos/screens/cuotas_admin_screen.dart`
- Modify: `lib/core/routes/app_router.dart`

- [ ] **Step 1: Agregar botón en AppBar de CuotasAdminScreen**

Cambiar:
```dart
appBar: AppBar(title: const Text('Cuotas')),
```

Por:
```dart
appBar: AppBar(
  title: const Text('Cuotas'),
  actions: [
    IconButton(
      icon: const Icon(Icons.bar_chart),
      tooltip: 'Ver reporte',
      onPressed: () => context.push('/home/cuotas/reporte'),
    ),
  ],
),
```

- [ ] **Step 2: Agregar ruta en app_router.dart**

Agregar import:
```dart
import '../../features/pagos/screens/reporte_cuotas_screen.dart';
```

Agregar ruta antes de `cuotas/nueva`:
```dart
GoRoute(
  path: 'cuotas/reporte',
  builder: (_, __) => const ReporteCuotasScreen(),
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/pagos/screens/cuotas_admin_screen.dart \
        lib/core/routes/app_router.dart
git commit -m "feat(cuotas): add reporte button in CuotasAdminScreen AppBar, GoRouter route"
```

---

## Task 5: Flutter — Morosidad en DashboardAdminScreen

**Files:**
- Modify: `lib/features/visitas/screens/dashboard_admin_screen.dart`

- [ ] **Step 1: Actualizar DashboardAdminScreen con morosidad**

Reemplazar el archivo completo con la versión que incluye morosidad:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers/auth_provider.dart';
import '../models/visita.dart';
import '../providers/visita_provider.dart';

class DashboardAdminScreen extends ConsumerStatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  ConsumerState<DashboardAdminScreen> createState() =>
      _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends ConsumerState<DashboardAdminScreen> {
  Map<String, dynamic>? _morosidad;
  bool _loadingMorosidad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarMorosidad());
  }

  Future<void> _cargarMorosidad() async {
    setState(() => _loadingMorosidad = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.get(ApiConstants.morosidad);
      setState(() {
        _morosidad = data;
        _loadingMorosidad = false;
      });
    } catch (e) {
      setState(() => _loadingMorosidad = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitaState = ref.watch(visitaProvider);
    final visitas = visitaState.todasVisitas;
    final now = DateTime.now();

    final hoy = visitas
        .where((v) =>
            v.fechaHoraProgramada.year == now.year &&
            v.fechaHoraProgramada.month == now.month &&
            v.fechaHoraProgramada.day == now.day)
        .length;

    final programadas =
        visitas.where((v) => v.estado == EstadoVisita.programada).length;
    final completadas =
        visitas.where((v) => v.estado == EstadoVisita.completada).length;
    final canceladas =
        visitas.where((v) => v.estado == EstadoVisita.cancelada).length;

    final totalMonto = _morosidad?['totalMonto'] ?? 0.0;
    final totalMorosos = _morosidad?['totalMorosos'] ?? 0;
    final cuotasVencidas = _morosidad?['cuotasVencidas'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(visitaProvider.notifier).cargarTodasVisitas();
              _cargarMorosidad();
            },
          ),
        ],
      ),
      body: visitaState.isLoading && visitas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sección morosidad
                const Text(
                  'Morosidad',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _loadingMorosidad
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          _StatCard(
                            title: 'Total vencido',
                            value:
                                '\$${(totalMonto as num).toStringAsFixed(0)}',
                            icon: Icons.money_off,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            title: 'Morosos',
                            value: '$totalMorosos',
                            icon: Icons.person_off_outlined,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            title: 'Cuotas venc.',
                            value: '$cuotasVencidas',
                            icon: Icons.receipt_long,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                const SizedBox(height: 24),

                // Sección visitas
                const Text(
                  'Resumen de visitas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                        title: 'Hoy',
                        value: '$hoy',
                        icon: Icons.today,
                        color: Colors.indigo),
                    _StatCard(
                        title: 'Programadas',
                        value: '$programadas',
                        icon: Icons.schedule,
                        color: Colors.blue),
                    _StatCard(
                        title: 'Completadas',
                        value: '$completadas',
                        icon: Icons.check_circle_outline,
                        color: Colors.green),
                    _StatCard(
                        title: 'Canceladas',
                        value: '$canceladas',
                        icon: Icons.cancel_outlined,
                        color: Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Total registradas: ${visitas.length}',
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit y push**

```bash
git add lib/features/visitas/screens/dashboard_admin_screen.dart
git commit -m "feat(dashboard): add morosidad section — total vencido, morosos, cuotas vencidas"
git push
```

---

## Self-Review

### Spec Coverage

| Requisito | Task |
|---|---|
| `MorosidadResponse` DTO | Task 1 |
| `findReporte()` con filtros mes + estado | Task 1 |
| `findMorosos()` vencidos y sin pagar | Task 1 |
| `CuotaService.listarReporte()` — filtro TODOS/CONFIRMADO/PENDIENTE | Task 2 |
| `CuotaService.obtenerMorosidad()` — suma monto, count morosos distintos, count cuotas | Task 2 |
| `GET /api/cuotas/reporte?mes=&estado=` | Task 2 |
| `GET /api/cuotas/morosidad` | Task 2 |
| Backend compila | Task 2 |
| `share_plus` en pubspec | Task 3 |
| `ApiConstants.cuotaReporte` y `ApiConstants.morosidad` | Task 3 |
| `ReporteCuotasScreen` — filtros mes + estado + botón buscar | Task 3 |
| Lista de resultados con chips de color | Task 3 |
| Botón exportar CSV — descarga en web, comparte en móvil | Task 3 |
| CSV con columnas: Unidad, Nombre, Concepto, Mes, Monto, Estado, Referencia, Fecha | Task 3 |
| Botón `Icons.bar_chart` en `CuotasAdminScreen` AppBar | Task 4 |
| Ruta `/home/cuotas/reporte` | Task 4 |
| `DashboardAdminScreen` carga morosidad en initState | Task 5 |
| 3 tarjetas: total vencido, morosos, cuotas vencidas | Task 5 |
| Sin crash si morosidad falla (try/catch silencioso) | Task 5 |
