package com.condos.visita.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response de validación de QR.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidarQrResponse {

    private boolean valido;
    private String mensaje;
    private VisitaResponse visita;
}
