package com.deepbark.dto;

import com.deepbark.entity.User;
import lombok.Data;

@Data
public class UserDto {
    private Long id;
    private String username;
    private String email;

    public UserDto(User user) {
        this.id = user.getId();
        this.username = user.getUsername();
        this.email = user.getEmail();
    }

    // getter/setter 생략
} 