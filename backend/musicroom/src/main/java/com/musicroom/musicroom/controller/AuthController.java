package com.musicroom.musicroom.controller;

import com.musicroom.musicroom.dto.AuthResponse;
import com.musicroom.musicroom.dto.RegisterRequestDTO;
import com.musicroom.musicroom.dto.ResetPassword;
import com.musicroom.musicroom.dto.LoginRequestDTO;
import com.musicroom.musicroom.dto.TokenRefreshRequestDTO;
import com.musicroom.musicroom.dto.TokenRefreshResponseDTO;
import com.musicroom.musicroom.dto.SendVerificationEmailDTO;
import com.musicroom.musicroom.dto.VerifyEmailDTO;
import com.musicroom.musicroom.service.AuthService;
import com.musicroom.musicroom.service.RefreshTokenService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.http.ResponseEntity;
import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final RefreshTokenService refreshTokenService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequestDTO request, HttpServletRequest httpRequest) {
        AuthResponse response = authService.login(request, httpRequest);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequestDTO request, HttpServletRequest httpRequest) {
        AuthResponse response = authService.register(request, httpRequest);
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
    public ResponseEntity<String> sendVerificationEmail(@RequestBody SendVerificationEmailDTO request, HttpServletRequest httpRequest) {
        String response = authService.sendVerificationEmail(request, httpRequest);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/verify-email")
    public ResponseEntity<String> verifyEmail(@RequestBody VerifyEmailDTO request, HttpServletRequest httpRequest) {
        String response = authService.verifyEmail(request, httpRequest);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/verify-email-password-reset")
    public ResponseEntity<String> verifyEmailPassReset(@RequestBody VerifyEmailDTO request, HttpServletRequest httpRequest) {
        String response = authService.verifyEmailPassReset(request, httpRequest);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/Password-reset-change")
    public ResponseEntity<String> PassResetChange(@RequestBody ResetPassword request, HttpServletRequest httpRequest) {
        String response = authService.PassResetChange(request, httpRequest);
        return ResponseEntity.ok(response);
    }



    @PostMapping("/google-login")
    public ResponseEntity<AuthResponse> googleLogin(
            @RequestHeader(value = "Authorization", required = false) String authHeader, 
            HttpServletRequest httpRequest) {
        try {
            // Extract token from "Bearer <token>"
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                throw new RuntimeException("Missing or invalid Authorization header");
            }
            
            String idToken = authHeader.replace("Bearer ", "");
            
            // Call service to handle Google login with token
            AuthResponse response = authService.googleLoginWithToken(idToken, httpRequest);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            throw new RuntimeException("Google login failed: " + e.getMessage());
        }
    }

}