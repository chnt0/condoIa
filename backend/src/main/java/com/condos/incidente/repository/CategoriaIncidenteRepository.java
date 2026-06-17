package com.condos.incidente.repository;

import com.condos.incidente.model.CategoriaIncidenteEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoriaIncidenteRepository extends JpaRepository<CategoriaIncidenteEntity, Long> {
    List<CategoriaIncidenteEntity> findByCondominioIdOrderByNombreAsc(Long condominioId);
    List<CategoriaIncidenteEntity> findByCondominioIdAndActivaOrderByNombreAsc(Long condominioId, boolean activa);
    boolean existsByCondominioIdAndNombre(Long condominioId, String nombre);
}
