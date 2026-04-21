package com.musicroom.musicroom.auth.controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.http.ResponseEntity;
@RestController
@RequestMapping("/auth")
public class AuthController {

    @GetMapping("/login")
    public String login() {
        return "from login";
        // return ResponseEntity.ok("from login");
    }

    @GetMapping("/register")
    public String register() {
        return "from register";
        // return ResponseEntity.ok("from register");
    }

    @GetMapping("/logout")
    public String logout() {
        return "from logout";
        // return ResponseEntity.ok("from logout");
    }
    
}