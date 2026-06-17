package com.condos.dispositivo.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterTokenRequest {

    @NotBlank
    private String token;

    @NotBlank
    private String plataforma; // ANDROID, IOS, WEB
}
