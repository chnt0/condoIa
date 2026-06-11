package com.condos.reservacion.repository;

import com.condos.reservacion.model.EstadoReservacion;
import com.condos.reservacion.model.Reservacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ReservacionRepository extends JpaRepository<Reservacion, Long> {
    List<Reservacion> findByAreaComunCondominioIdOrderByFechaHoraInicioDesc(Long condominioId);
    List<Reservacion> findByUsuarioIdOrderByFechaHoraInicioDesc(Long usuarioId);

    boolean existsByAreaComunIdAndFechaHoraInicioAndEstado(
            Long areaComunId, LocalDateTime fechaHoraInicio, EstadoReservacion estado);

    long countByAreaComunIdAndUsuarioIdAndEstadoAndFechaHoraInicioGreaterThanEqualAndFechaHoraInicioLessThan(
            Long areaComunId, Long usuarioId, EstadoReservacion estado,
            LocalDateTime inicioMes, LocalDateTime finMes);
}
