package com.condos.notificacion.dto;

import com.condos.notificacion.model.SegmentoNotificacion;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class NotificacionResponse {
    private Long id;
    private String titulo;
    private String mensaje;
    private SegmentoNotificacion segmento;
    private String edificio;
    private Long adminCreadorId;
    private String adminCreadorNombre;
    private LocalDateTime createdAt;
}
