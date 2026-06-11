package com.condos.notificacion.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.notificacion.dto.CreateNotificacionRequest;
import com.condos.notificacion.dto.NotificacionResponse;
import com.condos.notificacion.model.Notificacion;
import com.condos.notificacion.model.SegmentoNotificacion;
import com.condos.notificacion.repository.NotificacionRepository;
import com.condos.usuario.model.Rol;
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
public class NotificacionService {

    private final NotificacionRepository notificacionRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;

    @Transactional
    public NotificacionResponse crearNotificacion(CreateNotificacionRequest request, Long adminId) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));
        Usuario admin = usuarioRepository.findById(adminId)
                .orElseThrow(() -> new ResourceNotFoundException("Admin no encontrado"));

        if (request.getSegmento() == SegmentoNotificacion.EDIFICIO_X &&
                (request.getEdificio() == null || request.getEdificio().isBlank())) {
            throw new IllegalArgumentException("El campo 'edificio' es requerido para el segmento EDIFICIO_X");
        }

        Notificacion notificacion = Notificacion.builder()
                .condominio(condominio)
                .adminCreador(admin)
                .titulo(request.getTitulo())
                .mensaje(request.getMensaje())
                .segmento(request.getSegmento())
                .edificio(request.getEdificio())
                .build();

        notificacion = notificacionRepository.save(notificacion);
        log.info("Notificación creada: id={}, segmento={}", notificacion.getId(), notificacion.getSegmento());
        return toResponse(notificacion);
    }

    @Transactional(readOnly = true)
    public List<NotificacionResponse> listarNotificaciones(Long usuarioId) {
        Long condominioId = TenantContext.getCondominioId();
        List<Notificacion> todas = notificacionRepository.findByCondominioIdOrderByCreatedAtDesc(condominioId);

        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        if (usuario.getRol() != Rol.USUARIO) {
            return todas.stream().map(this::toResponse).collect(Collectors.toList());
        }

        String unidad = usuario.getUnidadHabitacional();
        return todas.stream()
                .filter(n -> {
                    if (n.getSegmento() == SegmentoNotificacion.TODOS) return true;
                    if (unidad == null || n.getEdificio() == null) return false;
                    return unidad.toLowerCase().startsWith(n.getEdificio().toLowerCase());
                })
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void eliminarNotificacion(Long id) {
        Notificacion notificacion = notificacionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notificación no encontrada"));
        notificacionRepository.delete(notificacion);
        log.info("Notificación eliminada: id={}", id);
    }

    private NotificacionResponse toResponse(Notificacion n) {
        return NotificacionResponse.builder()
                .id(n.getId())
                .titulo(n.getTitulo())
                .mensaje(n.getMensaje())
                .segmento(n.getSegmento())
                .edificio(n.getEdificio())
                .adminCreadorId(n.getAdminCreador().getId())
                .adminCreadorNombre(n.getAdminCreador().getNombreCompleto())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
