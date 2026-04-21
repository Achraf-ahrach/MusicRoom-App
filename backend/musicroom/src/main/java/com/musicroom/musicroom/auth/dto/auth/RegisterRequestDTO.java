package com.musicroom.musicroom.auth.dto.auth;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class RegisterRequestDTO {
    private String email;
    private String password;
    private String displayname;
}
