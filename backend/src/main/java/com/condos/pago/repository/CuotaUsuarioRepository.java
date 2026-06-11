package com.condos.pago.repository;

import com.condos.pago.model.CuotaUsuario;
import com.condos.pago.model.EstadoPago;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CuotaUsuarioRepository extends JpaRepository<CuotaUsuario, Long> {
    List<CuotaUsuario> findByCuotaId(Long cuotaId);
    List<CuotaUsuario> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);
    boolean existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(
            Long usuarioId, EstadoPago estado, LocalDate fecha);
}
