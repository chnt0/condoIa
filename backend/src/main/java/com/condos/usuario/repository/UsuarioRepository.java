package com.condos.usuario.repository;

import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByUsername(String username);

    Optional<Usuario> findByEmail(String email);

    List<Usuario> findByCondominioId(Long condominioId);

    List<Usuario> findByCondominioIdAndRolAndActivo(Long condominioId, Rol rol, Boolean activo);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);
}
