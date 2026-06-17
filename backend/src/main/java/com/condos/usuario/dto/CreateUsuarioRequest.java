package com.condos.usuario.dto;

import com.condos.usuario.model.Rol;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateUsuarioRequest {

    @NotBlank(message = "El username es requerido")
    @Size(min = 3, max = 50, message = "El username debe tener entre 3 y 50 caracteres")
    private String username;

    @NotBlank(message = "El email es requerido")
    @Email(message = "El email no es válido")
    private String email;

    @NotBlank(message = "La contraseña es requerida")
    @Size(min = 6, message = "La contraseña debe tener al menos 6 caracteres")
    private String password;

    @NotBlank(message = "El nombre completo es requerido")
    private String nombreCompleto;

    private String telefono;
    private String telefono2;

    @NotNull(message = "El rol es requerido")
    private Rol rol;

    private String unidadHabitacional;

    private Boolean esPropietario = false;

    private Long condominioId; // Requerido solo cuando SUPERADMIN crea usuarios
}
