package com.condos.usuario.dto;

import com.condos.usuario.model.Rol;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateUsuarioRequest {

    @NotBlank(message = "El nombre completo es requerido")
    private String nombreCompleto;

    private String telefono;
    private String telefono2;

    @NotNull(message = "El rol es requerido")
    private Rol rol;

    private String unidadHabitacional;

    @NotNull(message = "esPropietario es requerido")
    private Boolean esPropietario;
}
