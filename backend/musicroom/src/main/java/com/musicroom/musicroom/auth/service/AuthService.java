package com.musicroom.musicroom.auth.service;

import com.musicroom.musicroom.auth.dto.auth.AuthResponse;
import com.musicroom.musicroom.auth.dto.auth.RegisterRequestDTO;
import com.musicroom.musicroom.auth.dto.auth.RegisterResponseDTO;
import com.musicroom.musicroom.auth.dto.auth.ResetPassword;
import com.musicroom.musicroom.auth.dto.auth.LoginRequestDTO;
import com.musicroom.musicroom.auth.dto.auth.TokenRefreshRequestDTO;
import com.musicroom.musicroom.auth.dto.auth.TokenRefreshResponseDTO;
import com.musicroom.musicroom.auth.dto.auth.SendVerificationEmailDTO;
import com.musicroom.musicroom.auth.dto.auth.VerifyEmailDTO;
import com.musicroom.musicroom.auth.security.jwt.JwtTokenProvider;
import com.musicroom.musicroom.entity.User;
import com.musicroom.musicroom.entity.RefreshToken;
import com.musicroom.musicroom.auth.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final RefreshTokenService refreshTokenService;
    private final EmailService emailService;

    public AuthResponse register(RegisterRequestDTO request) {
        try {
                if (userRepository.existsByEmail(request.email())) {
                throw new RuntimeException("Email already exists");
                } else if (request.password().length() < 6) {
                throw new RuntimeException("Password must be at least 6 characters");
                }

                String verificationCode = String.format("%06d", new Random().nextInt(1000000));
                User user = User.builder()
                        .email(request.email())
                        .passwordHash(passwordEncoder.encode(request.password()))
                        .displayName(request.displayname())
                        .authProvider("local")
                        .build();
        
                user.setVerificationCode(verificationCode);

                User savedUser = userRepository.save(user);
                emailService.sendVerificationEmail(request.email(), verificationCode);
                
                String accessToken = jwtTokenProvider.generateAccessToken(
                        savedUser.getEmail(),
                        savedUser.getId().toString()
                );

                String refreshToken = refreshTokenService.createRefreshToken(savedUser);

                return new AuthResponse(
                        accessToken,
                        refreshToken,
                        "Bearer",
                        jwtTokenProvider.getAccessTokenExpiration(),
                        new RegisterResponseDTO(
                                savedUser.getId(),
                                savedUser.getEmail(),
                                savedUser.getDisplayName(),
                                savedUser.getAvatarUrl(),
                                String.valueOf(savedUser.isEmailVerified())
                        )
                );
        } catch (Exception e) {
                throw new RuntimeException("Registration failed: " + e.getMessage());
        }
    }

    public AuthResponse login(LoginRequestDTO request) {

        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));
        
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new RuntimeException("Invalid credentials");
        }
        
        String accessToken = jwtTokenProvider.generateAccessToken(
                user.getEmail(),
                user.getId().toString()
        );

        String refreshToken = refreshTokenService.createRefreshToken(user);
        
        return new AuthResponse(
                accessToken,
                refreshToken,
                "Bearer",
                jwtTokenProvider.getAccessTokenExpiration(),
                new RegisterResponseDTO(
                        user.getId(),
                        user.getEmail(),
                        user.getDisplayName(),
                        user.getAvatarUrl(),
                        String.valueOf(user.isEmailVerified())
                )
        );
    }

    public TokenRefreshResponseDTO refreshAccessToken(TokenRefreshRequestDTO request) {
        // Verify refresh token is valid and not revoked
        RefreshToken refreshToken = refreshTokenService.verifyRefreshToken(request.refreshToken())
                .orElseThrow(() -> new RuntimeException("Invalid or expired refresh token"));

        User user = refreshToken.getUser();

        String accessToken = jwtTokenProvider.generateAccessToken(
                user.getEmail(),
                user.getId().toString()
        );

        return new TokenRefreshResponseDTO(
                accessToken,
                request.refreshToken(),
                "Bearer",
                jwtTokenProvider.getAccessTokenExpiration()
        );
    }

    // Generate and send verification code
     public String sendVerificationEmail(SendVerificationEmailDTO request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new RuntimeException("User not found"));

        String verificationCode = String.format("%06d", new Random().nextInt(1000000));

        user.setVerificationCode(verificationCode);
        userRepository.save(user);

        // ✅ SEND EMAIL WITH CODE
        emailService.sendVerificationEmail(request.email(), verificationCode);

        return "Verification code sent to " + request.email();
    }

    // Verify email with code
    public String verifyEmail(VerifyEmailDTO request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getVerificationCode() == null || !user.getVerificationCode().equals(request.verificationCode())) {
            throw new RuntimeException("Invalid verification code");
        }

        user.setEmailVerified(true);
        user.setVerificationCode(null);
        userRepository.save(user);

        return "Email verified successfully";
    }

     public String verifyEmailPassReset(VerifyEmailDTO request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getVerificationCode() == null || !user.getVerificationCode().equals(request.verificationCode())) {
            throw new RuntimeException("Invalid verification code");
        }

        return "Email verified successfully";
    }

    public String PassResetChange(ResetPassword request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getVerificationCode() == null || !user.getVerificationCode().equals(request.verificationCode())) {
            throw new RuntimeException("Invalid verification code");
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);

        return "Email verified successfully";
    }



    public AuthResponse googleLogin(String email, String name, String googleId) {
        // Check if user exists
        User user = userRepository.findByEmail(email)
                .orElseGet(() -> {
                    // Create new user if doesn't exist
                    User newUser = User.builder()
                            .email(email)
                            .displayName(name)
                            .authProvider("google")
                            .providerId(googleId)
                            .emailVerified(true)  // Google email is already verified
                            .passwordHash(null)  // No password for Google users
                            .build();
                    return userRepository.save(newUser);
                });

        // Generate tokens
        String accessToken = jwtTokenProvider.generateAccessToken(
                user.getEmail(),
                user.getId().toString()
        );

        String refreshToken = refreshTokenService.createRefreshToken(user);

        return new AuthResponse(
                accessToken,
                refreshToken,
                "Bearer",
                jwtTokenProvider.getAccessTokenExpiration(),
                new RegisterResponseDTO(
                        user.getId(),
                        user.getEmail(),
                        user.getDisplayName(),
                        user.getAvatarUrl(),
                        String.valueOf(user.isEmailVerified())
                )
        );
    }

    @SuppressWarnings("unchecked")
    public AuthResponse googleLoginWithToken(String idToken) {
        try {
            // Decode the JWT token
            String[] parts = idToken.split("\\.");
            if (parts.length != 3) {
                throw new RuntimeException("Invalid token format");
            }
            
            // Decode payload (2nd part)
            String payload = new String(java.util.Base64.getUrlDecoder().decode(parts[1]));
            
            // Parse JSON
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            java.util.Map<String, Object> tokenData = mapper.readValue(payload, java.util.Map.class);
            
            String email = (String) tokenData.get("email");
            String name = (String) tokenData.get("name");
            String googleId = (String) tokenData.get("sub");

            if (email == null || name == null || googleId == null) {
                throw new RuntimeException("Invalid token: missing email, name, or googleId");
            }

            // Check if user exists
            User user = userRepository.findByEmail(email)
                    .orElseGet(() -> {
                        // Create new user if doesn't exist
                        User newUser = User.builder()
                                .email(email)
                                .displayName(name)
                                .authProvider("google")
                                .providerId(googleId)
                                .emailVerified(true)
                                .passwordHash(null)
                                .build();
                        return userRepository.save(newUser);
                    });

            // Generate tokens
            String accessToken = jwtTokenProvider.generateAccessToken(
                    user.getEmail(),
                    user.getId().toString()
            );

            String refreshToken = refreshTokenService.createRefreshToken(user);

            return new AuthResponse(
                    accessToken,
                    refreshToken,
                    "Bearer",
                    jwtTokenProvider.getAccessTokenExpiration(),
                    new RegisterResponseDTO(
                            user.getId(),
                            user.getEmail(),
                            user.getDisplayName(),
                            user.getAvatarUrl(),
                            String.valueOf(user.isEmailVerified())
                    )
            );
        } catch (Exception e) {
            throw new RuntimeException("Failed to process Google token: " + e.getMessage());
        }
    }

}