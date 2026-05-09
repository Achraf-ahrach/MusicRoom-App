package com.musicroom.musicroom.service;

public interface EmailService {

    public String sendVerificationEmail(String toEmail, String verificationCode);
}
