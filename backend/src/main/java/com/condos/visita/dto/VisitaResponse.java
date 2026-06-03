package com.condos.visita.dto;

import com.condos.visita.model.EstadoVisita;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response con información de una visita.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VisitaResponse {

    private Long id;
    private String nombreVisitante;
    private String telefonoVisitante;
    private LocalDateTime fechaHoraProgramada;
    private String codigoQrHash;
    private String motivo;
    private String vehiculoPlacas;
    private EstadoVisita estado;
    private LocalDateTime fechaHoraEntrada;
    private String notas;
    private LocalDateTime createdAt;

    // Usuario que programó
    private Long usuarioId;
    private String usuarioNombre;
    private String unidadHabitacional;

    // Guardia que registró entrada (si aplica)
    private Long guardiaEntradaId;
    private String guardiaEntradaNombre;
}
