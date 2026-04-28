package com.musicroom.musicroom.auth.controller;

import com.musicroom.musicroom.auth.dto.auth.AuthResponse;
import com.musicroom.musicroom.auth.dto.auth.RegisterRequestDTO;
import com.musicroom.musicroom.auth.dto.auth.ResetPassword;
import com.musicroom.musicroom.auth.dto.auth.LoginRequestDTO;
import com.musicroom.musicroom.auth.dto.auth.TokenRefreshRequestDTO;
import com.musicroom.musicroom.auth.dto.auth.TokenRefreshResponseDTO;
import com.musicroom.musicroom.auth.dto.auth.SendVerificationEmailDTO;
import com.musicroom.musicroom.auth.dto.auth.VerifyEmailDTO;
import com.musicroom.musicroom.auth.service.AuthService;
import com.musicroom.musicroom.auth.service.RefreshTokenService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.http.ResponseEntity;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final RefreshTokenService refreshTokenService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequestDTO request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequestDTO request) {
        AuthResponse response = authService.register(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<TokenRefreshResponseDTO> refreshToken(@RequestBody TokenRefreshRequestDTO request) {
        TokenRefreshResponseDTO response = authService.refreshAccessToken(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(@RequestBody TokenRefreshRequestDTO request) {
        // Delete refresh token from database
        refreshTokenService.revokeRefreshToken(request.refreshToken());
        return ResponseEntity.ok("Logged out successfully");
    }

    @PostMapping("/send-verification-email")
    public ResponseEntity<String> sendVerificationEmail(@RequestBody SendVerificationEmailDTO request) {
        String response = authService.sendVerificationEmail(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/verify-email")
    public ResponseEntity<String> verifyEmail(@RequestBody VerifyEmailDTO request) {
        String response = authService.verifyEmail(request);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/verify-email-password-reset")
    public ResponseEntity<String> verifyEmailPassReset(@RequestBody VerifyEmailDTO request) {
        String response = authService.verifyEmailPassReset(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/Password-reset-change")
    public ResponseEntity<String> PassResetChange(@RequestBody ResetPassword request) {
        String response = authService.PassResetChange(request);
        return ResponseEntity.ok(response);
    }



    @PostMapping("/google-login")
    public ResponseEntity<AuthResponse> googleLogin(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        try {
            // Extract token from "Bearer <token>"
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                throw new RuntimeException("Missing or invalid Authorization header");
            }
            
            String idToken = authHeader.replace("Bearer ", "");
            
            // Call service to handle Google login with token
            AuthResponse response = authService.googleLoginWithToken(idToken);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            throw new RuntimeException("Google login failed: " + e.getMessage());
        }
    }

}