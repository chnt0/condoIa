package com.condos.reservacion.dto;

import com.condos.reservacion.model.EstadoReservacion;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ReservacionResponse {
    private Long id;
    private Long areaComunId;
    private String areaComunNombre;
    private Long usuarioId;
    private String usuarioNombre;
    private LocalDateTime fechaHoraInicio;
    private LocalDateTime fechaHoraFin;
    private EstadoReservacion estado;
    private LocalDateTime createdAt;
}
