package com.condos.pago.dto;

import com.condos.pago.model.TipoCuota;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
public class CreateCuotaRequest {

    @NotNull
    private TipoCuota tipo;

    @NotBlank
    private String concepto;

    @NotNull
    @DecimalMin("0.01")
    private BigDecimal monto;

    private String mes;

    @NotNull
    private LocalDate fechaVencimiento;

    private List<Long> usuarioIds;
}
