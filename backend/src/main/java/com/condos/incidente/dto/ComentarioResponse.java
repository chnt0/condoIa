package com.condos.incidente.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ComentarioResponse {
    private Long id;
    private Long incidenteId;
    private Long usuarioId;
    private String usuarioNombre;
    private String comentario;
    private LocalDateTime createdAt;
}
