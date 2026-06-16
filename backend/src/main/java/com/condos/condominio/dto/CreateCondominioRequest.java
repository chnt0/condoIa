package com.condos.condominio.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateCondominioRequest {

    @NotBlank
    private String nombre;

    @NotBlank
    private String direccion;

    @NotNull
    @Min(1)
    private Integer numUnidades;

    private boolean activo = true;
}
