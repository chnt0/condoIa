package com.condos.area.controller;

import com.condos.area.dto.AreaComunResponse;
import com.condos.area.dto.BloqueDisponibilidadResponse;
import com.condos.area.dto.CreateAreaComunRequest;
import com.condos.area.service.AreaComunService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/areas-comunes")
@RequiredArgsConstructor
public class AreaComunController {

    private final AreaComunService areaComunService;

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<AreaComunResponse>> listarAreas(Authentication authentication) {
        boolean esUsuario = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_USUARIO"));
        return ResponseEntity.ok(areaComunService.listarAreas(esUsuario));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<AreaComunResponse> crearArea(@Valid @RequestBody CreateAreaComunRequest request) {
        return ResponseEntity.ok(areaComunService.crearArea(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<AreaComunResponse> editarArea(
            @PathVariable Long id,
            @Valid @RequestBody CreateAreaComunRequest request) {
        return ResponseEntity.ok(areaComunService.editarArea(id, request));
    }

    @PutMapping("/{id}/toggle")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<AreaComunResponse> toggleActiva(@PathVariable Long id) {
        return ResponseEntity.ok(areaComunService.toggleActiva(id));
    }

    @GetMapping("/{id}/disponibilidad")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<BloqueDisponibilidadResponse>> obtenerDisponibilidad(
            @PathVariable Long id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        return ResponseEntity.ok(areaComunService.obtenerDisponibilidad(id, fecha));
    }
}
