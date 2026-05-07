package com.musicroom.musicroom.dto;

import lombok.*;
import java.util.UUID;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class FriendRequestDto {
    private UUID addresseeId;
}