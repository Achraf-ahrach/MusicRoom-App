package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.PlaylistOperation;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.UUID;

public interface PlaylistOperationRepository extends JpaRepository<PlaylistOperation, UUID> {
}