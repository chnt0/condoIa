package com.condos;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class CondosApplication {

    public static void main(String[] args) {
        SpringApplication.run(CondosApplication.class, args);
    }

}
