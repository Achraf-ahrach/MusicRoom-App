package com.musicroom.musicroom.repository;

import com.musicroom.musicroom.entity.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceRepository extends JpaRepository<Device, UUID> {

    // Get all devices for a user
    List<Device> findByUserId(UUID userId);

    // Check if device already registered for this user
    Optional<Device> findByUserIdAndDeviceName(UUID userId, String deviceName);

    // Get device by push token
    Optional<Device> findByPushToken(String pushToken);
}
