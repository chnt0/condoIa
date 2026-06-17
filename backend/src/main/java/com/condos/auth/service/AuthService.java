package com.condos.auth.service;

import com.condos.auth.dto.LoginRequest;
import com.condos.auth.dto.LoginResponse;
import com.condos.auth.dto.UserInfoResponse;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.condominio.model.Condominio;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * Service for handling authentication operations.
 * Manages user login and token generation.
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final JwtService jwtService;
    private final PasswordEncoder passwordEncoder;

    /**
     * Authenticates a user and generates a JWT token.
     *
     * @param request Login credentials containing username and password
     * @return LoginResponse with JWT token and user information
     * @throws UnauthorizedException if credentials are invalid or user is inactive
     */
    public LoginResponse login(LoginRequest request) {
        // Find user by username
        Usuario usuario = usuarioRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new UnauthorizedException("Credenciales inválidas"));

        // Check if user is active
        if (!usuario.getActivo()) {
            throw new UnauthorizedException("Credenciales inválidas");
        }

        // Validate password
        if (!passwordEncoder.matches(request.getPassword(), usuario.getPasswordHash())) {
            throw new UnauthorizedException("Credenciales inválidas");
        }

        // Extract condominio ID (handle null Condominio for Superadmin)
        Long condominioId = null;
        String condominioNombre = null;
        if (usuario.getCondominio() != null) {
            condominioId = usuario.getCondominio().getId();
            condominioNombre = usuario.getCondominio().getNombre();

            // Bloquear login si el condominio está desactivado
            if (!usuario.getCondominio().getActivo()) {
                throw new UnauthorizedException("El condominio está desactivado. Contacta al administrador.");
            }
        }

        // Generate JWT token
        String token = jwtService.generateToken(
                usuario.getId(),
                usuario.getUsername(),
                usuario.getRol(),
                condominioId
        );

        // Build user info response
        UserInfoResponse userInfo = new UserInfoResponse(
                usuario.getId(),
                usuario.getUsername(),
                usuario.getEmail(),
                usuario.getNombreCompleto(),
                usuario.getRol(),
                condominioId,
                condominioNombre,
                usuario.getUnidadHabitacional()
        );

        // Return login response with token and user info
        return new LoginResponse(token, userInfo);
    }
}
