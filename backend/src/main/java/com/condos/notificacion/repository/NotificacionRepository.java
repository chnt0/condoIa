package com.condos.notificacion.repository;

import com.condos.notificacion.model.Notificacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificacionRepository extends JpaRepository<Notificacion, Long> {
    List<Notificacion> findByCondominioIdOrderByCreatedAtDesc(Long condominioId);
}
