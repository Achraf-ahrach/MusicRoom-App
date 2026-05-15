package com.musicroom.musicroom.dto;

public record LoginRequestDTO (
    String email,
    String password,
    String deviceName,
    String platform,
    String appVersion,
    String pushToken
){}
