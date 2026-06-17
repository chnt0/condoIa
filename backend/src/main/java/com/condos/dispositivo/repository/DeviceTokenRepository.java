package com.condos.dispositivo.repository;

import com.condos.dispositivo.model.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {
    List<DeviceToken> findByUsuarioId(Long usuarioId);
    Optional<DeviceToken> findByUsuarioIdAndPlataforma(Long usuarioId, String plataforma);
}
