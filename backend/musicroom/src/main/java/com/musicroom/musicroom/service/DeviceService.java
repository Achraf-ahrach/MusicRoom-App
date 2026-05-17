package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.DeviceDto;
import java.util.List;
import java.util.UUID;

public interface DeviceService {

    // Register or update device (call this on every login)

    public DeviceDto registerOrUpdateDevice(UUID userId, String deviceName, String platform, 
                                           String appVersion, String ipAddress);
    // Get all user's devices

    public List<DeviceDto> getUserDevices(UUID userId);

}
