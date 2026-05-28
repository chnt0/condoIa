package com.condos.auth;

import com.condos.auth.service.JwtService;
import com.condos.usuario.model.Rol;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for JwtService.
 * These are simple unit tests that don't require Spring context.
 */
class JwtServiceTest {

    private JwtService jwtService;

    private Long testUserId;
    private String testUsername;
    private Rol testRol;
    private Long testCondominioId;

    @BeforeEach
    void setUp() {
        // Create JwtService with test configuration
        String testSecret = "test-secret-key-must-be-at-least-256-bits-long-for-hs256";
        long testExpiration = 3600000L; // 1 hour
        jwtService = new JwtService(testSecret, testExpiration);

        // Set test data
        testUserId = 123L;
        testUsername = "testuser@example.com";
        testRol = Rol.USUARIO;
        testCondominioId = 456L;
    }

    @Test
    void shouldGenerateTokenWithUserDetails() {
        // When
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // Then
        assertNotNull(token);
        assertFalse(token.isEmpty());

        // Verify token structure (JWT has 3 parts separated by dots)
        String[] parts = token.split("\\.");
        assertEquals(3, parts.length, "JWT should have 3 parts: header, payload, signature");
    }

    @Test
    void shouldExtractUsernameFromToken() {
        // Given
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // When
        String extractedUsername = jwtService.extractUsername(token);

        // Then
        assertEquals(testUsername, extractedUsername);
    }

    @Test
    void shouldExtractUserIdFromToken() {
        // Given
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // When
        Long extractedUserId = jwtService.extractUserId(token);

        // Then
        assertEquals(testUserId, extractedUserId);
    }

    @Test
    void shouldExtractRolFromToken() {
        // Given
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // When
        Rol extractedRol = jwtService.extractRol(token);

        // Then
        assertEquals(testRol, extractedRol);
    }

    @Test
    void shouldExtractCondominioIdFromToken() {
        // Given
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // When
        Long extractedCondominioId = jwtService.extractCondominioId(token);

        // Then
        assertEquals(testCondominioId, extractedCondominioId);
    }

    @Test
    void shouldValidateValidToken() {
        // Given
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // When
        boolean isValid = jwtService.validateToken(token);

        // Then
        assertTrue(isValid, "Token should be valid");
    }

    @Test
    void shouldInvalidateTamperedToken() {
        // Given - Create a valid token
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // Tamper with the token by changing a character in the signature part
        String[] parts = token.split("\\.");
        String tamperedSignature = parts[2].substring(0, parts[2].length() - 1) + "X";
        String tamperedToken = parts[0] + "." + parts[1] + "." + tamperedSignature;

        // When
        boolean isValid = jwtService.validateToken(tamperedToken);

        // Then
        assertFalse(isValid, "Tampered token should be invalid");
    }

    @Test
    void shouldInvalidateExpiredToken() {
        // Given - Create a token with the secret key but with past expiration
        String secret = "test-secret-key-must-be-at-least-256-bits-long-for-hs256";
        SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));

        String expiredToken = Jwts.builder()
                .setSubject(testUsername)
                .claim("userId", testUserId)
                .claim("rol", testRol.name())
                .claim("condominioId", testCondominioId)
                .setIssuedAt(new Date(System.currentTimeMillis() - 7200000)) // 2 hours ago
                .setExpiration(new Date(System.currentTimeMillis() - 3600000)) // 1 hour ago
                .signWith(key)
                .compact();

        // When
        boolean isValid = jwtService.validateToken(expiredToken);

        // Then
        assertFalse(isValid, "Expired token should be invalid");
    }

    @Test
    void shouldHandleNullTokenGracefully() {
        // When/Then
        assertFalse(jwtService.validateToken(null), "Null token should be invalid");
    }

    @Test
    void shouldHandleEmptyTokenGracefully() {
        // When/Then
        assertFalse(jwtService.validateToken(""), "Empty token should be invalid");
    }

    @Test
    void shouldHandleInvalidTokenFormatGracefully() {
        // When/Then
        assertFalse(jwtService.validateToken("invalid.token"), "Invalid token format should be invalid");
    }

    @Test
    void shouldSetCorrectExpirationTime() {
        // Given
        String token = jwtService.generateToken(testUserId, testUsername, testRol, testCondominioId);

        // When - Extract claims manually to verify expiration
        String secret = "test-secret-key-must-be-at-least-256-bits-long-for-hs256";
        SecretKey key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();

        Date issuedAt = claims.getIssuedAt();
        Date expiration = claims.getExpiration();

        // Then - Verify expiration is approximately 1 hour (3600000ms) from issued time
        long expirationDuration = expiration.getTime() - issuedAt.getTime();
        assertThat(expirationDuration).isCloseTo(3600000L, org.assertj.core.data.Offset.offset(1000L));
    }
}
