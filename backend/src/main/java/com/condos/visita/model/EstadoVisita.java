package com.condos.visita.model;

/**
 * Estados posibles de una visita.
 */
public enum EstadoVisita {
    PROGRAMADA,   // Visita creada, esperando llegada
    COMPLETADA,   // Guardia registró entrada
    CANCELADA     // Usuario o admin canceló
}
