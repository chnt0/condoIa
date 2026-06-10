package com.condos.pago.dto;

import lombok.Data;

@Data
public class ConfirmarPagoRequest {
    private boolean confirmado;
    private String notasAdmin;
}
