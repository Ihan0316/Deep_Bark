package com.deepbark.service;

import com.deepbark.entity.User;
import com.deepbark.repository.UserRepository;
import com.deepbark.security.JwtTokenProvider;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Service
@Log4j2
@RequiredArgsConstructor
public class PasswordResetService {
    private static final String INVALID_TOKEN_MESSAGE =
            "비밀번호 재설정 링크가 유효하지 않거나 만료되었습니다. 다시 요청해주세요.";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final JavaMailSender mailSender;

    @Value("${app.mail.enabled:false}")
    private boolean mailEnabled;

    @Value("${app.password-reset.base-url:http://localhost:8080}")
    private String passwordResetBaseUrl;

    @Value("${app.password-reset.expiration:1800000}")
    private long passwordResetExpirationInMs;

    @Value("${spring.mail.username:}")
    private String mailUsername;

    public void requestPasswordReset(String email) {
        ensureMailConfigured();

        userRepository.findByEmail(email).ifPresent(user -> {
            String token = jwtTokenProvider.generatePasswordResetToken(
                    user.getEmail(),
                    createPasswordFingerprint(user.getPassword()),
                    passwordResetExpirationInMs
            );
            sendResetEmail(user, token);
        });
    }

    public String validatePasswordResetToken(String token) {
        try {
            resolveUser(token);
            return null;
        } catch (IllegalArgumentException ex) {
            return ex.getMessage();
        }
    }

    public void resetPassword(String token, String newPassword) {
        User user = resolveUser(token);
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    private void ensureMailConfigured() {
        if (!mailEnabled || mailUsername == null || mailUsername.isBlank()) {
            throw new IllegalStateException(
                    "비밀번호 재설정 메일 설정이 완료되지 않았습니다. 관리자에게 문의해주세요."
            );
        }
    }

    private void sendResetEmail(User user, String token) {
        String encodedToken = URLEncoder.encode(token, StandardCharsets.UTF_8);
        String resetLink = passwordResetBaseUrl + "/api/auth/password-reset?token=" + encodedToken;

        SimpleMailMessage message = new SimpleMailMessage();
        message.setTo(user.getEmail());
        message.setFrom(mailUsername);
        message.setSubject("[Deep Bark] 비밀번호 재설정 링크");
        message.setText(
                "비밀번호를 재설정하려면 아래 링크를 열어 새 비밀번호를 입력해주세요.\n\n"
                        + resetLink
                        + "\n\n"
                        + "이 링크는 일정 시간이 지나면 만료됩니다."
        );

        try {
            mailSender.send(message);
        } catch (Exception ex) {
            log.error("Failed to send password reset email to {}", user.getEmail(), ex);
            throw new IllegalStateException(
                    "비밀번호 재설정 메일을 전송할 수 없습니다. 메일 설정을 확인해주세요."
            );
        }
    }

    private User resolveUser(String token) {
        try {
            Claims claims = jwtTokenProvider.parseClaims(token);

            if (!jwtTokenProvider.isPasswordResetToken(claims)) {
                throw new IllegalArgumentException(INVALID_TOKEN_MESSAGE);
            }

            String email = claims.getSubject();
            String passwordFingerprint = claims.get("passwordFingerprint", String.class);

            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new IllegalArgumentException(INVALID_TOKEN_MESSAGE));

            String currentFingerprint = createPasswordFingerprint(user.getPassword());
            if (!currentFingerprint.equals(passwordFingerprint)) {
                throw new IllegalArgumentException(INVALID_TOKEN_MESSAGE);
            }

            return user;
        } catch (ExpiredJwtException ex) {
            throw new IllegalArgumentException(INVALID_TOKEN_MESSAGE);
        } catch (JwtException | IllegalArgumentException ex) {
            if (INVALID_TOKEN_MESSAGE.equals(ex.getMessage())) {
                throw ex;
            }
            throw new IllegalArgumentException(INVALID_TOKEN_MESSAGE);
        }
    }

    private String createPasswordFingerprint(String encodedPassword) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(encodedPassword.getBytes(StandardCharsets.UTF_8));
            StringBuilder builder = new StringBuilder();

            for (byte b : hash) {
                builder.append(String.format("%02x", b));
            }

            return builder.toString();
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("비밀번호 토큰 서명을 생성할 수 없습니다.", ex);
        }
    }
}
