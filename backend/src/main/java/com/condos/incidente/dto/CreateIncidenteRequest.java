package com.condos.incidente.dto;

import com.condos.incidente.model.PrioridadIncidente;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateIncidenteRequest {

    @NotBlank
    private String categoria;

    @NotBlank
    private String titulo;

    @NotBlank
    private String descripcion;

    @NotBlank
    private String ubicacion;

    @NotNull
    private PrioridadIncidente prioridad;
}
