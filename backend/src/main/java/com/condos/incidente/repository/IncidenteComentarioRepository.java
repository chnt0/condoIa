package com.condos.incidente.repository;

import com.condos.incidente.model.IncidenteComentario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IncidenteComentarioRepository extends JpaRepository<IncidenteComentario, Long> {
    List<IncidenteComentario> findByIncidenteIdOrderByCreatedAtAsc(Long incidenteId);
}
