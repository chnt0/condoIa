package com.condos.condominio.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class CondominioResponse {
    private Long id;
    private String nombre;
    private String direccion;
    private int numUnidades;
    private boolean activo;
    private int totalUsuarios;
    private int totalAdmins;
    private LocalDateTime createdAt;
}
