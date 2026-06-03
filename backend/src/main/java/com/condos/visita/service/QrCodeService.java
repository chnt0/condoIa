package com.condos.visita.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Servicio para generación y validación de códigos QR.
 */
@Slf4j
@Service
public class QrCodeService {

    private static final int QR_WIDTH = 300;
    private static final int QR_HEIGHT = 300;
    private static final String QR_PREFIX = "CONDOS-VISIT-";

    /**
     * Genera un hash único para el código QR de una visita.
     * Formato: CONDOS-VISIT-{visitaId}-{condominioId}-{uuid}
     */
    public String generateQrHash(Long visitaId, Long condominioId) {
        String uuid = UUID.randomUUID().toString();
        return String.format("%s%d-%d-%s", QR_PREFIX, visitaId, condominioId, uuid);
    }

    /**
     * Genera una imagen QR en formato Base64.
     */
    public String generateQrCodeImage(String data) {
        try {
            QRCodeWriter qrCodeWriter = new QRCodeWriter();
            Map<EncodeHintType, Object> hints = new HashMap<>();
            hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");

            BitMatrix bitMatrix = qrCodeWriter.encode(
                    data,
                    BarcodeFormat.QR_CODE,
                    QR_WIDTH,
                    QR_HEIGHT,
                    hints
            );

            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(bitMatrix, "PNG", outputStream);
            byte[] imageBytes = outputStream.toByteArray();

            return Base64.getEncoder().encodeToString(imageBytes);

        } catch (WriterException | IOException e) {
            log.error("Error generando código QR: {}", e.getMessage(), e);
            throw new RuntimeException("Error al generar código QR", e);
        }
    }

    /**
     * Valida que el formato del QR sea correcto.
     */
    public boolean validateQrFormat(String qrHash) {
        if (qrHash == null || qrHash.isEmpty()) {
            return false;
        }

        // Debe empezar con el prefijo correcto
        if (!qrHash.startsWith(QR_PREFIX)) {
            return false;
        }

        // Debe tener el formato correcto: PREFIX-{visitaId}-{condominioId}-{uuid}
        // Split with limit of 4 to handle UUID with hyphens: parts[0]=visitaId, parts[1]=condominioId, parts[2...] form the UUID
        String[] parts = qrHash.substring(QR_PREFIX.length()).split("-", 3);
        if (parts.length != 3) {
            return false;
        }

        // Validar que visitaId y condominioId sean números
        try {
            Long.parseLong(parts[0]);
            Long.parseLong(parts[1]);
            UUID.fromString(parts[2]);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    /**
     * Extrae el ID de la visita del hash del QR.
     */
    public Long extractVisitaId(String qrHash) {
        if (!validateQrFormat(qrHash)) {
            throw new IllegalArgumentException("Formato de QR inválido");
        }

        String[] parts = qrHash.substring(QR_PREFIX.length()).split("-", 3);
        return Long.parseLong(parts[0]);
    }

    /**
     * Extrae el ID del condominio del hash del QR.
     */
    public Long extractCondominioId(String qrHash) {
        if (!validateQrFormat(qrHash)) {
            throw new IllegalArgumentException("Formato de QR inválido");
        }

        String[] parts = qrHash.substring(QR_PREFIX.length()).split("-", 3);
        return Long.parseLong(parts[1]);
    }
}
