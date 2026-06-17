package com.condos.notificacion.service;

import com.condos.dispositivo.repository.DeviceTokenRepository;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificacionPushService {

    private final DeviceTokenRepository deviceTokenRepository;

    @Async
    public void notificarPaquete(Long usuarioId, String descripcion) {
        enviar(
                usuarioId,
                "📦 Tienes un paquete",
                "Llegó un paquete para ti en portería. Pasa a recogerlo."
        );
    }

    @Async
    public void notificarVisitaDirecta(Long usuarioId, String nombreVisitante, String motivo) {
        enviar(
                usuarioId,
                "🔔 Tienes una visita",
                "Visitante: " + nombreVisitante + ". Motivo: " + motivo
        );
    }

    private void enviar(Long usuarioId, String titulo, String cuerpo) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.debug("Firebase no inicializado — omitiendo push para usuario {}", usuarioId);
            return;
        }
        deviceTokenRepository.findByUsuarioId(usuarioId).forEach(dt -> {
            try {
                Message message = Message.builder()
                        .setNotification(Notification.builder()
                                .setTitle(titulo)
                                .setBody(cuerpo)
                                .build())
                        .setToken(dt.getToken())
                        .build();
                String response = FirebaseMessaging.getInstance().send(message);
                log.info("Push enviado a usuario={}: {}", usuarioId, response);
            } catch (Exception e) {
                log.warn("Error enviando push a usuario={}: {}", usuarioId, e.getMessage());
            }
        });
    }
}
