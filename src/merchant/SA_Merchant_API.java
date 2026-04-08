package merchant;

import java.sql.SQLException;
import java.util.List;

public interface SA_Merchant_API { 

    double getCustomerBalance(int customerID); 

    boolean setCreditLimit(int customerID, double newLimit);

    boolean updateAccountStatus(int customerID, String status);
    
    boolean processCreditPayment(int customerID, double amount);

    boolean processCardPayment(String orderID, String cardNumber, String expiry, double amount);

    boolean processCashPayment(String orderID, double amount);

    boolean autoSuspendAccount(int customerID);

    boolean autoMoveToDefault(int customerID);

    boolean autoRestoreAccount(int customerID);

    boolean managerReactivateAccount(int customerID);

    boolean recordAccountPayment(int customerID, double amount);

    boolean recordCustomerPurchase(int customerID, List<Object[]> saleItems, double totalAmount, String paymentMethod);

    List<String> generateStatements();

    List<String> generateReminders();

    void checkAndAutoUpdateAllAccounts();

    double getTotalSales() throws SQLException;

    int getTransactionCount() throws SQLException;

    int getOrdersPlacedCount() throws SQLException;

    List<Object[]> getTopSellingProducts() throws SQLException;

    List<Object[]> getSalesReportRows() throws SQLException;
}


