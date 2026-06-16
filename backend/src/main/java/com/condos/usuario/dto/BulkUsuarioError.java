package com.condos.usuario.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class BulkUsuarioError {
    private int fila;
    private String email;
    private String motivo;
}
