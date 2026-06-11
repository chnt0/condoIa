package com.condos.usuario.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ResidenteBasicoResponse {
    private Long id;
    private String nombreCompleto;
    private String unidadHabitacional;
}
