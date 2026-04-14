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
    private static final String BASE_URL = "http://localhost:8081";

    private static volatile boolean started = false;
    private static HttpClient client;

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
            System.out.println("SA communication client ready.");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static synchronized void startServer() {
        if (started) {
            return;
        }

        client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();

        started = true;
        System.out.println("SA stock delivery API client initialised for " + BASE_URL + ".");
    }

    public static String login(String username, String password) {
        try {
            ensureStarted();

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("username", username);
            body.put("password", password);

            HttpResponse<String> response = post(
                    "/api/ipos_sa/sa_login_api/login",
                    MAPPER.writeValueAsString(body)
            );

            if (response.statusCode() != 200) {
                return "Login failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Login failed: " + e.getMessage();
        }
    }

    public static String createSupplierOrder(String username) {
        try {
            ensureStarted();

            HttpResponse<String> response = get(
                    "/api/ipos_sa/sa_ord_api/newOrder?username=" + encode(username)
            );

            if (response.statusCode() != 200) {
                return "Create order failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            JsonNode json = MAPPER.readTree(response.body());
            JsonNode orderIdNode = json.get("orderId");

            if (orderIdNode == null || orderIdNode.asText().isBlank()) {
                return "Create order failed: missing orderId in response";
            }

            return orderIdNode.asText();
        } catch (Exception e) {
            return "Create order failed: " + e.getMessage();
        }
    }

    public static String addItems(String orderId, List<Integer> itemIds, List<BigDecimal> quantities) {
        try {
            ensureStarted();

            if (orderId == null || orderId.isBlank()) {
                return "Add items failed: orderId is required";
            }
            if (itemIds == null || quantities == null || itemIds.isEmpty() || itemIds.size() != quantities.size()) {
                return "Add items failed: itemIds and quantities must be non-empty and the same size";
            }

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("orderId", orderId);
            body.put("itemId", itemIds);
            body.put("quantity", quantities);

            HttpResponse<String> response = post(
                    "/api/ipos_sa/sa_ord_api/addItems",
                    MAPPER.writeValueAsString(body)
            );

            if (response.statusCode() != 200) {
                return "Add items failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Add items failed: " + e.getMessage();
        }
    }

    public static String removeItems(String orderId, List<Integer> itemIds, List<BigDecimal> quantities) {
        try {
            ensureStarted();

            if (orderId == null || orderId.isBlank()) {
                return "Remove items failed: orderId is required";
            }
            if (itemIds == null || quantities == null || itemIds.isEmpty() || itemIds.size() != quantities.size()) {
                return "Remove items failed: itemIds and quantityToRemove must be non-empty and the same size";
            }

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("orderId", orderId);
            body.put("itemId", itemIds);
            body.put("quantityToRemove", quantities);

            HttpResponse<String> response = post(
                    "/api/ipos_sa/sa_ord_api/removeItems",
                    MAPPER.writeValueAsString(body)
            );

            if (response.statusCode() != 200) {
                return "Remove items failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Remove items failed: " + e.getMessage();
        }
    }

    public static String submitSupplierOrder(String orderId) {
        try {
            ensureStarted();

            if (orderId == null || orderId.isBlank()) {
                return "Submit order failed: orderId is required";
            }

            Map<String, Object> body = new LinkedHashMap<>();
            body.put("orderId", orderId);

            HttpResponse<String> response = post(
                    "/api/ipos_sa/sa_ord_api/submitOrder",
                    MAPPER.writeValueAsString(body)
            );

            if (response.statusCode() != 200) {
                return "Submit order failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Submit order failed: " + e.getMessage();
        }
    }

    public static String readOrderStatuses(String orderId) {
        try {
            ensureStarted();

            if (orderId == null || orderId.isBlank()) {
                return "Get order status failed: orderId is required";
            }

            HttpResponse<String> response = get(
                    "/api/ipos_sa/sa_merchant_api/getOrderStatuses?orderId=" + encode(orderId)
            );

            if (response.statusCode() != 200) {
                return "Get order status failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Get order status failed: " + e.getMessage();
        }
    }

    public static String readInvoices(String orderId, String invoiceId) {
        try {
            ensureStarted();

            StringBuilder path = new StringBuilder("/api/ipos_sa/sa_merchant_api/getInvoice?");
            boolean hasOrderId = orderId != null && !orderId.isBlank();
            boolean hasInvoiceId = invoiceId != null && !invoiceId.isBlank();

            if (!hasOrderId && !hasInvoiceId) {
                return "Get invoice failed: orderId or invoiceId is required";
            }

            if (hasOrderId) {
                path.append("orderId=").append(encode(orderId));
            }
            if (hasInvoiceId) {
                if (hasOrderId) {
                    path.append("&");
                }
                path.append("invoiceId=").append(encode(invoiceId));
            }

            HttpResponse<String> response = get(path.toString());

            if (response.statusCode() != 200) {
                return "Get invoice failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Get invoice failed: " + e.getMessage();
        }
    }

    public static String readSupplierBalance(String username) {
        try {
            ensureStarted();

            if (username == null || username.isBlank()) {
                return "Get balance failed: username is required";
            }

            HttpResponse<String> response = get(
                    "/api/ipos_sa/sa_merchant_api/getBalance?username=" + encode(username)
            );

            if (response.statusCode() != 200) {
                return "Get balance failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Get balance failed: " + e.getMessage();
        }
    }

    public static String readActiveCatalogue(String username) {
        try {
            ensureStarted();

            if (username == null || username.isBlank()) {
                return "Get catalogue failed: username is required";
            }

            HttpResponse<String> response = get(
                    "/api/ipos_sa/sa_ord_api/getActiveCatalogue?username=" + encode(username)
            );

            if (response.statusCode() != 200) {
                return "Get catalogue failed: HTTP " + response.statusCode() + " - " + response.body();
            }

            return response.body();
        } catch (Exception e) {
            return "Get catalogue failed: " + e.getMessage();
        }
    }

    private static HttpResponse<String> get(String path) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + path))
                .timeout(Duration.ofSeconds(15))
                .GET()
                .build();

        return client.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private static HttpResponse<String> post(String path, String jsonBody) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(BASE_URL + path))
                .timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                .build();

        return client.send(request, HttpResponse.BodyHandlers.ofString());
    }

    private static void ensureStarted() {
        if (!started) {
            startServer();
        }
    }

    private static String encode(String value) {
        return URLEncoder.encode(value == null ? "" : value, StandardCharsets.UTF_8);
    }
}