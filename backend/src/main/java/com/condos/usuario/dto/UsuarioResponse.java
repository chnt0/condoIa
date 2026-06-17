package com.condos.usuario.dto;

import com.condos.usuario.model.Rol;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UsuarioResponse {

    private Long id;
    private String username;
    private String email;
    private String nombreCompleto;
    private String telefono;
    private String telefono2;
    private Rol rol;
    private Long condominioId;
    private String condominioNombre;
    private String unidadHabitacional;
    private Boolean esPropietario;
    private Boolean activo;
    private LocalDateTime createdAt;
}
