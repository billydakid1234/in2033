import io.javalin.Javalin;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import stock.CA_Stock_API_Impl;
import database.DBConnection;

public class MockSubsystemSA {

    public static void main(String[] args) {

        final int port = Integer.parseInt(System.getenv().getOrDefault("SA_API_PORT", "8083"));

        System.out.println("Starting Mock Subsystem SA (Stock Delivery API) on port " + port + "...");

        Connection conn = DBConnection.getConnection();
        CA_Stock_API_Impl stockApi = new CA_Stock_API_Impl(conn);

        Javalin app = Javalin.create().start(port);

        app.get("/health", ctx -> ctx.json(Map.of("status", "ok")));
        app.get("/api/ipos_sa/health", ctx -> ctx.json(Map.of("status", "ok")));

        app.get("/api/ipos_sa/catalogue", ctx -> {
            String search = ctx.queryParam("search");
            if (search == null) {
                search = "";
            }
            handleCatalogue(conn, search, ctx);
        });

        app.get("/api/stock/catalogue", ctx -> {
            String search = ctx.queryParam("search");
            if (search == null) {
                search = "";
            }
            handleCatalogue(conn, search, ctx);
        });

        // Namespaced SA route (similar style to other subsystem mocks)
        app.post("/api/ipos_sa/delivery", ctx -> {
            handleDelivery(ctx.bodyAsClass(Map.class), stockApi, ctx);
        });

        // Backward-compatible route already used in your tests/curl commands
        app.post("/api/stock/delivery", ctx -> {
            handleDelivery(ctx.bodyAsClass(Map.class), stockApi, ctx);
        });
    }

    private static void handleDelivery(Map<String, Object> body, CA_Stock_API_Impl stockApi, io.javalin.http.Context ctx) {
        try {
            Object productObj = body.get("product_id");
            Object quantityObj = body.get("quantity");

            if (!(productObj instanceof Number) || !(quantityObj instanceof Number)) {
                ctx.status(400).json(Map.of("status", "failed", "error", "product_id and quantity must be numeric"));
                return;
            }

            int productId = ((Number) productObj).intValue();
            int quantity = ((Number) quantityObj).intValue();

            if (quantity <= 0) {
                ctx.status(400).json(Map.of("status", "failed", "error", "quantity must be > 0"));
                return;
            }

            boolean result = stockApi.recordDelivery(productId, quantity);

            if (result) {
                ctx.json(Map.of("status", "success"));
            } else {
                ctx.status(400).json(Map.of("status", "failed", "error", "product not found or invalid data"));
            }
        } catch (Exception e) {
            ctx.status(400).json(Map.of("status", "failed", "error", "invalid payload"));
        }
    }

    private static void handleCatalogue(Connection conn, String search, io.javalin.http.Context ctx) {
        String sql = "SELECT product_id, product_name FROM ca_products WHERE LOWER(product_name) LIKE ? ORDER BY product_name";
        String searchTerm = search == null ? "" : search.trim().toLowerCase();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "%" + searchTerm + "%");

            List<Map<String, Object>> items = new ArrayList<>();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("product_id", rs.getInt("product_id"));
                    row.put("product_name", rs.getString("product_name"));
                    items.add(row);
                }
            }

            ctx.json(Map.of("status", "success", "items", items));
        } catch (Exception e) {
            ctx.status(500).json(Map.of("status", "failed", "error", "unable to fetch catalogue"));
        }
    }
}