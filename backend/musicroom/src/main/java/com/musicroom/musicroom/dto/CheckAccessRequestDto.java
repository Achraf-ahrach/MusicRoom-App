package com.musicroom.musicroom.dto;

import com.musicroom.musicroom.enums.ResourceType;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CheckAccessRequestDto {
    private UUID resourceId;
    private ResourceType resourceType;
}
