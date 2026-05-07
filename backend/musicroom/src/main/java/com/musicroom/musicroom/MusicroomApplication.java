package com.musicroom.musicroom;

import com.musicroom.musicroom.config.DotEnvConfig;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class MusicroomApplication {

    public static void main(String[] args) {
        DotEnvConfig.loadEnvVariables();
        
        SpringApplication.run(MusicroomApplication.class, args);
    }
}