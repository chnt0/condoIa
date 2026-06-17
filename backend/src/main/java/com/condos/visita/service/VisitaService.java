package com.condos.visita.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import com.condos.visita.dto.CreateVisitaRequest;
import com.condos.visita.dto.ValidarQrRequest;
import com.condos.visita.dto.ValidarQrResponse;
import com.condos.visita.dto.VisitaResponse;
import com.condos.visita.model.EstadoVisita;
import com.condos.visita.model.Visita;
import com.condos.visita.repository.VisitaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.condos.notificacion.service.NotificacionPushService;
import com.condos.visita.dto.CreateVisitaDirectaRequest;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Servicio de lógica de negocio para Visitas.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class VisitaService {

    private final VisitaRepository visitaRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;
    private final QrCodeService qrCodeService;
    private final NotificacionPushService notificacionPushService;

    /**
     * Crea una nueva visita programada.
     */
    @Transactional
    public VisitaResponse crearVisita(CreateVisitaRequest request, Long usuarioId) {
        // Obtener condominio del contexto multi-tenant
        Long condominioId = TenantContext.getCondominioId();
        if (condominioId == null) {
            throw new IllegalStateException("Condominio no establecido en el contexto");
        }

        // Validar usuario y condominio existen
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        // Crear entidad Visita con UUID temporal en codigoQrHash
        // (se reemplaza con el hash real después de obtener el ID)
        Visita visita = Visita.builder()
                .condominio(condominio)
                .usuario(usuario)
                .nombreVisitante(request.getNombreVisitante())
                .telefonoVisitante(request.getTelefonoVisitante())
                .fechaHoraProgramada(request.getFechaHoraProgramada())
                .motivo(request.getMotivo())
                .vehiculoPlacas(request.getVehiculoPlacas())
                .estado(EstadoVisita.PROGRAMADA)
                .codigoQrHash(UUID.randomUUID().toString())
                .build();

        // Guardar para obtener ID
        visita = visitaRepository.save(visita);

        // Generar código QR hash
        String qrHash = qrCodeService.generateQrHash(visita.getId(), condominioId);
        visita.setCodigoQrHash(qrHash);

        // Actualizar con QR hash
        visita = visitaRepository.save(visita);

        log.info("Visita creada: id={}, visitante={}, qrHash={}",
                visita.getId(), visita.getNombreVisitante(), qrHash);

        return toResponse(visita);
    }

    /**
     * Valida un código QR y registra la entrada de la visita.
     */
    @Transactional
    public ValidarQrResponse validarQr(ValidarQrRequest request, Long guardiaId) {
        String codigoQr = request.getCodigoQr();

        // Validar formato del QR
        if (!qrCodeService.validateQrFormat(codigoQr)) {
            return ValidarQrResponse.builder()
                    .valido(false)
                    .mensaje("Código QR inválido o formato incorrecto")
                    .build();
        }

        // Extraer condominio del QR y validar coincide con contexto
        Long qrCondominioId = qrCodeService.extractCondominioId(codigoQr);
        Long contextCondominioId = TenantContext.getCondominioId();

        if (!qrCondominioId.equals(contextCondominioId)) {
            log.warn("Intento de validar QR de otro condominio: qr={}, context={}",
                    qrCondominioId, contextCondominioId);
            return ValidarQrResponse.builder()
                    .valido(false)
                    .mensaje("Este código QR pertenece a otro condominio")
                    .build();
        }

        // Buscar visita por QR hash
        Visita visita = visitaRepository.findByCodigoQrHash(codigoQr)
                .orElse(null);

        if (visita == null) {
            return ValidarQrResponse.builder()
                    .valido(false)
                    .mensaje("Visita no encontrada")
                    .build();
        }

        // Validar estado
        if (visita.getEstado() == EstadoVisita.COMPLETADA) {
            return ValidarQrResponse.builder()
                    .valido(false)
                    .mensaje("Esta visita ya fue registrada anteriormente")
                    .visita(toResponse(visita))
                    .build();
        }

        if (visita.getEstado() == EstadoVisita.CANCELADA) {
            return ValidarQrResponse.builder()
                    .valido(false)
                    .mensaje("Esta visita fue cancelada")
                    .visita(toResponse(visita))
                    .build();
        }

        // Obtener guardia
        Usuario guardia = usuarioRepository.findById(guardiaId)
                .orElseThrow(() -> new ResourceNotFoundException("Guardia no encontrado"));

        // Registrar entrada
        visita.setEstado(EstadoVisita.COMPLETADA);
        visita.setFechaHoraEntrada(LocalDateTime.now());
        visita.setGuardiaEntrada(guardia);
        visita.setNotas(request.getNotas());

        visita = visitaRepository.save(visita);

        log.info("Visita validada: id={}, visitante={}, guardia={}",
                visita.getId(), visita.getNombreVisitante(), guardia.getUsername());

        return ValidarQrResponse.builder()
                .valido(true)
                .mensaje("Código QR válido. Entrada registrada correctamente.")
                .visita(toResponse(visita))
                .build();
    }

    /**
     * Lista visitas del condominio actual.
     */
    @Transactional(readOnly = true)
    public List<VisitaResponse> listarVisitas() {
        Long condominioId = TenantContext.getCondominioId();
        List<Visita> visitas = visitaRepository.findByCondominioId(condominioId);
        return visitas.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lista visitas de un usuario específico.
     */
    @Transactional(readOnly = true)
    public List<VisitaResponse> listarVisitasUsuario(Long usuarioId) {
        List<Visita> visitas = visitaRepository.findByUsuarioIdAndEstado(
                usuarioId, EstadoVisita.PROGRAMADA);
        return visitas.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene detalle de una visita.
     */
    @Transactional(readOnly = true)
    public VisitaResponse obtenerVisita(Long visitaId) {
        Visita visita = visitaRepository.findById(visitaId)
                .orElseThrow(() -> new ResourceNotFoundException("Visita no encontrada"));

        return toResponse(visita);
    }

    /**
     * Cancela una visita programada.
     */
    @Transactional
    public VisitaResponse cancelarVisita(Long visitaId, Long usuarioId) {
        Visita visita = visitaRepository.findById(visitaId)
                .orElseThrow(() -> new ResourceNotFoundException("Visita no encontrada"));

        // Validar que el usuario sea el dueño de la visita
        if (!visita.getUsuario().getId().equals(usuarioId)) {
            throw new UnauthorizedException("No tienes permiso para cancelar esta visita");
        }

        // Solo se pueden cancelar visitas programadas
        if (visita.getEstado() != EstadoVisita.PROGRAMADA) {
            throw new IllegalStateException(
                    "Solo se pueden cancelar visitas en estado PROGRAMADA");
        }

        visita.setEstado(EstadoVisita.CANCELADA);
        visita = visitaRepository.save(visita);

        log.info("Visita cancelada: id={}, usuario={}", visitaId, usuarioId);

        return toResponse(visita);
    }

    /**
     * Genera la imagen QR para una visita.
     */
    public String generarImagenQr(Long visitaId) {
        Visita visita = visitaRepository.findById(visitaId)
                .orElseThrow(() -> new ResourceNotFoundException("Visita no encontrada"));

        return qrCodeService.generateQrCodeImage(visita.getCodigoQrHash());
    }

    /**
     * Registra una visita directa (sin QR) por el guardia en el momento.
     */
    @Transactional
    public VisitaResponse registrarVisitaDirecta(CreateVisitaDirectaRequest request, Long guardiaId) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        Usuario guardia = usuarioRepository.findById(guardiaId)
                .orElseThrow(() -> new ResourceNotFoundException("Guardia no encontrado"));

        Usuario destinatario = usuarioRepository.findById(request.getUsuarioDestinatarioId())
                .orElseThrow(() -> new ResourceNotFoundException("Residente destinatario no encontrado"));

        Visita visita = Visita.builder()
                .condominio(condominio)
                .usuario(destinatario)
                .nombreVisitante(request.getNombreVisitante())
                .telefonoVisitante(request.getTelefonoVisitante())
                .fechaHoraProgramada(LocalDateTime.now())
                .codigoQrHash("DIRECTA-" + UUID.randomUUID())
                .motivo(request.getMotivo())
                .vehiculoPlacas(request.getVehiculoPlacas())
                .fotoVehiculo(request.getFotoVehiculo())
                .estado(EstadoVisita.COMPLETADA)
                .fechaHoraEntrada(LocalDateTime.now())
                .guardiaEntrada(guardia)
                .tipoVisita("DIRECTA")
                .build();

        visita = visitaRepository.save(visita);
        log.info("Visita directa registrada: id={}, visitante={}, guardia={}",
                visita.getId(), visita.getNombreVisitante(), guardia.getUsername());

        // Notificar push al residente destinatario
        notificacionPushService.notificarVisitaDirecta(
                destinatario.getId(),
                request.getNombreVisitante(),
                request.getMotivo()
        );

        return toResponse(visita);
    }

    /**
     * Convierte entidad Visita a DTO Response.
     */
    private VisitaResponse toResponse(Visita visita) {
        return VisitaResponse.builder()
                .id(visita.getId())
                .nombreVisitante(visita.getNombreVisitante())
                .telefonoVisitante(visita.getTelefonoVisitante())
                .fechaHoraProgramada(visita.getFechaHoraProgramada())
                .codigoQrHash(visita.getCodigoQrHash())
                .motivo(visita.getMotivo())
                .vehiculoPlacas(visita.getVehiculoPlacas())
                .estado(visita.getEstado())
                .fechaHoraEntrada(visita.getFechaHoraEntrada())
                .notas(visita.getNotas())
                .createdAt(visita.getCreatedAt())
                .usuarioId(visita.getUsuario().getId())
                .usuarioNombre(visita.getUsuario().getNombreCompleto())
                .unidadHabitacional(visita.getUsuario().getUnidadHabitacional())
                .guardiaEntradaId(visita.getGuardiaEntrada() != null ?
                        visita.getGuardiaEntrada().getId() : null)
                .guardiaEntradaNombre(visita.getGuardiaEntrada() != null ?
                        visita.getGuardiaEntrada().getNombreCompleto() : null)
                .fotoVehiculo(visita.getFotoVehiculo())
                .tipoVisita(visita.getTipoVisita())
                .build();
    }
}
