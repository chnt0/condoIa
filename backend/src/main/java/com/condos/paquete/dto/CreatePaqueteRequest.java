package com.condos.paquete.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreatePaqueteRequest {

    @NotNull
    private Long usuarioDestinatarioId;

    @NotBlank
    private String descripcion;

    private String notas;

    private String foto;
}
