package com.condos.visita.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateVisitaDirectaRequest {

    @NotBlank
    private String nombreVisitante;

    private String telefonoVisitante;

    @NotBlank
    private String motivo;

    private String vehiculoPlacas;

    private String fotoVehiculo;

    @NotNull
    private Long usuarioDestinatarioId;
}
