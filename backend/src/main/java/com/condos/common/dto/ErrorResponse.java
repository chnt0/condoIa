package com.condos.common.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Standardized error response DTO for consistent error formatting across the API.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ErrorResponse {

    private String error;
    private String message;
    private int code;
    private LocalDateTime timestamp;

    /**
     * Constructor that automatically sets timestamp to current time
     * @param error the error type/name
     * @param message the error message
     * @param code the HTTP status code
     */
    public ErrorResponse(String error, String message, int code) {
        this.error = error;
        this.message = message;
        this.code = code;
        this.timestamp = LocalDateTime.now();
    }
}
