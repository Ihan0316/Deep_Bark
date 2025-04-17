package com.deepbark.controller;

import com.deepbark.service.UserService;
import com.deepbark.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class UserController {
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);
    private final UserService userService;
    private final PasswordEncoder passwordEncoder;

    @Autowired
    public UserController(UserService userService, PasswordEncoder passwordEncoder) {
        this.userService = userService;
        this.passwordEncoder = passwordEncoder;
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

    @DeleteMapping("/{userId}")
    public ResponseEntity<?> deleteUser(@PathVariable Long userId) {
        try {
            logger.info("Deleting user with ID: {}", userId);
            userService.deleteUser(userId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "사용자가 성공적으로 삭제되었습니다.");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error deleting user with ID {}: {}", userId, e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "사용자 삭제 중 오류가 발생했습니다.");
            error.put("details", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    @PutMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @RequestHeader("Authorization") String token,
            @RequestBody Map<String, String> request) {
        try {
            logger.info("Changing password for user");
            String currentPassword = request.get("currentPassword");
            String newPassword = request.get("newPassword");
            String userId = request.get("userId");

            if (currentPassword == null || currentPassword.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "현재 비밀번호는 필수 입력값입니다."));
            }
            if (newPassword == null || newPassword.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "새 비밀번호는 필수 입력값입니다."));
            }
            if (userId == null || userId.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "사용자 ID는 필수 입력값입니다."));
            }

            // 사용자 조회
            User user = userService.getUserById(Long.parseLong(userId));
            if (user == null) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "사용자를 찾을 수 없습니다."));
            }

            // 현재 비밀번호 확인
            if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "현재 비밀번호가 일치하지 않습니다."));
            }

            // 새 비밀번호로 변경
            user.setPassword(passwordEncoder.encode(newPassword));
            userService.updateUser(user);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "비밀번호가 성공적으로 변경되었습니다.");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error changing password: {}", e.getMessage(), e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "비밀번호 변경 중 오류가 발생했습니다.");
            error.put("details", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }
}