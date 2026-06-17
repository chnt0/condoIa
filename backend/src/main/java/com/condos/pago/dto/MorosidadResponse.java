package com.condos.pago.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
public class MorosidadResponse {
    private BigDecimal totalMonto;
    private int totalMorosos;
    private int cuotasVencidas;
}
