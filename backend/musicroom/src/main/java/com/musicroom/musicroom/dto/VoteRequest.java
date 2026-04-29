package com.musicroom.musicroom.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class VoteRequest {
    private int value;   // +1 ou -1
}