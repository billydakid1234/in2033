package sa_orders;


import java.sql.*;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

public class SA_ORD_API {

    private Connection conn;
    private SA_Catalogue_API catalogueApi;

    // how to connect to the database and run queries will be in all classes to connect and change the database
    public SA_ORD_API(Connection conn) {
        this.conn = conn;
        this.catalogueApi = new SA_Catalogue_API(conn);
    }

    private int getNextOnlineOrderItemId() throws SQLException {
        String sql = "SELECT COALESCE(MAX(online_order_item_id), 0) + 1 AS next_id FROM ca_online_order_items";
        PreparedStatement ps = conn.prepareStatement(sql);
        ResultSet rs = ps.executeQuery();
        return rs.next() ? rs.getInt("next_id") : 1;
    }

    /**
     * Create new order
     */
    public String newOrder() {
        // Generate a readable ONL order ID.
        String orderID = "ONL-" + java.time.LocalDateTime.now()
            .format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
            + "-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();

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
            int nextItemId = getNextOnlineOrderItemId();

            //Loop through all items being added
            for (int i = 0; i < itemIDs.length; i++) {

                 //Ignore 0 or -ive quantities 
                if (quantities[i] <= 0) continue;

                String sql = "INSERT INTO ca_online_order_items (online_order_item_id, online_order_id, product_id, quantity) VALUES (?, ?, ?, ?)";
                PreparedStatement ps = conn.prepareStatement(sql);

                ps.setInt(1, nextItemId++);
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
            // Get items in order
            String query = "SELECT product_id, quantity FROM ca_online_order_items WHERE online_order_id = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, orderID);

            ResultSet rs = ps.executeQuery();

            //store items temporarily in a map
            Map<Integer, Integer> items = new HashMap<>();

            while (rs.next()) {
                items.put(rs.getInt("product_id"), rs.getInt("quantity"));
            }

            // no items in the order
            if (items.isEmpty()) {
                System.out.println("Order is empty.");
                return;
            }

            // 2. Check stock for the items in the order
            for (Map.Entry<Integer, Integer> e : items.entrySet()) {

                String stockQuery = "SELECT quantity FROM ca_stock WHERE product_id = ?";
                PreparedStatement psStock = conn.prepareStatement(stockQuery);
                psStock.setInt(1, e.getKey());

                ResultSet rsStock = psStock.executeQuery();

                if (rsStock.next()) {
                    int stock = rsStock.getInt("quantity");

                    if (stock < e.getValue()) {
                        System.out.println("Order rejected: not enough stock for product " + e.getKey());
                        return;
                    }
                }
            }

            // 3. Reduce stock in the database for the items in the order
            for (Map.Entry<Integer, Integer> e : items.entrySet()) {

                String update = "UPDATE ca_stock SET quantity = quantity - ? WHERE product_id = ?";
                PreparedStatement psUpdate = conn.prepareStatement(update);

                psUpdate.setInt(1, e.getValue());
                psUpdate.setInt(2, e.getKey());
                psUpdate.executeUpdate();
            }

            // 4. Mark order processed
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
        return catalogueApi.getCatalogue("");
    }

    public Map<Integer, String> searchCatalogue(String searchTerm) {
        return catalogueApi.getCatalogue(searchTerm);
    }

    
    
    
    public ResultSet getAllOrders() {
        
    try {
        String query =
            "SELECT " +
            "  o.online_order_id AS order_ref, " +
            "  COALESCE(o.received_at, CURRENT_TIMESTAMP) AS order_date, " +
            "  CASE WHEN o.processed = 1 THEN 'Processed' ELSE 'Pending' END AS status, " +
            "  i.product_id AS product_id, " +
            "  i.quantity AS quantity, " +
            "  (i.quantity * COALESCE(p.price, 0)) AS total_cost " +
            "FROM ca_online_orders o " +
            "JOIN ca_online_order_items i ON o.online_order_id = i.online_order_id " +
            "LEFT JOIN ca_products p ON p.product_id = i.product_id " +
            "ORDER BY order_date DESC";

        PreparedStatement ps = conn.prepareStatement(query);
        return ps.executeQuery();

    } catch (SQLException e) {
        e.printStackTrace();
        return null;
    }
}
    
    
}