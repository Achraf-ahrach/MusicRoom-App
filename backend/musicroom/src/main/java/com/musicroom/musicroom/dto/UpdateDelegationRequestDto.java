package com.musicroom.musicroom.dto;

import com.musicroom.musicroom.enums.PermissionLevel;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpdateDelegationRequestDto {
    private UUID ownerId;
    private PermissionLevel permissionLevel;
    private boolean active;
}
