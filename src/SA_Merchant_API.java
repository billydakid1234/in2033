
public interface SA_Merchant_API{ 

    /** 
    * 
    * @param orderId 
    */ 

    //abstract Invoice getInvoice(String orderID); 

    /** 
    * 
    * @param orderId 
    */ 

    //abstract String[] getOrderStatus(String orderID);

    double getBalance(int customerID); 

    boolean setCreditLimit(int customerID, double newLimit);

    boolean updateAccountStatus(int customerID, String status);
    
    //abstract Invoice[] getDuePayments(); 

}
