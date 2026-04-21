package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class UpdateProfileRequest {
    private String displayName;
    private String avatarUrl;
    private Map<String, Object> publicInfo;
    private Map<String, Object> friendsInfo;
    private Map<String, Object> privateInfo;
}