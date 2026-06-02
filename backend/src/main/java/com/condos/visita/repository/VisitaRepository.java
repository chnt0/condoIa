package com.condos.visita.repository;

import com.condos.visita.model.EstadoVisita;
import com.condos.visita.model.Visita;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for managing Visita entities.
 * Provides query methods for common visit lookup scenarios.
 */
@Repository
public interface VisitaRepository extends JpaRepository<Visita, Long> {

    /**
     * Find all visits for a specific condominio.
     *
     * @param condominioId the condominio ID
     * @return list of visits for the condominio
     */
    List<Visita> findByCondominioId(Long condominioId);

    /**
     * Find a visit by its unique QR code hash.
     *
     * @param codigoQrHash the QR code hash
     * @return Optional containing the visit if found
     */
    Optional<Visita> findByCodigoQrHash(String codigoQrHash);

    /**
     * Find all visits for a specific user filtered by estado.
     *
     * @param usuarioId the usuario ID
     * @param estado the visit estado
     * @return list of visits matching the criteria
     */
    List<Visita> findByUsuarioIdAndEstado(Long usuarioId, EstadoVisita estado);

    /**
     * Find all visits for a condominio filtered by estado.
     *
     * @param condominioId the condominio ID
     * @param estado the visit estado
     * @return list of visits matching the criteria
     */
    List<Visita> findByCondominioIdAndEstado(Long condominioId, EstadoVisita estado);

    /**
     * Find all programmed visits for a condominio within a date range.
     * Uses a custom query to filter by date/time range and estado.
     *
     * @param condominioId the condominio ID
     * @param inicio start of date range
     * @param fin end of date range
     * @return list of visits programmed within the date range, ordered by scheduled time
     */
    @Query("SELECT v FROM Visita v WHERE v.condominio.id = :condominioId " +
           "AND v.fechaHoraProgramada BETWEEN :inicio AND :fin " +
           "AND v.estado = com.condos.visita.model.EstadoVisita.PROGRAMADA " +
           "ORDER BY v.fechaHoraProgramada ASC")
    List<Visita> findProgramadasByCondominioAndFecha(
            @Param("condominioId") Long condominioId,
            @Param("inicio") LocalDateTime inicio,
            @Param("fin") LocalDateTime fin
    );
}
