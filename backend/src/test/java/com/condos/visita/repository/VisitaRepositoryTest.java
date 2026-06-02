package com.condos.visita.repository;

import com.condos.condominio.model.Condominio;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.visita.model.EstadoVisita;
import com.condos.visita.model.Visita;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Test for VisitaRepository query methods.
 * Uses @DataJpaTest for repository layer testing.
 */
@DataJpaTest
class VisitaRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private VisitaRepository visitaRepository;

    private Condominio condominio1;
    private Condominio condominio2;
    private Usuario usuario1;
    private Usuario usuario2;

    @BeforeEach
    void setUp() {
        // Create test condominios
        condominio1 = new Condominio();
        condominio1.setNombre("Torre Central");
        condominio1.setDireccion("Calle 1");
        condominio1.setActivo(true);
        condominio1.setCreatedAt(LocalDateTime.now());
        condominio1.setUpdatedAt(LocalDateTime.now());
        entityManager.persist(condominio1);

        condominio2 = new Condominio();
        condominio2.setNombre("Torre Norte");
        condominio2.setDireccion("Calle 2");
        condominio2.setActivo(true);
        condominio2.setCreatedAt(LocalDateTime.now());
        condominio2.setUpdatedAt(LocalDateTime.now());
        entityManager.persist(condominio2);

        // Create test usuarios
        usuario1 = new Usuario();
        usuario1.setUsername("user1");
        usuario1.setEmail("user1@test.com");
        usuario1.setPasswordHash("hash1");
        usuario1.setNombreCompleto("Usuario Uno");
        usuario1.setRol(Rol.USUARIO);
        usuario1.setCondominio(condominio1);
        usuario1.setUnidadHabitacional("101");
        usuario1.setActivo(true);
        usuario1.setCreatedAt(LocalDateTime.now());
        usuario1.setUpdatedAt(LocalDateTime.now());
        entityManager.persist(usuario1);

        usuario2 = new Usuario();
        usuario2.setUsername("user2");
        usuario2.setEmail("user2@test.com");
        usuario2.setPasswordHash("hash2");
        usuario2.setNombreCompleto("Usuario Dos");
        usuario2.setRol(Rol.USUARIO);
        usuario2.setCondominio(condominio2);
        usuario2.setUnidadHabitacional("201");
        usuario2.setActivo(true);
        usuario2.setCreatedAt(LocalDateTime.now());
        usuario2.setUpdatedAt(LocalDateTime.now());
        entityManager.persist(usuario2);

        entityManager.flush();
    }

    @Test
    @DisplayName("Should find visits by condominio ID")
    void findByCondominioId_shouldReturnVisitsForCondominio() {
        // Given
        Visita visita1 = createVisita(condominio1, usuario1, "Juan Perez", "hash1", EstadoVisita.PROGRAMADA);
        Visita visita2 = createVisita(condominio1, usuario1, "Maria Lopez", "hash2", EstadoVisita.COMPLETADA);
        Visita visita3 = createVisita(condominio2, usuario2, "Carlos Ruiz", "hash3", EstadoVisita.PROGRAMADA);

        entityManager.persist(visita1);
        entityManager.persist(visita2);
        entityManager.persist(visita3);
        entityManager.flush();

        // When
        List<Visita> result = visitaRepository.findByCondominioId(condominio1.getId());

        // Then
        assertThat(result).hasSize(2);
        assertThat(result).extracting(Visita::getNombreVisitante)
                .containsExactlyInAnyOrder("Juan Perez", "Maria Lopez");
    }

    @Test
    @DisplayName("Should find visit by QR code hash")
    void findByCodigoQrHash_shouldReturnVisit() {
        // Given
        String qrHash = "unique-qr-hash-123";
        Visita visita = createVisita(condominio1, usuario1, "Pedro Gomez", qrHash, EstadoVisita.PROGRAMADA);
        entityManager.persist(visita);
        entityManager.flush();

        // When
        Optional<Visita> result = visitaRepository.findByCodigoQrHash(qrHash);

        // Then
        assertThat(result).isPresent();
        assertThat(result.get().getNombreVisitante()).isEqualTo("Pedro Gomez");
        assertThat(result.get().getCodigoQrHash()).isEqualTo(qrHash);
    }

    @Test
    @DisplayName("Should find visits by usuario ID and estado")
    void findByUsuarioIdAndEstado_shouldReturnFilteredVisits() {
        // Given
        Visita visita1 = createVisita(condominio1, usuario1, "Ana Torres", "hash-a1", EstadoVisita.PROGRAMADA);
        Visita visita2 = createVisita(condominio1, usuario1, "Luis Mora", "hash-a2", EstadoVisita.COMPLETADA);
        Visita visita3 = createVisita(condominio1, usuario1, "Sofia Castro", "hash-a3", EstadoVisita.PROGRAMADA);
        Visita visita4 = createVisita(condominio2, usuario2, "Diego Vega", "hash-b1", EstadoVisita.PROGRAMADA);

        entityManager.persist(visita1);
        entityManager.persist(visita2);
        entityManager.persist(visita3);
        entityManager.persist(visita4);
        entityManager.flush();

        // When
        List<Visita> result = visitaRepository.findByUsuarioIdAndEstado(usuario1.getId(), EstadoVisita.PROGRAMADA);

        // Then
        assertThat(result).hasSize(2);
        assertThat(result).extracting(Visita::getNombreVisitante)
                .containsExactlyInAnyOrder("Ana Torres", "Sofia Castro");
    }

    @Test
    @DisplayName("Should find visits by condominio ID and estado")
    void findByCondominioIdAndEstado_shouldReturnFilteredVisits() {
        // Given
        Visita visita1 = createVisita(condominio1, usuario1, "Roberto Silva", "hash-r1", EstadoVisita.PROGRAMADA);
        Visita visita2 = createVisita(condominio1, usuario1, "Elena Diaz", "hash-r2", EstadoVisita.COMPLETADA);
        Visita visita3 = createVisita(condominio1, usuario1, "Fernando Rojas", "hash-r3", EstadoVisita.PROGRAMADA);
        Visita visita4 = createVisita(condominio2, usuario2, "Patricia Luna", "hash-r4", EstadoVisita.PROGRAMADA);

        entityManager.persist(visita1);
        entityManager.persist(visita2);
        entityManager.persist(visita3);
        entityManager.persist(visita4);
        entityManager.flush();

        // When
        List<Visita> result = visitaRepository.findByCondominioIdAndEstado(condominio1.getId(), EstadoVisita.PROGRAMADA);

        // Then
        assertThat(result).hasSize(2);
        assertThat(result).extracting(Visita::getNombreVisitante)
                .containsExactlyInAnyOrder("Roberto Silva", "Fernando Rojas");
    }

    @Test
    @DisplayName("Should find programmed visits by condominio and date range")
    void findProgramadasByCondominioAndFecha_shouldReturnVisitsInDateRange() {
        // Given
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime tomorrow = now.plusDays(1);
        LocalDateTime dayAfterTomorrow = now.plusDays(2);
        LocalDateTime threeDaysLater = now.plusDays(3);

        Visita visita1 = createVisitaWithDate(condominio1, usuario1, "Visitor A", "hash-d1",
                EstadoVisita.PROGRAMADA, tomorrow.withHour(10).withMinute(0));
        Visita visita2 = createVisitaWithDate(condominio1, usuario1, "Visitor B", "hash-d2",
                EstadoVisita.PROGRAMADA, dayAfterTomorrow.withHour(14).withMinute(30));
        Visita visita3 = createVisitaWithDate(condominio1, usuario1, "Visitor C", "hash-d3",
                EstadoVisita.COMPLETADA, dayAfterTomorrow.withHour(16).withMinute(0));
        Visita visita4 = createVisitaWithDate(condominio1, usuario1, "Visitor D", "hash-d4",
                EstadoVisita.PROGRAMADA, threeDaysLater.withHour(9).withMinute(0));
        Visita visita5 = createVisitaWithDate(condominio2, usuario2, "Visitor E", "hash-d5",
                EstadoVisita.PROGRAMADA, dayAfterTomorrow.withHour(11).withMinute(0));

        entityManager.persist(visita1);
        entityManager.persist(visita2);
        entityManager.persist(visita3);
        entityManager.persist(visita4);
        entityManager.persist(visita5);
        entityManager.flush();

        // When - Query for visits in condominio1 from tomorrow start to day after tomorrow end
        LocalDateTime inicio = tomorrow.withHour(0).withMinute(0).withSecond(0);
        LocalDateTime fin = dayAfterTomorrow.withHour(23).withMinute(59).withSecond(59);
        List<Visita> result = visitaRepository.findProgramadasByCondominioAndFecha(condominio1.getId(), inicio, fin);

        // Then - Should return only PROGRAMADA visits in the date range for condominio1
        assertThat(result).hasSize(2);
        assertThat(result).extracting(Visita::getNombreVisitante)
                .containsExactly("Visitor A", "Visitor B"); // Ordered by fechaHoraProgramada ASC
        assertThat(result).allMatch(v -> v.getEstado() == EstadoVisita.PROGRAMADA);
        assertThat(result).allMatch(v -> v.getCondominio().getId().equals(condominio1.getId()));
    }

    // Helper method to create Visita instances
    private Visita createVisita(Condominio condo, Usuario user, String nombreVisitante,
                                 String qrHash, EstadoVisita estado) {
        Visita visita = new Visita();
        visita.setCondominio(condo);
        visita.setUsuario(user);
        visita.setNombreVisitante(nombreVisitante);
        visita.setTelefonoVisitante("5551234567");
        visita.setFechaHoraProgramada(LocalDateTime.now().plusDays(1));
        visita.setCodigoQrHash(qrHash);
        visita.setMotivo("Visita personal");
        visita.setEstado(estado);
        return visita;
    }

    // Helper method to create Visita instances with specific date/time
    private Visita createVisitaWithDate(Condominio condo, Usuario user, String nombreVisitante,
                                         String qrHash, EstadoVisita estado, LocalDateTime fechaHora) {
        Visita visita = new Visita();
        visita.setCondominio(condo);
        visita.setUsuario(user);
        visita.setNombreVisitante(nombreVisitante);
        visita.setTelefonoVisitante("5551234567");
        visita.setFechaHoraProgramada(fechaHora);
        visita.setCodigoQrHash(qrHash);
        visita.setMotivo("Visita personal");
        visita.setEstado(estado);
        return visita;
    }
}
