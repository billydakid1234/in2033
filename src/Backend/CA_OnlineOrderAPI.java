package Backend;


//Just method calls for the impl class if you need to understand how it works check comments or contact Dylan

public interface CA_OnlineOrderAPI {

    void processOnlineOrder(String orderID, String basketOrder);

    int checkProductStock(String productID);

    String[] getMerchantCatalogue(String searchTerm);

    boolean payByCard(String orderID, String cardNumber, String expiry);

    boolean payByCash(String orderID, double amount);

    boolean payByCredit(String orderID, int customerID, double amount);

    String generateReceipt(String orderID);

    String getOrderStatus(String orderID);

    String createOrder();
}
