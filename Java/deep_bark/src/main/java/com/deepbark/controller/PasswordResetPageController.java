package com.deepbark.controller;

import com.deepbark.service.PasswordResetService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
@RequiredArgsConstructor
@RequestMapping("/api/auth/password-reset")
public class PasswordResetPageController {
    private final PasswordResetService passwordResetService;

    @GetMapping
    public String showResetPage(@RequestParam String token, Model model) {
        model.addAttribute("token", token);
        model.addAttribute("error", passwordResetService.validatePasswordResetToken(token));
        return "member/reset-password";
    }

    @PostMapping
    public String resetPassword(
            @RequestParam String token,
            @RequestParam String newPassword,
            @RequestParam String confirmPassword,
            Model model
    ) {
        model.addAttribute("token", token);

        if (newPassword == null || newPassword.isBlank()) {
            model.addAttribute("error", "새 비밀번호를 입력해주세요.");
            return "member/reset-password";
        }

        if (newPassword.length() < 8) {
            model.addAttribute("error", "새 비밀번호는 8자 이상이어야 합니다.");
            return "member/reset-password";
        }

        if (!newPassword.equals(confirmPassword)) {
            model.addAttribute("error", "비밀번호 확인이 일치하지 않습니다.");
            return "member/reset-password";
        }

        try {
            passwordResetService.resetPassword(token, newPassword);
            model.addAttribute("success", "비밀번호가 재설정되었습니다. 앱에서 새 비밀번호로 로그인해주세요.");
        } catch (IllegalArgumentException ex) {
            model.addAttribute("error", ex.getMessage());
        }

        return "member/reset-password";
    }
}
