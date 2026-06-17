package com.condos.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

@Slf4j
@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initializeFirebase() {
        String serviceAccountJson = System.getenv("FIREBASE_SERVICE_ACCOUNT_JSON");
        if (serviceAccountJson == null || serviceAccountJson.isBlank()) {
            log.warn("FIREBASE_SERVICE_ACCOUNT_JSON no configurado — push notifications desactivadas");
            return;
        }
        try {
            if (!FirebaseApp.getApps().isEmpty()) return;

            GoogleCredentials credentials = GoogleCredentials.fromStream(
                    new ByteArrayInputStream(serviceAccountJson.getBytes(StandardCharsets.UTF_8))
            );
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .build();
            FirebaseApp.initializeApp(options);
            log.info("Firebase Admin SDK inicializado correctamente");
        } catch (Exception e) {
            log.error("Error al inicializar Firebase: {}", e.getMessage());
        }
    }
}
