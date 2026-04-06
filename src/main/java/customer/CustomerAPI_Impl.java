/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package customer;

import database.DBConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

/**
 *
 * @author laraashour
 */
public class CustomerAPI_Impl implements CustomerAPI  {
    
    private int parseCustomerId(String accountId) throws Exception {
        if (accountId == null || !accountId.matches("ACC\\d+")) {
            throw new Exception("Invalid account ID format. Expected ACC followed by numbers.");
        }
        return Integer.parseInt(accountId.substring(3));
    }

    private String formatAccountId(int customerId) {
        return String.format("ACC%03d", customerId);
    }

@Override
public boolean addCustomer(String firstName,
                           String surname,
                           String dob,
                           String email,
                           String phone,
                           int houseNumber,
                           String postcode,
                           double creditLimit) throws Exception {

    String sql = "INSERT INTO ca_customers " +
                 "(firstname, surname, dob, email, phone, houseNumber, postcode, credit_limit, outstanding_balance, account_status, account_holder) " +
                 "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        if (conn == null) {
            throw new Exception("Database connection failed.");
        }

        ps.setString(1, firstName);
        ps.setString(2, surname);
        ps.setString(3, dob);
        ps.setString(4, email);
        ps.setString(5, phone);
        ps.setInt(6, houseNumber);
        ps.setString(7, postcode);
        ps.setDouble(8, creditLimit);
        ps.setDouble(9, 0.0);
        ps.setString(10, "NORMAL");
        ps.setInt(11, 1);

        return ps.executeUpdate() > 0;
    }
}

    @Override
    public List<Customer> getAllCustomers() throws Exception {
        List<Customer> customers = new ArrayList<>();

        String sql = "SELECT customer_id, firstname, surname, email, phone, credit_limit, outstanding_balance, account_status " +
                     "FROM ca_customers";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (conn == null) {
                throw new Exception("Database connection failed.");
            }

            while (rs.next()) {
                int customerId = rs.getInt("customer_id");

                customers.add(new Customer(
                    formatAccountId(customerId),
                    rs.getString("firstname"),
                    rs.getString("surname"),
                    rs.getString("email"),
                    rs.getString("phone"),
                    rs.getDouble("credit_limit"),
                    rs.getString("account_status"),
                    rs.getDouble("outstanding_balance")
                ));
            }
        }

        return customers;
    }

    @Override
    public boolean deleteCustomer(String accountId) throws Exception {
        int customerId = parseCustomerId(accountId);

        String sql = "DELETE FROM ca_customers WHERE customer_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (conn == null) {
                throw new Exception("Database connection failed.");
            }

            ps.setInt(1, customerId);
            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public boolean customerExists(String accountId) throws Exception {
        int customerId = parseCustomerId(accountId);

        String sql = "SELECT 1 FROM ca_customers WHERE customer_id = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (conn == null) {
                throw new Exception("Database connection failed.");
            }

            ps.setInt(1, customerId);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }
        
        
    public void normaliseStatuses() throws Exception {
    String sql1 = "UPDATE ca_customers SET account_status = 'NORMAL' WHERE account_status = 'ACTIVE'";
    String sql2 = "UPDATE ca_customers SET account_status = 'IN_DEFAULT' WHERE account_status = 'CLOSED'";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps1 = conn.prepareStatement(sql1);
         PreparedStatement ps2 = conn.prepareStatement(sql2)) {

        if (conn == null) {
            throw new Exception("Database connection failed.");
        }

        ps1.executeUpdate();
        ps2.executeUpdate();
   
        }
    }
    
    @Override
public void updateAccountStatuses() throws Exception {
    String suspendSql =
        "UPDATE ca_customers " +
        "SET account_status = 'SUSPENDED' " +
        "WHERE account_holder = 1 " +
        "AND outstanding_balance > 0 " +
        "AND outstanding_balance <= credit_limit";

    String defaultSql =
        "UPDATE ca_customers " +
        "SET account_status = 'IN_DEFAULT' " +
        "WHERE account_holder = 1 " +
        "AND outstanding_balance > credit_limit";

    String normalSql =
        "UPDATE ca_customers " +
        "SET account_status = 'NORMAL' " +
        "WHERE account_holder = 1 " +
        "AND outstanding_balance <= 0";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement psSuspend = conn.prepareStatement(suspendSql);
         PreparedStatement psDefault = conn.prepareStatement(defaultSql);
         PreparedStatement psNormal = conn.prepareStatement(normalSql)) {

        if (conn == null) {
            throw new Exception("Database connection failed.");
        }

        psSuspend.executeUpdate();
        psDefault.executeUpdate();
        psNormal.executeUpdate();
    }
    
    }
}
