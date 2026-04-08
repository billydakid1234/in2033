

import merchant.SA_Merchant_API;
import java.sql.*;
import java.util.Map;
import database.DBConnection;

public class CA_OnlineOrderAPI_Impl implements CA_OnlineOrderAPI {

    private sa_orders.SA_ORD_API ordApi;
    private stock.CA_Stock_API_Impl stockApi;
    private SA_Merchant_API merchantApi;
    private Connection conn;

    

    public CA_OnlineOrderAPI_Impl(sa_orders.SA_ORD_API ordApi, SA_Merchant_API merchantApi, stock.CA_Stock_API_Impl stockApi, Connection conn) {
        this.ordApi = ordApi;
        this.merchantApi = merchantApi;
        this.stockApi = stockApi;
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
     * ============================
     * CALCULATE ORDER TOTAL (IMPORTANT FIX)
     * ============================
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
                double price = rs.getDouble("price");
                int qty = rs.getInt("quantity");

                total += price * qty;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return total;
    }

    /**
     * PAY USING CARD moved to merchant api
     */
    public boolean payByCard(String orderID, String cardNumber, String expiry) {

        double total = calculateOrderTotal(orderID);

        return merchantApi.processCardPayment(orderID, cardNumber, expiry, total);
    }

    /**
     * PAY USING CASH moved to merchant api
     */
    public boolean payByCash(String orderID) {

        double total = calculateOrderTotal(orderID);

        return merchantApi.processCashPayment(orderID, total);
    }

    /**
     * PAY USING CREDIT ACCOUNT moved to merchant api
     */
    public boolean payByCredit(String orderID, int customerID) {

        double total = calculateOrderTotal(orderID);

        return merchantApi.processCreditPayment(customerID, total);
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

    @Override
    public boolean payByCash(String orderID, double amount) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'payByCash'");
    }

    @Override
    public boolean payByCredit(String orderID, int customerID, double amount) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'payByCredit'");
    }
}


