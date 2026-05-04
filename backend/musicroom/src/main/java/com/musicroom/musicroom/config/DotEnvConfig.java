package com.musicroom.musicroom.config;

import io.github.cdimascio.dotenv.Dotenv;
import io.github.cdimascio.dotenv.DotenvException;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;
import java.io.File;

@Configuration
public class DotEnvConfig {

    // Static initializer - runs BEFORE Spring context loads
    static {
        loadEnvVariables();
    }

    public static void loadEnvVariables() {
        try {
            //  Check if .env file exists
            File envFile = new File(".env");
            if (!envFile.exists()) {
                System.out.println("⚠️ .env file not found at: " + envFile.getAbsolutePath());
                System.out.println("⚠️ Using environment variables or application.properties instead");
                return;
            }
            
            System.out.println("✅ Found .env file at: " + envFile.getAbsolutePath());
            
            Dotenv dotenv = Dotenv.load();
            
            //  Set all environment variables from .env into System properties
            dotenv.entries().forEach(entry -> {
                System.setProperty(entry.getKey(), entry.getValue());
                System.out.println("Loaded: " + entry.getKey() + " = " + 
                    (entry.getKey().contains("SECRET") || entry.getKey().contains("PASSWORD") 
                        ? "***" : entry.getValue()));
            });
            
            System.out.println(".env file loaded successfully!");
        } catch (DotenvException e) {
            System.err.println("Error loading .env file: " + e.getMessage());
            System.out.println("Using environment variables or application.properties instead");
        } catch (Exception e) {
            System.err.println("Unexpected error: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @PostConstruct
    public void loadEnv() {
        if (System.getProperty("APP_NAME") == null) {
            loadEnvVariables();
        }
    }
}