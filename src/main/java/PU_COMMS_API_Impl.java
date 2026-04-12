package main.java;

import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public class PU_COMMS_API_Impl implements PU_COMMS_API {
    private static final String DEFAULT_PU_API_ENDPOINT = "http://localhost:8080/api/ipos_pu";

    private final String puApiEndpoint;

    public PU_COMMS_API_Impl() {
        this(DEFAULT_PU_API_ENDPOINT);
    }

    public PU_COMMS_API_Impl(String puApiEndpoint) {
        // No SMTP credentials needed since PU is handling sending
        this.puApiEndpoint = (puApiEndpoint == null || puApiEndpoint.isBlank())
                ? DEFAULT_PU_API_ENDPOINT
                : puApiEndpoint;
    }

    /**
     * Instead of sending email directly, this method passes the
     * email data to the PU subsystem for actual sending.
     */
    /*
     * Stub version - not in use. Kept for reference.
     *
     * @Override
     * public boolean sendEmail(String recipient, String subject, String content) {
     *     try {
     *         Map<String, String> emailData = Map.of(
     *                 "recipient", recipient,
     *                 "subject", subject,
     *                 "content", content
     *         );
     *         System.out.println("Email data handed off to PU subsystem: " + emailData);
     *         return true;
     *     } catch (Exception e) {
     *         e.printStackTrace();
     *         return false;
     *     }
     * }
     */

    @Override
    public boolean sendEmail(String recipient, String subject, String content) {
        System.out.println("sendEmail called - recipient: " + recipient + ", subject: " + subject);
        try {
            String primaryUrl = buildEndpointUrl("/email/send");
            HttpResult primaryResult = postJson(primaryUrl, createPrimaryEmailPayload(recipient, subject, content));

            if (primaryResult.isSuccess()) {
                return true;
            }

            logHttpFailure("PU email API", primaryUrl, primaryResult);

            String legacyUrl = buildEndpointUrl("/sendEmail");
            if (!legacyUrl.equals(primaryUrl)) {
                System.out.println("Retrying with legacy PU email contract...");
                HttpResult legacyResult = postJson(legacyUrl, createLegacyEmailPayload(recipient, subject, content));

                if (legacyResult.isSuccess()) {
                    return true;
                }

                logHttpFailure("Legacy PU email API", legacyUrl, legacyResult);
            }

            return false;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private String createPrimaryEmailPayload(String recipient, String subject, String content) {
        return String.format(
                "{\"email\":\"%s\",\"subject\":\"%s\",\"body\":\"%s\"}",
                escapeJson(recipient),
                escapeJson(subject),
                escapeJson(content)
        );
    }

    private String createLegacyEmailPayload(String recipient, String subject, String content) {
        return String.format(
                "{\"email\":\"%s\",\"subject\":\"%s\",\"body\":\"%s\"}",
                escapeJson(recipient),
                escapeJson(subject),
                escapeJson(content)
        );
    }

    private HttpResult postJson(String endpointUrl, String payload) throws Exception {
        URL url = new URL(endpointUrl);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "application/json");
        conn.setDoOutput(true);

        try (OutputStream os = conn.getOutputStream()) {
            os.write(payload.getBytes(StandardCharsets.UTF_8));
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

    private void logHttpFailure(String label, String endpointUrl, HttpResult result) {
        System.out.println(label + " returned error code: " + result.responseCode + " at " + endpointUrl);
        if (!result.responseBody.isBlank()) {
            System.out.println(label + " response body: " + result.responseBody);
        }
    }

    private String buildEndpointUrl(String path) {
        String base = puApiEndpoint == null ? DEFAULT_PU_API_ENDPOINT : puApiEndpoint.trim();
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }

        String normalizedPath = (path == null || path.isBlank())
                ? ""
                : (path.startsWith("/") ? path : "/" + path);

        if (!normalizedPath.isEmpty() && base.endsWith(normalizedPath)) {
            return base;
        }

        return base + normalizedPath;
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

    public boolean processCardPayment(String cardNumber, String expiry, double amount, String orderID) {
        try {
            // Creating JSON payload
            String payload = String.format(
                    "{\"cardNumber\":\"%s\",\"expiry\":\"%s\",\"amount\":%.2f,\"orderID\":\"%s\"}",
                    escapeJson(cardNumber), escapeJson(expiry), amount, escapeJson(orderID)
            );

            // Opening HTTPS connection to PU API
            URL url = new URL(buildEndpointUrl("/processCardPayment"));
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);

            // Sending encrypted payload
            try (OutputStream os = conn.getOutputStream()) {
                os.write(payload.getBytes(StandardCharsets.UTF_8));
            }

            // Checking PU response
            int responseCode = conn.getResponseCode();
            if (responseCode >= 200 && responseCode < 300) {
                // PU confirmed payment
                return true;
            } else {
                System.out.println("PU API returned error code: " + responseCode);
                return false;
            }

        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}


