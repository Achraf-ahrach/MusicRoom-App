package com.musicroom.musicroom.auth.service;

import com.musicroom.musicroom.auth.repository.RefreshTokenRepository;
import com.musicroom.musicroom.auth.security.jwt.JwtTokenProvider;
import com.musicroom.musicroom.entity.RefreshToken;
import com.musicroom.musicroom.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtTokenProvider jwtTokenProvider;

    // Create and save refresh token
    public String createRefreshToken(User user) {
        String refreshToken = jwtTokenProvider.generateRefreshToken(
                user.getEmail(),
                user.getId().toString()
        );

        RefreshToken token = RefreshToken.builder()
                .user(user)
                .token(refreshToken)
                .expiryDate(LocalDateTime.now().plusDays(7))
                .revoked(false)
                .build();

        refreshTokenRepository.save(token);
        return refreshToken;
    }

    // Verify and get refresh token
    public Optional<RefreshToken> verifyRefreshToken(String token) {
        Optional<RefreshToken> refreshToken = refreshTokenRepository.findByToken(token);

        if (refreshToken.isPresent() && !refreshToken.get().isRevoked() &&
                refreshToken.get().getExpiryDate().isAfter(LocalDateTime.now())) {
            return refreshToken;
        }

        return Optional.empty();
    }

    // Delete refresh token (logout) - completely remove from database
    public void revokeRefreshToken(String token) {
        Optional<RefreshToken> refreshToken = refreshTokenRepository.findByToken(token);
        if (refreshToken.isPresent()) {
            refreshTokenRepository.delete(refreshToken.get());
        }
    }
}
