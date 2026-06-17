package com.condos.visita.model;

import com.condos.condominio.model.Condominio;
import com.condos.usuario.model.Usuario;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.time.LocalDateTime;

/**
 * Entidad que representa una visita programada en un condominio.
 */
@Entity
@Table(name = "visitas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"condominio", "usuario", "guardiaEntrada"})
@EqualsAndHashCode(exclude = {"condominio", "usuario", "guardiaEntrada"})
public class Visita {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id", nullable = false)
    private Condominio condominio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    @Column(name = "nombre_visitante", nullable = false, length = 200)
    private String nombreVisitante;

    @Column(name = "telefono_visitante", length = 20)
    private String telefonoVisitante;

    @Column(name = "fecha_hora_programada", nullable = false)
    private LocalDateTime fechaHoraProgramada;

    @Column(name = "codigo_qr_hash", nullable = false, unique = true, length = 500)
    private String codigoQrHash;

    @Column(name = "motivo", length = 500)
    private String motivo;

    @Column(name = "vehiculo_placas", length = 20)
    private String vehiculoPlacas;

    @Enumerated(EnumType.STRING)
    @Column(name = "estado", nullable = false)
    private EstadoVisita estado;

    @Column(name = "fecha_hora_entrada")
    private LocalDateTime fechaHoraEntrada;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "guardia_entrada_id")
    private Usuario guardiaEntrada;

    @Column(name = "notas", columnDefinition = "TEXT")
    private String notas;

    @Column(name = "foto_vehiculo", columnDefinition = "TEXT")
    private String fotoVehiculo;

    @Column(name = "tipo_visita", length = 20)
    private String tipoVisita = "PROGRAMADA";

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (estado == null) {
            estado = EstadoVisita.PROGRAMADA;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
