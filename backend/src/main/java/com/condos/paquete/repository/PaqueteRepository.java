package com.condos.paquete.repository;

import com.condos.paquete.model.Paquete;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PaqueteRepository extends JpaRepository<Paquete, Long> {
    List<Paquete> findByCondominioIdOrderByFechaHoraLlegadaDesc(Long condominioId);
    List<Paquete> findByDestinatarioIdOrderByFechaHoraLlegadaDesc(Long usuarioId);
}
