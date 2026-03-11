

public interface SA_ORD_API {   

    abstract String newOrder();  

    abstract void addItems(String orderID, int[] itemIDs, int[] quantities);   

    abstract void removeItems(String orderID, int[] itemIDs, int[] quantitiesToRemove);  

    abstract void submitOrder(String orderID);

    abstract Catalogue getActiveCatalogue(); 
    
}
