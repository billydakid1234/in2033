public class CA_OnlineOrderAPI_Impl implements CA_OnlineOrderAPI { 

    private StockRepository stockRepository;  

    private SalesRepository salesRepository;  


    public CA_OnlineOrderAPI_Impl( StockRepository stockRepository, SalesRepository salesRepository)

    public void processOnlineOrder(String orderID, String basketOrder)

    private boolean reduceStock(String productID, int quantity)

    public String[] getMerchantCatalogue(String searchTerm)

    public int checkProductStock(String productID)
    
}
