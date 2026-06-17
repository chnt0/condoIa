package com.condos.incidente.controller;

import com.condos.incidente.dto.CategoriaIncidenteResponse;
import com.condos.incidente.dto.CreateCategoriaRequest;
import com.condos.incidente.service.CategoriaIncidenteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/categorias-incidente")
@RequiredArgsConstructor
public class CategoriaIncidenteController {

    private final CategoriaIncidenteService categoriaService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CategoriaIncidenteResponse>> listar(Authentication authentication) {
        boolean esUsuario = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_USUARIO"));
        return ResponseEntity.ok(categoriaService.listarCategorias(esUsuario));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<CategoriaIncidenteResponse> crear(
            @Valid @RequestBody CreateCategoriaRequest request) {
        return ResponseEntity.ok(categoriaService.crearCategoria(request));
    }

    @PutMapping("/{id}/toggle")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<CategoriaIncidenteResponse> toggleActiva(@PathVariable Long id) {
        return ResponseEntity.ok(categoriaService.toggleActiva(id));
    }
}
