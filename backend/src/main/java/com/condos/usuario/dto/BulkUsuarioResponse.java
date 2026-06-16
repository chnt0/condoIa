package com.condos.usuario.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class BulkUsuarioResponse {
    private int creados;
    private List<BulkUsuarioError> errores;
}
