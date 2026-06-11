package com.condos.reservacion.service;

import com.condos.area.model.AreaComun;
import com.condos.area.repository.AreaComunRepository;
import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.pago.model.EstadoPago;
import com.condos.pago.repository.CuotaUsuarioRepository;
import com.condos.reservacion.dto.CreateReservacionRequest;
import com.condos.reservacion.dto.ReservacionResponse;
import com.condos.reservacion.model.EstadoReservacion;
import com.condos.reservacion.model.Reservacion;
import com.condos.reservacion.repository.ReservacionRepository;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReservacionService {

    private final ReservacionRepository reservacionRepository;
    private final AreaComunRepository areaComunRepository;
    private final UsuarioRepository usuarioRepository;
    private final CuotaUsuarioRepository cuotaUsuarioRepository;

    @Transactional
    public ReservacionResponse crearReservacion(CreateReservacionRequest request, Long usuarioId) {
        AreaComun area = areaComunRepository.findById(request.getAreaComunId())
                .orElseThrow(() -> new ResourceNotFoundException("Área común no encontrada"));

        if (!area.isActiva()) {
            throw new IllegalStateException("El área no está disponible para reservas");
        }

        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));

        boolean esMoroso = cuotaUsuarioRepository.existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(
                usuarioId, EstadoPago.PENDIENTE, LocalDate.now());
        if (esMoroso) {
            throw new IllegalStateException("No puedes realizar reservaciones mientras tengas pagos pendientes vencidos");
        }

        LocalDateTime inicio = request.getFechaHoraInicio();
        LocalDateTime fin = inicio.plusMinutes(area.getDuracionBloqueMinutos());
        LocalDateTime ahora = LocalDateTime.now();

        if (inicio.isBefore(ahora.plusHours(area.getAnticipacionMinimaHoras()))) {
            throw new IllegalArgumentException(
                    "La reservación debe hacerse con al menos " + area.getAnticipacionMinimaHoras() + " horas de anticipación");
        }

        if (inicio.isAfter(ahora.plusDays(area.getAnticipacionMaximaDias()))) {
            throw new IllegalArgumentException(
                    "La reservación no puede hacerse con más de " + area.getAnticipacionMaximaDias() + " días de anticipación");
        }

        boolean ocupado = reservacionRepository.existsByAreaComunIdAndFechaHoraInicioAndEstado(
                area.getId(), inicio, EstadoReservacion.ACTIVA);
        if (ocupado) {
            throw new IllegalStateException("Este bloque horario ya está reservado");
        }

        YearMonth mesActual = YearMonth.from(inicio);
        LocalDateTime inicioMes = mesActual.atDay(1).atStartOfDay();
        LocalDateTime finMes = mesActual.atEndOfMonth().atTime(23, 59, 59).plusSeconds(1);

        long reservasMes = reservacionRepository
                .countByAreaComunIdAndUsuarioIdAndEstadoAndFechaHoraInicioGreaterThanEqualAndFechaHoraInicioLessThan(
                        area.getId(), usuarioId, EstadoReservacion.ACTIVA, inicioMes, finMes);
        if (reservasMes >= area.getMaxReservasMesPorUsuario()) {
            throw new IllegalStateException(
                    "Has alcanzado el límite de " + area.getMaxReservasMesPorUsuario() + " reservaciones mensuales para esta área");
        }

        Reservacion reservacion = Reservacion.builder()
                .areaComun(area)
                .usuario(usuario)
                .fechaHoraInicio(inicio)
                .fechaHoraFin(fin)
                .estado(EstadoReservacion.ACTIVA)
                .build();

        reservacion = reservacionRepository.save(reservacion);
        log.info("Reservación creada: id={}, area={}, usuario={}", reservacion.getId(), area.getNombre(), usuario.getUsername());
        return toResponse(reservacion);
    }

    @Transactional(readOnly = true)
    public List<ReservacionResponse> listarReservaciones() {
        Long condominioId = TenantContext.getCondominioId();
        return reservacionRepository.findByAreaComunCondominioIdOrderByFechaHoraInicioDesc(condominioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ReservacionResponse> listarMisReservaciones(Long usuarioId) {
        return reservacionRepository.findByUsuarioIdOrderByFechaHoraInicioDesc(usuarioId)
                .stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public void cancelarReservacion(Long reservacionId, Long usuarioId, boolean esAdmin) {
        Reservacion reservacion = reservacionRepository.findById(reservacionId)
                .orElseThrow(() -> new ResourceNotFoundException("Reservación no encontrada"));

        if (!esAdmin && !reservacion.getUsuario().getId().equals(usuarioId)) {
            throw new UnauthorizedException("No tienes permiso para cancelar esta reservación");
        }
        if (!esAdmin && reservacion.getFechaHoraInicio().isBefore(LocalDateTime.now())) {
            throw new IllegalStateException("No puedes cancelar una reservación que ya pasó");
        }
        if (reservacion.getEstado() == EstadoReservacion.CANCELADA) {
            throw new IllegalStateException("La reservación ya está cancelada");
        }

        reservacion.setEstado(EstadoReservacion.CANCELADA);
        reservacionRepository.save(reservacion);
        log.info("Reservación cancelada: id={}", reservacionId);
    }

    private ReservacionResponse toResponse(Reservacion r) {
        return ReservacionResponse.builder()
                .id(r.getId())
                .areaComunId(r.getAreaComun().getId())
                .areaComunNombre(r.getAreaComun().getNombre())
                .usuarioId(r.getUsuario().getId())
                .usuarioNombre(r.getUsuario().getNombreCompleto())
                .fechaHoraInicio(r.getFechaHoraInicio())
                .fechaHoraFin(r.getFechaHoraFin())
                .estado(r.getEstado())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
