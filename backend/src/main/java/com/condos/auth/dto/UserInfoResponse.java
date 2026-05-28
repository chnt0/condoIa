package com.condos.auth.dto;

import com.condos.usuario.model.Rol;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserInfoResponse {

    private Long id;
    private String username;
    private String email;
    private String nombreCompleto;
    private Rol rol;
    private Long condominioId;
    private String condominioNombre;
    private String unidadHabitacional;
}
