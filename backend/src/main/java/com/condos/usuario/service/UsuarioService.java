package com.condos.usuario.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.TenantMismatchException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.usuario.dto.CreateUsuarioRequest;
import com.condos.usuario.dto.ResidenteBasicoResponse;
import com.condos.usuario.dto.UpdateUsuarioRequest;
import com.condos.usuario.dto.UsuarioResponse;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.condos.usuario.dto.BulkUsuarioError;
import com.condos.usuario.dto.BulkUsuarioResponse;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<UsuarioResponse> listarUsuarios() {
        Long condominioId = TenantContext.getCondominioId();
        List<Usuario> usuarios;
        if (condominioId == null) {
            usuarios = usuarioRepository.findAll();
        } else {
            usuarios = usuarioRepository.findByCondominioId(condominioId);
        }
        return usuarios.stream()
                .filter(u -> u.getRol() != Rol.SUPERADMIN)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UsuarioResponse obtenerUsuario(Long id) {
        return toResponse(findAndValidate(id));
    }

    @Transactional
    public UsuarioResponse crearUsuario(CreateUsuarioRequest request) {
        if (usuarioRepository.existsByUsername(request.getUsername())) {
            throw new IllegalArgumentException("El username '" + request.getUsername() + "' ya está en uso");
        }
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("El email '" + request.getEmail() + "' ya está en uso");
        }

        Long condominioId = TenantContext.getCondominioId();
        if (condominioId == null) {
            condominioId = request.getCondominioId();
            if (condominioId == null) {
                throw new IllegalArgumentException("condominioId es requerido");
            }
            if (request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("No se puede crear un usuario SUPERADMIN");
            }
        } else {
            if (request.getRol() == Rol.ADMIN || request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("ADMIN solo puede crear usuarios con rol GUARDIA o USUARIO");
            }
        }

        if (request.getRol() == Rol.USUARIO) {
            if (request.getUnidadHabitacional() == null || request.getUnidadHabitacional().isBlank()) {
                throw new IllegalArgumentException("La unidad habitacional es requerida para residentes");
            }
        }

        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        Usuario usuario = Usuario.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .nombreCompleto(request.getNombreCompleto())
                .telefono(request.getTelefono())
                .telefono2(request.getTelefono2())
                .rol(request.getRol())
                .condominio(condominio)
                .unidadHabitacional(request.getUnidadHabitacional())
                .esPropietario(request.getEsPropietario() != null ? request.getEsPropietario() : false)
                .activo(true)
                .build();

        usuario = usuarioRepository.save(usuario);
        log.info("Usuario creado: username={}, rol={}, condominioId={}",
                usuario.getUsername(), usuario.getRol(), condominio.getId());
        return toResponse(usuario);
    }

    @Transactional
    public UsuarioResponse actualizarUsuario(Long id, UpdateUsuarioRequest request) {
        Usuario usuario = findAndValidate(id);

        Long condominioId = TenantContext.getCondominioId();
        if (condominioId != null) {
            if (request.getRol() == Rol.ADMIN || request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("ADMIN solo puede asignar roles GUARDIA o USUARIO");
            }
        } else {
            if (request.getRol() == Rol.SUPERADMIN) {
                throw new UnauthorizedException("No se puede asignar rol SUPERADMIN");
            }
        }

        if (request.getRol() == Rol.USUARIO) {
            if (request.getUnidadHabitacional() == null || request.getUnidadHabitacional().isBlank()) {
                throw new IllegalArgumentException("La unidad habitacional es requerida para residentes");
            }
        }

        usuario.setNombreCompleto(request.getNombreCompleto());
        usuario.setTelefono(request.getTelefono());
        usuario.setTelefono2(request.getTelefono2());
        usuario.setRol(request.getRol());
        usuario.setUnidadHabitacional(request.getUnidadHabitacional());
        usuario.setEsPropietario(request.getEsPropietario());

        usuario = usuarioRepository.save(usuario);
        log.info("Usuario actualizado: id={}", id);
        return toResponse(usuario);
    }

    @Transactional
    public UsuarioResponse toggleEstado(Long id) {
        Usuario usuario = findAndValidate(id);
        usuario.setActivo(!usuario.getActivo());
        usuario = usuarioRepository.save(usuario);
        log.info("Estado de usuario cambiado: id={}, activo={}", id, usuario.getActivo());
        return toResponse(usuario);
    }

    @Transactional(readOnly = true)
    public List<ResidenteBasicoResponse> listarResidentes() {
        Long condominioId = TenantContext.getCondominioId();
        return usuarioRepository.findByCondominioIdAndRolAndActivo(condominioId, Rol.USUARIO, true)
                .stream()
                .map(u -> ResidenteBasicoResponse.builder()
                        .id(u.getId())
                        .nombreCompleto(u.getNombreCompleto())
                        .unidadHabitacional(u.getUnidadHabitacional())
                        .build())
                .collect(Collectors.toList());
    }

    private Usuario findAndValidate(Long id) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        Long condominioId = TenantContext.getCondominioId();
        if (condominioId != null) {
            if (usuario.getCondominio() == null ||
                    !usuario.getCondominio().getId().equals(condominioId)) {
                throw new TenantMismatchException("No tienes permiso para gestionar este usuario");
            }
        }
        return usuario;
    }

    @Transactional
    public BulkUsuarioResponse crearUsuariosBulk(MultipartFile file) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        int creados = 0;
        List<BulkUsuarioError> errores = new ArrayList<>();
        int fila = 1;

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {

            String linea;
            boolean primeraLinea = true;

            while ((linea = reader.readLine()) != null) {
                if (primeraLinea) { primeraLinea = false; continue; }
                fila++;
                String[] col = linea.split(",", -1);
                if (col.length < 3) {
                    errores.add(new BulkUsuarioError(fila, "", "Formato inválido: faltan columnas"));
                    continue;
                }

                String nombreCompleto = col[0].trim();
                String email = col[1].trim();
                String rol = col[2].trim().toUpperCase();
                String unidad = col.length > 3 ? col[3].trim() : "";

                if (nombreCompleto.isEmpty() || email.isEmpty() || rol.isEmpty()) {
                    errores.add(new BulkUsuarioError(fila, email, "Campos obligatorios vacíos"));
                    continue;
                }
                if (!rol.equals("USUARIO") && !rol.equals("GUARDIA")) {
                    errores.add(new BulkUsuarioError(fila, email, "Rol inválido: " + rol));
                    continue;
                }
                if (rol.equals("USUARIO") && unidad.isEmpty()) {
                    errores.add(new BulkUsuarioError(fila, email, "Unidad habitacional requerida para USUARIO"));
                    continue;
                }
                if (usuarioRepository.existsByEmail(email)) {
                    errores.add(new BulkUsuarioError(fila, email, "El email ya está en uso"));
                    continue;
                }
                if (usuarioRepository.existsByUsername(email)) {
                    errores.add(new BulkUsuarioError(fila, email, "El username ya está en uso"));
                    continue;
                }

                try {
                    Rol rolEnum = Rol.valueOf(rol);
                    Usuario usuario = Usuario.builder()
                            .username(email)
                            .email(email)
                            .passwordHash(passwordEncoder.encode("Condos2024!"))
                            .nombreCompleto(nombreCompleto)
                            .rol(rolEnum)
                            .condominio(condominio)
                            .unidadHabitacional(unidad.isEmpty() ? null : unidad)
                            .esPropietario(false)
                            .activo(true)
                            .build();
                    usuarioRepository.save(usuario);
                    creados++;
                } catch (Exception e) {
                    errores.add(new BulkUsuarioError(fila, email, "Error: " + e.getMessage()));
                }
            }
        } catch (Exception e) {
            throw new IllegalArgumentException("Error al leer el archivo: " + e.getMessage());
        }

        log.info("Bulk usuarios: creados={}, errores={}", creados, errores.size());
        return BulkUsuarioResponse.builder().creados(creados).errores(errores).build();
    }

    public UsuarioResponse toResponse(Usuario usuario) {
        return UsuarioResponse.builder()
                .id(usuario.getId())
                .username(usuario.getUsername())
                .email(usuario.getEmail())
                .nombreCompleto(usuario.getNombreCompleto())
                .telefono(usuario.getTelefono())
                .telefono2(usuario.getTelefono2())
                .rol(usuario.getRol())
                .condominioId(usuario.getCondominio() != null ? usuario.getCondominio().getId() : null)
                .condominioNombre(usuario.getCondominio() != null ? usuario.getCondominio().getNombre() : null)
                .unidadHabitacional(usuario.getUnidadHabitacional())
                .esPropietario(usuario.getEsPropietario())
                .activo(usuario.getActivo())
                .createdAt(usuario.getCreatedAt())
                .build();
    }
}
