package com.condos.pago.dto;

import com.condos.pago.model.EstadoPago;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class CuotaUsuarioResponse {
    private Long id;
    private Long cuotaId;
    private String concepto;
    private BigDecimal monto;
    private LocalDate fechaVencimiento;
    private Long usuarioId;
    private String usuarioNombre;
    private String unidadHabitacional;
    private EstadoPago estado;
    private String referenciaPago;
    private String notasUsuario;
    private String notasAdmin;
    private LocalDateTime fechaReporte;
    private LocalDateTime fechaConfirmacion;
}
