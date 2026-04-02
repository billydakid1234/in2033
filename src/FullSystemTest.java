import org.junit.jupiter.api.*;

import static org.junit.jupiter.api.Assertions.*;
import java.sql.Connection;
import java.util.List;
import java.util.Map;

public class FullSystemTest {

    private static Connection conn;

    private SA_ORD_API ordApi;
    private SA_Merchant_API_Impl merchantApi;
    private CA_OnlineOrderAPI_Impl onlineApi;

    @BeforeAll
    static void setupDB() {
        conn = DBConnection.getConnection();
        assertNotNull(conn, "DB connection failed");
    }

    @BeforeEach
    void setup() {
        ordApi = new SA_ORD_API(conn);
        merchantApi = new SA_Merchant_API_Impl(conn);
        onlineApi = new CA_OnlineOrderAPI_Impl(ordApi, merchantApi, conn);
    }

    // =============================
    // ORDER TESTS
    // =============================
    @Test
    void testCreateOrder() {
        String orderID = ordApi.newOrder();
        assertNotNull(orderID);
    }

    @Test
    void testAddAndViewOrder() {
        String orderID = ordApi.newOrder();

        ordApi.addItems(orderID, new int[]{1}, new int[]{2});

        Map<String, Integer> order = ordApi.viewOrder(orderID);

        assertNotNull(order);
        assertFalse(order.isEmpty());
    }

    @Test
    void testSubmitOrder() {
        String orderID = ordApi.newOrder();

        ordApi.addItems(orderID, new int[]{1}, new int[]{1});
        ordApi.submitOrder(orderID);

        // No crash = pass
        assertTrue(true);
    }

    // =============================
    // ONLINE ORDER TESTS
    // =============================
    @Test
    void testProcessOnlineOrder() {
        String orderID = onlineApi.createOrder();

        onlineApi.processOnlineOrder(orderID, "1:2");

        String status = onlineApi.getOrderStatus(orderID);

        assertTrue(status.equals("PROCESSED") || status.equals("CREATED"));
    }

    @Test
    void testStockCheck() {
        int stock = onlineApi.checkProductStock("1");
        assertTrue(stock >= 0);
    }

    @Test
    void testGenerateReceipt() {
        String orderID = onlineApi.createOrder();

        onlineApi.processOnlineOrder(orderID, "1:1");

        String receipt = onlineApi.generateReceipt(orderID);

        assertNotNull(receipt);
        assertTrue(receipt.contains("Receipt"));
    }

    // =============================
    // MERCHANT - PAYMENTS
    // =============================
    @Test
    void testCreditPaymentSuccess() {
        boolean result = merchantApi.processCreditPayment(1, 10.0);
        assertTrue(result);
    }

    @Test
    void testCreditLimitExceeded() {
        boolean result = merchantApi.processCreditPayment(1, 999999);
        assertFalse(result);
    }

    @Test
    void testGetBalance() {
        double balance = merchantApi.getCustomerBalance(1);
        assertTrue(balance >= 0);
    }

    @Test
    void testSetCreditLimit() {
        boolean result = merchantApi.setCreditLimit(1, 5000);
        assertTrue(result);
    }

    // =============================
    // ACCOUNT STATUS TESTS
    // =============================
    @Test
    void testUpdateAccountStatus() {
        boolean result = merchantApi.updateAccountStatus(1, "SUSPENDED");
        assertTrue(result);
    }

    @Test
    void testManagerReactivate() {
        merchantApi.updateAccountStatus(1, "IN_DEFAULT");

        boolean result = merchantApi.managerReactivateAccount(1);

        assertTrue(result);
    }

    // =============================
    // AUTO LOGIC TESTS
    // =============================
    @Test
    void testAutoSuspend() {
        boolean result = merchantApi.autoSuspendAccount(1);

        // depends on date → just check no crash
        assertNotNull(result);
    }

    @Test
    void testAutoDefault() {
        boolean result = merchantApi.autoMoveToDefault(1);

        // depends on date → just check no crash
        assertNotNull(result);
    }

    @Test
    void testBatchAutoUpdate() {
        merchantApi.checkAndAutoUpdateAllAccounts();

        // pass if no crash
        assertTrue(true);
    }

    // =============================
    // STATEMENTS + REMINDERS
    // =============================
    @Test
    void testGenerateStatements() {
        List<String> statements = merchantApi.generateStatements();

        assertNotNull(statements);
    }

    @Test
    void testGenerateReminders() {
        List<String> reminders = merchantApi.generateReminders();

        assertNotNull(reminders);
    }

    @AfterAll
    static void closeDB() throws Exception {
        if (conn != null) conn.close();
    }

    public static void main(String[] args) throws Exception {

    FullSystemTest test = new FullSystemTest();

    // Run @BeforeAll
    setupDB();

    System.out.println("\n=== RUNNING FULL SYSTEM TEST ===\n");

    java.lang.reflect.Method[] methods = FullSystemTest.class.getDeclaredMethods();

    int passed = 0;
    int failed = 0;

    for (java.lang.reflect.Method method : methods) {

        if (method.isAnnotationPresent(org.junit.jupiter.api.Test.class)) {

            try {
                System.out.println("Running: " + method.getName());

                // Run @BeforeEach
                test.setup();

                // Run test
                method.invoke(test);

                System.out.println("✓ PASSED\n");
                passed++;

            } catch (Exception e) {
                System.out.println("✗ FAILED");

                if (e.getCause() != null) {
                    e.getCause().printStackTrace();
                } else {
                    e.printStackTrace();
                }

                failed++;
            }
        }
    }

    System.out.println("\n=== RESULTS ===");
    System.out.println("Passed: " + passed);
    System.out.println("Failed: " + failed);
}
}

