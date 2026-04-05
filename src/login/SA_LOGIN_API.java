package login;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import database.DBConnection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class SA_LOGIN_API {



    /**
     * Hash password using SHA-256
     */
    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] bytes = md.digest(password.getBytes());

            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) {
                sb.append(String.format("%02x", b));
            }

            return sb.toString();

        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 not available");
        }
    }

    /**
     * LOGIN
     */
public boolean login(String username, String password) {

    String sql = "SELECT password_hash FROM ca_users WHERE username = ?";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        ps.setString(1, username);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                String storedHash = rs.getString("password_hash");
                return storedHash.equals(hashPassword(password));
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

    /**
     * CREATE STAFF USER
     */
public boolean createStaff(String username, String password, String roleName) {
    String checkSql = "SELECT user_id FROM ca_users WHERE username = ?";
    String insertSql = "INSERT INTO ca_users (username, password_hash, role_id) VALUES (?, ?, ?)";

    try (Connection conn = DBConnection.getConnection()) {

        try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
            checkPs.setString(1, username);
            try (ResultSet rs = checkPs.executeQuery()) {
                if (rs.next()) {
                    return false;
                }
            }
        }

        int roleId = getRoleIdByName(roleName);
        if (roleId == -1) {
            return false;
        }

        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            ps.setString(1, username);
            ps.setString(2, hashPassword(password));
            ps.setInt(3, roleId);
            return ps.executeUpdate() > 0;
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

    /**
     * REMOVE STAFF USER
     */
public boolean removeStaff(String username) {
    String sql = "DELETE FROM ca_users WHERE username = ?";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        ps.setString(1, username);
        return ps.executeUpdate() > 0;

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

    /**
     * UPDATE USER ROLE
     */
public boolean updateUserRole(String username, String roleName) {
    String sql = "UPDATE ca_users SET role_id = ? WHERE username = ?";

    try (Connection conn = DBConnection.getConnection()) {
        int roleId = getRoleIdByName(roleName);

        if (roleId == -1) {
            return false;
        }

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, roleId);
            ps.setString(2, username);
            return ps.executeUpdate() > 0;
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

    /**
     * GET USER ROLE
     */
public String getUserRole(String username) {
    String sql = "SELECT r.role_name " +
                 "FROM ca_users u " +
                 "JOIN ca_roles r ON u.role_id = r.role_id " +
                 "WHERE u.username = ?";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        ps.setString(1, username);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getString("role_name");
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return null;
}

    /**
     * LOAD ALL USERS FOR MANAGE STAFF TABLE
     */
public java.util.List<User> getAllUsers() throws SQLException {
    java.util.List<User> users = new java.util.ArrayList<>();

    String sql = "SELECT u.user_id, u.username, r.role_name, u.created_at " +
                 "FROM ca_users u " +
                 "JOIN ca_roles r ON u.role_id = r.role_id " +
                 "ORDER BY u.user_id";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {

        while (rs.next()) {
            users.add(new User(
                rs.getInt("user_id"),
                rs.getString("username"),
                rs.getString("role_name"),
                rs.getString("created_at")
            ));
        }
    }

    return users;
}

    /**
     * HELPER: role name -> role_id
     */
private int getRoleIdByName(String roleName) {
    String sql = "SELECT role_id FROM ca_roles WHERE lower(role_name) = lower(?)";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        ps.setString(1, roleName);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("role_id");
            }
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return -1;
}
}