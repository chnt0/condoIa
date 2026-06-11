package com.condos.area.model;

import com.condos.condominio.model.Condominio;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "areas_comunes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = "condominio")
@EqualsAndHashCode(exclude = "condominio")
public class AreaComun {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "condominio_id", nullable = false)
    private Condominio condominio;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(nullable = false)
    private int capacidad;

    @Column(name = "horario_inicio", nullable = false)
    private LocalTime horarioInicio;

    @Column(name = "horario_fin", nullable = false)
    private LocalTime horarioFin;

    @Column(name = "duracion_bloque_minutos", nullable = false)
    private int duracionBloqueMinutos;

    @Column(name = "max_reservas_mes_por_usuario", nullable = false)
    private int maxReservasMesPorUsuario;

    @Column(name = "anticipacion_minima_horas", nullable = false)
    private int anticipacionMinimaHoras;

    @Column(name = "anticipacion_maxima_dias", nullable = false)
    private int anticipacionMaximaDias;

    @Column(nullable = false)
    private boolean activa = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
