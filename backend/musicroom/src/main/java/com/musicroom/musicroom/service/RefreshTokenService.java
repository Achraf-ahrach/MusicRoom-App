package com.musicroom.musicroom.service;

import com.musicroom.musicroom.entity.RefreshToken;
import com.musicroom.musicroom.entity.User;
import java.util.Optional;
import org.springframework.stereotype.Service;

@Service
public interface RefreshTokenService {

    public String createRefreshToken(User user);
    public Optional<RefreshToken> verifyRefreshToken(String token);
    public void revokeRefreshToken(String token);
    public void cleanupExpiredTokens();

}


