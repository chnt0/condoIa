package com.condos.common.utils;

/**
 * ThreadLocal utility for storing and retrieving the current condominio ID
 * for multi-tenant request isolation.
 */
public class TenantContext {

    private static final ThreadLocal<Long> currentCondominioId = new ThreadLocal<>();

    /**
     * Set the current condominio ID for this thread
     * @param condominioId the condominio ID to set
     */
    public static void setCondominioId(Long condominioId) {
        currentCondominioId.set(condominioId);
    }

    /**
     * Get the current condominio ID for this thread
     * @return the current condominio ID, or null if not set
     */
    public static Long getCondominioId() {
        return currentCondominioId.get();
    }

    /**
     * Clear the current condominio ID for this thread
     * Should be called after request processing to prevent memory leaks
     */
    public static void clear() {
        currentCondominioId.remove();
    }
}
