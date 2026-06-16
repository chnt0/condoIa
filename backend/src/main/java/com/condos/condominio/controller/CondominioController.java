package com.condos.condominio.controller;

import com.condos.condominio.dto.CondominioResponse;
import com.condos.condominio.dto.CreateCondominioRequest;
import com.condos.condominio.service.CondominioService;
import com.condos.usuario.dto.UsuarioResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/condominios")
@RequiredArgsConstructor
public class CondominioController {

    private final CondominioService condominioService;

    @GetMapping
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<List<CondominioResponse>> listarCondominios() {
        return ResponseEntity.ok(condominioService.listarCondominios());
    }

    @PostMapping
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<CondominioResponse> crearCondominio(
            @Valid @RequestBody CreateCondominioRequest request) {
        return ResponseEntity.ok(condominioService.crearCondominio(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<CondominioResponse> editarCondominio(
            @PathVariable Long id,
            @Valid @RequestBody CreateCondominioRequest request) {
        return ResponseEntity.ok(condominioService.editarCondominio(id, request));
    }

    @PutMapping("/{id}/toggle")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<CondominioResponse> toggleActivo(@PathVariable Long id) {
        return ResponseEntity.ok(condominioService.toggleActivo(id));
    }

    @GetMapping("/{id}/admins")
    @PreAuthorize("hasRole('SUPERADMIN')")
    public ResponseEntity<List<UsuarioResponse>> listarAdmins(@PathVariable Long id) {
        return ResponseEntity.ok(condominioService.listarAdmins(id));
    }
}
