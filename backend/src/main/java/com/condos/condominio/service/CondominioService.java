package com.condos.condominio.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.condominio.dto.CondominioResponse;
import com.condos.condominio.dto.CreateCondominioRequest;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.usuario.dto.UsuarioResponse;
import com.condos.usuario.model.Rol;
import com.condos.usuario.repository.UsuarioRepository;
import com.condos.usuario.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CondominioService {

    private final CondominioRepository condominioRepository;
    private final UsuarioRepository usuarioRepository;
    private final UsuarioService usuarioService;

    @Transactional(readOnly = true)
    public List<CondominioResponse> listarCondominios() {
        return condominioRepository.findAllByOrderByNombreAsc()
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public CondominioResponse crearCondominio(CreateCondominioRequest request) {
        Condominio condominio = Condominio.builder()
                .nombre(request.getNombre())
                .direccion(request.getDireccion())
                .numUnidades(request.getNumUnidades())
                .activo(request.isActivo())
                .build();
        condominio = condominioRepository.save(condominio);
        log.info("Condominio creado: id={}, nombre={}", condominio.getId(), condominio.getNombre());
        return toResponse(condominio);
    }

    @Transactional
    public CondominioResponse editarCondominio(Long id, CreateCondominioRequest request) {
        Condominio condominio = findById(id);
        condominio.setNombre(request.getNombre());
        condominio.setDireccion(request.getDireccion());
        condominio.setNumUnidades(request.getNumUnidades());
        condominio.setActivo(request.isActivo());
        condominio = condominioRepository.save(condominio);
        log.info("Condominio editado: id={}", id);
        return toResponse(condominio);
    }

    @Transactional
    public CondominioResponse toggleActivo(Long id) {
        Condominio condominio = findById(id);
        condominio.setActivo(!condominio.getActivo());
        condominio = condominioRepository.save(condominio);
        log.info("Condominio {} activo: {}", id, condominio.getActivo());
        return toResponse(condominio);
    }

    @Transactional(readOnly = true)
    public List<UsuarioResponse> listarAdmins(Long condominioId) {
        findById(condominioId);
        return usuarioRepository.findByCondominioIdAndRolAndActivo(condominioId, Rol.ADMIN, true)
                .stream().map(usuarioService::toResponse).collect(Collectors.toList());
    }

    private Condominio findById(Long id) {
        return condominioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));
    }

    public CondominioResponse toResponse(Condominio c) {
        int totalUsuarios = usuarioRepository.findByCondominioId(c.getId()).size();
        long totalAdmins = usuarioRepository.findByCondominioIdAndRolAndActivo(
                c.getId(), Rol.ADMIN, true).size();
        return CondominioResponse.builder()
                .id(c.getId())
                .nombre(c.getNombre())
                .direccion(c.getDireccion())
                .numUnidades(c.getNumUnidades() != null ? c.getNumUnidades() : 0)
                .activo(c.getActivo())
                .totalUsuarios(totalUsuarios)
                .totalAdmins((int) totalAdmins)
                .createdAt(c.getCreatedAt())
                .build();
    }
}
