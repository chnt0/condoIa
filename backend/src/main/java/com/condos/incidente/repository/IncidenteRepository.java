package com.condos.incidente.repository;

import com.condos.incidente.model.Incidente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IncidenteRepository extends JpaRepository<Incidente, Long> {
    List<Incidente> findByCondominioIdOrderByCreatedAtDesc(Long condominioId);
    List<Incidente> findByUsuarioReportaIdOrderByCreatedAtDesc(Long usuarioId);
}
