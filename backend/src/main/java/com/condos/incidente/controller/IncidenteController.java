package com.condos.incidente.controller;

import com.condos.incidente.dto.*;
import com.condos.incidente.service.IncidenteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/incidentes")
@RequiredArgsConstructor
public class IncidenteController {

    private final IncidenteService incidenteService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<IncidenteResponse>> listarIncidentes() {
        return ResponseEntity.ok(incidenteService.listarIncidentes());
    }

    @GetMapping("/mis-incidentes")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<IncidenteResponse>> listarMisIncidentes(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(incidenteService.listarMisIncidentes(usuarioId));
    }

    @PostMapping
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<IncidenteResponse> crearIncidente(
            @Valid @RequestBody CreateIncidenteRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(incidenteService.crearIncidente(request, usuarioId));
    }

    @PutMapping("/{id}/estado")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<IncidenteResponse> actualizarEstado(
            @PathVariable Long id,
            @Valid @RequestBody UpdateEstadoRequest request) {
        return ResponseEntity.ok(incidenteService.actualizarEstado(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<Void> cancelarIncidente(
            @PathVariable Long id,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        incidenteService.cancelarIncidente(id, usuarioId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/comentarios")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<ComentarioResponse>> listarComentarios(@PathVariable Long id) {
        return ResponseEntity.ok(incidenteService.listarComentarios(id));
    }

    @PostMapping("/{id}/comentarios")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<ComentarioResponse> agregarComentario(
            @PathVariable Long id,
            @Valid @RequestBody AddComentarioRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(incidenteService.agregarComentario(id, request, usuarioId));
    }
}
