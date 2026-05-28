package com.condos.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    private String token;
    private String type = "Bearer";
    private UserInfoResponse user;

    /**
     * Constructor that sets type to "Bearer" automatically
     * @param token the JWT token
     * @param user the user information
     */
    public LoginResponse(String token, UserInfoResponse user) {
        this.token = token;
        this.type = "Bearer";
        this.user = user;
    }
}
