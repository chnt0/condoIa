package com.condos.incidente.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CategoriaIncidenteResponse {
    private Long id;
    private String nombre;
    private boolean activa;
}
