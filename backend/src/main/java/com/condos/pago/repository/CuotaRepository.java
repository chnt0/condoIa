package com.condos.pago.repository;

import com.condos.pago.model.Cuota;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CuotaRepository extends JpaRepository<Cuota, Long> {
    List<Cuota> findByCondominioIdOrderByCreatedAtDesc(Long condominioId);
}
