package com.condos.area.service;

import com.condos.area.dto.AreaComunResponse;
import com.condos.area.dto.BloqueDisponibilidadResponse;
import com.condos.area.dto.CreateAreaComunRequest;
import com.condos.area.model.AreaComun;
import com.condos.area.repository.AreaComunRepository;
import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.TenantMismatchException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.reservacion.model.EstadoReservacion;
import com.condos.reservacion.repository.ReservacionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AreaComunService {

    private final AreaComunRepository areaComunRepository;
    private final CondominioRepository condominioRepository;
    private final ReservacionRepository reservacionRepository;

    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

    @Transactional(readOnly = true)
    public List<AreaComunResponse> listarAreas(boolean soloActivas) {
        Long condominioId = TenantContext.getCondominioId();
        List<AreaComun> areas = soloActivas
                ? areaComunRepository.findByCondominioIdAndActivaOrderByNombreAsc(condominioId, true)
                : areaComunRepository.findByCondominioIdOrderByNombreAsc(condominioId);
        return areas.stream().map(this::toResponse).collect(Collectors.toList());
    }

    @Transactional
    public AreaComunResponse crearArea(CreateAreaComunRequest request) {
        Long condominioId = TenantContext.getCondominioId();
        Condominio condominio = condominioRepository.findById(condominioId)
                .orElseThrow(() -> new ResourceNotFoundException("Condominio no encontrado"));

        AreaComun area = AreaComun.builder()
                .condominio(condominio)
                .nombre(request.getNombre())
                .descripcion(request.getDescripcion())
                .capacidad(request.getCapacidad())
                .horarioInicio(LocalTime.parse(request.getHorarioInicio(), TIME_FORMATTER))
                .horarioFin(LocalTime.parse(request.getHorarioFin(), TIME_FORMATTER))
                .duracionBloqueMinutos(request.getDuracionBloqueMinutos())
                .maxReservasMesPorUsuario(request.getMaxReservasMesPorUsuario())
                .anticipacionMinimaHoras(request.getAnticipacionMinimaHoras())
                .anticipacionMaximaDias(request.getAnticipacionMaximaDias())
                .activa(request.isActiva())
                .build();

        area = areaComunRepository.save(area);
        log.info("Área común creada: id={}, nombre={}", area.getId(), area.getNombre());
        return toResponse(area);
    }

    @Transactional
    public AreaComunResponse editarArea(Long id, CreateAreaComunRequest request) {
        AreaComun area = findAndValidate(id);
        area.setNombre(request.getNombre());
        area.setDescripcion(request.getDescripcion());
        area.setCapacidad(request.getCapacidad());
        area.setHorarioInicio(LocalTime.parse(request.getHorarioInicio(), TIME_FORMATTER));
        area.setHorarioFin(LocalTime.parse(request.getHorarioFin(), TIME_FORMATTER));
        area.setDuracionBloqueMinutos(request.getDuracionBloqueMinutos());
        area.setMaxReservasMesPorUsuario(request.getMaxReservasMesPorUsuario());
        area.setAnticipacionMinimaHoras(request.getAnticipacionMinimaHoras());
        area.setAnticipacionMaximaDias(request.getAnticipacionMaximaDias());
        area.setActiva(request.isActiva());
        area = areaComunRepository.save(area);
        log.info("Área común editada: id={}", id);
        return toResponse(area);
    }

    @Transactional
    public AreaComunResponse toggleActiva(Long id) {
        AreaComun area = findAndValidate(id);
        area.setActiva(!area.isActiva());
        area = areaComunRepository.save(area);
        log.info("Área común {} activa: {}", id, area.isActiva());
        return toResponse(area);
    }

    @Transactional(readOnly = true)
    public List<BloqueDisponibilidadResponse> obtenerDisponibilidad(Long areaId, LocalDate fecha) {
        AreaComun area = findAndValidate(areaId);
        LocalDateTime ahora = LocalDateTime.now();
        List<BloqueDisponibilidadResponse> bloques = new ArrayList<>();

        LocalDateTime inicio = LocalDateTime.of(fecha, area.getHorarioInicio());
        LocalDateTime fin = LocalDateTime.of(fecha, area.getHorarioFin());

        // Sin duración de bloque = todo el día es un solo bloque
        if (area.getDuracionBloqueMinutos() == 0) {
            if (inicio.isAfter(ahora)) {
                boolean ocupado = reservacionRepository.existsByAreaComunIdAndFechaHoraInicioAndEstado(
                        areaId, inicio, EstadoReservacion.ACTIVA);
                bloques.add(BloqueDisponibilidadResponse.builder()
                        .fechaHoraInicio(inicio)
                        .fechaHoraFin(fin)
                        .disponible(!ocupado)
                        .build());
            }
            return bloques;
        }

        LocalDateTime bloque = inicio;
        while (bloque.isBefore(fin)) {
            LocalDateTime bloqueHoraFin = bloque.plusMinutes(area.getDuracionBloqueMinutos());
            if (bloqueHoraFin.isAfter(fin)) break;

            if (bloque.isAfter(ahora)) {
                boolean ocupado = reservacionRepository.existsByAreaComunIdAndFechaHoraInicioAndEstado(
                        areaId, bloque, EstadoReservacion.ACTIVA);
                bloques.add(BloqueDisponibilidadResponse.builder()
                        .fechaHoraInicio(bloque)
                        .fechaHoraFin(bloqueHoraFin)
                        .disponible(!ocupado)
                        .build());
            }
            bloque = bloque.plusMinutes(area.getDuracionBloqueMinutos());
        }
        return bloques;
    }

    private AreaComun findAndValidate(Long id) {
        AreaComun area = areaComunRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Área común no encontrada"));
        Long condominioId = TenantContext.getCondominioId();
        if (condominioId != null && !area.getCondominio().getId().equals(condominioId)) {
            throw new TenantMismatchException("No tienes permiso sobre esta área");
        }
        return area;
    }

    public AreaComunResponse toResponse(AreaComun area) {
        return AreaComunResponse.builder()
                .id(area.getId())
                .nombre(area.getNombre())
                .descripcion(area.getDescripcion())
                .capacidad(area.getCapacidad())
                .horarioInicio(area.getHorarioInicio().format(TIME_FORMATTER))
                .horarioFin(area.getHorarioFin().format(TIME_FORMATTER))
                .duracionBloqueMinutos(area.getDuracionBloqueMinutos())
                .maxReservasMesPorUsuario(area.getMaxReservasMesPorUsuario())
                .anticipacionMinimaHoras(area.getAnticipacionMinimaHoras())
                .anticipacionMaximaDias(area.getAnticipacionMaximaDias())
                .activa(area.isActiva())
                .createdAt(area.getCreatedAt())
                .build();
    }
}
