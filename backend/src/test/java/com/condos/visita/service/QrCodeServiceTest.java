package com.condos.visita.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class QrCodeServiceTest {

    @Autowired
    private QrCodeService qrCodeService;

    @Test
    void generateQrHash_shouldGenerateUniqueHash() {
        // When
        String hash1 = qrCodeService.generateQrHash(1L, 100L);
        String hash2 = qrCodeService.generateQrHash(1L, 100L);

        // Then
        assertThat(hash1).isNotNull();
        assertThat(hash2).isNotNull();
        assertThat(hash1).isNotEqualTo(hash2); // UUIDs should be unique
    }

    @Test
    void generateQrHash_shouldIncludeVisitaId() {
        // Given
        Long visitaId = 42L;

        // When
        String hash = qrCodeService.generateQrHash(visitaId, 1L);

        // Then
        assertThat(hash).contains(visitaId.toString());
    }

    @Test
    void generateQrCodeImage_shouldReturnBase64String() {
        // Given
        String data = "TEST-QR-DATA-123";

        // When
        String base64 = qrCodeService.generateQrCodeImage(data);

        // Then
        assertThat(base64).isNotNull();
        assertThat(base64).isNotEmpty();
        assertThat(base64.length()).isGreaterThan(100); // Base64 image is large
    }

    @Test
    void validateQrFormat_shouldReturnTrueForValidFormat() {
        // Given
        String validHash = qrCodeService.generateQrHash(1L, 100L);

        // When
        boolean valid = qrCodeService.validateQrFormat(validHash);

        // Then
        assertThat(valid).isTrue();
    }

    @Test
    void validateQrFormat_shouldReturnFalseForInvalidFormat() {
        // When
        boolean valid = qrCodeService.validateQrFormat("invalid-format");

        // Then
        assertThat(valid).isFalse();
    }
}
