package main.java;

import database.DBConnection;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class MockSubsystemCA {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static volatile boolean started = false;
    private static HttpServer server;

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
        }, "ca-catalogue-api");
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

    private static synchronized void startServer() throws IOException {
        if (started) {
            return;
        }

        final int port = Integer.parseInt(System.getenv().getOrDefault("CA_API_PORT", "8082"));

        System.out.println("Starting Mock Subsystem CA (Catalogue API) on port " + port + "...");

        Connection conn = DBConnection.getConnection();
        if (conn == null) {
            System.err.println("Cannot start CA catalogue API: database connection failed.");
            return;
        }

        server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/health", exchange -> respondJson(exchange, 200, Map.of("status", "ok")));
        server.createContext("/api/ipos_ca/health", exchange -> respondJson(exchange, 200, Map.of("status", "ok")));

        server.createContext("/api/ipos_ca/catalogue", exchange -> {
            if (!"GET".equalsIgnoreCase(exchange.getRequestMethod())) {
                System.out.println("[CA->PU] Rejected non-GET request on /api/ipos_ca/catalogue");
                respondJson(exchange, 405, Map.of("status", "failed", "error", "method not allowed"));
                return;
            }

            String search = extractQueryParam(exchange.getRequestURI().getRawQuery(), "search");
            System.out.println("[CA->PU] Catalogue request received. search='" + search + "'");
            List<Map<String, Object>> items = readCatalogue(conn, search);
            System.out.println("[CA->PU] Catalogue response sent. items=" + items.size());
            respondJson(exchange, 200, items);
        });

        server.setExecutor(null);
        server.start();
        started = true;
        System.out.println("CA catalogue API system started successfully on port " + port + ".");
    }

    private static String extractQueryParam(String query, String key) {
        if (query == null || query.isBlank()) {
            return "";
        }

        String[] pairs = query.split("&");
        for (String pair : pairs) {
            int idx = pair.indexOf('=');
            String paramKey = idx >= 0 ? pair.substring(0, idx) : pair;
            if (key.equals(paramKey)) {
                String rawValue = idx >= 0 ? pair.substring(idx + 1) : "";
                return URLDecoder.decode(rawValue, StandardCharsets.UTF_8);
            }
        }

        return "";
    }

    private static void respondJson(HttpExchange exchange, int status, Object payload) throws IOException {
        byte[] bytes = MAPPER.writeValueAsBytes(payload);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.getResponseBody().flush();
        exchange.close();
    }

    private static List<Map<String, Object>> readCatalogue(Connection conn, String search) {
        String sql = "SELECT CAST(p.product_id AS TEXT) AS item_id, p.product_name, COALESCE(p.description, '') AS description, "
                + "p.price, COALESCE(s.quantity, 0) AS stock_level, COALESCE(p.product_type, '') AS category "
                + "FROM ca_products p LEFT JOIN ca_stock s ON s.product_id = p.product_id "
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
                    row.put("item_id", rs.getString("item_id"));
                    row.put("product_name", rs.getString("product_name"));
                    row.put("description", rs.getString("description"));
                    row.put("price", rs.getDouble("price"));
                    row.put("stock_level", rs.getInt("stock_level"));
                    row.put("category", rs.getString("category"));
                    items.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return items;
    }
}

/*
# Health
curl -i http://localhost:8082/health

# Search: "para"
curl -i "http://localhost:8082/api/ipos_ca/catalogue?search=para"

# Search: "cardiovascular"
curl -i "http://localhost:8082/api/ipos_ca/catalogue?search=cardiovascular"

# Search: no results expected
curl -i "http://localhost:8082/api/ipos_ca/catalogue?search=zzzz"

 */

/*
curl.exe -i http://localhost:8082/health
curl.exe -i http://localhost:8082/api/ipos_ca/health
curl.exe -i "http://localhost:8082/api/ipos_ca/catalogue?search="
Gets all items in the catalogue.
curl.exe -i "http://localhost:8082/api/ipos_ca/catalogue?search=para"
Gets items with "para" in the name or category.
curl.exe -i "http://localhost:8082/api/ipos_ca/catalogue?search=cardiovascular"
Gets items with "cardiovascular" in the name or category.
curl.exe -i "http://localhost:8082/api/ipos_ca/catalogue?search=zzzz"
Gets no items, as "zzzz" does not match any name or category.
 */