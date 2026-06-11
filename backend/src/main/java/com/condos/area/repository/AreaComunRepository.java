package com.condos.area.repository;

import com.condos.area.model.AreaComun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AreaComunRepository extends JpaRepository<AreaComun, Long> {
    List<AreaComun> findByCondominioIdOrderByNombreAsc(Long condominioId);
    List<AreaComun> findByCondominioIdAndActivaOrderByNombreAsc(Long condominioId, boolean activa);
}
