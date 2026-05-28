package com.condos.auth.service;

import com.condos.usuario.model.Rol;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.function.Function;

/**
 * Service for JWT token generation and validation.
 * Handles token creation with user claims and token validation.
 */
@Service
public class JwtService {

    private final SecretKey signingKey;
    private final long jwtExpiration;

    /**
     * Constructor that initializes JWT configuration from application properties.
     *
     * @param secret The JWT secret key (must be at least 256 bits for HS256)
     * @param jwtExpiration Token expiration time in milliseconds
     */
    public JwtService(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-token.expiration}") long jwtExpiration) {
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.jwtExpiration = jwtExpiration;
    }

    /**
     * Generates a JWT token with user details and claims.
     *
     * @param userId The user ID
     * @param username The username (typically email)
     * @param rol The user role
     * @param condominioId The condominium ID associated with the user
     * @return A signed JWT token string
     */
    public String generateToken(Long userId, String username, Rol rol, Long condominioId) {
        return Jwts.builder()
                .setSubject(username)
                .claim("userId", userId)
                .claim("rol", rol.name())
                .claim("condominioId", condominioId)
                .setIssuedAt(new Date(System.currentTimeMillis()))
                .setExpiration(new Date(System.currentTimeMillis() + jwtExpiration))
                .signWith(signingKey)
                .compact();
    }

    /**
     * Extracts the username (subject) from the token.
     *
     * @param token The JWT token
     * @return The username
     */
    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * Extracts the user ID from the token.
     *
     * @param token The JWT token
     * @return The user ID
     */
    public Long extractUserId(String token) {
        return extractClaim(token, claims -> claims.get("userId", Long.class));
    }

    /**
     * Extracts the user role from the token.
     *
     * @param token The JWT token
     * @return The user role
     */
    public Rol extractRol(String token) {
        String rolString = extractClaim(token, claims -> claims.get("rol", String.class));
        return Rol.valueOf(rolString);
    }

    /**
     * Extracts the condominium ID from the token.
     *
     * @param token The JWT token
     * @return The condominium ID
     */
    public Long extractCondominioId(String token) {
        return extractClaim(token, claims -> claims.get("condominioId", Long.class));
    }

    /**
     * Validates the JWT token by checking signature and expiration.
     *
     * @param token The JWT token to validate
     * @return true if the token is valid, false otherwise
     */
    public boolean validateToken(String token) {
        try {
            if (token == null || token.isEmpty()) {
                return false;
            }

            extractAllClaims(token);
            return !isTokenExpired(token);
        } catch (Exception e) {
            // Token is invalid (signature mismatch, malformed, expired, etc.)
            return false;
        }
    }

    /**
     * Extracts a specific claim from the token using a claims resolver function.
     *
     * @param token The JWT token
     * @param claimsResolver Function to extract the desired claim
     * @param <T> The type of the claim
     * @return The extracted claim value
     */
    private <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    /**
     * Extracts all claims from the token.
     *
     * @param token The JWT token
     * @return All claims from the token
     */
    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(signingKey)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    /**
     * Checks if the token has expired.
     *
     * @param token The JWT token
     * @return true if the token is expired, false otherwise
     */
    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    /**
     * Extracts the expiration date from the token.
     *
     * @param token The JWT token
     * @return The expiration date
     */
    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }
}
