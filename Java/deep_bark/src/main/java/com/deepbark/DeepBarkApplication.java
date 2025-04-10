package com.deepbark;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class DeepBarkApplication {
    public static void main(String[] args) {
        SpringApplication.run(DeepBarkApplication.class, args);
    }
} 