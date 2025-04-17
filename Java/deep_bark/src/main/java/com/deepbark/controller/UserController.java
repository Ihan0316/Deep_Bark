package com.deepbark.controller;

import com.deepbark.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class UserController {
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);
    private final UserService userService;

    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/check-username")
    public ResponseEntity<?> checkUsernameAvailability(@RequestParam String username) {
        try {
            logger.info("Checking username availability for: {}", username);
            boolean isAvailable = userService.isUsernameAvailable(username);
            Map<String, Object> response = new HashMap<>();
            response.put("available", isAvailable);
            response.put("username", username);
            logger.info("Username check result for {}: {}", username, isAvailable);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error checking username availability for {}: {}", username, e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "사용자 이름 확인 중 오류가 발생했습니다.");
            error.put("details", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @GetMapping("/check-email")
    public ResponseEntity<?> checkEmailAvailability(@RequestParam String email) {
        try {
            logger.info("Checking email availability for: {}", email);
            boolean isAvailable = userService.isEmailAvailable(email);
            Map<String, Object> response = new HashMap<>();
            response.put("available", isAvailable);
            response.put("email", email);
            logger.info("Email check result for {}: {}", email, isAvailable);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error checking email availability for {}: {}", email, e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "이메일 확인 중 오류가 발생했습니다.");
            error.put("details", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
}