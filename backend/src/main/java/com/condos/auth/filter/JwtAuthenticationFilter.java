package com.condos.auth.filter;

import com.condos.auth.service.JwtService;
import com.condos.common.utils.TenantContext;
import com.condos.usuario.model.Rol;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

/**
 * JWT Authentication Filter that intercepts requests to validate JWT tokens.
 * Extracts JWT from Authorization header, validates it, and sets the security context.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        try {
            // Extract Authorization header
            final String authHeader = request.getHeader("Authorization");

            // If header is null or doesn't start with "Bearer ", skip authentication
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                filterChain.doFilter(request, response);
                return;
            }

            // Extract token (substring from index 7 to skip "Bearer " prefix)
            final String token = authHeader.substring(7);

            // Validate token
            if (!jwtService.validateToken(token)) {
                log.warn("Invalid JWT token received");
                filterChain.doFilter(request, response);
                return;
            }

            // Extract claims from token
            final String username = jwtService.extractUsername(token);
            final Long condominioId = jwtService.extractCondominioId(token);
            final Rol rol = jwtService.extractRol(token);

            // Set TenantContext with condominioId if not null
            if (condominioId != null) {
                TenantContext.setCondominioId(condominioId);
            }

            // Create authentication token with "ROLE_" prefix for Spring Security
            final String authority = "ROLE_" + rol.name();
            final UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            username,
                            null,
                            Collections.singletonList(new SimpleGrantedAuthority(authority))
                    );

            // Set authentication details
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

            // Set SecurityContext authentication
            SecurityContextHolder.getContext().setAuthentication(authentication);

            log.debug("Authenticated user: {} with role: {} for condominio: {}",
                    username, rol, condominioId);

            // Continue the filter chain
            filterChain.doFilter(request, response);

        } catch (Exception e) {
            log.error("Error processing JWT authentication: {}", e.getMessage(), e);
            // Continue filter chain even on error, let Spring Security handle it
            filterChain.doFilter(request, response);
        } finally {
            // Always clear TenantContext to prevent memory leaks
            TenantContext.clear();
        }
    }
}
