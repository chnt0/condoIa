package com.condos.pago.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ReportarPagoRequest {

    @NotBlank
    private String referenciaPago;

    private String notasUsuario;
}
