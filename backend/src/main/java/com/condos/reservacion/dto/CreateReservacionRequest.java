package com.condos.reservacion.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class CreateReservacionRequest {

    @NotNull
    private Long areaComunId;

    @NotNull
    private LocalDateTime fechaHoraInicio;
}
