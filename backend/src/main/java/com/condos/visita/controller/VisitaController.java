package com.condos.visita.controller;

import com.condos.visita.dto.CreateVisitaRequest;
import com.condos.visita.dto.ValidarQrRequest;
import com.condos.visita.dto.ValidarQrResponse;
import com.condos.visita.dto.VisitaResponse;
import com.condos.visita.service.VisitaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Controller REST para gestión de visitas.
 */
@RestController
@RequestMapping("/api/visitas")
@RequiredArgsConstructor
public class VisitaController {

    private final VisitaService visitaService;

    /**
     * Crear una nueva visita (Usuario o Admin).
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<VisitaResponse> crearVisita(
            @Valid @RequestBody CreateVisitaRequest request,
            Authentication authentication) {

        Long usuarioId = extractUsuarioId(authentication);
        VisitaResponse response = visitaService.crearVisita(request, usuarioId);
        return ResponseEntity.ok(response);
    }

    /**
     * Listar todas las visitas del condominio (Guardia, Admin).
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('GUARDIA', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<VisitaResponse>> listarVisitas() {
        List<VisitaResponse> visitas = visitaService.listarVisitas();
        return ResponseEntity.ok(visitas);
    }

    /**
     * Listar mis visitas programadas (Usuario).
     */
    @GetMapping("/mis-visitas")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<VisitaResponse>> listarMisVisitas(Authentication authentication) {
        Long usuarioId = extractUsuarioId(authentication);
        List<VisitaResponse> visitas = visitaService.listarVisitasUsuario(usuarioId);
        return ResponseEntity.ok(visitas);
    }

    /**
     * Obtener detalle de una visita.
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<VisitaResponse> obtenerVisita(@PathVariable Long id) {
        VisitaResponse visita = visitaService.obtenerVisita(id);
        return ResponseEntity.ok(visita);
    }

    /**
     * Validar código QR y registrar entrada (solo Guardia).
     */
    @PostMapping("/validar-qr")
    @PreAuthorize("hasRole('GUARDIA')")
    public ResponseEntity<ValidarQrResponse> validarQr(
            @Valid @RequestBody ValidarQrRequest request,
            Authentication authentication) {

        Long guardiaId = extractUsuarioId(authentication);
        ValidarQrResponse response = visitaService.validarQr(request, guardiaId);
        return ResponseEntity.ok(response);
    }

    /**
     * Cancelar una visita programada.
     */
    @PutMapping("/{id}/cancelar")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<VisitaResponse> cancelarVisita(
            @PathVariable Long id,
            Authentication authentication) {

        Long usuarioId = extractUsuarioId(authentication);
        VisitaResponse visita = visitaService.cancelarVisita(id, usuarioId);
        return ResponseEntity.ok(visita);
    }

    /**
     * Obtener imagen QR en Base64.
     */
    @GetMapping("/{id}/qr-image")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, String>> obtenerImagenQr(@PathVariable Long id) {
        String base64Image = visitaService.generarImagenQr(id);
        return ResponseEntity.ok(Map.of("qrImage", base64Image));
    }

    /**
     * Extrae el ID del usuario del authentication principal.
     */
    private Long extractUsuarioId(Authentication authentication) {
        // El principal ahora es el userId como String
        String userIdStr = authentication.getName();
        return Long.parseLong(userIdStr);
    }
}
