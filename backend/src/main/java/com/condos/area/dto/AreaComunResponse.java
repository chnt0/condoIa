package com.condos.area.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AreaComunResponse {
    private Long id;
    private String nombre;
    private String descripcion;
    private int capacidad;
    private String horarioInicio;
    private String horarioFin;
    private int duracionBloqueMinutos;
    private int maxReservasMesPorUsuario;
    private int anticipacionMinimaHoras;
    private int anticipacionMaximaDias;
    private boolean activa;
    private LocalDateTime createdAt;
}
