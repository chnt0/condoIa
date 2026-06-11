package com.condos.notificacion.dto;

import com.condos.notificacion.model.SegmentoNotificacion;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateNotificacionRequest {

    @NotBlank
    private String titulo;

    @NotBlank
    private String mensaje;

    @NotNull
    private SegmentoNotificacion segmento;

    private String edificio;
}
