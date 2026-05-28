package com.condos.common.exceptions;

/**
 * Exception thrown when a multi-tenant isolation violation is detected.
 * Results in HTTP 403 Forbidden response.
 */
public class TenantMismatchException extends RuntimeException {

    public TenantMismatchException(String message) {
        super(message);
    }

    public TenantMismatchException(String message, Throwable cause) {
        super(message, cause);
    }
}
