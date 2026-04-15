

import java.sql.*;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import database.DBConnection;
import stock.CA_Stock_API_Impl;

public class SA_ORD_API {

    private Connection conn;

    private CA_Stock_API_Impl stockApi;

    // how to connect to the database and run queries will be in all classes to connect and change the database
public SA_ORD_API(Connection conn) {
    this.conn = conn;
    this.stockApi = new CA_Stock_API_Impl(conn);
}

    /**
     * Create new order
     */
    public String newOrder() {
        // Generate a unique order ID using UUID
        String orderID = UUID.randomUUID().toString();

        try {
            // sql to insert order into the database with the generated order ID and default processed status as false            
            String sql = "INSERT INTO ca_online_orders (online_order_id, processed) VALUES (?, FALSE)";
            // PreparedStatement is used to insert values into SQL
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, orderID);
            // Execute the SQL 
            ps.executeUpdate();

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return orderID;
    }

    /**
     * Add items to order
     */
    public void addItems(String orderID, int[] itemIDs, int[] quantities) {

        try {
            //Loop through all items being added
            for (int i = 0; i < itemIDs.length; i++) {

                 //Ignore 0 or -ive quantities 
                if (quantities[i] <= 0) continue;

                String sql = "INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (?, ?, ?, ?)";
                PreparedStatement ps = conn.prepareStatement(sql);

                //so no id is the same as its a primary key and doesnt use auto increment
                ps.setInt(1, (int)(Math.random() * 100000)); 
                ps.setString(2, orderID);
                ps.setInt(3, itemIDs[i]);
                ps.setInt(4, quantities[i]);

                ps.executeUpdate();
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * Remove items from order
     */
    public void removeItems(String orderID, int[] itemIDs, int[] quantities) {

        try {
            for (int i = 0; i < itemIDs.length; i++) {

                String select = "SELECT quantity FROM ca_online_order_items WHERE online_order_id = ? AND product_id = ?";
                PreparedStatement psSelect = conn.prepareStatement(select);
                psSelect.setString(1, orderID);
                psSelect.setInt(2, itemIDs[i]);

                ResultSet rs = psSelect.executeQuery();

                // If the item exists in the order
                if (rs.next()) {

                    int currentQty = rs.getInt("quantity");

                    // Calculate new quantity after removal
                    int newQty = currentQty - quantities[i];

                    if (newQty > 0) {
                        // If still some left → UPDATE quantity
                        String update = "UPDATE ca_online_order_items SET quantity = ? WHERE online_order_id = ? AND product_id = ?";
                        PreparedStatement psUpdate = conn.prepareStatement(update);
                        psUpdate.setInt(1, newQty);
                        psUpdate.setString(2, orderID);
                        psUpdate.setInt(3, itemIDs[i]);
                        psUpdate.executeUpdate();

                    } else {
                         // If quantity becomes 0 or less → DELETE item completely
                        String delete = "DELETE FROM ca_online_order_items WHERE online_order_id = ? AND product_id = ?";
                        PreparedStatement psDelete = conn.prepareStatement(delete);
                        psDelete.setString(1, orderID);
                        psDelete.setInt(2, itemIDs[i]);
                        psDelete.executeUpdate();
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * Submit order (check stock + reduce stock)
     */
    public void submitOrder(String orderID) {

    try {
        String query = "SELECT product_id, quantity FROM ca_online_order_items WHERE online_order_id = ?";
        PreparedStatement ps = conn.prepareStatement(query);
        ps.setString(1, orderID);

        ResultSet rs = ps.executeQuery();

        Map<Integer, Integer> items = new HashMap<>();

        while (rs.next()) {
            items.put(rs.getInt("product_id"), rs.getInt("quantity"));
        }

        if (items.isEmpty()) {
            System.out.println("Order is empty.");
            return;
        }

        // Check stock via Stock API
        for (Map.Entry<Integer, Integer> e : items.entrySet()) {

            int stock = stockApi.getStockLevel(e.getKey());

            if (stock < e.getValue()) {
                System.out.println("Order rejected: not enough stock for product " + e.getKey());
                return;
            }
        }

        // Reduce stock via Stock API
        for (Map.Entry<Integer, Integer> e : items.entrySet()) {
            int currentStock = stockApi.getStockLevel(e.getKey());
            stockApi.updateStockQuantity(e.getKey(), currentStock - e.getValue());
        }

        // Mark order processed
        String updateOrder = "UPDATE ca_online_orders SET processed = TRUE WHERE online_order_id = ?";
        PreparedStatement psUpdateOrder = conn.prepareStatement(updateOrder);
        psUpdateOrder.setString(1, orderID);
        psUpdateOrder.executeUpdate();

        System.out.println("Order accepted: " + orderID);

    } catch (SQLException e) {
        e.printStackTrace();
    }
    }

    /**
     * View order (readable)
     */
    public Map<String, Integer> viewOrder(String orderID) {

        Map<String, Integer> result = new HashMap<>();

        try {
            // JOIN combines product names with order items
            String query = "SELECT p.product_name, i.quantity " +
               "FROM ca_online_order_items i " +
               "JOIN ca_products p ON i.product_id = p.product_id " +
               "WHERE i.online_order_id = ?";

            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, orderID);

            ResultSet rs = ps.executeQuery();

            // Store results as (product_name -> quantity)
            while (rs.next()) {
                result.put(rs.getString("product_name"), rs.getInt("quantity"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }

    /**
     * View stock
     */
    public Map<String, Integer> viewStock() {

        Map<String, Integer> result = new HashMap<>();

        try {
            String query = "SELECT p.product_name, s.quantity " +
               "FROM ca_stock s " +
               "JOIN ca_products p ON s.product_id = p.product_id";

            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(query);

            while (rs.next()) {
                result.put(rs.getString("product_name"), rs.getInt("quantity"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return result;
    }

    /**
     * Get catalogue
     */
    public Map<Integer, String> getCatalogue() {

        Map<Integer, String> catalogue = new HashMap<>();

        try {
            String query = "SELECT product_id, product_name FROM ca_products";
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(query);

            while (rs.next()) {
                catalogue.put(rs.getInt("product_id"), rs.getString("product_name"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return catalogue;
    }
    
public Map<Integer, Integer> getOrderItems(String orderID) {
    Map<Integer, Integer> items = new HashMap<>();

    try {
        String sql = "SELECT product_id, quantity FROM ca_online_order_items WHERE online_order_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, orderID);

        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            items.put(rs.getInt("product_id"), rs.getInt("quantity"));
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return items;
}

public boolean updateOrderStatus(String orderID, String status) {
    try {
        String sql = "UPDATE ca_online_orders SET status = ? WHERE online_order_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, status);
        ps.setString(2, orderID);

        return ps.executeUpdate() > 0;

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

public String getLocalOrderStatus(String orderID) {
    try {
        String sql = "SELECT status FROM ca_online_orders WHERE online_order_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, orderID);

        ResultSet rs = ps.executeQuery();

        if (rs.next()) {
            return rs.getString("status");
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return null;
} 

    
}






