package com.condos.paquete.controller;

import com.condos.paquete.dto.CreatePaqueteRequest;
import com.condos.paquete.dto.PaqueteResponse;
import com.condos.paquete.service.PaqueteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/paquetes")
@RequiredArgsConstructor
public class PaqueteController {

    private final PaqueteService paqueteService;

    @GetMapping
    @PreAuthorize("hasAnyRole('GUARDIA', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<PaqueteResponse>> listarPaquetes() {
        return ResponseEntity.ok(paqueteService.listarPaquetes());
    }

    @GetMapping("/mis-paquetes")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<PaqueteResponse>> listarMisPaquetes(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(paqueteService.listarMisPaquetes(usuarioId));
    }

    @PostMapping
    @PreAuthorize("hasRole('GUARDIA')")
    public ResponseEntity<PaqueteResponse> registrarPaquete(
            @Valid @RequestBody CreatePaqueteRequest request,
            Authentication authentication) {
        Long guardiaId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(paqueteService.registrarPaquete(request, guardiaId));
    }

    @PutMapping("/{id}/entregar")
    @PreAuthorize("hasRole('GUARDIA')")
    public ResponseEntity<PaqueteResponse> entregarPaquete(
            @PathVariable Long id,
            Authentication authentication) {
        Long guardiaId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(paqueteService.entregarPaquete(id, guardiaId));
    }
}
