package main.java;

import java.io.InputStream;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.net.HttpURLConnection;
import java.net.URLEncoder;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Objects;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.URI;
import java.time.Duration;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.io.IOException;
import com.fasterxml.jackson.databind.JsonNode;

/**
 * Dedicated client for CA -> SA HTTP communication.
 * Keeps SA integration separate from PU comms implementation.
 */
public class SA_COMMS_API_Impl {

    private static final String DEFAULT_SA_API_BASE = "http://localhost:8081/api/ipos_sa";
        private static final String BASE_URL = "http://localhost:8081";

    private final String saApiBase;

    public SA_COMMS_API_Impl() {
        this(DEFAULT_SA_API_BASE);
    }

    public SA_COMMS_API_Impl(String saApiBase) {
        this.saApiBase = normalizeBase(saApiBase);
    }

    /**
     * GET /sa_ord_api/newOrder?username=...
     */
    public String newOrder(String username) {
        try {
            if (username == null || username.isBlank()) {
                return null;
            }

            String endpoint = buildUrl("/sa_ord_api/newOrder?username=" + encode(username));
            HttpResult result = send("GET", endpoint, null);
            if (!result.isSuccess()) {
                logHttpFailure("newOrder", endpoint, result);
                return null;
            }
            return result.responseBody;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /**
     * POST /sa_ord_api/addItems
     */
    public boolean addItems(String orderId, int[] itemId, BigDecimal[] quantity) {
        return postOrderItems("/sa_ord_api/addItems", "addItems", orderId, itemId, quantity);
    }

    /**
     * POST /sa_ord_api/removeItems
     */
    public boolean removeItems(String orderId, int[] itemId, BigDecimal[] quantityToRemove) {
        return postOrderItems("/sa_ord_api/removeItems", "removeItems", orderId, itemId, quantityToRemove, "quantityToRemove");
    }

    /**
     * POST /sa_ord_api/submitOrder
     */
    public boolean submitOrder(String orderId) {
        try {
            String endpoint = buildUrl("/sa_ord_api/submitOrder");
            String payload = "{\"orderId\":\"" + escapeJson(orderId) + "\"}";

            HttpResult result = send("POST", endpoint, payload);
            if (!result.isSuccess()) {
                logHttpFailure("submitOrder", endpoint, result);
                return false;
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * GET /sa_merchant_api/getOrderStatuses (optional query pass-through)
     */
    public String getOrderStatuses(String queryString) {
        return getRaw("/sa_merchant_api/getOrderStatuses", queryString, "getOrderStatuses");
    }

    /**
     * GET /sa_merchant_api/getInvoice (optional query pass-through)
     */
    public String getInvoice(String queryString) {
        return getRaw("/sa_merchant_api/getInvoice", queryString, "getInvoice");
    }

    /**
     * GET /sa_merchant_api/getBalance (optional query pass-through)
     */
    public String getBalance(String queryString) {
        return getRaw("/sa_merchant_api/getBalance", queryString, "getBalance");
    }

    /**
     * GET /sa_ord_api/getActiveCatalogue (optional query pass-through)
     */
    public String getActiveCatalogue(String queryString) {
        return getRaw("/sa_ord_api/getActiveCatalogue", queryString, "getActiveCatalogue");
    }

    private boolean postOrderItems(String path, String operation, String orderId, int[] itemId, BigDecimal[] quantity) {
        return postOrderItems(path, operation, orderId, itemId, quantity, "quantity");
    }

    private boolean postOrderItems(String path, String operation, String orderId, int[] itemId, BigDecimal[] quantity, String quantityFieldName) {
        try {
            if (orderId == null || orderId.isBlank() || itemId == null || quantity == null || itemId.length != quantity.length) {
                return false;
            }

            String endpoint = buildUrl(path);
            String payload = buildItemsPayload(orderId, itemId, quantity, quantityFieldName);
            HttpResult result = send("POST", endpoint, payload);

            if (!result.isSuccess()) {
                logHttpFailure(operation, endpoint, result);
                return false;
            }
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    


private String getRaw(String path, String queryString, String operation) {
    
    String endpoint = buildUrl(path + normalizeQuery(queryString));


    System.out.println("SA GET request: " + endpoint);
    System.out.println("Query string: " + queryString);

    try {
        HttpResult result = doGet(endpoint);

        System.out.println("SA GET status: " + result.responseCode);
        System.out.println("SA GET body: " + result.responseBody);

        if (result.responseCode != 200) {
            logHttpFailure(operation, endpoint, result);
            return null;
        }

        return result.responseBody;

    } catch (Exception e) {
        logException(operation, endpoint, e);
        return null;
    }
}

    private HttpResult send(String method, String endpointUrl, String payload) throws Exception {
        URL url = new URL(endpointUrl);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod(method);
        conn.setRequestProperty("Accept", "application/json");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(10000);

        if (payload != null) {
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(payload.getBytes(StandardCharsets.UTF_8));
            }
        }

        int responseCode = conn.getResponseCode();
        String responseBody = readResponseBody(conn, responseCode);
        conn.disconnect();

        return new HttpResult(responseCode, responseBody);
    }

    private String readResponseBody(HttpURLConnection conn, int responseCode) throws Exception {
        InputStream stream = responseCode >= 400 ? conn.getErrorStream() : conn.getInputStream();
        if (stream == null) {
            return "";
        }

        try (InputStream responseStream = stream) {
            return new String(responseStream.readAllBytes(), StandardCharsets.UTF_8).trim();
        }
    }

    private String buildItemsPayload(String orderId, int[] itemId, BigDecimal[] quantity, String quantityFieldName) {
        StringBuilder itemIdJson = new StringBuilder("[");
        StringBuilder qtyJson = new StringBuilder("[");

        for (int i = 0; i < itemId.length; i++) {
            if (i > 0) {
                itemIdJson.append(',');
                qtyJson.append(',');
            }
            itemIdJson.append(itemId[i]);
            qtyJson.append(quantity[i] == null ? "0" : quantity[i].toPlainString());
        }

        itemIdJson.append(']');
        qtyJson.append(']');

        return "{"
            + "\"orderId\":\"" + escapeJson(orderId) + "\"," 
            + "\"itemId\":" + itemIdJson + ","
            + "\"" + escapeJson(quantityFieldName) + "\":" + qtyJson
            + "}";
    }

    private String buildUrl(String path) {
        String normalizedPath = path == null ? "" : path.trim();
        if (!normalizedPath.startsWith("/")) {
            normalizedPath = "/" + normalizedPath;
        }
        return saApiBase + normalizedPath;
    }

    private String normalizeBase(String base) {
        String value = Objects.requireNonNullElse(base, DEFAULT_SA_API_BASE).trim();
        if (value.isEmpty()) {
            value = DEFAULT_SA_API_BASE;
        }
        while (value.endsWith("/")) {
            value = value.substring(0, value.length() - 1);
        }
        return value;
    }

    private String normalizeQuery(String queryString) {
        if (queryString == null || queryString.isBlank()) {
            return "";
        }
        String trimmed = queryString.trim();
        return trimmed.startsWith("?") ? trimmed : "?" + trimmed;
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }

        return value
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\r", "\\r")
            .replace("\n", "\\n");
    }

    private void logHttpFailure(String operation, String endpointUrl, HttpResult result) {
        System.out.println("SA API " + operation + " failed with HTTP " + result.responseCode + " at " + endpointUrl);
        if (!result.responseBody.isBlank()) {
            System.out.println("SA API response body: " + result.responseBody);
        }
    }
    
    private HttpResult doGet(String endpoint) throws Exception {
    return send("GET", endpoint, null);
}
    
private void logException(String operation, String endpoint, Exception e) {
    System.out.println("ERROR in " + operation + " -> " + endpoint);
    e.printStackTrace();
}   

    private static final class HttpResult {
        private final int responseCode;
        private final String responseBody;

        private HttpResult(int responseCode, String responseBody) {
            this.responseCode = responseCode;
            this.responseBody = responseBody == null ? "" : responseBody;
        }

        private boolean isSuccess() {
            return responseCode >= 200 && responseCode < 300;
        }
    }
}
