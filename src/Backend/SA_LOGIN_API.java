package Backend;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.*;

public class SA_LOGIN_API {

    // Database connection (shared across all methods and classes)
    private Connection conn;

    // Constructor: receives connection from DBConnection class
    public SA_LOGIN_API(Connection conn) {
        this.conn = conn;
    }


    // ROLE CONSTANTS (available roles)

    public static final String ROLE_CUSTOMER = "CUSTOMER";
    public static final String ROLE_STAFF = "STAFF";
    public static final String ROLE_ADMIN = "ADMIN";

    /**
     * Hash password using SHA-256 (hash the password)
     */
    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");

            // Convert password into hashed bytes
            byte[] bytes = md.digest(password.getBytes());

            // Convert bytes to readable hex string
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
     * Checks if username + password hash match database
     */
    public boolean login(String username, String password) {

        try {
            // SQL to get stored password hash
            String sql = "SELECT password_hash FROM ca_users WHERE username = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setString(1, username);

            ResultSet rs = ps.executeQuery();

            // If user exists
            if (rs.next()) {
                String storedHash = rs.getString("password_hash");

                // Compare stored hash with hashed input password
                return storedHash.equals(hashPassword(password));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * CREATE ACCOUNT
     * Only assumption is that the new account will be a CUSTOMER (default role)
     */
    public boolean createStaff(String username, String password) {

        try {
            // Check if username already exists
            String checkSql = "SELECT user_id FROM ca_users WHERE username = ?";
            PreparedStatement checkPs = conn.prepareStatement(checkSql);
            checkPs.setString(1, username);

            ResultSet rs = checkPs.executeQuery();

            if (rs.next()) {
                return false; // user already exists
            }

            // Get role_id for Staff
            int roleId = getRoleIdByName(ROLE_STAFF);

            // Step 3: Insert user into database
            String insertSql = "INSERT INTO ca_users (username, password_hash, role_id) VALUES (?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(insertSql);

            ps.setString(1, username);
            ps.setString(2, hashPassword(password));
            ps.setInt(3, roleId);

            ps.executeUpdate();

            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean createCustomer(int id, String name, String email) {

    try {
        String sql = "INSERT INTO ca_customers (customer_id, firstname, surname, dob, email, phone, houseNumber, postcode, account_holder, credit_limit, outstanding_balance, account_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, TRUE, 0, 0, 'ACTIVE')";
        PreparedStatement ps = conn.prepareStatement(sql);

        ps.setInt(1, id);
        ps.setString(2, name);
        ps.setString(3, "");
        ps.setString(4, "1970-01-01");
        ps.setString(5, email);
        ps.setString(6, "");
        ps.setInt(7, 0);
        ps.setString(8, "");

        return ps.executeUpdate() > 0;

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
    }

    /**
     * REMOVE ACCOUNT
     */
    public boolean removeStaff(String username) {

        try {
            String sql = "DELETE FROM ca_users WHERE username = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setString(1, username);

            int rows = ps.executeUpdate();

            return rows > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    public boolean deleteCustomer(int customerID) {

    try {
        String sql = "DELETE FROM ca_customers WHERE customer_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);

        ps.setInt(1, customerID);

        return ps.executeUpdate() > 0;

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
    }

    /**
     * UPDATE USER ROLE
     * Options are : "ADMIN", "STAFF", "CUSTOMER"
     */
    public boolean updateUserRole(String username, String roleName) {

        try {
            // Step 1: Convert role name → role_id
            int roleId = getRoleIdByName(roleName);

            if (roleId == -1) {
                System.out.println("Invalid role");
                return false;
            }

            // Step 2: Update user role in database
            String sql = "UPDATE ca_users SET role_id = ? WHERE username = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, roleId);
            ps.setString(2, username);

            int rows = ps.executeUpdate();

            return rows > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * GET ROLE NAME for GUI display
     */
    public String getUserRole(String username) {

        try {
            String sql = "SELECT r.role_name " +
                         "FROM ca_users u " +
                         "JOIN ca_roles r ON u.role_id = r.role_id " +
                         "WHERE u.username = ?";

            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, username);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getString("role_name");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * HELPER METHOD
     * Convert role name → role_id easier to read and what note
     */
    private int getRoleIdByName(String roleName) {

        try {
            String sql = "SELECT role_id FROM ca_roles WHERE role_name = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setString(1, roleName.toUpperCase());

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("role_id");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return -1; // role not found
    }
}