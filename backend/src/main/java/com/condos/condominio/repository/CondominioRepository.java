package com.condos.condominio.repository;

import com.condos.condominio.model.Condominio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CondominioRepository extends JpaRepository<Condominio, Long> {

    List<Condominio> findByActivoTrue();
    List<Condominio> findAllByOrderByNombreAsc();
}
