package com.condos.incidente.dto;

import com.condos.incidente.model.EstadoIncidente;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateEstadoRequest {

    @NotNull
    private EstadoIncidente estado;
}
