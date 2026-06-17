package com.condos.incidente.dto;

import com.condos.incidente.model.EstadoIncidente;
import com.condos.incidente.model.PrioridadIncidente;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class IncidenteResponse {
    private Long id;
    private String categoria;
    private String titulo;
    private String descripcion;
    private String ubicacion;
    private PrioridadIncidente prioridad;
    private EstadoIncidente estado;
    private Long usuarioReportaId;
    private String usuarioReportaNombre;
    private String usuarioReportaUnidad;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
