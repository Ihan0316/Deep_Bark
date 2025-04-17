package com.deepbark.controller;

import com.deepbark.dto.LoginRequest;
import com.deepbark.dto.RegisterRequest;
import com.deepbark.dto.AuthResponse;
import com.deepbark.dto.UserDto;
import com.deepbark.entity.User;
import com.deepbark.repository.UserRepository;
import com.deepbark.security.JwtTokenProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            // 필수 필드 검증
            if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "이메일은 필수 입력값입니다."));
            }
            if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "비밀번호는 필수 입력값입니다."));
            }
            if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "사용자 이름은 필수 입력값입니다."));
            }

            // 이메일 중복 체크
            if (userRepository.existsByEmail(request.getEmail())) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "이미 등록된 이메일입니다."));
            }

            // 사용자 생성
            User user = new User();
            user.setUsername(request.getUsername());
            user.setEmail(request.getEmail());
            user.setPassword(passwordEncoder.encode(request.getPassword()));

            userRepository.save(user);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "회원가입이 완료되었습니다.");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", "회원가입 중 오류가 발생했습니다.");
            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            // 이메일 존재 여부 확인
            if (!userRepository.existsByEmail(request.getEmail())) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("email", "이메일이 존재하지 않습니다."));
            }

            // 인증
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));

            // JWT 토큰 생성
            String token = jwtTokenProvider.generateToken(authentication);

            // 사용자 정보 조회
            User user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() -> new RuntimeException("사용자를 찾을 수 없습니다."));

            // 응답 생성
            AuthResponse response = new AuthResponse();
            response.setToken(token);
            response.setUser(new UserDto(user));

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            if (e.getMessage().contains("Bad credentials")) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("password", "비밀번호가 일치하지 않습니다."));
            }
            return ResponseEntity.badRequest().body(Collections.singletonMap("error", "로그인에 실패했습니다."));
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");

            if (email == null || email.trim().isEmpty()) {
                return ResponseEntity.badRequest().body(Collections.singletonMap("error", "이메일은 필수 입력값입니다."));
            }

            // 이메일로 사용자 찾기
            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("해당 이메일로 등록된 사용자가 없습니다."));

            // 비밀번호를 "1234"로 초기화
            user.setPassword(passwordEncoder.encode("1234"));
            userRepository.save(user);

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "비밀번호가 1234로 초기화되었습니다. 로그인 후 비밀번호를 변경해주세요.");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(response);
        }
    }
}