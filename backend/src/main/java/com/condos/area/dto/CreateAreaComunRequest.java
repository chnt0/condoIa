package com.condos.area.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreateAreaComunRequest {

    @NotBlank
    private String nombre;

    private String descripcion;

    @NotNull
    @Min(1)
    private Integer capacidad;

    @NotBlank
    private String horarioInicio;

    @NotBlank
    private String horarioFin;

    @NotNull
    @Min(15)
    private Integer duracionBloqueMinutos;

    @NotNull
    @Min(1)
    private Integer maxReservasMesPorUsuario;

    @NotNull
    @Min(0)
    private Integer anticipacionMinimaHoras;

    @NotNull
    @Min(1)
    private Integer anticipacionMaximaDias;

    private boolean activa = true;
}
