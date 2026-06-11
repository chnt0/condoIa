package com.condos.incidente.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AddComentarioRequest {

    @NotBlank
    private String comentario;
}
