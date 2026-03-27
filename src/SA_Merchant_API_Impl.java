import java.util.*;

public class SA_Merchant_API_Impl implements SA_Merchant_API {
    // these are just temporary until the databases are in effect

    // userID -> outstanding balance
    private Map<String, Double> balances = new HashMap<>();

    // userID -> (userStatus, userType)
    private Map<String, Map<String, String>> users = new HashMap<>();

    private Map<String, String> userInfo = new HashMap<>();


    SA_Merchant_API_Impl(){
        String orderID = UUID.randomUUID().toString();
        String orderID2 = UUID.randomUUID().toString();
        String orderID3 = UUID.randomUUID().toString();

        balances.put("0001", new Double(1000.00));
        balances.put("0002", new Double(590.00));
        balances.put("0003", new Double(0.00));

        userInfo.put("suspended", "merchant");
        users.put("0001",userInfo);
        userInfo.put("active", "merchant");
        users.put("0002",userInfo);
        userInfo.put("active", "admin");
        users.put("0003",userInfo);







    }

    // Will have to be changed when we start communicating with IPOS-SA.
    //Invoice getInvoice(String orderID){
    //    return new Invoice(orderID);
    //
    //
    //};


    public double getBalance(String userID) {
        if (!balances.containsKey(userID)){

            throw new IllegalArgumentException("User " + userID + " does not exist");
        }
        else if (userInfo.containsValue("suspended")) {
            throw new IllegalArgumentException("User " + userID + " is suspended");
        }
        else{

        return balances.get(userID);
        }


    }


//    public Invoice[] getDuePayments(){
//
//    };

}
