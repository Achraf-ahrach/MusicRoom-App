package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.DeviceDto;
import com.musicroom.musicroom.entity.Device;
import com.musicroom.musicroom.entity.User;
import com.musicroom.musicroom.repository.DeviceRepository;
import com.musicroom.musicroom.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DeviceService {

    private final DeviceRepository deviceRepository;
    private final UserRepository userRepository;
    private final LogService logService;

    /**
     * Register or update device (call this on every login)
     */
    public DeviceDto registerOrUpdateDevice(UUID userId, String deviceName, String platform, 
                                           String appVersion, String pushToken, String ipAddress) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Check if device already exists for this user
        Device device = deviceRepository.findByUserIdAndDeviceName(userId, deviceName)
                .orElse(null);

        if (device == null) {
            // NEW DEVICE - Create it
            device = Device.builder()
                    .user(user)
                    .deviceName(deviceName)
                    .platform(platform)
                    .appVersion(appVersion)
                    .pushToken(pushToken)
                    .lastSeen(LocalDateTime.now())
                    .createdAt(LocalDateTime.now())
                    .build();

            device = deviceRepository.save(device);

            // Log new device
            logService.logDeviceConnected(userId, device.getId(), deviceName, platform, ipAddress);
            
        } else {
            // EXISTING DEVICE - Update it
            device.setPlatform(platform);
            device.setAppVersion(appVersion);
            device.setPushToken(pushToken);
            device.setLastSeen(LocalDateTime.now());

            device = deviceRepository.save(device);
        }

        return mapToDto(device);
    }

    /**
     * Get all user's devices
     */
    public List<DeviceDto> getUserDevices(UUID userId) {
        return deviceRepository.findByUserId(userId)
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    private DeviceDto mapToDto(Device device) {
        return new DeviceDto(
            device.getId(),
            device.getUser().getId(),
            device.getDeviceName(),
            device.getPlatform(),
            device.getAppVersion(),
            device.getPushToken(),
            device.getLastSeen(),
            device.getCreatedAt()
        );
    }
}
