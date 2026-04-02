import java.sql.*;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

public class SA_Merchant_API_Impl implements SA_Merchant_API {

    private Connection conn;

    public SA_Merchant_API_Impl(Connection conn) {
        this.conn = conn;
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
            // Check order exists
            String check = "SELECT online_order_id FROM ca_online_orders WHERE online_order_id = ?";
            PreparedStatement psCheck = conn.prepareStatement(check);
            psCheck.setString(1, orderID);

            ResultSet rs = psCheck.executeQuery();

            if (!rs.next()) {
                System.out.println("Payment failed: order not found");
                return false;
            }

            // Basic validation
            if (cardNumber.length() < 8) {
                System.out.println("Payment failed: invalid card");
                return false;
            }

            // Insert payment record
            String sql = "INSERT INTO ca_payments (payment_id, sale_id, payment_method, amount) VALUES (?, NULL, ?, ?)";

            PreparedStatement ps = conn.prepareStatement(sql);

            ps.setInt(1, (int)(Math.random() * 100000)); // TEMP ID
            ps.setString(2, "CARD");
            ps.setDouble(3, 0.0); // you can calculate real total later

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
            // check order exists
            String check = "SELECT online_order_id FROM ca_online_orders WHERE online_order_id = ?";
            PreparedStatement psCheck = conn.prepareStatement(check);
            psCheck.setString(1, orderID);

            ResultSet rs = psCheck.executeQuery();

            if (!rs.next()) {
                System.out.println("Cash payment failed: order not found");
                return false;
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
            String sql = "SELECT account_status FROM ca_customers WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerID);

            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                System.out.println("Customer not found");
                return false;
            }

            String status = rs.getString("account_status");

            // Only reactivate if currently IN_DEFAULT
            if (!status.equalsIgnoreCase("IN_DEFAULT")) {
                System.out.println("Account is not IN_DEFAULT - cannot reactivate");
                return false;
            }

            String updateSql = "UPDATE ca_customers SET account_status = 'NORMAL' WHERE customer_id = ?";
            PreparedStatement psUpdate = conn.prepareStatement(updateSql);
            psUpdate.setInt(1, customerID);
            psUpdate.executeUpdate();

            System.out.println("Account reactivated by manager - status changed from IN_DEFAULT to NORMAL");
            return true;

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return false;
    }

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

            int suspendCount = 0;
            int defaultCount = 0;

            while (rs.next()) {
                int customerId = rs.getInt("customer_id");

                // Check for default first (most severe)
                if (autoMoveToDefault(customerId)) {
                    defaultCount++;
                } else if (autoSuspendAccount(customerId)) {
                    suspendCount++;
                }
            }

            System.out.println("Batch account status update complete:");
            System.out.println("  - Accounts suspended: " + suspendCount);
            System.out.println("  - Accounts moved to IN_DEFAULT: " + defaultCount);

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}