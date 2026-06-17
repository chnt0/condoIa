package com.condos.pago.repository;

import com.condos.pago.model.CuotaUsuario;
import com.condos.pago.model.EstadoPago;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CuotaUsuarioRepository extends JpaRepository<CuotaUsuario, Long> {
    List<CuotaUsuario> findByCuotaId(Long cuotaId);
    List<CuotaUsuario> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);
    boolean existsByUsuarioIdAndEstadoAndCuotaFechaVencimientoBefore(
            Long usuarioId, EstadoPago estado, LocalDate fecha);

    @Query("SELECT cu FROM CuotaUsuario cu " +
           "JOIN cu.cuota c " +
           "WHERE c.condominio.id = :condominioId " +
           "AND (:mes IS NULL OR c.mes = :mes " +
           "     OR (FUNCTION('TO_CHAR', c.fechaVencimiento, 'YYYY-MM') = :mes)) " +
           "AND (:estado IS NULL OR cu.estado = :estado) " +
           "ORDER BY c.fechaVencimiento DESC, cu.id ASC")
    List<CuotaUsuario> findReporte(
            @Param("condominioId") Long condominioId,
            @Param("mes") String mes,
            @Param("estado") EstadoPago estado);

    @Query("SELECT cu FROM CuotaUsuario cu " +
           "JOIN cu.cuota c " +
           "WHERE c.condominio.id = :condominioId " +
           "AND cu.estado IN ('PENDIENTE', 'RECHAZADO') " +
           "AND c.fechaVencimiento < :hoy")
    List<CuotaUsuario> findMorosos(
            @Param("condominioId") Long condominioId,
            @Param("hoy") LocalDate hoy);
}
