package merchant;



import java.util.List;




public interface SA_Merchant_API{ 

    double getCustomerBalance(int customerID); 

    boolean setCreditLimit(int customerID, double newLimit);

    boolean updateAccountStatus(int customerID, String status);
    
    boolean processCreditPayment(int customerID, double amount);

    boolean processCardPayment(String orderID, String cardNumber, String expiry, double amount);

    boolean processCashPayment(String orderID, double amount);

    boolean autoSuspendAccount(int customerID);

    boolean autoMoveToDefault(int customerID);

    boolean managerReactivateAccount(int customerID);

    List<String> generateStatements();

    List<String> generateReminders();

    void checkAndAutoUpdateAllAccounts();

}
