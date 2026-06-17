package com.condos.auth.controller;

import com.condos.auth.dto.CambiarPasswordRequest;
import com.condos.auth.dto.LoginRequest;
import com.condos.auth.dto.LoginResponse;
import com.condos.auth.dto.UserInfoResponse;
import com.condos.auth.service.AuthService;
import com.condos.auth.service.JwtService;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final JwtService jwtService;
    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<UserInfoResponse> getCurrentUser(Authentication authentication) {
        // Principal is now userId as String
        Long userId = Long.parseLong(authentication.getName());

        Usuario usuario = usuarioRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        UserInfoResponse userInfo = new UserInfoResponse(
                usuario.getId(),
                usuario.getUsername(),
                usuario.getEmail(),
                usuario.getNombreCompleto(),
                usuario.getRol(),
                usuario.getCondominio().getId(),
                usuario.getCondominio().getNombre(),
                usuario.getUnidadHabitacional()
        );

        return ResponseEntity.ok(userInfo);
    }

    @PutMapping("/cambiar-password")
    public ResponseEntity<Void> cambiarPassword(
            @Valid @RequestBody CambiarPasswordRequest request,
            Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        Usuario usuario = usuarioRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        if (!passwordEncoder.matches(request.getPasswordActual(), usuario.getPasswordHash())) {
            throw new UnauthorizedException("La contraseña actual es incorrecta");
        }

        usuario.setPasswordHash(passwordEncoder.encode(request.getPasswordNuevo()));
        usuarioRepository.save(usuario);
        return ResponseEntity.noContent().build();
    }
}
