package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.*;
import jakarta.servlet.http.HttpServletRequest;

public interface AuthService {
        public AuthResponse register(RegisterRequestDTO request, HttpServletRequest httpRequest);
        public AuthResponse login(LoginRequestDTO request, HttpServletRequest httpRequest);
        public String verifyEmail(VerifyEmailDTO request, HttpServletRequest httpRequest);
        public String verifyEmailPassReset(VerifyEmailDTO request, HttpServletRequest httpRequest);
        public String PassResetChange(ResetPassword request, HttpServletRequest httpRequest);
        public AuthResponse googleLogin(String email, String name, String googleId, HttpServletRequest httpRequest);
        public AuthResponse googleLoginWithToken(String idToken, HttpServletRequest httpRequest);
        public TokenRefreshResponseDTO refreshToken(TokenRefreshRequestDTO request);
        public String sendVerificationEmail(SendVerificationEmailDTO request, HttpServletRequest httpRequest);
        public TokenRefreshResponseDTO refreshAccessToken(TokenRefreshRequestDTO request);



}