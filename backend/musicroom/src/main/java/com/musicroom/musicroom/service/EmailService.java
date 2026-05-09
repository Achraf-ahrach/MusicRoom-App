package com.musicroom.musicroom.service;

public interface EmailService {

    public void sendVerificationEmail(String toEmail, String verificationCode);
}
