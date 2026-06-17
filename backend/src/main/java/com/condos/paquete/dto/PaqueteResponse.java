package com.condos.paquete.dto;

import com.condos.paquete.model.EstadoPaquete;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class PaqueteResponse {
    private Long id;
    private Long usuarioDestinatarioId;
    private String destinatarioNombre;
    private String destinatarioUnidad;
    private String descripcion;
    private String notas;
    private String foto;
    private LocalDateTime fechaHoraLlegada;
    private Long guardiaRegistroId;
    private String guardiaRegistroNombre;
    private EstadoPaquete estado;
    private LocalDateTime fechaHoraEntrega;
    private Long guardiaEntregaId;
    private String guardiaEntregaNombre;
    private LocalDateTime createdAt;
}
