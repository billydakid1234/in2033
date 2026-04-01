import java.sql.*;
import java.util.Map;

public class CA_OnlineOrderAPI_Impl implements CA_OnlineOrderAPI {

    private SA_ORD_API ordApi;
    private Connection conn;

    public CA_OnlineOrderAPI_Impl(SA_ORD_API ordApi, Connection conn) {
        this.ordApi = ordApi;
        this.conn = conn;
    }

    /**
     * Process online order
     * basket format: 1:2,2:1
     */
    @Override
    public void processOnlineOrder(String orderID, String basketOrder) {

        String[] items = basketOrder.split(",");

        int[] itemIDs = new int[items.length];
        int[] quantities = new int[items.length];

        for (int i = 0; i < items.length; i++) {
            String[] parts = items[i].split(":");
            itemIDs[i] = Integer.parseInt(parts[0]);
            quantities[i] = Integer.parseInt(parts[1]);
        }

        // Use existing ORD methodss (already DB-based)
        ordApi.addItems(orderID, itemIDs, quantities);
        ordApi.submitOrder(orderID);

        // Mark as processed in DB
        try {
            String sql = "UPDATE ca_online_orders SET processed = TRUE WHERE online_order_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, orderID);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * Check stock directly from DB
     */
    @Override
    public int checkProductStock(String productID) {

        try {
            String sql = "SELECT quantity FROM ca_stock WHERE product_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, Integer.parseInt(productID));

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("quantity");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    /**
     * Search catalogue using DB
     */
    @Override
    public String[] getMerchantCatalogue(String searchTerm) {

        try {
            String sql = "SELECT product_id, product_name FROM ca_products WHERE LOWER(product_name) LIKE ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setString(1, "%" + searchTerm.toLowerCase() + "%");

            ResultSet rs = ps.executeQuery();

            // Temporary storage
            java.util.List<String> results = new java.util.ArrayList<>();

            while (rs.next()) {
                results.add(rs.getInt("product_id") + " - " + rs.getString("product_name"));
            }

            return results.toArray(new String[0]);

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return new String[0];
    }

    /**
     * Pay by card payment in db
     */
    @Override
    public boolean payByCard(String orderID, String cardNumber, String expiry) {

        try {
            // Check order exists
            String check = "SELECT online_order_id FROM ca_online_orders WHERE online_order_id = ?";
            PreparedStatement psCheck = conn.prepareStatement(check);
            psCheck.setString(1, orderID);

            ResultSet rs = psCheck.executeQuery();

            if (!rs.next()) {
                System.out.println("Payment failed: order not found");
                return false;
            }

            // Basic validation
            if (cardNumber.length() < 8) {
                System.out.println("Payment failed: invalid card");
                return false;
            }

            // Insert payment record
            String sql = "INSERT INTO ca_payments (payment_id, sale_id, payment_method, amount) VALUES (?, NULL, ?, ?)";

            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, (int)(Math.random() * 100000)); // TEMP ID
            ps.setString(2, "CARD");
            ps.setDouble(3, 0.0); // you can calculate real total later

            ps.executeUpdate();

            System.out.println("Payment successful for order: " + orderID);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Pay by cash
     * Used mainly for non-account customers
     */
    @Override
    public boolean payByCash(String orderID, double amount) {

        try {
            // check order exists
            String check = "SELECT online_order_id FROM ca_online_orders WHERE online_order_id = ?";
            PreparedStatement psCheck = conn.prepareStatement(check);
            psCheck.setString(1, orderID);

            ResultSet rs = psCheck.executeQuery();

            if (!rs.next()) {
                System.out.println("Cash payment failed: order not found");
                return false;
            }

            //insert payment
            String sql = "INSERT INTO ca_payments (payment_id, payment_method, amount) VALUES (?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, (int)(Math.random() * 100000)); // TEMP
            ps.setString(2, "CASH");
            ps.setDouble(3, amount);

            ps.executeUpdate();

            System.out.println("Cash payment successful for order: " + orderID);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * pay using customer credit account
     */
    public boolean payByCredit(String orderID, int customerID, double amount) {

        try {
            //get customer's credit info
            String sqlCustomer = "SELECT credit_limit, outstanding_balance, account_status FROM ca_customers WHERE customer_id = ?";
            PreparedStatement psCustomer = conn.prepareStatement(sqlCustomer);
            psCustomer.setInt(1, customerID);

            ResultSet rs = psCustomer.executeQuery();

            if (!rs.next()) {
                System.out.println("Credit payment failed: customer not found");
                return false;
            }

            double creditLimit = rs.getDouble("credit_limit");
            double balance = rs.getDouble("outstanding_balance");
            String status = rs.getString("account_status");

            // check account is active
            if (!status.equalsIgnoreCase("ACTIVE")) {
                System.out.println("Credit payment failed: account not active");
                return false;
            }

            
            if ((balance + amount) > creditLimit) {
                System.out.println("Credit payment failed: credit limit exceeded");
                return false;
            }

            String updateBalance = "UPDATE ca_customers SET outstanding_balance = outstanding_balance + ? WHERE customer_id = ?";
            PreparedStatement psUpdate = conn.prepareStatement(updateBalance);

            psUpdate.setDouble(1, amount);
            psUpdate.setInt(2, customerID);
            psUpdate.executeUpdate();

            // record payment
            String insertPayment = "INSERT INTO ca_payments (payment_id, customer_id, payment_method, amount) VALUES (?, ?, ?, ?)";
            PreparedStatement psPayment = conn.prepareStatement(insertPayment);

            psPayment.setInt(1, (int)(Math.random() * 100000)); // TEMP
            psPayment.setInt(2, customerID);
            psPayment.setString(3, "CREDIT");
            psPayment.setDouble(4, amount);

            psPayment.executeUpdate();

            System.out.println("Credit payment successful for order: " + orderID);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Generate receipt 
     */
    @Override
    public String generateReceipt(String orderID) {

        try {
            // Check if order is processed
            String check = "SELECT processed FROM ca_online_orders WHERE online_order_id = ?";
            PreparedStatement psCheck = conn.prepareStatement(check);
            psCheck.setString(1, orderID);

            ResultSet rsCheck = psCheck.executeQuery();

            if (!rsCheck.next() || !rsCheck.getBoolean("processed")) {
                return "Cannot generate receipt: order not processed.";
            }

            // Get order items
            Map<String, Integer> order = ordApi.viewOrder(orderID);

            if (order == null || order.isEmpty()) {
                return "Order not found.";
            }

            StringBuilder receipt = new StringBuilder();
            receipt.append("Receipt for Order: ").append(orderID).append("\n");

            int totalItems = 0;

            for (Map.Entry<String, Integer> entry : order.entrySet()) {
                receipt.append(entry.getKey())
                        .append(" x ")
                        .append(entry.getValue())
                        .append("\n");

                totalItems += entry.getValue();
            }

            receipt.append("Total items: ").append(totalItems);

            return receipt.toString();

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return "Error generating receipt.";
    }

    /**
     * Track order status using DB
     */
    @Override
    public String getOrderStatus(String orderID) {

        try {
            String sql = "SELECT processed FROM ca_online_orders WHERE online_order_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setString(1, orderID);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getBoolean("processed") ? "PROCESSED" : "CREATED";
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return "UNKNOWN";
    }

    /**
     * Create new order
     */
    public String createOrder() {
        return ordApi.newOrder(); // already inserts into DB
    }
}