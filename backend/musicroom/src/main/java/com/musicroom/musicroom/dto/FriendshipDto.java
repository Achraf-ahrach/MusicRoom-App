package com.musicroom.musicroom.dto;

import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class FriendshipDto {
    private UUID id;
    private UUID requesterId;
    private String requesterName;
    private String requesterAvatar;
    private UUID addresseeId;
    private String addresseeName;
    private String addresseeAvatar;
    private String status;
    private LocalDateTime createdAt;
}