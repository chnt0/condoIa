package com.condos.reservacion.controller;

import com.condos.reservacion.dto.CreateReservacionRequest;
import com.condos.reservacion.dto.ReservacionResponse;
import com.condos.reservacion.service.ReservacionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reservaciones")
@RequiredArgsConstructor
public class ReservacionController {

    private final ReservacionService reservacionService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPERADMIN')")
    public ResponseEntity<List<ReservacionResponse>> listarReservaciones() {
        return ResponseEntity.ok(reservacionService.listarReservaciones());
    }

    @GetMapping("/mis-reservaciones")
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<List<ReservacionResponse>> listarMisReservaciones(Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(reservacionService.listarMisReservaciones(usuarioId));
    }

    @PostMapping
    @PreAuthorize("hasRole('USUARIO')")
    public ResponseEntity<ReservacionResponse> crearReservacion(
            @Valid @RequestBody CreateReservacionRequest request,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(reservacionService.crearReservacion(request, usuarioId));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('USUARIO', 'ADMIN', 'SUPERADMIN')")
    public ResponseEntity<Void> cancelarReservacion(
            @PathVariable Long id,
            Authentication authentication) {
        Long usuarioId = Long.parseLong(authentication.getName());
        boolean esAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") ||
                               a.getAuthority().equals("ROLE_SUPERADMIN"));
        reservacionService.cancelarReservacion(id, usuarioId, esAdmin);
        return ResponseEntity.noContent().build();
    }
}
