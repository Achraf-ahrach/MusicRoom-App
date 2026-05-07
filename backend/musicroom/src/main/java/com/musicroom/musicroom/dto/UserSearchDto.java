package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class UserSearchDto {
    private UUID id;
    private String displayName;
    private String avatarUrl;
}