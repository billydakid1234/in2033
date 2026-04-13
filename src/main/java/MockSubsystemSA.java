package main.java;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.javalin.Javalin;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import database.DBConnection;

public class MockSubsystemSA {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static volatile boolean started = false;

    public static synchronized void startInBackground() {
        if (started) {
            return;
        }

        Thread apiThread = new Thread(() -> {
            try {
                startServer();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }, "sa-stock-api");
        apiThread.setDaemon(true);
        apiThread.start();
    }

    public static void main(String[] args) {
        try {
            startServer();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static synchronized void startServer() {
        if (started) {
            return;
        }

        final int port = Integer.parseInt(System.getenv().getOrDefault("SA_API_PORT", "8081"));

        System.out.println("Starting Mock Subsystem SA (Stock Delivery API) on port " + port + "...");

        Connection conn = DBConnection.getConnection();

        Javalin app = Javalin.create().start(port);

        app.get("/health", ctx -> ctx.json(Map.of("status", "ok")));
        app.get("/api/ipos_sa/health", ctx -> ctx.json(Map.of("status", "ok")));

        app.get("/api/ipos_sa/sa_ord_api/newOrder", ctx -> {
            String username = ctx.queryParam("username");
            String orderId = createSupplierOrder(conn, username);

            if (orderId == null) {
                ctx.status(500).json(Map.of("status", "failed", "error", "unable to create supplier order"));
                return;
            }

            ctx.json(Map.of(
                "status", "success",
                "orderId", orderId,
                "username", username == null ? "" : username,
                "message", "Supplier order created"
            ));
        });

        app.post("/api/ipos_sa/sa_ord_api/addItems", ctx -> {
            Map<String, Object> body = readJsonBody(ctx);
            String orderId = stringValue(body.get("orderId"));
            List<Integer> itemIds = intList(body.get("itemId"));
            List<Integer> quantities = intList(body.get("quantity"));

            if (orderId.isBlank() || itemIds.isEmpty() || itemIds.size() != quantities.size()) {
                ctx.status(400).json(Map.of("status", "failed", "error", "orderId, itemId and quantity are required"));
                return;
            }

            int affected = upsertOrderItems(conn, orderId, itemIds, quantities, true);
            if (affected < 0) {
                ctx.status(400).json(Map.of("status", "failed", "error", "unable to add items to supplier order"));
                return;
            }

            ctx.json(Map.of(
                "status", "success",
                "orderId", orderId,
                "itemsAdded", affected
            ));
        });

        app.post("/api/ipos_sa/sa_ord_api/removeItems", ctx -> {
            Map<String, Object> body = readJsonBody(ctx);
            String orderId = stringValue(body.get("orderId"));
            List<Integer> itemIds = intList(body.get("itemId"));
            List<Integer> quantities = intList(body.get("quantityToRemove"));

            if (orderId.isBlank() || itemIds.isEmpty() || itemIds.size() != quantities.size()) {
                ctx.status(400).json(Map.of("status", "failed", "error", "orderId, itemId and quantityToRemove are required"));
                return;
            }

            int affected = upsertOrderItems(conn, orderId, itemIds, quantities, false);
            if (affected < 0) {
                ctx.status(400).json(Map.of("status", "failed", "error", "unable to remove items from supplier order"));
                return;
            }

            ctx.json(Map.of(
                "status", "success",
                "orderId", orderId,
                "itemsRemoved", affected
            ));
        });

        app.post("/api/ipos_sa/sa_ord_api/submitOrder", ctx -> {
            Map<String, Object> body = readJsonBody(ctx);
            String orderId = stringValue(body.get("orderId"));

            if (orderId.isBlank()) {
                ctx.status(400).json(Map.of("status", "failed", "error", "orderId is required"));
                return;
            }

            if (!submitSupplierOrder(conn, orderId)) {
                ctx.status(404).json(Map.of("status", "failed", "error", "supplier order not found"));
                return;
            }

            ctx.json(Map.of(
                "status", "success",
                "orderId", orderId,
                "submitted", true
            ));
        });

        app.get("/api/ipos_sa/sa_ord_api/getActiveCatalogue", ctx -> {
            String search = ctx.queryParam("search");
            if (search == null) {
                search = "";
            }
            ctx.json(Map.of("status", "success", "items", readActiveCatalogue(conn, search)));
        });

        app.get("/api/ipos_sa/sa_merchant_api/getOrderStatuses", ctx -> {
            String orderId = stringValue(ctx.queryParam("orderId"));
            ctx.json(Map.of("status", "success", "orders", readOrderStatuses(conn, orderId)));
        });

        app.get("/api/ipos_sa/sa_merchant_api/getInvoice", ctx -> {
            String orderId = stringValue(ctx.queryParam("orderId"));
            String invoiceId = stringValue(ctx.queryParam("invoiceId"));
            ctx.json(Map.of("status", "success", "invoices", readInvoices(conn, orderId, invoiceId)));
        });

        app.get("/api/ipos_sa/sa_merchant_api/getBalance", ctx -> {
            ctx.json(readSupplierBalance(conn));
        });

        started = true;
        System.out.println("SA stock delivery API system started successfully on port " + port + ".");
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

    private static Map<String, Object> readJsonBody(io.javalin.http.Context ctx) {
        String rawBody = ctx.body();
        if (rawBody == null || rawBody.isBlank()) {
            return Map.of();
        }

        try {
            return MAPPER.readValue(rawBody, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            return Map.of();
        }
    }

    private static String createSupplierOrder(Connection conn, String username) {
        String orderId = "SO-" + java.time.LocalDateTime.now()
            .format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMddHHmmss"))
            + "-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        String saOrderRef = "SA-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        String sql = "INSERT INTO supplier_orders (order_id, sa_order_ref, status, created_at, last_status_at) VALUES (?, ?, 'CREATED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, orderId);
            ps.setString(2, saOrderRef);
            ps.executeUpdate();
            return orderId;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    private static int upsertOrderItems(Connection conn, String orderId, List<Integer> itemIds, List<Integer> quantities, boolean addMode) {
        try {
            if (!supplierOrderExists(conn, orderId)) {
                return -1;
            }

            int affected = 0;
            int nextId = getNextSupplierOrderItemId(conn);
            String selectSql = "SELECT order_item_id, quantity FROM supplier_order_items WHERE order_id = ? AND product_id = ?";
            String insertSql = "INSERT INTO supplier_order_items (order_item_id, order_id, product_id, quantity) VALUES (?, ?, ?, ?)";
            String updateSql = "UPDATE supplier_order_items SET quantity = ? WHERE order_item_id = ?";
            String deleteSql = "DELETE FROM supplier_order_items WHERE order_item_id = ?";

            for (int index = 0; index < itemIds.size(); index++) {
                int itemId = itemIds.get(index);
                int quantity = quantities.get(index);
                if (quantity <= 0) {
                    continue;
                }

                try (PreparedStatement select = conn.prepareStatement(selectSql)) {
                    select.setString(1, orderId);
                    select.setInt(2, itemId);

                    try (ResultSet rs = select.executeQuery()) {
                        if (rs.next()) {
                            int orderItemId = rs.getInt("order_item_id");
                            int currentQuantity = rs.getInt("quantity");
                            int nextQuantity = addMode ? currentQuantity + quantity : currentQuantity - quantity;

                            if (nextQuantity > 0) {
                                try (PreparedStatement update = conn.prepareStatement(updateSql)) {
                                    update.setInt(1, nextQuantity);
                                    update.setInt(2, orderItemId);
                                    update.executeUpdate();
                                    affected++;
                                }
                            } else {
                                try (PreparedStatement delete = conn.prepareStatement(deleteSql)) {
                                    delete.setInt(1, orderItemId);
                                    delete.executeUpdate();
                                    affected++;
                                }
                            }
                        } else if (addMode) {
                            try (PreparedStatement insert = conn.prepareStatement(insertSql)) {
                                insert.setInt(1, nextId++);
                                insert.setString(2, orderId);
                                insert.setInt(3, itemId);
                                insert.setInt(4, quantity);
                                insert.executeUpdate();
                                affected++;
                            }
                        }
                    }
                }
            }

            return affected;
        } catch (Exception e) {
            e.printStackTrace();
            return -1;
        }
    }

    private static boolean submitSupplierOrder(Connection conn, String orderId) {
        String sql = "UPDATE supplier_orders SET status = 'SUBMITTED', submitted_at = CURRENT_TIMESTAMP, last_status_at = CURRENT_TIMESTAMP WHERE order_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, orderId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private static List<Map<String, Object>> readOrderStatuses(Connection conn, String orderId) {
        StringBuilder sql = new StringBuilder(
            "SELECT so.order_id, so.sa_order_ref, so.status, so.created_at, so.submitted_at, so.last_status_at, "
                + "COALESCE(SUM(soi.quantity), 0) AS total_quantity, COUNT(soi.product_id) AS line_count "
                + "FROM supplier_orders so "
                + "LEFT JOIN supplier_order_items soi ON soi.order_id = so.order_id"
        );

        boolean filterByOrderId = orderId != null && !orderId.isBlank();
        if (filterByOrderId) {
            sql.append(" WHERE so.order_id = ? OR so.sa_order_ref = ?");
        }
        sql.append(" GROUP BY so.order_id, so.sa_order_ref, so.status, so.created_at, so.submitted_at, so.last_status_at ORDER BY so.created_at DESC");

        List<Map<String, Object>> orders = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            if (filterByOrderId) {
                ps.setString(1, orderId);
                ps.setString(2, orderId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> order = new LinkedHashMap<>();
                    order.put("order_id", rs.getString("order_id"));
                    order.put("sa_order_ref", rs.getString("sa_order_ref"));
                    order.put("status", rs.getString("status"));
                    order.put("created_at", toIsoString(rs.getTimestamp("created_at")));
                    order.put("submitted_at", toIsoString(rs.getTimestamp("submitted_at")));
                    order.put("last_status_at", toIsoString(rs.getTimestamp("last_status_at")));
                    order.put("total_quantity", rs.getInt("total_quantity"));
                    order.put("line_count", rs.getInt("line_count"));
                    orders.add(order);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return orders;
    }

    private static List<Map<String, Object>> readInvoices(Connection conn, String orderId, String invoiceId) {
        StringBuilder sql = new StringBuilder(
            "SELECT si.invoice_id, si.order_id, si.total_amount, si.due_date, si.received_at, so.status "
                + "FROM supplier_invoices si "
                + "LEFT JOIN supplier_orders so ON so.order_id = si.order_id"
        );

        List<String> conditions = new ArrayList<>();
        if (orderId != null && !orderId.isBlank()) {
            conditions.add("si.order_id = ?");
        }
        if (invoiceId != null && !invoiceId.isBlank()) {
            conditions.add("si.invoice_id = ?");
        }
        if (!conditions.isEmpty()) {
            sql.append(" WHERE ").append(String.join(" AND ", conditions));
        }
        sql.append(" ORDER BY si.received_at DESC");

        List<Map<String, Object>> invoices = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int parameterIndex = 1;
            if (orderId != null && !orderId.isBlank()) {
                ps.setString(parameterIndex++, orderId);
            }
            if (invoiceId != null && !invoiceId.isBlank()) {
                ps.setString(parameterIndex, invoiceId);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> invoice = new LinkedHashMap<>();
                    invoice.put("invoice_id", rs.getString("invoice_id"));
                    invoice.put("order_id", rs.getString("order_id"));
                    invoice.put("status", rs.getString("status"));
                    invoice.put("total_amount", rs.getBigDecimal("total_amount"));
                    invoice.put("due_date", rs.getString("due_date"));
                    invoice.put("received_at", toIsoString(rs.getTimestamp("received_at")));
                    invoices.add(invoice);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return invoices;
    }

    private static Map<String, Object> readSupplierBalance(Connection conn) {
        String sql = "SELECT COALESCE(SUM(total_amount), 0) AS outstanding_balance, COUNT(*) AS invoice_count FROM supplier_invoices";
        try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                BigDecimal outstandingBalance = rs.getBigDecimal("outstanding_balance");
                Map<String, Object> response = new LinkedHashMap<>();
                response.put("status", "success");
                response.put("outstandingBalance", outstandingBalance == null ? BigDecimal.ZERO : outstandingBalance);
                response.put("invoiceCount", rs.getInt("invoice_count"));
                return response;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return Map.of("status", "failed", "error", "unable to calculate supplier balance");
    }

    private static List<Map<String, Object>> readActiveCatalogue(Connection conn, String search) {
        String sql = "SELECT p.product_id, p.product_name, COALESCE(p.description, '') AS description, p.price, COALESCE(p.product_type, '') AS category, COALESCE(s.quantity, 0) AS stock_level "
            + "FROM ca_products p "
            + "LEFT JOIN ca_stock s ON s.product_id = p.product_id "
            + "WHERE LOWER(p.product_name) LIKE ? OR LOWER(COALESCE(p.product_type, '')) LIKE ? "
            + "ORDER BY p.product_name";

        String normalizedSearch = search == null ? "" : search.trim().toLowerCase();
        String wildcard = "%" + normalizedSearch + "%";
        List<Map<String, Object>> items = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, wildcard);
            ps.setString(2, wildcard);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("product_id", rs.getInt("product_id"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("description", rs.getString("description"));
                    row.put("price", rs.getBigDecimal("price"));
                    row.put("category", rs.getString("category"));
                    row.put("stock_level", rs.getInt("stock_level"));
                    items.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return items;
    }

    private static boolean supplierOrderExists(Connection conn, String orderId) {
        String sql = "SELECT 1 FROM supplier_orders WHERE order_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, orderId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private static int getNextSupplierOrderItemId(Connection conn) throws Exception {
        String sql = "SELECT COALESCE(MAX(order_item_id), 0) + 1 AS next_id FROM supplier_order_items";
        try (PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt("next_id") : 1;
        }
    }

    private static List<Integer> intList(Object value) {
        List<Integer> results = new ArrayList<>();
        if (!(value instanceof List<?> rawValues)) {
            return results;
        }

        for (Object rawValue : rawValues) {
            if (rawValue instanceof Number numberValue) {
                results.add(numberValue.intValue());
            }
        }

        return results;
    }

    private static String stringValue(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }

    private static String toIsoString(Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant().toString();
    }
}

/*
# Health
curl -i http://localhost:8081/health

# Check active catalogue
curl -i "http://localhost:8081/api/ipos_sa/sa_ord_api/getActiveCatalogue?search=para"

# Create a supplier order
curl -i "http://localhost:8081/api/ipos_sa/sa_ord_api/newOrder?username=ca_user"

# Add items to a supplier order
curl -i -X POST "http://localhost:8081/api/ipos_sa/sa_ord_api/addItems" \
    -H "Content-Type: application/json" \
    --data-raw '{"orderId":"SO-1001","itemId":[1,2],"quantity":[5,9]}'

# Submit a supplier order
curl -i -X POST "http://localhost:8081/api/ipos_sa/sa_ord_api/submitOrder" \
    -H "Content-Type: application/json" \
    --data-raw '{"orderId":"SO-1001"}'
*/

/*
curl.exe -i "http://localhost:8081/api/ipos_sa/sa_ord_api/getActiveCatalogue?search=para"
*/