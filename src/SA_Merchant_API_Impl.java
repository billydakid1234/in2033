import java.sql.*;

public class SA_Merchant_API_Impl {

    private Connection conn;

    public SA_Merchant_API_Impl(Connection conn) {
        this.conn = conn;
    }

    /**
     * CALCULATE ORDER TOTAL
     */
    private double calculateOrderTotal(String orderID) {

        double total = 0;

        try {
            String sql =
                "SELECT p.price, i.quantity " +
                "FROM ca_online_order_items i " +
                "JOIN ca_products p ON i.product_id = p.product_id " +
                "WHERE i.online_order_id = ?";

            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, orderID);

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                total += rs.getDouble("price") * rs.getInt("quantity");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return total;
    }

    /**
     * PAY BY CARD
     */
    public boolean payByCard(String orderID, String cardNumber) {

        try {
            if (cardNumber.length() < 8) {
                System.out.println("Invalid card");
                return false;
            }

            double total = calculateOrderTotal(orderID);

            String sql = "INSERT INTO ca_payments (payment_id, payment_method, amount) VALUES (?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, (int)(Math.random() * 100000));
            ps.setString(2, "CARD");
            ps.setDouble(3, total);

            ps.executeUpdate();

            System.out.println("Card payment successful: £" + total);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * PAY BY CASH
     */
    public boolean payByCash(String orderID) {

        try {
            double total = calculateOrderTotal(orderID);

            String sql = "INSERT INTO ca_payments (payment_id, payment_method, amount) VALUES (?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, (int)(Math.random() * 100000));
            ps.setString(2, "CASH");
            ps.setDouble(3, total);

            ps.executeUpdate();

            System.out.println("Cash payment successful: £" + total);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * 
     * PAY BY CREDIT
     * 
     */
    public boolean payByCredit(String orderID, int customerID) {

        try {
            double total = calculateOrderTotal(orderID);

            String sql = "SELECT credit_limit, outstanding_balance, account_status FROM ca_customers WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerID);

            ResultSet rs = ps.executeQuery();

            if (!rs.next()) return false;

            double limit = rs.getDouble("credit_limit");
            double balance = rs.getDouble("outstanding_balance");
            String status = rs.getString("account_status");

            if (!status.equalsIgnoreCase("ACTIVE")) {
                System.out.println("Account not active");
                return false;
            }

            if (balance + total > limit) {
                System.out.println("Credit limit exceeded");
                return false;
            }

            // Update balance
            String update = "UPDATE ca_customers SET outstanding_balance = outstanding_balance + ? WHERE customer_id = ?";
            PreparedStatement psUpdate = conn.prepareStatement(update);
            psUpdate.setDouble(1, total);
            psUpdate.setInt(2, customerID);
            psUpdate.executeUpdate();

            // Record payment
            String insert = "INSERT INTO ca_payments (payment_id, customer_id, payment_method, amount) VALUES (?, ?, ?, ?)";
            PreparedStatement psInsert = conn.prepareStatement(insert);

            psInsert.setInt(1, (int)(Math.random() * 100000));
            psInsert.setInt(2, customerID);
            psInsert.setString(3, "CREDIT");
            psInsert.setDouble(4, total);

            psInsert.executeUpdate();

            System.out.println("Credit payment successful: £" + total);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * CHECK ACCOUNT BALANCE
     */
    public double getCustomerBalance(int customerID) {

        try {
            String sql = "SELECT outstanding_balance FROM ca_customers WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerID);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getDouble("outstanding_balance");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    /**
     * SET CREDIT LIMIT
     */
    public boolean setCreditLimit(int customerID, double limit) {

        try {
            String sql = "UPDATE ca_customers SET credit_limit = ? WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setDouble(1, limit);
            ps.setInt(2, customerID);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }


    /**
     * Update account status (ACTIVE / SUSPENDED / DEFAULT)
     */
    public boolean updateAccountStatus(int customerID, String status) {

        try {
            String sql = "UPDATE ca_customers SET account_status = ? WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setString(1, status.toUpperCase());
            ps.setInt(2, customerID);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }
}