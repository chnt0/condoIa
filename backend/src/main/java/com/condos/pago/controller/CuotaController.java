package com.condos.pago.controller;

import com.condos.pago.dto.*;
import com.condos.pago.service.CuotaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import java.util.List;

@RestController
@RequestMapping("/api/cuotas")
@RequiredArgsConstructor
public class CuotaController {

    private final CuotaService cuotaService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<CuotaResponse>> listarCuotas() {
        return ResponseEntity.ok(cuotaService.listarCuotas());
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<CuotaResponse> crearCuota(@Valid @RequestBody CreateCuotaRequest request) {
        return ResponseEntity.ok(cuotaService.crearCuota(request));
    }

    @GetMapping("/mis-cuotas")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<CuotaUsuarioResponse>> listarMisCuotas(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(cuotaService.listarMisCuotas(usuarioId));
    }

    @GetMapping("/{id}/detalle")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<CuotaUsuarioResponse>> obtenerDetalle(@PathVariable Long id) {
        return ResponseEntity.ok(cuotaService.obtenerDetalle(id));
    }

    @PutMapping("/{cuotaUsuarioId}/reportar")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<CuotaUsuarioResponse> reportarPago(
            @PathVariable Long cuotaUsuarioId,
            @Valid @RequestBody ReportarPagoRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(cuotaService.reportarPago(cuotaUsuarioId, request, usuarioId));
    }

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

    @PutMapping("/{cuotaUsuarioId}/confirmar")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<CuotaUsuarioResponse> confirmarPago(
            @PathVariable Long cuotaUsuarioId,
            @Valid @RequestBody ConfirmarPagoRequest request) {
        return ResponseEntity.ok(cuotaService.confirmarPago(cuotaUsuarioId, request));
    }
}
