package com.condos.visita.dto;

import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Request para crear una nueva visita.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateVisitaRequest {

    @NotBlank(message = "El nombre del visitante es requerido")
    @Size(max = 200, message = "El nombre no puede exceder 200 caracteres")
    private String nombreVisitante;

    @Size(max = 20, message = "El teléfono no puede exceder 20 caracteres")
    private String telefonoVisitante;

    @NotNull(message = "La fecha y hora programada es requerida")
    @FutureOrPresent(message = "La fecha debe ser presente o futura")
    private LocalDateTime fechaHoraProgramada;

    @Size(max = 500, message = "El motivo no puede exceder 500 caracteres")
    private String motivo;

    @Size(max = 20, message = "Las placas no pueden exceder 20 caracteres")
    private String vehiculoPlacas;
}
