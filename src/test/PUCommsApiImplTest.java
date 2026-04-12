/*package test;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicInteger;
import main.java.PU_COMMS_API_Impl;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class PUCommsApiImplTest {

    private HttpServer server;

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void sendEmailFallsBackToLegacyPuContractWhenPrimaryEndpointFails() throws Exception {
        AtomicInteger primaryCalls = new AtomicInteger();
        AtomicInteger legacyCalls = new AtomicInteger();

        server = HttpServer.create(new InetSocketAddress(0), 0);
        server.createContext("/api/ipos_pu/email/send", exchange -> {
            primaryCalls.incrementAndGet();
            respond(exchange, 500, "primary contract failed");
        });
        server.createContext("/api/ipos_pu/sendEmail", exchange -> {
            legacyCalls.incrementAndGet();
            String body = new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8);
            assertTrue(body.contains("\"email\":\"dylan@example.com\""));
            assertTrue(body.contains("\"subject\":\"Order Confirmation\""));
            assertTrue(body.contains("\"body\":\"Thanks for your order\""));
            respond(exchange, 200, "ok");
        });
        server.start();

        int port = server.getAddress().getPort();
        PU_COMMS_API_Impl api = new PU_COMMS_API_Impl("http://localhost:" + port + "/api/ipos_pu");

        boolean sent = api.sendEmail("dylan@example.com", "Order Confirmation", "Thanks for your order");

        assertTrue(sent);
        assertEquals(1, primaryCalls.get());
        assertEquals(1, legacyCalls.get());
    }

    private static void respond(HttpExchange exchange, int status, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }
}
*/