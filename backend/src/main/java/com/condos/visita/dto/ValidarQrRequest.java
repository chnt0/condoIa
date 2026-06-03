package com.condos.visita.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Request para validar un código QR.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ValidarQrRequest {

    @NotBlank(message = "El código QR es requerido")
    private String codigoQr;

    private String notas;
}
