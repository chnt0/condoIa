package com.condos.area.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class BloqueDisponibilidadResponse {
    private LocalDateTime fechaHoraInicio;
    private LocalDateTime fechaHoraFin;
    private boolean disponible;
}
