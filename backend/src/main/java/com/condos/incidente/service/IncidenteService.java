package com.condos.incidente.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.incidente.dto.*;
import com.condos.incidente.model.*;
import com.condos.incidente.repository.IncidenteComentarioRepository;
import com.condos.incidente.repository.IncidenteRepository;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class IncidenteService {

    private final IncidenteRepository incidenteRepository;
    private final IncidenteComentarioRepository comentarioRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;

    @Transactional
    public IncidenteResponse crearIncidente(CreateIncidenteRequest request, Long usuarioId) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        Incidente incidente = Incidente.builder()
                .condominio(condominio)
                .usuarioReporta(usuario)
                .categoria(request.getCategoria())
                .titulo(request.getTitulo())
                .descripcion(request.getDescripcion())
                .ubicacion(request.getUbicacion())
                .prioridad(request.getPrioridad())
                .estado(EstadoIncidente.PENDIENTE)
                .build();

        incidente = incidenteRepository.save(incidente);
        log.info("Incidente creado: id={}, usuario={}", incidente.getId(), usuario.getUsername());
        return toResponse(incidente);
    }

    @Transactional(readOnly = true)
    public List<IncidenteResponse> listarIncidentes() {
        Long condominioId = TenantContext.getCondominioId();
        return incidenteRepository.findByCondominioIdOrderByCreatedAtDesc(condominioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<IncidenteResponse> listarMisIncidentes(Long usuarioId) {
        return incidenteRepository.findByUsuarioReportaIdOrderByCreatedAtDesc(usuarioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public IncidenteResponse actualizarEstado(Long incidenteId, UpdateEstadoRequest request) {
        Incidente incidente = incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));

        if (incidente.getEstado() == EstadoIncidente.RESUELTO ||
                incidente.getEstado() == EstadoIncidente.CANCELADO) {
            throw new IllegalStateException("El incidente ya está cerrado y no puede cambiar de estado");
        }
        if (request.getEstado() == EstadoIncidente.CANCELADO) {
            throw new IllegalArgumentException("Use el endpoint de cancelar para cancelar un incidente");
        }

        incidente.setEstado(request.getEstado());
        incidente = incidenteRepository.save(incidente);
        log.info("Estado incidente actualizado: id={}, estado={}", incidenteId, request.getEstado());
        return toResponse(incidente);
    }

    @Transactional
    public void cancelarIncidente(Long incidenteId, Long usuarioId) {
        Incidente incidente = incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));

        if (!incidente.getUsuarioReporta().getId().equals(usuarioId)) {
            throw new UnauthorizedException("No tienes permiso para cancelar este incidente");
        }
        if (incidente.getEstado() == EstadoIncidente.RESUELTO ||
                incidente.getEstado() == EstadoIncidente.CANCELADO) {
            throw new IllegalStateException("El incidente ya está cerrado");
        }

        incidente.setEstado(EstadoIncidente.CANCELADO);
        incidenteRepository.save(incidente);
        log.info("Incidente cancelado: id={}, usuario={}", incidenteId, usuarioId);
    }

    @Transactional(readOnly = true)
    public List<ComentarioResponse> listarComentarios(Long incidenteId) {
        incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));
        return comentarioRepository.findByIncidenteIdOrderByCreatedAtAsc(incidenteId)
                .stream().map(this::toComentarioResponse).collect(Collectors.toList());
    }

    @Transactional
    public ComentarioResponse agregarComentario(Long incidenteId, AddComentarioRequest request, Long usuarioId) {
        Incidente incidente = incidenteRepository.findById(incidenteId)
                .orElseThrow(() -> new ResourceNotFoundException("Incidente no encontrado"));
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        IncidenteComentario comentario = IncidenteComentario.builder()
                .incidente(incidente)
                .usuario(usuario)
                .comentario(request.getComentario())
                .build();

        comentario = comentarioRepository.save(comentario);
        log.info("Comentario agregado: incidenteId={}, usuario={}", incidenteId, usuario.getUsername());
        return toComentarioResponse(comentario);
    }

    private IncidenteResponse toResponse(Incidente i) {
        return IncidenteResponse.builder()
                .id(i.getId())
                .categoria(i.getCategoria())
                .titulo(i.getTitulo())
                .descripcion(i.getDescripcion())
                .ubicacion(i.getUbicacion())
                .prioridad(i.getPrioridad())
                .estado(i.getEstado())
                .usuarioReportaId(i.getUsuarioReporta().getId())
                .usuarioReportaNombre(i.getUsuarioReporta().getNombreCompleto())
                .usuarioReportaUnidad(i.getUsuarioReporta().getUnidadHabitacional())
                .createdAt(i.getCreatedAt())
                .updatedAt(i.getUpdatedAt())
                .build();
    }

    private ComentarioResponse toComentarioResponse(IncidenteComentario c) {
        return ComentarioResponse.builder()
                .id(c.getId())
                .incidenteId(c.getIncidente().getId())
                .usuarioId(c.getUsuario().getId())
                .usuarioNombre(c.getUsuario().getNombreCompleto())
                .comentario(c.getComentario())
                .createdAt(c.getCreatedAt())
                .build();
    }
}
