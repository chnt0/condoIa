package com.condos.dispositivo.controller;

import com.condos.dispositivo.dto.RegisterTokenRequest;
import com.condos.dispositivo.model.DeviceToken;
import com.condos.dispositivo.repository.DeviceTokenRepository;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/device-tokens")
@RequiredArgsConstructor
public class DeviceTokenController {

    private final DeviceTokenRepository deviceTokenRepository;
    private final UsuarioRepository usuarioRepository;

    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Void> registerToken(
            @Valid @RequestBody RegisterTokenRequest request,
            Authentication authentication) {

        Long usuarioId = Long.parseLong(authentication.getName());
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        deviceTokenRepository.findByUsuarioIdAndPlataforma(usuarioId, request.getPlataforma())
                .ifPresentOrElse(
                        existing -> {
                            existing.setToken(request.getToken());
                            deviceTokenRepository.save(existing);
                        },
                        () -> deviceTokenRepository.save(DeviceToken.builder()
                                .usuario(usuario)
                                .token(request.getToken())
                                .plataforma(request.getPlataforma())
                                .build())
                );

        log.info("Token FCM registrado: usuario={}, plataforma={}", usuarioId, request.getPlataforma());
        return ResponseEntity.noContent().build();
    }
}
