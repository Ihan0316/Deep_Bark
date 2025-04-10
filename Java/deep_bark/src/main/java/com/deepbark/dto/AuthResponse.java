package com.deepbark.dto;

import com.deepbark.dto.UserDto;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AuthResponse {
    private String token;
    private UserDto user;
} 