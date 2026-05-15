package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Log;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface LogRepository extends JpaRepository<Log, UUID> {

    // Get all logs for a user
    List<Log> findByUserIdOrderByCreatedAtDesc(UUID userId);

    // Get all logs for a specific action
    List<Log> findByActionOrderByCreatedAtDesc(String action);

    // Get logs between dates
    List<Log> findByCreatedAtBetween(LocalDateTime startDate, LocalDateTime endDate);

    // Get all device logs
    List<Log> findByDeviceIdOrderByCreatedAtDesc(UUID deviceId);

    // Get logs for a user within a date range
    List<Log> findByUserIdAndCreatedAtBetweenOrderByCreatedAtDesc(UUID userId, LocalDateTime startDate, LocalDateTime endDate);
}
