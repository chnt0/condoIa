package com.condos.visita.service;

import com.condos.common.exceptions.ResourceNotFoundException;
import com.condos.common.exceptions.UnauthorizedException;
import com.condos.common.utils.TenantContext;
import com.condos.condominio.model.Condominio;
import com.condos.condominio.repository.CondominioRepository;
import com.condos.usuario.model.Rol;
import com.condos.usuario.model.Usuario;
import com.condos.usuario.repository.UsuarioRepository;
import com.condos.visita.dto.CreateVisitaRequest;
import com.condos.visita.dto.ValidarQrRequest;
import com.condos.visita.dto.ValidarQrResponse;
import com.condos.visita.dto.VisitaResponse;
import com.condos.visita.model.EstadoVisita;
import com.condos.visita.model.Visita;
import com.condos.visita.repository.VisitaRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VisitaServiceTest {

    @Mock
    private VisitaRepository visitaRepository;

    @Mock
    private UsuarioRepository usuarioRepository;

    @Mock
    private CondominioRepository condominioRepository;

    @Mock
    private QrCodeService qrCodeService;

    @InjectMocks
    private VisitaService visitaService;

    private Condominio condominio;
    private Usuario usuario;
    private Usuario guardia;

    @BeforeEach
    void setUp() {
        TenantContext.setCondominioId(1L);

        condominio = Condominio.builder()
                .id(1L)
                .nombre("Test Condo")
                .activo(true)
                .build();

        usuario = Usuario.builder()
                .id(1L)
                .username("user")
                .nombreCompleto("Test User")
                .rol(Rol.USUARIO)
                .condominio(condominio)
                .unidadHabitacional("A-101")
                .build();

        guardia = Usuario.builder()
                .id(2L)
                .username("guard")
                .nombreCompleto("Test Guard")
                .rol(Rol.GUARDIA)
                .condominio(condominio)
                .build();
    }

    @AfterEach
    void tearDown() {
        TenantContext.clear();
    }

    @Test
    void crearVisita_shouldCreateVisitWithQrCode() {
        // Given
        CreateVisitaRequest request = CreateVisitaRequest.builder()
                .nombreVisitante("John Doe")
                .telefonoVisitante("555-1234")
                .fechaHoraProgramada(LocalDateTime.now().plusDays(1))
                .motivo("Social visit")
                .build();

        when(usuarioRepository.findById(1L)).thenReturn(Optional.of(usuario));
        when(condominioRepository.findById(1L)).thenReturn(Optional.of(condominio));
        when(qrCodeService.generateQrHash(any(), eq(1L))).thenReturn("QR-HASH-123");
        when(visitaRepository.save(any(Visita.class))).thenAnswer(i -> {
            Visita v = i.getArgument(0);
            v.setId(100L);
            return v;
        });

        // When
        VisitaResponse response = visitaService.crearVisita(request, 1L);

        // Then
        assertThat(response.getId()).isEqualTo(100L);
        assertThat(response.getNombreVisitante()).isEqualTo("John Doe");
        assertThat(response.getCodigoQrHash()).isEqualTo("QR-HASH-123");
        assertThat(response.getEstado()).isEqualTo(EstadoVisita.PROGRAMADA);
        verify(visitaRepository, times(2)).save(any(Visita.class));
    }

    @Test
    void validarQr_shouldCompleteVisit() {
        // Given
        Visita visita = Visita.builder()
                .id(1L)
                .condominio(condominio)
                .usuario(usuario)
                .nombreVisitante("John Doe")
                .fechaHoraProgramada(LocalDateTime.now().minusHours(1))
                .codigoQrHash("QR-HASH-123")
                .estado(EstadoVisita.PROGRAMADA)
                .build();

        ValidarQrRequest request = ValidarQrRequest.builder()
                .codigoQr("QR-HASH-123")
                .notas("Visitor arrived")
                .build();

        when(qrCodeService.validateQrFormat("QR-HASH-123")).thenReturn(true);
        when(qrCodeService.extractCondominioId("QR-HASH-123")).thenReturn(1L);
        when(visitaRepository.findByCodigoQrHash("QR-HASH-123")).thenReturn(Optional.of(visita));
        when(usuarioRepository.findById(2L)).thenReturn(Optional.of(guardia));
        when(visitaRepository.save(any(Visita.class))).thenAnswer(i -> i.getArgument(0));

        // When
        ValidarQrResponse response = visitaService.validarQr(request, 2L);

        // Then
        assertThat(response.isValido()).isTrue();
        assertThat(response.getMensaje()).contains("válido");
        assertThat(response.getVisita().getEstado()).isEqualTo(EstadoVisita.COMPLETADA);
        verify(visitaRepository).save(argThat(v ->
                v.getEstado() == EstadoVisita.COMPLETADA &&
                v.getFechaHoraEntrada() != null &&
                v.getGuardiaEntrada().getId().equals(2L)
        ));
    }

    @Test
    void validarQr_shouldRejectInvalidFormat() {
        // Given
        ValidarQrRequest request = ValidarQrRequest.builder()
                .codigoQr("INVALID")
                .build();

        when(qrCodeService.validateQrFormat("INVALID")).thenReturn(false);

        // When
        ValidarQrResponse response = visitaService.validarQr(request, 2L);

        // Then
        assertThat(response.isValido()).isFalse();
        assertThat(response.getMensaje()).contains("inválido");
        verify(visitaRepository, never()).save(any());
    }

    @Test
    void validarQr_shouldRejectWrongCondominio() {
        // Given
        ValidarQrRequest request = ValidarQrRequest.builder()
                .codigoQr("QR-HASH-123")
                .build();

        when(qrCodeService.validateQrFormat("QR-HASH-123")).thenReturn(true);
        when(qrCodeService.extractCondominioId("QR-HASH-123")).thenReturn(999L);

        // When
        ValidarQrResponse response = visitaService.validarQr(request, 2L);

        // Then
        assertThat(response.isValido()).isFalse();
        assertThat(response.getMensaje()).contains("condominio");
        verify(visitaRepository, never()).save(any());
    }

    @Test
    void validarQr_shouldRejectAlreadyCompletedVisit() {
        // Given
        Visita visita = Visita.builder()
                .id(1L)
                .condominio(condominio)
                .usuario(usuario)
                .nombreVisitante("John Doe")
                .fechaHoraProgramada(LocalDateTime.now().minusHours(2))
                .codigoQrHash("QR-HASH-123")
                .estado(EstadoVisita.COMPLETADA)
                .fechaHoraEntrada(LocalDateTime.now().minusHours(1))
                .build();

        ValidarQrRequest request = ValidarQrRequest.builder()
                .codigoQr("QR-HASH-123")
                .build();

        when(qrCodeService.validateQrFormat("QR-HASH-123")).thenReturn(true);
        when(qrCodeService.extractCondominioId("QR-HASH-123")).thenReturn(1L);
        when(visitaRepository.findByCodigoQrHash("QR-HASH-123")).thenReturn(Optional.of(visita));

        // When
        ValidarQrResponse response = visitaService.validarQr(request, 2L);

        // Then
        assertThat(response.isValido()).isFalse();
        assertThat(response.getMensaje()).contains("ya fue registrada");
        verify(visitaRepository, never()).save(any());
    }

    @Test
    void cancelarVisita_shouldCancelProgrammedVisit() {
        // Given
        Visita visita = Visita.builder()
                .id(1L)
                .condominio(condominio)
                .usuario(usuario)
                .nombreVisitante("John Doe")
                .fechaHoraProgramada(LocalDateTime.now().plusDays(1))
                .codigoQrHash("QR-HASH-123")
                .estado(EstadoVisita.PROGRAMADA)
                .build();

        when(visitaRepository.findById(1L)).thenReturn(Optional.of(visita));
        when(visitaRepository.save(any(Visita.class))).thenAnswer(i -> i.getArgument(0));

        // When
        VisitaResponse response = visitaService.cancelarVisita(1L, 1L);

        // Then
        assertThat(response.getEstado()).isEqualTo(EstadoVisita.CANCELADA);
        verify(visitaRepository).save(argThat(v -> v.getEstado() == EstadoVisita.CANCELADA));
    }

    @Test
    void cancelarVisita_shouldThrowIfNotOwner() {
        // Given
        Visita visita = Visita.builder()
                .id(1L)
                .condominio(condominio)
                .usuario(usuario)
                .estado(EstadoVisita.PROGRAMADA)
                .build();

        when(visitaRepository.findById(1L)).thenReturn(Optional.of(visita));

        // When/Then
        assertThatThrownBy(() -> visitaService.cancelarVisita(1L, 999L))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("No tienes permiso");
    }
}
