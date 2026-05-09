package com.musicroom.musicroom.service;

import com.musicroom.musicroom.dto.*;

public interface AuthService {
        public AuthResponse register(RegisterRequestDTO request);
        public AuthResponse login(LoginRequestDTO request);
        public String verifyEmail(VerifyEmailDTO request);
        public String verifyEmailPassReset(VerifyEmailDTO request);
        public String PassResetChange(ResetPassword request);
        public AuthResponse googleLogin(String email, String name, String googleId);
        public AuthResponse googleLoginWithToken(String idToken);
        public TokenRefreshResponseDTO refreshToken(TokenRefreshRequestDTO request);
        public void sendVerificationEmail(SendVerificationEmailDTO request);
        public TokenRefreshResponseDTO refreshAccessToken(TokenRefreshRequestDTO request);



}