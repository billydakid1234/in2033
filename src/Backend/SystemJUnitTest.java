/*
package Backend;


import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

import java.sql.Connection;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class SystemJUnitTest {

    private static Connection conn;
    private static SA_ORD_API ordApi;
    private static CA_OnlineOrderAPI_Impl onlineApi;
    private static SA_LOGIN_API loginApi;

    private static String orderID;

    @BeforeAll
    static void setup() {
        conn = DBConnection.getConnection();

        ordApi = new SA_ORD_API(conn);
        onlineApi = new CA_OnlineOrderAPI_Impl(ordApi, conn);
        loginApi = new SA_LOGIN_API(conn);

        System.out.println("=== TEST START ===");
    }


    // LOGIN TEST
    @Test
    @Order(1)
    void testLogin() {

        boolean created = loginApi.createStaff("junitUser", "1234");
        boolean login = loginApi.login("junitUser", "1234");

        assertTrue(created || login); // allow if already exists
        assertTrue(login);
    }


    // CREATE ORDER
    @Test
    @Order(2)
    void testCreateOrder() {

        orderID = onlineApi.createOrder();

        assertNotNull(orderID);
    }


    // PROCESS ORDER
    @Test
    @Order(3)
    void testProcessOrder() {

        onlineApi.processOnlineOrder(orderID, "1:2,2:1");

        String status = onlineApi.getOrderStatus(orderID);

        assertEquals("PROCESSED", status);
    }


    // STOCK CHECK
    @Test
    @Order(4)
    void testStockCheck() {

        int stock = onlineApi.checkProductStock("1");

        assertTrue(stock >= 0);
    }


    // CARD PAYMENT

    @Test
    @Order(5)
    void testCardPayment() {

        boolean result = onlineApi.payByCard(orderID, "12345678", "12/28");

        assertTrue(result);
    }


    // CASH PAYMENT

    @Test
    @Order(6)
    void testCashPayment() {

        boolean result = onlineApi.payByCash(orderID, 10.0);

        assertTrue(result);
    }


    // CREDIT PAYMENT

    @Test
    @Order(7)
    void testCreditPayment() {

        boolean result = onlineApi.payByCredit(orderID, 1, 5.0); // assumes customer_id=1

        assertTrue(result);
    }


    // RECEIPT
    @Test
    @Order(8)
    void testReceipt() {

        String receipt = onlineApi.generateReceipt(orderID);

        assertNotNull(receipt);
        assertTrue(receipt.contains("Receipt"));
    }


    // CATALOGUE
    @Test
    @Order(9)
    void testCatalogue() {

        String[] results = onlineApi.getMerchantCatalogue("para");

        assertNotNull(results);
        assertTrue(results.length > 0);
    }
    
    // EMAIL NOTIFICATION TEST

    @Test
    @Order(10)
    void testEmailNotification() {
        // Email service is now pre-configured with credentials
        PU_COMMS_API_Impl emailService = new PU_COMMS_API_Impl();

        // Send order confirmation email
        boolean emailSent = emailService.sendEmail(
            "Ben.Folley@citystgeorges.ac.uk",
            "Order Confirmation",
            "Your order has been placed successfully!\n\nOrder ID: " + orderID
        );

        assertTrue(emailSent);
    }
    


    // MAIN - Run all tests

    public static void main(String[] args) throws Exception {
        SystemJUnitTest test = new SystemJUnitTest();
        
        // Call setup
        java.lang.reflect.Method setupMethod = SystemJUnitTest.class.getDeclaredMethod("setup");
        setupMethod.invoke(null);
        
        System.out.println("\n=== Running SystemJUnitTest ===\n");
        
        java.lang.reflect.Method[] methods = SystemJUnitTest.class.getDeclaredMethods();
        int passed = 0, failed = 0;
        
        for (java.lang.reflect.Method m : methods) {
            if (m.isAnnotationPresent(org.junit.jupiter.api.Test.class)) {
                try {
                    System.out.println("Running: " + m.getName());
                    m.invoke(test);
                    System.out.println("✓ PASSED: " + m.getName());
                    passed++;
                } catch (Exception e) {
                    System.out.println("✗ FAILED: " + m.getName());
                    if (e.getCause() != null) {
                        e.getCause().printStackTrace();
                    } else {
                        e.printStackTrace();
                    }
                    failed++;
                }
            }
        }
        
        System.out.println("\n=== TEST SUMMARY ===");
        System.out.println("Passed: " + passed);
        System.out.println("Failed: " + failed);
        System.out.println("Total:  " + (passed + failed));
    }
}
*/