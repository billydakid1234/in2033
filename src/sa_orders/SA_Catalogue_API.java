package sa_orders;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Reads catalogue data from SA.
 * Primary path calls SA REST API, with local SQL fallback for resilience.
 */
public class SA_Catalogue_API {

    private final Connection conn;
    private final HttpClient httpClient;
    private final String saBaseUrl;

    private static final Pattern ITEM_PATTERN = Pattern.compile(
        "\\\"product_id\\\"\\s*:\\s*(\\d+).*?\\\"product_name\\\"\\s*:\\s*\\\"((?:\\\\\\\"|[^\\\"])*)\\\"",
        Pattern.DOTALL
    );

    public SA_Catalogue_API(Connection conn) {
        this.conn = conn;
        this.httpClient = HttpClient.newHttpClient();
        this.saBaseUrl = System.getenv().getOrDefault("SA_API_BASE_URL", "http://localhost:8083");
    }

    public Map<Integer, String> getCatalogue(String searchTerm) {
        Map<Integer, String> catalogue = new LinkedHashMap<>();
        String normalizedSearch = searchTerm == null ? "" : searchTerm.trim();

        try {
            readViaRest(catalogue, normalizedSearch);
            return catalogue;
        } catch (Exception restEx) {
            try {
                readViaFallbackQuery(catalogue, normalizedSearch);
            } catch (SQLException queryEx) {
                queryEx.printStackTrace();
            }
        }

        return catalogue;
    }

    private void readViaRest(Map<Integer, String> catalogue, String searchTerm) throws IOException, InterruptedException {
        String encoded = URLEncoder.encode(searchTerm, StandardCharsets.UTF_8);
        String url = saBaseUrl + "/api/ipos_sa/catalogue?search=" + encoded;

        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create(url))
            .GET()
            .header("Accept", "application/json")
            .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IOException("SA catalogue REST call failed with status " + response.statusCode());
        }

        parseCatalogueItems(response.body(), catalogue);
        if (catalogue.isEmpty()) {
            throw new IOException("SA catalogue response did not contain parseable items");
        }
    }

    private void readViaFallbackQuery(Map<Integer, String> catalogue, String searchTerm) throws SQLException {
        String sql = "SELECT product_id, product_name FROM ca_products WHERE LOWER(product_name) LIKE ? ORDER BY product_name";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "%" + searchTerm.toLowerCase() + "%");

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    catalogue.put(rs.getInt("product_id"), rs.getString("product_name"));
                }
            }
        }
    }

    private void parseCatalogueItems(String body, Map<Integer, String> catalogue) {
        Matcher matcher = ITEM_PATTERN.matcher(body);
        while (matcher.find()) {
            int productId = Integer.parseInt(matcher.group(1));
            String productName = matcher.group(2)
                .replace("\\\"", "\"")
                .replace("\\\\", "\\");
            catalogue.put(productId, productName);
        }
    }
}
