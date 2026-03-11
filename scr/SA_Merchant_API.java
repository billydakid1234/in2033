
public interface SA_Merchant_API{ 

    abstract Invoice getInvoice(String orderID); 

    abstract String[] getOrderStatus(String orderID);

    abstract double getBalance(); 
    
    abstract Invoice[] getDuePayments(); 

}
