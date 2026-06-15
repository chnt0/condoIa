package com.condos.auth.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Rate limiter para el endpoint de login.
 * Permite máximo 5 intentos por IP en una ventana de 60 segundos.
 * Al superar el límite bloquea la IP por 5 minutos.
 */
@Component
public class LoginRateLimitFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(LoginRateLimitFilter.class);

    private static final int MAX_ATTEMPTS = 5;
    private static final long WINDOW_SECONDS = 60;
    private static final long BLOCK_SECONDS = 300;

    private final ConcurrentHashMap<String, AttemptRecord> attempts = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().equals("/api/auth/login") ||
               !request.getMethod().equals("POST");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String ip = getClientIp(request);
        AttemptRecord record = attempts.compute(ip, (key, existing) -> {
            long now = Instant.now().getEpochSecond();
            if (existing == null) return new AttemptRecord(now, 1);
            if (existing.blockedUntil > now) return existing;
            if (now - existing.windowStart > WINDOW_SECONDS) return new AttemptRecord(now, 1);
            return new AttemptRecord(existing.windowStart, existing.count + 1);
        });

        long now = Instant.now().getEpochSecond();

        if (record.blockedUntil > now) {
            long remaining = record.blockedUntil - now;
            log.warn("Login bloqueado por rate limit: ip={}, segundos_restantes={}", ip, remaining);
            response.setStatus(429);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write(
                "{\"error\":\"Too Many Requests\",\"message\":\"Demasiados intentos. Intenta de nuevo en " +
                (remaining / 60 + 1) + " minuto(s).\",\"code\":429}"
            );
            return;
        }

        if (record.count >= MAX_ATTEMPTS) {
            long blockedUntil = now + BLOCK_SECONDS;
            attempts.put(ip, new AttemptRecord(record.windowStart, record.count, blockedUntil));
            log.warn("IP bloqueada por múltiples intentos de login: ip={}", ip);
            response.setStatus(429);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write(
                "{\"error\":\"Too Many Requests\",\"message\":\"Demasiados intentos fallidos. IP bloqueada por 5 minutos.\",\"code\":429}"
            );
            return;
        }

        filterChain.doFilter(request, response);

        if (response.getStatus() == 200) {
            attempts.remove(ip);
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private static class AttemptRecord {
        final long windowStart;
        final int count;
        final long blockedUntil;

        AttemptRecord(long windowStart, int count) {
            this(windowStart, count, 0);
        }

        AttemptRecord(long windowStart, int count, long blockedUntil) {
            this.windowStart = windowStart;
            this.count = count;
            this.blockedUntil = blockedUntil;
        }
    }
}
