

public interface CA_OnlineOrderAPI {

    abstract void processOnlineOrder(String orderID, String basketOrder);

    abstract int checkProductStock(String productID);

    abstract String[] getMerchangtCatalogue(String searchTerm);
}
