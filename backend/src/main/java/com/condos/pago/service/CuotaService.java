package com.condos.pago.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.pago.dto.*;
import com.condos.pago.model.*;
import com.condos.pago.repository.CuotaRepository;
import com.condos.pago.repository.CuotaUsuarioRepository;
import com.condos.usuario.model.Rol;
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
public class CuotaService {

    private final CuotaRepository cuotaRepository;
    private final CuotaUsuarioRepository cuotaUsuarioRepository;
    private final UsuarioRepository usuarioRepository;
    private final CondominioRepository condominioRepository;

    @Transactional
    public CuotaResponse crearCuota(CreateCuotaRequest request) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        Cuota cuota = Cuota.builder()
                .condominio(condominio)
                .tipo(request.getTipo())
                .concepto(request.getConcepto())
                .monto(request.getMonto())
                .mes(request.getMes())
                .fechaVencimiento(request.getFechaVencimiento())
                .build();
        cuota = cuotaRepository.save(cuota);

        List<Usuario> destinatarios;
        if (request.getTipo() == TipoCuota.MENSUAL) {
            destinatarios = usuarioRepository.findByCondominioIdAndRolAndActivo(
                    condominioId, Rol.USUARIO, true);
        } else {
            if (request.getUsuarioIds() == null || request.getUsuarioIds().isEmpty()) {
                throw new IllegalArgumentException(
                        "Una cuota EXTRAORDINARIA requiere al menos un usuario destinatario");
            }
            destinatarios = usuarioRepository.findAllById(request.getUsuarioIds());
        }

        for (Usuario u : destinatarios) {
            CuotaUsuario cu = CuotaUsuario.builder()
                    .cuota(cuota)
                    .usuario(u)
                    .estado(EstadoPago.PENDIENTE)
                    .build();
            cuotaUsuarioRepository.save(cu);
        }

        log.info("Cuota creada: id={}, tipo={}, destinatarios={}", cuota.getId(), cuota.getTipo(), destinatarios.size());
        return toCuotaResponse(cuota);
    }

    @Transactional(readOnly = true)
    public List<CuotaResponse> listarCuotas() {
        Long condominioId = TenantContext.getCondominioId();
        return cuotaRepository.findByCondominioIdOrderByCreatedAtDesc(condominioId)
                .stream()
                .map(this::toCuotaResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CuotaUsuarioResponse> obtenerDetalle(Long cuotaId) {
        return cuotaUsuarioRepository.findByCuotaId(cuotaId)
                .stream()
                .map(this::toCuotaUsuarioResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CuotaUsuarioResponse> listarMisCuotas(Long usuarioId) {
        return cuotaUsuarioRepository.findByUsuarioIdOrderByCreatedAtDesc(usuarioId)
                .stream()
                .map(this::toCuotaUsuarioResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public CuotaUsuarioResponse reportarPago(Long cuotaUsuarioId, ReportarPagoRequest request, Long usuarioId) {
        CuotaUsuario cu = cuotaUsuarioRepository.findById(cuotaUsuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Cuota de usuario no encontrada"));

        if (!cu.getUsuario().getId().equals(usuarioId)) {
            throw new UnauthorizedException("No tienes permiso para reportar este pago");
        }
        if (cu.getEstado() == EstadoPago.CONFIRMADO) {
            throw new IllegalStateException("Este pago ya fue confirmado");
        }
        if (cu.getEstado() == EstadoPago.REPORTADO) {
            throw new IllegalStateException("El pago ya fue reportado y está pendiente de revisión");
        }

        cu.setEstado(EstadoPago.REPORTADO);
        cu.setReferenciaPago(request.getReferenciaPago());
        cu.setNotasUsuario(request.getNotasUsuario());
        cu.setComprobanteFoto(request.getComprobanteFoto());
        cu.setFechaReporte(LocalDateTime.now());

        cu = cuotaUsuarioRepository.save(cu);
        log.info("Pago reportado: cuotaUsuarioId={}, usuario={}", cuotaUsuarioId, usuarioId);
        return toCuotaUsuarioResponse(cu);
    }

    @Transactional
    public CuotaUsuarioResponse confirmarPago(Long cuotaUsuarioId, ConfirmarPagoRequest request) {
        CuotaUsuario cu = cuotaUsuarioRepository.findById(cuotaUsuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Cuota de usuario no encontrada"));

        if (cu.getEstado() != EstadoPago.REPORTADO) {
            throw new IllegalStateException("Solo se pueden confirmar/rechazar pagos en estado REPORTADO");
        }
        if (!request.isConfirmado() &&
                (request.getNotasAdmin() == null || request.getNotasAdmin().isBlank())) {
            throw new IllegalArgumentException("Se requiere una nota del admin para rechazar un pago");
        }

        cu.setEstado(request.isConfirmado() ? EstadoPago.CONFIRMADO : EstadoPago.RECHAZADO);
        cu.setNotasAdmin(request.getNotasAdmin());
        cu.setFechaConfirmacion(LocalDateTime.now());

        cu = cuotaUsuarioRepository.save(cu);
        log.info("Pago {}: cuotaUsuarioId={}", cu.getEstado(), cuotaUsuarioId);
        return toCuotaUsuarioResponse(cu);
    }

    private CuotaResponse toCuotaResponse(Cuota cuota) {
        List<CuotaUsuario> registros = cuotaUsuarioRepository.findByCuotaId(cuota.getId());
        long confirmados = registros.stream().filter(r -> r.getEstado() == EstadoPago.CONFIRMADO).count();
        long reportados  = registros.stream().filter(r -> r.getEstado() == EstadoPago.REPORTADO).count();
        long pendientes  = registros.stream().filter(r ->
                r.getEstado() == EstadoPago.PENDIENTE || r.getEstado() == EstadoPago.RECHAZADO).count();

        return CuotaResponse.builder()
                .id(cuota.getId())
                .tipo(cuota.getTipo())
                .concepto(cuota.getConcepto())
                .monto(cuota.getMonto())
                .mes(cuota.getMes())
                .fechaVencimiento(cuota.getFechaVencimiento())
                .totalResidentes(registros.size())
                .totalConfirmados((int) confirmados)
                .totalReportados((int) reportados)
                .totalPendientes((int) pendientes)
                .createdAt(cuota.getCreatedAt())
                .build();
    }

    private CuotaUsuarioResponse toCuotaUsuarioResponse(CuotaUsuario cu) {
        Cuota cuota = cu.getCuota();
        Usuario usuario = cu.getUsuario();
        return CuotaUsuarioResponse.builder()
                .id(cu.getId())
                .cuotaId(cuota.getId())
                .concepto(cuota.getConcepto())
                .monto(cuota.getMonto())
                .fechaVencimiento(cuota.getFechaVencimiento())
                .usuarioId(usuario.getId())
                .usuarioNombre(usuario.getNombreCompleto())
                .unidadHabitacional(usuario.getUnidadHabitacional())
                .estado(cu.getEstado())
                .referenciaPago(cu.getReferenciaPago())
                .notasUsuario(cu.getNotasUsuario())
                .comprobanteFoto(cu.getComprobanteFoto())
                .notasAdmin(cu.getNotasAdmin())
                .fechaReporte(cu.getFechaReporte())
                .fechaConfirmacion(cu.getFechaConfirmacion())
                .build();
    }
}
