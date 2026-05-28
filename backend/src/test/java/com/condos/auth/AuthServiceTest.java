package com.condos.auth;

import com.condos.auth.dto.LoginRequest;
import com.condos.auth.dto.LoginResponse;
import com.condos.auth.dto.UserInfoResponse;
import com.condos.auth.service.AuthService;
import com.condos.auth.service.JwtService;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.condominio.model.Condominio;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private JwtService jwtService;

    private PasswordEncoder passwordEncoder;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        // Use real BCryptPasswordEncoder with strength 12
        passwordEncoder = new BCryptPasswordEncoder(12);
        authService = new AuthService(usuarioRepository, jwtService, passwordEncoder);
    }

    @Test
    @DisplayName("Should login successfully with valid credentials")
    void shouldLoginSuccessfullyWithValidCredentials() {
        // Given
        String username = "admin@test.com";
        String rawPassword = "password123";
        String hashedPassword = passwordEncoder.encode(rawPassword);

        Condominio condominio = new Condominio();
        condominio.setId(1L);
        condominio.setNombre("Torre Central");

        Usuario usuario = new Usuario();
        usuario.setId(1L);
        usuario.setUsername(username);
        usuario.setEmail(username);
        usuario.setPasswordHash(hashedPassword);
        usuario.setNombreCompleto("Admin User");
        usuario.setRol(Rol.ADMIN);
        usuario.setCondominio(condominio);
        usuario.setUnidadHabitacional("101");
        usuario.setActivo(true);

        LoginRequest request = new LoginRequest(username, rawPassword);
        String expectedToken = "jwt.token.here";

        when(usuarioRepository.findByUsername(username)).thenReturn(Optional.of(usuario));
        when(jwtService.generateToken(1L, username, Rol.ADMIN, 1L)).thenReturn(expectedToken);

        // When
        LoginResponse response = authService.login(request);

        // Then
        assertNotNull(response);
        assertEquals(expectedToken, response.getToken());
        assertEquals("Bearer", response.getType());
        assertNotNull(response.getUser());
        assertEquals(1L, response.getUser().getId());
        assertEquals(username, response.getUser().getUsername());
        assertEquals(username, response.getUser().getEmail());
        assertEquals("Admin User", response.getUser().getNombreCompleto());
        assertEquals(Rol.ADMIN, response.getUser().getRol());
        assertEquals(1L, response.getUser().getCondominioId());
        assertEquals("Torre Central", response.getUser().getCondominioNombre());
        assertEquals("101", response.getUser().getUnidadHabitacional());

        verify(usuarioRepository).findByUsername(username);
        verify(jwtService).generateToken(1L, username, Rol.ADMIN, 1L);
    }

    @Test
    @DisplayName("Should throw exception when user not found")
    void shouldThrowExceptionWhenUserNotFound() {
        // Given
        LoginRequest request = new LoginRequest("nonexistent@test.com", "password123");
        when(usuarioRepository.findByUsername(anyString())).thenReturn(Optional.empty());

        // When & Then
        UnauthorizedException exception = assertThrows(UnauthorizedException.class, () -> {
            authService.login(request);
        });

        assertEquals("Credenciales inválidas", exception.getMessage());
        verify(usuarioRepository).findByUsername("nonexistent@test.com");
        verifyNoInteractions(jwtService);
    }

    @Test
    @DisplayName("Should throw exception when password incorrect")
    void shouldThrowExceptionWhenPasswordIncorrect() {
        // Given
        String username = "admin@test.com";
        String correctPassword = "password123";
        String incorrectPassword = "wrongpassword";
        String hashedPassword = passwordEncoder.encode(correctPassword);

        Usuario usuario = new Usuario();
        usuario.setId(1L);
        usuario.setUsername(username);
        usuario.setPasswordHash(hashedPassword);
        usuario.setActivo(true);

        LoginRequest request = new LoginRequest(username, incorrectPassword);
        when(usuarioRepository.findByUsername(username)).thenReturn(Optional.of(usuario));

        // When & Then
        UnauthorizedException exception = assertThrows(UnauthorizedException.class, () -> {
            authService.login(request);
        });

        assertEquals("Credenciales inválidas", exception.getMessage());
        verify(usuarioRepository).findByUsername(username);
        verifyNoInteractions(jwtService);
    }

    @Test
    @DisplayName("Should throw exception when user inactive")
    void shouldThrowExceptionWhenUserInactive() {
        // Given
        String username = "inactive@test.com";
        String rawPassword = "password123";
        String hashedPassword = passwordEncoder.encode(rawPassword);

        Usuario usuario = new Usuario();
        usuario.setId(1L);
        usuario.setUsername(username);
        usuario.setPasswordHash(hashedPassword);
        usuario.setActivo(false);

        LoginRequest request = new LoginRequest(username, rawPassword);
        when(usuarioRepository.findByUsername(username)).thenReturn(Optional.of(usuario));

        // When & Then
        UnauthorizedException exception = assertThrows(UnauthorizedException.class, () -> {
            authService.login(request);
        });

        assertEquals("Credenciales inválidas", exception.getMessage());
        verify(usuarioRepository).findByUsername(username);
        verifyNoInteractions(jwtService);
    }

    @Test
    @DisplayName("Should handle user with null condominio (Superadmin)")
    void shouldHandleUserWithNullCondominio() {
        // Given
        String username = "superadmin@test.com";
        String rawPassword = "password123";
        String hashedPassword = passwordEncoder.encode(rawPassword);

        Usuario usuario = new Usuario();
        usuario.setId(1L);
        usuario.setUsername(username);
        usuario.setEmail(username);
        usuario.setPasswordHash(hashedPassword);
        usuario.setNombreCompleto("Super Admin");
        usuario.setRol(Rol.SUPERADMIN);
        usuario.setCondominio(null); // Superadmin has no condominio
        usuario.setActivo(true);

        LoginRequest request = new LoginRequest(username, rawPassword);
        String expectedToken = "jwt.token.superadmin";

        when(usuarioRepository.findByUsername(username)).thenReturn(Optional.of(usuario));
        when(jwtService.generateToken(1L, username, Rol.SUPERADMIN, null)).thenReturn(expectedToken);

        // When
        LoginResponse response = authService.login(request);

        // Then
        assertNotNull(response);
        assertEquals(expectedToken, response.getToken());
        assertNotNull(response.getUser());
        assertNull(response.getUser().getCondominioId());
        assertNull(response.getUser().getCondominioNombre());
        assertEquals(Rol.SUPERADMIN, response.getUser().getRol());

        verify(usuarioRepository).findByUsername(username);
        verify(jwtService).generateToken(1L, username, Rol.SUPERADMIN, null);
    }
}
