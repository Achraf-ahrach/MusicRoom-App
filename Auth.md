# Authentication API Documentation

This document outlines the authentication API endpoints expected by the frontend. The current implementation points to a local Node.js mock backend, but any production backend should match these request and response formats.

## Base URL
Local Development: `http://127.0.0.1:3000`

---

## 1. Sign Up
Creates a new user account. The user is initially unverified and an OTP is sent.

- **Endpoint**: `POST /signup`
- **Request Body (JSON)**:
  ```json
  {
    "fullName": "John Doe",
    "email": "john@example.com",
    "password": "strongPassword123"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "User created successfully",
    "token": "123456" // Mock only: OTP returned for testing
  }
  ```
- **Error Response (400)**:
  ```json
  {
    "error": "Missing full name, email, or password" // or "User already exists"
  }
  ```

---

## 2. Verify Account (OTP)
Verifies a newly signed up user. Upon success, returns authentication tokens to automatically log the user in.

- **Endpoint**: `POST /verify-otp`
- **Request Body (JSON)**:
  ```json
  {
    "email": "john@example.com",
    "token": "123456"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "User verified successfully",
    "user": {
      "id": "1777042843617",
      "fullName": "John Doe",
      "email": "john@example.com"
    },
    "accessToken": "ey...",
    "refreshToken": "ey..."
  }
  ```
- **Error Response (400/404)**:
  ```json
  {
    "error": "Invalid token" // or "User not found"
  }
  ```

---

## 3. Resend Verification OTP
Requests a new verification OTP for a user who has signed up but is not yet verified.

- **Endpoint**: `POST /resend-otp`
- **Request Body (JSON)**:
  ```json
  {
    "email": "john@example.com"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "OTP resent successfully"
  }
  ```
- **Error Response (400/404)**:
  ```json
  {
    "error": "User is already verified" // or "User not found"
  }
  ```

---

## 4. Login
Authenticates an existing, verified user.

- **Endpoint**: `POST /login`
- **Request Body (JSON)**:
  ```json
  {
    "email": "john@example.com",
    "password": "strongPassword123"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "Login successful",
    "user": {
      "id": "1777042843617",
      "fullName": "John Doe",
      "email": "john@example.com"
    },
    "accessToken": "ey...",
    "refreshToken": "ey..."
  }
  ```
- **Error Response (401)**:
  ```json
  {
    "error": "Invalid email or password" // or "User is not verified"
  }
  ```

---

## 5. Forgot Password (Request OTP)
Initiates the password reset flow by sending an OTP to the user's email.

- **Endpoint**: `POST /forgot-password`
- **Request Body (JSON)**:
  ```json
  {
    "email": "john@example.com"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "OTP sent to email"
  }
  ```

---

## 6. Verify Reset OTP
Confirms the OTP is correct before allowing the user to type a new password.

- **Endpoint**: `POST /verify-reset-otp`
- **Request Body (JSON)**:
  ```json
  {
    "email": "john@example.com",
    "token": "123456"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "Token verified successfully"
  }
  ```
- **Error Response (400)**:
  ```json
  {
    "error": "Invalid token"
  }
  ```

---

## 7. Reset Password
Sets a new password for the user. Returns tokens so the user is immediately logged in upon success.

- **Endpoint**: `POST /reset-password`
- **Request Body (JSON)**:
  ```json
  {
    "email": "john@example.com",
    "token": "123456",
    "newPassword": "newStrongPassword456"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "Password reset successfully",
    "user": {
      "id": "1777042843617",
      "fullName": "John Doe",
      "email": "john@example.com"
    },
    "accessToken": "ey...",
    "refreshToken": "ey..."
  }
  ```
- **Error Response (400)**:
  ```json
  {
    "error": "Invalid token"
  }
  ```

---

## 8. Google Authentication (OAuth Mock)
Handles the OAuth fallback flow. If a user signs in via Google, they bypass the password/OTP system.

- **Endpoint**: `POST /auth/google`
- **Request Body (JSON)**:
  ```json
  {
    "email": "john@example.com",
    "fullName": "John Doe",
    "googleId": "104829104812"
  }
  ```
- **Success Response (200)**:
  ```json
  {
    "message": "Google login successful",
    "user": {
      "id": "104829104812",
      "fullName": "John Doe",
      "email": "john@example.com"
    }
  }
  ```
