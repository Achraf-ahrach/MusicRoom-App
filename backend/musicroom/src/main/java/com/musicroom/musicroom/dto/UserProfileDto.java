package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.Map;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class UserProfileDto {
    private UUID id;
    private String displayName;
    private String avatarUrl;
    private String email;
    private Map<String, Object> publicInfo;
    private Map<String, Object> friendsInfo;
    private Map<String, Object> privateInfo;
    private Map<String, Object> musicPreferences;
}