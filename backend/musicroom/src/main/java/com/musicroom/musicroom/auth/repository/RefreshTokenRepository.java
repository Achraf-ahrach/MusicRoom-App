package com.musicroom.musicroom.auth.repository;

import com.musicroom.musicroom.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {
    Optional<RefreshToken> findByToken(String token);
    long deleteByExpiryDateBeforeAndRevoked(LocalDateTime date, boolean revoked);
}
