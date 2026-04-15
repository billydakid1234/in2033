package stock;

import main.java.PU_COMMS_API;
import main.java.PU_COMMS_API_Impl;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CA_Stock_API_Impl {

    private final Connection conn;
    private final PU_COMMS_API puCommsApi;

    public CA_Stock_API_Impl(Connection conn) {
        this(conn, new PU_COMMS_API_Impl());
    }

    public CA_Stock_API_Impl(Connection conn, PU_COMMS_API puCommsApi) {
        this.conn = conn;
        this.puCommsApi = puCommsApi != null ? puCommsApi : new PU_COMMS_API_Impl();
    }

    /**
     * ADD NEW STOCK ITEM
     */
    public boolean addStock(int productId, int quantity, int lowerBound) {
        if (conn == null) return false;

        try {
            String sql = "INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, productId);
            ps.setInt(2, quantity);
            ps.setInt(3, lowerBound);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }


    public boolean addNewProductWithStock(int productId, String productName, double price,
                                          double vatRate, String productType, String description,
                                          int quantity, int lowStockThreshold) {
        if (conn == null) return false;

        try {
            conn.setAutoCommit(false);

            String productSql = "INSERT INTO ca_products (product_id, product_name, price, vat_rate, product_type, description) VALUES (?, ?, ?, ?, ?, ?)";
            PreparedStatement psProduct = conn.prepareStatement(productSql);
            psProduct.setInt(1, productId);
            psProduct.setString(2, productName);
            psProduct.setDouble(3, price);
            psProduct.setDouble(4, vatRate);
            psProduct.setString(5, productType);
            psProduct.setString(6, description);
            psProduct.executeUpdate();

            String stockSql = "INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (?, ?, ?)";
            PreparedStatement psStock = conn.prepareStatement(stockSql);
            psStock.setInt(1, productId);
            psStock.setInt(2, quantity);
            psStock.setInt(3, lowStockThreshold);
            psStock.executeUpdate();

            conn.commit();
            return true;

        } catch (SQLException e) {
            try {
                conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
            e.printStackTrace();
            return false;

        } finally {
            try {
                conn.setAutoCommit(true);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }



    /**
     * MODIFY STOCK QUANTITY so +10 or -2
     */
    public boolean updateStockQuantity(int productId, int newQuantity) {

        if (conn == null) return false;

        if (newQuantity < 0) {
            System.out.println("Stock cannot be negative");
            return false;
        }

        try {
            String sql = "UPDATE ca_stock SET quantity = ? WHERE product_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, newQuantity);
            ps.setInt(2, productId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }
    /**
     * REMOVE STOCK ITEM
     */
    public boolean removeStock(int productId) {
        if (conn == null) return false;

        try {
            String sql = "DELETE FROM ca_stock WHERE product_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, productId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }


    public boolean productExists(int productId) {
        if (conn == null) return false;

        try {
            String sql = "SELECT 1 FROM ca_products WHERE product_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, productId);
            ResultSet rs = ps.executeQuery();
            return rs.next();
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * LIST ITEMS BELOW LOWER BOUND
     */
    public List<String> getLowStockItems() {
        List<String> lowStock = new ArrayList<>();

        if (conn == null) return lowStock;

        try {
            String sql =
                    "SELECT s.product_id, p.product_name, s.quantity, s.low_stock_threshold " +
                            "FROM ca_stock s " +
                            "JOIN ca_products p ON s.product_id = p.product_id " +
                            "WHERE s.quantity < s.low_stock_threshold";

            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                String item = String.format(
                        "%s (ID: %d) | Qty: %d | Low Bound: %d",
                        rs.getString("product_name"),
                        rs.getInt("product_id"),
                        rs.getInt("quantity"),
                        rs.getInt("low_stock_threshold")
                );
                lowStock.add(item);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return lowStock;
    }



    public List<Object[]> getAllStockItems() {
        List<Object[]> items = new ArrayList<>();

        if (conn == null) return items;

        try {
            String sql =
                    "SELECT s.product_id, p.product_name, s.quantity, s.low_stock_threshold, p.price, p.product_type " +
                            "FROM ca_stock s " +
                            "JOIN ca_products p ON s.product_id = p.product_id";

            PreparedStatement ps = conn.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                items.add(new Object[]{
                        rs.getInt("product_id"),
                        rs.getString("product_name"),
                        rs.getInt("quantity"),
                        rs.getInt("low_stock_threshold"),
                        rs.getDouble("price"),
                        rs.getString("product_type")
                });
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return items;
    }


public boolean recordDelivery(int productId, int quantity) {
    return recordDelivery(productId, quantity, null);
}

    /**
     * RECORD DELIVERY (increase stock from SA)
     */
public boolean recordDelivery(int productId, int quantity, String email) {
    if (conn == null) return false;

    // Basic validation
    if (quantity <= 0) {
        System.out.println("Invalid delivery quantity");
        return false;
    }

    try {
        // Try to UPDATE existing stock
        String sql = "UPDATE ca_stock SET quantity = quantity + ? WHERE product_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);

        ps.setInt(1, quantity);
        ps.setInt(2, productId);

        int rows = ps.executeUpdate();

        if (rows > 0) {
            // Product exists so updated
            System.out.println("Delivery recorded: +" + quantity + " for product " + productId);

        } else {
            // Product does not exist so INSERT it
            System.out.println("Product not found → inserting new stock row");

            String insert = "INSERT INTO ca_stock (product_id, quantity, low_stock_threshold) VALUES (?, ?, ?)";
            PreparedStatement psInsert = conn.prepareStatement(insert);

            psInsert.setInt(1, productId);
            psInsert.setInt(2, quantity);
            psInsert.setInt(3, 10); // default threshold

            psInsert.executeUpdate();

            System.out.println("New product added to stock with quantity " + quantity);
        }

        //Optional email (unchanged)
        if (puCommsApi != null && email != null && !email.isBlank()) {
            String subject = "Stock Delivery Recorded";
            String content = "<html><body>"
                    + "<h3>Stock Delivery Update</h3>"
                    + "<p>Product ID: " + productId + "</p>"
                    + "<p>Quantity added: " + quantity + "</p>"
                    + "</body></html>";

            puCommsApi.sendEmail(email, subject, content);
        }

        return true;

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

    /**
     * GET CURRENT STOCK LEVEL
     */
    public int getStockLevel(int productId) {
        if (conn == null) return 0;
        try {
            String sql = "SELECT quantity FROM ca_stock WHERE product_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, productId);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt("quantity");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }
}