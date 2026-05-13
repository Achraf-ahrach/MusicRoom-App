package com.musicroom.musicroom.dto;

import com.musicroom.musicroom.enums.PermissionLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePermissionDto {
    private PermissionLevel permissionLevel;
    private boolean active;
}