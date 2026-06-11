package com.condos.paquete.model;

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

@Entity
@Table(name = "paquetes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"condominio", "destinatario", "guardiaRegistro", "guardiaEntrega"})
@EqualsAndHashCode(exclude = {"condominio", "destinatario", "guardiaRegistro", "guardiaEntrega"})
public class Paquete {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id", nullable = false)
    private Condominio condominio;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_destinatario_id", nullable = false)
    private Usuario destinatario;

    @Column(nullable = false, length = 500)
    private String descripcion;

    @Column(columnDefinition = "TEXT")
    private String notas;

    @Column(name = "fecha_hora_llegada", nullable = false)
    private LocalDateTime fechaHoraLlegada;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "guardia_registro_id", nullable = false)
    private Usuario guardiaRegistro;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoPaquete estado;

    @Column(name = "fecha_hora_entrega")
    private LocalDateTime fechaHoraEntrega;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "guardia_entrega_id")
    private Usuario guardiaEntrega;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (estado == null) estado = EstadoPaquete.PENDIENTE;
        if (fechaHoraLlegada == null) fechaHoraLlegada = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
