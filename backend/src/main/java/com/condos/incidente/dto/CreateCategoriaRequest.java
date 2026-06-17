package com.condos.incidente.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreateCategoriaRequest {

    @NotBlank
    private String nombre;
}
