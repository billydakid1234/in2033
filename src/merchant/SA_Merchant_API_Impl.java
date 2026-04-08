package merchant;



import java.sql.*;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;


public class SA_Merchant_API_Impl implements SA_Merchant_API {

    private Connection conn;

    public SA_Merchant_API_Impl(Connection conn) {
        this.conn = conn;
    }

    private boolean isFrontendOrder(String orderID) {
        return orderID != null && orderID.startsWith("ONL-");
    }

    private boolean onlineOrderExists(String orderID) throws SQLException {
        String check = "SELECT online_order_id FROM ca_online_orders WHERE online_order_id = ?";
        PreparedStatement psCheck = conn.prepareStatement(check);
        psCheck.setString(1, orderID);
        ResultSet rs = psCheck.executeQuery();
        return rs.next();
    }

    private int getNextId(String tableName, String idColumn) throws SQLException {
        String sql = "SELECT COALESCE(MAX(" + idColumn + "), 0) + 1 AS next_id FROM " + tableName;
        PreparedStatement ps = conn.prepareStatement(sql);
        ResultSet rs = ps.executeQuery();
        return rs.next() ? rs.getInt("next_id") : 1;
    }
    
    

    /**
     * PROCESS CREDIT PAYMENT
     * Checks if account is not IN_DEFAULT, updates balance if allowed
     */
    public boolean processCreditPayment(int customerID, double amount) {
        try {
            // Get customer credit info
            String sql = "SELECT credit_limit, outstanding_balance, account_status FROM ca_customers WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerID);

            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                System.out.println("Customer not found");
                return false;
            }

            double creditLimit = rs.getDouble("credit_limit");
            double balance = rs.getDouble("outstanding_balance");
            String status = rs.getString("account_status");

            // Block purchase if account is IN_DEFAULT
            if (status.equalsIgnoreCase("IN_DEFAULT")) {
                System.out.println("Account is IN_DEFAULT - no purchases allowed");
                return false;
            }

            // Check if payment would exceed limit
            if ((balance + amount) > creditLimit) {
                System.out.println("Credit limit exceeded");
                return false;
            }

            // Update balance
            String updateBalance = "UPDATE ca_customers SET outstanding_balance = outstanding_balance + ? WHERE customer_id = ?";
            PreparedStatement psUpdate = conn.prepareStatement(updateBalance);
            psUpdate.setDouble(1, amount);
            psUpdate.setInt(2, customerID);
            psUpdate.executeUpdate();

            // Record payment
            String insertPayment = "INSERT INTO ca_payments (payment_id, customer_id, payment_method, amount) VALUES (?, ?, ?, ?)";
            PreparedStatement psPayment = conn.prepareStatement(insertPayment);
            psPayment.setInt(1, (int)(Math.random() * 100000)); // TEMP ID
            psPayment.setInt(2, customerID);
            psPayment.setString(3, "CREDIT");
            psPayment.setDouble(4, amount);
            psPayment.executeUpdate();

            System.out.println("Credit payment processed: £" + amount);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }
    /**
     * Pay by card payment in db
     */
    @Override
    public boolean processCardPayment(String orderID, String cardNumber, String expiry, double amount) {

        try {
            // Online orders must exist in ca_online_orders. Frontend-generated ONL IDs are allowed.
            if (!isFrontendOrder(orderID) && !onlineOrderExists(orderID)) {
                System.out.println("Payment failed: order not found");
                return false;
            }

            // Basic validation
            if (cardNumber.length() < 8) {
                System.out.println("Payment failed: invalid card");
                return false;
            }

            // Frontend ONL payments are persisted after sale_id is created in recordCustomerPurchase.
            if (isFrontendOrder(orderID)) {
                return true;
            }

            // Insert payment record
            String sql = "INSERT INTO ca_payments (payment_id, sale_id, payment_method, amount) VALUES (?, NULL, ?, ?)";

            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, (int)(Math.random() * 100000)); // TEMP ID
            ps.setString(2, "CARD");
            ps.setDouble(3, amount);

            ps.executeUpdate();

            System.out.println("Payment successful for order: " + orderID);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Pay by cash
     * Used mainly for non-account customers
     */
    @Override
    public boolean processCashPayment(String orderID, double amount) {

        try {
            // Online orders must exist in ca_online_orders. Frontend-generated ONL IDs are allowed.
            if (!isFrontendOrder(orderID) && !onlineOrderExists(orderID)) {
                System.out.println("Cash payment failed: order not found");
                return false;
            }

            // Frontend ONL payments are persisted after sale_id is created in recordCustomerPurchase.
            if (isFrontendOrder(orderID)) {
                return true;
            }

            //insert payment
            String sql = "INSERT INTO ca_payments (payment_id, payment_method, amount) VALUES (?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, (int)(Math.random() * 100000)); // TEMP
            ps.setString(2, "CASH");
            ps.setDouble(3, amount);

            ps.executeUpdate();

            System.out.println("Cash payment successful for order: " + orderID);
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * CHECK ACCOUNT BALANCE
     */
    public double getCustomerBalance(int customerID) {

        try {
            String sql = "SELECT outstanding_balance FROM ca_customers WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerID);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getDouble("outstanding_balance");
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return 0;
    }

    /**
     * SET CREDIT LIMIT
     */
    public boolean setCreditLimit(int customerID, double limit) {

        try {
            String sql = "UPDATE ca_customers SET credit_limit = ? WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setDouble(1, limit);
            ps.setInt(2, customerID);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * Update account status (NORMAL / SUSPENDED / IN_DEFAULT)
     */
    public boolean updateAccountStatus(int customerID, String status) {

        try {
            String sql = "UPDATE ca_customers SET account_status = ? WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setString(1, status.toUpperCase());
            ps.setInt(2, customerID);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * AUTO-SUSPEND ACCOUNT (Calendar-based)
     * Moves account to SUSPENDED if:
     * - Current date is between 15th and end of month (payment deadline was 15th of current month)
     * - Full payment not received from previous month's purchases
     * - Account is currently NORMAL
     */
    public boolean autoSuspendAccount(int customerID) {
        try {
            LocalDate today = LocalDate.now();
            int dayOfMonth = today.getDayOfMonth();

            // Only suspend between 15th and end of month
            if (dayOfMonth < 15) {
                return false;
            }

            String sql = "SELECT outstanding_balance, account_status FROM ca_customers WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerID);

            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                System.out.println("Customer not found");
                return false;
            }

            double balance = rs.getDouble("outstanding_balance");
            String status = rs.getString("account_status");

            // Only suspend if currently NORMAL
            if (!status.equalsIgnoreCase("NORMAL")) {
                return false;
            }

            // Suspend if balance > 0 (has unpaid charges)
            if (balance > 0) {
                String updateSql = "UPDATE ca_customers SET account_status = 'SUSPENDED' WHERE customer_id = ?";
                PreparedStatement psUpdate = conn.prepareStatement(updateSql);
                psUpdate.setInt(1, customerID);
                psUpdate.executeUpdate();

                System.out.println("Account suspended - unpaid balance from previous month");
                return true;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * AUTO-MOVE TO IN_DEFAULT (Calendar-based)
     * Moves account to IN_DEFAULT if:
     * - Current date is end of calendar month (31st or last day)
     * - Full payment not received
     * - Account is currently SUSPENDED
     */
    public boolean autoMoveToDefault(int customerID) {
        try {
            LocalDate today = LocalDate.now();
            LocalDate lastDayOfMonth = today.withDayOfMonth(today.lengthOfMonth());

            // Only check end of month
            if (!today.equals(lastDayOfMonth)) {
                return false;
            }

            String sql = "SELECT outstanding_balance, account_status FROM ca_customers WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerID);

            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                System.out.println("Customer not found");
                return false;
            }

            double balance = rs.getDouble("outstanding_balance");
            String status = rs.getString("account_status");

            // Only default if currently SUSPENDED and balance unpaid
            if (status.equalsIgnoreCase("SUSPENDED") && balance > 0) {
                String updateSql = "UPDATE ca_customers SET account_status = 'IN_DEFAULT' WHERE customer_id = ?";
                PreparedStatement psUpdate = conn.prepareStatement(updateSql);
                psUpdate.setInt(1, customerID);
                psUpdate.executeUpdate();

                System.out.println("Account moved to IN_DEFAULT - payment still not received");
                return true;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

    /**
     * MANAGER REACTIVATION
     * Allows manager to manually restore an IN_DEFAULT account back to NORMAL status
     * Only by explicit manager intervention
     */
public boolean managerReactivateAccount(int customerID) {
    try {
        String sql = "SELECT account_status, outstanding_balance FROM ca_customers WHERE customer_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, customerID);

        ResultSet rs = ps.executeQuery();

        if (!rs.next()) {
            System.out.println("Customer not found");
            return false;
        }

        String status = rs.getString("account_status");
        double balance = rs.getDouble("outstanding_balance");

        if (!status.equalsIgnoreCase("IN_DEFAULT")) {
            System.out.println("Account is not IN_DEFAULT - cannot reactivate");
            return false;
        }

        if (balance > 0) {
            System.out.println("Account still has unpaid balance - cannot reactivate");
            return false;
        }

        String updateSql = "UPDATE ca_customers SET account_status = 'NORMAL' WHERE customer_id = ?";
        PreparedStatement psUpdate = conn.prepareStatement(updateSql);
        psUpdate.setInt(1, customerID);
        psUpdate.executeUpdate();

        System.out.println("Account reactivated by manager");
        return true;

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

public boolean recordAccountPayment(int customerID, double amount) {
    try {
        String sql = "SELECT outstanding_balance FROM ca_customers WHERE customer_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, customerID);
        ResultSet rs = ps.executeQuery();

        if (!rs.next()) {
            System.out.println("Customer not found");
            return false;
        }

        double balance = rs.getDouble("outstanding_balance");

        if (amount <= 0) {
            System.out.println("Invalid payment amount");
            return false;
        }

        double newBalance = Math.max(0, balance - amount);

        String updateSql = "UPDATE ca_customers SET outstanding_balance = ? WHERE customer_id = ?";
        PreparedStatement psUpdate = conn.prepareStatement(updateSql);
        psUpdate.setDouble(1, newBalance);
        psUpdate.setInt(2, customerID);
        psUpdate.executeUpdate();

        String insertPayment = "INSERT INTO ca_payments (payment_id, customer_id, payment_method, amount) VALUES (?, ?, ?, ?)";
        PreparedStatement psPayment = conn.prepareStatement(insertPayment);
        psPayment.setInt(1, (int)(Math.random() * 100000));
        psPayment.setInt(2, customerID);
        psPayment.setString(3, "ACCOUNT_PAYMENT");
        psPayment.setDouble(4, amount);
        psPayment.executeUpdate();

        System.out.println("Account payment recorded: £" + amount);
        return true;

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

 // NOTE FROM LUKE:
    // On the Sales screen, the frontend already calls the correct backend payment method
    // depending on whether the customer pays by CARD or CASH.
    //
    // This method is separate from taking payment.
    // Its purpose is to record what the customer actually bought.
    //
    // The frontend currently calls this method and passes in the sale items.
    // Later, (i think) this method should save those sale items to the SQL database,
    // probably into ca_sales and ca_sale_items. Let me know if i got anything wrong.

    //    System.out.println("Recording customer purchase (stub only - no database write yet)");
    //    System.out.println("Customer ID: " + customerID);
    //    System.out.println("Total Amount: " + totalAmount);
    //    System.out.println("Payment Method: " + paymentMethod);
    //    System.out.println("Sale Items:");
    //
    //    if (saleItems == null || saleItems.isEmpty()) {
    //        System.out.println("  No sale items supplied");
    //    } else {
    //        for (Object[] item : saleItems) {
    //            Object productId = item.length > 0 ? item[0] : "UNKNOWN";
    //            Object quantity = item.length > 1 ? item[1] : "UNKNOWN";
    //            Object unitPrice = item.length > 2 ? item[2] : "UNKNOWN";
    //
    //            System.out.println("  Product ID: " + productId
    //                + ", Quantity: " + quantity
    //                + ", Unit Price: " + unitPrice);
    //        }
    //    }

    //System.out.println("Next backend step: insert into ca_sales, ca_sale_items, and ca_payments.");
   // return true;
//}

    /**
     * statement making
     * creates statements for account holders with unpaid balances from previous month
     * Accessible only between 5th-15th of current month
     * Returns list of statements generated
     */
    public List<String> generateStatements() {
        List<String> statementsGenerated = new ArrayList<>();

        try {
            LocalDate today = LocalDate.now();
            int dayOfMonth = today.getDayOfMonth();

            // Check if within allowed dates given
            if (dayOfMonth < 5 || dayOfMonth > 15) {
                System.out.println("Statements can only be generated between 5th-15th of the month");
                return statementsGenerated;
            }

            YearMonth previousMonth = YearMonth.now().minusMonths(1);

            // Get all customers with outstanding balance
            String sql = "SELECT customer_id, firstname, surname, outstanding_balance, credit_limit FROM ca_customers WHERE outstanding_balance > 0";
            PreparedStatement ps = conn.prepareStatement(sql);

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                int customerId = rs.getInt("customer_id");
                String firstName = rs.getString("firstname");
                String surname = rs.getString("surname");
                double balance = rs.getDouble("outstanding_balance");
                double creditLimit = rs.getDouble("credit_limit");

                // Create statement record
                String insertStmt = "INSERT INTO ca_statements (customer_id, period_start, period_end) VALUES (?, ?, ?)";
                PreparedStatement psInsert = conn.prepareStatement(insertStmt);
                psInsert.setInt(1, customerId);
                psInsert.setString(2, previousMonth.atDay(1).toString());
                psInsert.setString(3, previousMonth.atEndOfMonth().toString());
                psInsert.executeUpdate();

                String statementMsg = String.format(
                    "Statement for %s %s: Balance £%.2f due by 15th. Credit Limit: £%.2f",
                    firstName, surname, balance, creditLimit
                );
                statementsGenerated.add(statementMsg);

                System.out.println(statementMsg);
            }

            System.out.println("Statements generated: " + statementsGenerated.size());

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return statementsGenerated;
    }
    
    public boolean autoRestoreAccount(int customerID) {
    try {
        String sql = "SELECT outstanding_balance, account_status FROM ca_customers WHERE customer_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, customerID);

        ResultSet rs = ps.executeQuery();

        if (!rs.next()) {
            System.out.println("Customer not found");
            return false;
        }

        double balance = rs.getDouble("outstanding_balance");
        String status = rs.getString("account_status");

        if (balance <= 0 && status.equalsIgnoreCase("SUSPENDED")) {
            String updateSql = "UPDATE ca_customers SET account_status = 'NORMAL' WHERE customer_id = ?";
            PreparedStatement psUpdate = conn.prepareStatement(updateSql);
            psUpdate.setInt(1, customerID);
            psUpdate.executeUpdate();

            System.out.println("Account automatically restored to NORMAL");
            return true;
        }

    } catch (SQLException e) {
        e.printStackTrace();
    }

    return false;
}

    /**
     * GENERATE REMINDERS
     * Generates 1st and 2nd reminders based on account status
     * Uses ca_payment_reminders table to track reminder state
     * 
     * 1st Reminder: for suspended accounts using localDate.now()
     *   - Payment due = current date + 7 days
     * 2nd Reminder: for IN_DEFAULT accounts
     *   - Payment due = current date + 7 days
     */
    public List<String> generateReminders() {
        List<String> remindersGenerated = new ArrayList<>();

        try {
            LocalDate today = LocalDate.now();
            LocalDate paymentDue = today.plusDays(7);

            // Get all customers with unpaid balances
            String sql = "SELECT customer_id, firstname, surname, outstanding_balance, account_status FROM ca_customers WHERE outstanding_balance > 0";
            PreparedStatement ps = conn.prepareStatement(sql);

            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                int customerId = rs.getInt("customer_id");
                String firstName = rs.getString("firstname");
                String surname = rs.getString("surname");
                double balance = rs.getDouble("outstanding_balance");
                String accountStatus = rs.getString("account_status");

                // Generate 1st Reminder for SUSPENDED accounts (if not already sent)
                if (accountStatus.equalsIgnoreCase("SUSPENDED")) {
                    // Check if 1st reminder already sent in this suspension cycle
                    String check1st = "SELECT COUNT(*) as count FROM ca_payment_reminders WHERE customer_id = ? AND reminder_type = '1st' AND status = 'GENERATED'";
                    PreparedStatement psCheck1st = conn.prepareStatement(check1st);
                    psCheck1st.setInt(1, customerId);
                    ResultSet rsCheck1st = psCheck1st.executeQuery();

                    if (rsCheck1st.next() && rsCheck1st.getInt("count") == 0) {
                        String reminderMsg = String.format(
                            "1st REMINDER: %s %s - Please pay £%.2f by %s (7 days). Account will be escalated if unpaid.",
                            firstName, surname, balance, paymentDue
                        );
                        remindersGenerated.add(reminderMsg);
                        System.out.println(reminderMsg);

                        // Record reminder in database
                        String insertReminder = "INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, status) VALUES (?, ?, ?, ?)";
                        PreparedStatement psInsert = conn.prepareStatement(insertReminder);
                        psInsert.setInt(1, (int)(Math.random() * 100000));
                        psInsert.setInt(2, customerId);
                        psInsert.setString(3, "1st");
                        psInsert.setString(4, "GENERATED");
                        psInsert.executeUpdate();
                    }
                }

                // Generate 2nd Reminder for IN_DEFAULT accounts (if not already sent)
                if (accountStatus.equalsIgnoreCase("IN_DEFAULT")) {
                    // Check if 2nd reminder already sent in this default cycle
                    String check2nd = "SELECT COUNT(*) as count FROM ca_payment_reminders WHERE customer_id = ? AND reminder_type = '2nd' AND status = 'GENERATED'";
                    PreparedStatement psCheck2nd = conn.prepareStatement(check2nd);
                    psCheck2nd.setInt(1, customerId);
                    ResultSet rsCheck2nd = psCheck2nd.executeQuery();

                    if (rsCheck2nd.next() && rsCheck2nd.getInt("count") == 0) {
                        LocalDate paymentDue2nd = today.plusDays(7);
                        String reminderMsg = String.format(
                            "2nd REMINDER: %s %s - FINAL NOTICE: Pay £%.2f by %s or account will be escalated further.",
                            firstName, surname, balance, paymentDue2nd
                        );
                        remindersGenerated.add(reminderMsg);
                        System.out.println(reminderMsg);

                        // Record reminder in database
                        String insertReminder = "INSERT INTO ca_payment_reminders (reminder_id, customer_id, reminder_type, status) VALUES (?, ?, ?, ?)";
                        PreparedStatement psInsert = conn.prepareStatement(insertReminder);
                        psInsert.setInt(1, (int)(Math.random() * 100000));
                        psInsert.setInt(2, customerId);
                        psInsert.setString(3, "2nd");
                        psInsert.setString(4, "GENERATED");
                        psInsert.executeUpdate();
                    }
                }
            }

            System.out.println("Reminders generated: " + remindersGenerated.size());

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return remindersGenerated;
    }

    /**
     * CHECK AND AUTO-UPDATE ALL ACCOUNTS
     * Batch process to check all customer accounts and apply automatic status changes
     * Should be run periodically (e.g., daily via scheduled task)
     */
public void checkAndAutoUpdateAllAccounts() {
    try {
        String sql = "SELECT customer_id FROM ca_customers";
        PreparedStatement ps = conn.prepareStatement(sql);

        ResultSet rs = ps.executeQuery();

        int restoredCount = 0;
        int suspendCount = 0;
        int defaultCount = 0;

        while (rs.next()) {
            int customerId = rs.getInt("customer_id");

            if (autoRestoreAccount(customerId)) {
                restoredCount++;
            } else if (autoMoveToDefault(customerId)) {
                defaultCount++;
            } else if (autoSuspendAccount(customerId)) {
                suspendCount++;
            }
        }

        System.out.println("Batch account status update complete:");
        System.out.println("  - Accounts restored: " + restoredCount);
        System.out.println("  - Accounts suspended: " + suspendCount);
        System.out.println("  - Accounts moved to IN_DEFAULT: " + defaultCount);

    } catch (SQLException e) {
        e.printStackTrace();
    
        }
}
    
    
    @Override
public boolean recordCustomerPurchase(int customerID, List<Object[]> saleItems, double totalAmount, String paymentMethod) {
    if (saleItems == null || saleItems.isEmpty()) {
        System.out.println("Sale recording failed: no sale items supplied");
        return false;
    }

    boolean previousAutoCommit = true;

    try {
        previousAutoCommit = conn.getAutoCommit();
        conn.setAutoCommit(false);

        int saleId = getNextId("ca_sales", "sale_id");
        String saleSql = "INSERT INTO ca_sales (sale_id, customer_id, total_amount, payment_deferred, sale_source) VALUES (?, ?, ?, ?, ?)";
        PreparedStatement salePs = conn.prepareStatement(saleSql);
        salePs.setInt(1, saleId);

        if (customerID > 0) {
            salePs.setInt(2, customerID);
        } else {
            salePs.setNull(2, Types.INTEGER);
        }

        salePs.setDouble(3, totalAmount);
        salePs.setInt(4, "CREDIT".equalsIgnoreCase(paymentMethod) || "ACCOUNT".equalsIgnoreCase(paymentMethod) ? 1 : 0);
        salePs.setString(5, "IN_STORE");
        salePs.executeUpdate();

        String normalizedMethod = paymentMethod == null ? "UNKNOWN" : paymentMethod.trim().toUpperCase();
        if ("CASH".equals(normalizedMethod) || "CARD".equals(normalizedMethod)) {
            String paymentSql = "INSERT INTO ca_payments (payment_id, customer_id, sale_id, payment_method, amount) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement payPs = conn.prepareStatement(paymentSql);
            payPs.setInt(1, getNextId("ca_payments", "payment_id"));

            if (customerID > 0) {
                payPs.setInt(2, customerID);
            } else {
                payPs.setNull(2, Types.INTEGER);
            }

            payPs.setInt(3, saleId);
            payPs.setString(4, normalizedMethod);
            payPs.setDouble(5, totalAmount);
            payPs.executeUpdate();
        }

        int nextSaleItemId = getNextId("ca_sale_items", "sale_item_id");
        String itemSql = "INSERT INTO ca_sale_items (sale_item_id, sale_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?, ?)";
        PreparedStatement itemPs = conn.prepareStatement(itemSql);

        int insertedItems = 0;

        for (Object[] item : saleItems) {
            if (item == null || item.length < 3 || !(item[0] instanceof Number)
                    || !(item[1] instanceof Number) || !(item[2] instanceof Number)) {
                continue;
            }

            int productId = ((Number) item[0]).intValue();
            int quantity = ((Number) item[1]).intValue();
            double unitPrice = ((Number) item[2]).doubleValue();

            itemPs.setInt(1, nextSaleItemId++);
            itemPs.setInt(2, saleId);
            itemPs.setInt(3, productId);
            itemPs.setInt(4, quantity);
            itemPs.setDouble(5, unitPrice);
            itemPs.addBatch();
            insertedItems++;
        }

        if (insertedItems == 0) {
            conn.rollback();
            System.out.println("Sale recording failed: no valid items supplied");
            return false;
        }

        itemPs.executeBatch();
        conn.commit();
        System.out.println("Sale recorded successfully. Sale ID: " + saleId + ", items: " + insertedItems);
        return true;

    } catch (SQLException e) {
        try {
            conn.rollback();
        } catch (SQLException rollbackEx) {
            rollbackEx.printStackTrace();
        }
        e.printStackTrace();
        return false;
    } finally {
        try {
            conn.setAutoCommit(previousAutoCommit);
        } catch (SQLException ignored) {
        }
    }
    
}

    
    
    @Override
public double getTotalSales() throws SQLException {
    String sql = "SELECT COALESCE(SUM(total_amount), 0) AS total_sales FROM ca_sales";
    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();
    return rs.next() ? rs.getDouble("total_sales") : 0.0;
}

@Override
public int getTransactionCount() throws SQLException {
    String sql = "SELECT COUNT(*) AS transaction_count FROM ca_sales";
    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();
    return rs.next() ? rs.getInt("transaction_count") : 0;
}

@Override
public int getOrdersPlacedCount() throws SQLException {
    String sql = "SELECT COUNT(*) AS order_count FROM ca_online_orders";
    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();
    return rs.next() ? rs.getInt("order_count") : 0;
}

@Override
public List<Object[]> getTopSellingProducts() throws SQLException {
    List<Object[]> rows = new ArrayList<>();

    String sql =
        "SELECT p.product_name, " +
        "       SUM(si.quantity) AS units_sold, " +
        "       SUM(si.quantity * si.unit_price) AS revenue " +
        "FROM ca_sale_items si " +
        "JOIN ca_products p ON si.product_id = p.product_id " +
        "GROUP BY p.product_id, p.product_name " +
        "ORDER BY units_sold DESC, revenue DESC " +
        "LIMIT 10";

    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();

    while (rs.next()) {
        rows.add(new Object[] {
            rs.getString("product_name"),
            rs.getInt("units_sold"),
            rs.getDouble("revenue")
        });
    }

    return rows;
}



@Override
public List<Object[]> getSalesReportRows() throws SQLException {
    List<Object[]> rows = new ArrayList<>();

    String sql =
        "SELECT s.sale_id, " +
        "       DATE(s.sale_date) AS sale_date, " +
        "       CASE WHEN s.customer_id IS NULL THEN 'Occasional Customer' ELSE 'Account Holder' END AS customer_type, " +
        "       COALESCE(p.payment_method, CASE WHEN s.payment_deferred = 1 THEN 'ACCOUNT' ELSE 'UNKNOWN' END) AS payment_method, " +
        "       s.total_amount " +
        "FROM ca_sales s " +
        "LEFT JOIN ca_payments p ON s.sale_id = p.sale_id " +
        "ORDER BY s.sale_date DESC, s.sale_id DESC";

    PreparedStatement ps = conn.prepareStatement(sql);
    ResultSet rs = ps.executeQuery();

    while (rs.next()) {
        rows.add(new Object[] {
            "SAL-" + rs.getInt("sale_id"),
            rs.getString("sale_date"),
            rs.getString("customer_type"),
            rs.getString("payment_method"),
            String.format("£%.2f", rs.getDouble("total_amount"))
        });
    }

    return rows;
}
    
}


    
