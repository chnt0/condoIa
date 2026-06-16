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

        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        Usuario usuario = Usuario.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .nombreCompleto(request.getNombreCompleto())
                .telefono(request.getTelefono())
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

        usuario.setNombreCompleto(request.getNombreCompleto());
        usuario.setTelefono(request.getTelefono());
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

    public UsuarioResponse toResponse(Usuario usuario) {
        return UsuarioResponse.builder()
                .id(usuario.getId())
                .username(usuario.getUsername())
                .email(usuario.getEmail())
                .nombreCompleto(usuario.getNombreCompleto())
                .telefono(usuario.getTelefono())
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
