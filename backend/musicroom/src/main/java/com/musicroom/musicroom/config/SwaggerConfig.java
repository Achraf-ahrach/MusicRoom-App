package com.musicroom.musicroom.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Music Room API")
                        .description("API pour l'application Music Room — votes, playlists, événements")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("Music Room Team")
                                .email("contact@musicroom.com")));
    }
}