/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */


package login;

/**
 *
 * @author laraashour
 */
public class User {
    
        private int userId;
    private String username;
    private String roleName;
    private String createdAt;

    public User(int userId, String username, String roleName, String createdAt) {
        this.userId = userId;
        this.username = username;
        this.roleName = roleName;
        this.createdAt = createdAt;
    }

    public int getUserId() {
        return userId;
    }

    public String getUsername() {
        return username;
    }

    public String getRoleName() {
        return roleName;
    }

    public String getCreatedAt() {
        return createdAt;
    }
    
    
    
}
