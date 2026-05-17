package com.musicroom.musicroom.security;

// import com.musicroom.musicroom.auth.security.jwt.JwtTokenProvider;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String jwt = getJwtFromRequest(request);
            System.out.println("DEBUG [JwtFilter]: Extracted JWT from request: " + (jwt != null ? "length " + jwt.length() : "null"));

            if (jwt != null) {
                boolean isValid = jwtTokenProvider.validateToken(jwt);
                System.out.println("DEBUG [JwtFilter]: isTokenValid = " + isValid);
                
                if (isValid) {
                    String userId = jwtTokenProvider.getUserIdFromToken(jwt);
                    System.out.println("DEBUG [JwtFilter]: Authenticating user ID = " + userId);
                    
                    org.springframework.security.core.userdetails.UserDetails userDetails = 
                            org.springframework.security.core.userdetails.User.withUsername(userId)
                            .password("")
                            .authorities(new ArrayList<>())
                            .build();

                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                } else {
                    System.out.println("DEBUG [JwtFilter]: Token validation failed for: " + jwt);
                }
            }
        } catch (Exception ex) {
            System.out.println("DEBUG [JwtFilter]: Exception caught during authentication: " + ex.getMessage());
            ex.printStackTrace();
        }

        filterChain.doFilter(request, response);
    }

    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}