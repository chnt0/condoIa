package com.condos.pago.dto;

import com.condos.pago.model.TipoCuota;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
public class CuotaResponse {
    private Long id;
    private TipoCuota tipo;
    private String concepto;
    private BigDecimal monto;
    private String mes;
    private LocalDate fechaVencimiento;
    private int totalResidentes;
    private int totalConfirmados;
    private int totalReportados;
    private int totalPendientes;
    private LocalDateTime createdAt;
}
