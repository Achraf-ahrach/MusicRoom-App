package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UpdatePreferencesRequest {
    private Map<String, Object> musicPreferences;
}