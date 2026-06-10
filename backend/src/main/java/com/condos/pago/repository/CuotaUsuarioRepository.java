package com.condos.pago.repository;

import com.condos.pago.model.CuotaUsuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CuotaUsuarioRepository extends JpaRepository<CuotaUsuario, Long> {
    List<CuotaUsuario> findByCuotaId(Long cuotaId);
    List<CuotaUsuario> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);
}
