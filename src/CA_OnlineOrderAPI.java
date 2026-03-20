

public interface CA_OnlineOrderAPI {


    /** 
    * 
    * @param orderId 
    * @param basketOrder 
    */

    abstract void processOnlineOrder(String orderID, String basketOrder);

    /** 
    * 
    * @param productId 
    */

    abstract int checkProductStock(String productID);

    /** 
    * 
    * @param searchTerm
    */

    abstract String[] getMerchangtCatalogue(String searchTerm);
}
