package com.musicroom.musicroom.service.impl;

import com.musicroom.musicroom.service.EmailService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor

public class EmailServiceIml implements EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.from}")
    private String fromEmail;

    @Value("${app.mail.from.name}")
    private String fromName;

    @Override
    public void sendVerificationEmail(String toEmail, String verificationCode) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Email Verification - Music Room");
            message.setText("Your verification code is: " + verificationCode + "\n\n" +
                    "This code will expire in 10 minutes.\n" +
                    "Do not share this code with anyone.\n\n" +
                    "If you didn't request this, please ignore this email.");

            mailSender.send(message);
        } catch (Exception e) {
            throw new RuntimeException("Failed to send verification email: " + e.getMessage());
        }
    }
    
}
