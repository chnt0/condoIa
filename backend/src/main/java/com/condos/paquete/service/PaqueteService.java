package com.condos.paquete.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.paquete.dto.CreatePaqueteRequest;
import com.condos.paquete.dto.PaqueteResponse;
import com.condos.paquete.model.EstadoPaquete;
import com.condos.paquete.model.Paquete;
import com.condos.paquete.repository.PaqueteRepository;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PaqueteService {

    private final PaqueteRepository paqueteRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;

    @Transactional
    public PaqueteResponse registrarPaquete(CreatePaqueteRequest request, Long guardiaId) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        Usuario destinatario = usuarioRepository.findById(request.getUsuarioDestinatarioId())
                .orElseThrow(() -> new ResourceNotFoundException("Residente no encontrado"));

        Usuario guardia = usuarioRepository.findById(guardiaId)
                .orElseThrow(() -> new ResourceNotFoundException("Guardia no encontrado"));

        Paquete paquete = Paquete.builder()
                .condominio(condominio)
                .destinatario(destinatario)
                .descripcion(request.getDescripcion())
                .notas(request.getNotas())
                .guardiaRegistro(guardia)
                .estado(EstadoPaquete.PENDIENTE)
                .build();

        paquete = paqueteRepository.save(paquete);
        log.info("Paquete registrado: id={}, destinatario={}", paquete.getId(), destinatario.getNombreCompleto());
        return toResponse(paquete);
    }

    @Transactional
    public PaqueteResponse entregarPaquete(Long paqueteId, Long guardiaId) {
        Paquete paquete = paqueteRepository.findById(paqueteId)
                .orElseThrow(() -> new ResourceNotFoundException("Paquete no encontrado"));

        if (paquete.getEstado() == EstadoPaquete.ENTREGADO) {
            throw new IllegalStateException("Este paquete ya fue entregado");
        }

        Usuario guardia = usuarioRepository.findById(guardiaId)
                .orElseThrow(() -> new ResourceNotFoundException("Guardia no encontrado"));

        paquete.setEstado(EstadoPaquete.ENTREGADO);
        paquete.setFechaHoraEntrega(LocalDateTime.now());
        paquete.setGuardiaEntrega(guardia);

        paquete = paqueteRepository.save(paquete);
        log.info("Paquete entregado: id={}, guardia={}", paqueteId, guardia.getUsername());
        return toResponse(paquete);
    }

    @Transactional(readOnly = true)
    public List<PaqueteResponse> listarPaquetes() {
        Long condominioId = TenantContext.getCondominioId();
        return paqueteRepository.findByCondominioIdOrderByFechaHoraLlegadaDesc(condominioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<PaqueteResponse> listarMisPaquetes(Long usuarioId) {
        return paqueteRepository.findByDestinatarioIdOrderByFechaHoraLlegadaDesc(usuarioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    private PaqueteResponse toResponse(Paquete p) {
        return PaqueteResponse.builder()
                .id(p.getId())
                .usuarioDestinatarioId(p.getDestinatario().getId())
                .destinatarioNombre(p.getDestinatario().getNombreCompleto())
                .destinatarioUnidad(p.getDestinatario().getUnidadHabitacional())
                .descripcion(p.getDescripcion())
                .notas(p.getNotas())
                .fechaHoraLlegada(p.getFechaHoraLlegada())
                .guardiaRegistroId(p.getGuardiaRegistro().getId())
                .guardiaRegistroNombre(p.getGuardiaRegistro().getNombreCompleto())
                .estado(p.getEstado())
                .fechaHoraEntrega(p.getFechaHoraEntrega())
                .guardiaEntregaId(p.getGuardiaEntrega() != null ? p.getGuardiaEntrega().getId() : null)
                .guardiaEntregaNombre(p.getGuardiaEntrega() != null ? p.getGuardiaEntrega().getNombreCompleto() : null)
                .createdAt(p.getCreatedAt())
                .build();
    }
}
