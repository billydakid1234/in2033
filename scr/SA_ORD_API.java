import java.util.*;

public class SA_ORD_API {

    // these are just temporary until the databases are in effect

    // orderID -> (itemID -> quantity)
    private Map<String, Map<Integer, Integer>> orders = new HashMap<>();

    // itemID -> name
    private Map<Integer, String> catalogue = new HashMap<>();

    // itemID -> quantity
    private Map<Integer, Integer> stock = new HashMap<>();

    // used in the map to simulate the data base

    public SA_ORD_API() {
        catalogue.put(1, "Paracetamol");
        catalogue.put(2, "Ibuprofen");
        catalogue.put(3, "Aspirin");

        stock.put(1, 50);
        stock.put(2, 30);
        stock.put(3, 20);
    }

    // create a new order
    public String newOrder() {
        String orderID = UUID.randomUUID().toString(); //random string as order ID so we never have repeats
        orders.put(orderID, new HashMap<>());
        return orderID;
    }

    // add items to an order
    public void addItems(String orderID, int[] itemIDs, int[] quantities) {
        if (!orders.containsKey(orderID)) return;  // checks if order is real
        Map<Integer, Integer> orderItems = orders.get(orderID); //retrieve the map for the order will be moved to db whenever that happens
        for (int i = 0; i < itemIDs.length; i++) {
            int id = itemIDs[i];
            int qty = quantities[i];
            if (catalogue.containsKey(id) && qty > 0) { // check if it exist and has a +ive quanty
                orderItems.put(id, orderItems.getOrDefault(id, 0) + qty); // check for item quant if no item then it has a auto value of 0
            }
        }
    }

    // remove items from an order
    public void removeItems(String orderID, int[] itemIDs, int[] quantities) {
        if (!orders.containsKey(orderID)) return; // checks if order is real
        Map<Integer, Integer> orderItems = orders.get(orderID); //retrieve the map for the order will be moved to db whenever that happens
        for (int i = 0; i < itemIDs.length; i++) {
            int id = itemIDs[i];
            int qty = quantities[i];
            if (orderItems.containsKey(id)) {
                int newQty = orderItems.get(id) - qty;
                if (newQty > 0) orderItems.put(id, newQty);
                else orderItems.remove(id); 
            } // ^^ checks if its there. if it is subtrack value is it > 0 update if = or < 0 then remove it
        }
    }

    // submit order: only accepts if stock is enough
    public void submitOrder(String orderID) {
        if (!orders.containsKey(orderID)) return;  
        Map<Integer, Integer> orderItems = orders.get(orderID); // checks if order is real and get map

        if (orderItems.isEmpty()) { // is it  empty
            System.out.println("Order is empty.");
            return;
        }

        // check if stock is sufficient for all items
        for (Map.Entry<Integer, Integer> e : orderItems.entrySet()) {
            int itemID = e.getKey();
            int qty = e.getValue();
            if (stock.getOrDefault(itemID, 0) < qty) { //checks each item with the stock if it is insufficient then it rejects the order
                System.out.println("Order rejected: not enough stock for " + catalogue.get(itemID));
                return;
            }
        }

        // reduce stock for all items in the ordeer by their quantity
        for (Map.Entry<Integer, Integer> e : orderItems.entrySet()) {
            int itemID = e.getKey();
            stock.put(itemID, stock.get(itemID) - e.getValue());
        }

        System.out.println("Order accepted: " + orderID); // accepts the order
    }

    // view order with item names and quantities
    public Map<String, Integer> viewOrder(String orderID) {
        if (!orders.containsKey(orderID)) return null; // Checks order exists
        Map<String, Integer> result = new HashMap<>(); // Creates a new map to store readable output
        for (Map.Entry<Integer, Integer> e : orders.get(orderID).entrySet()) {
            result.put(catalogue.get(e.getKey()), e.getValue()); // Maps itemID to itemName and copies quantity and returns the map in written form
        }
        return result;
    }

    // view current stock makes the map readable
    public Map<String, Integer> viewStock() {
        Map<String, Integer> result = new HashMap<>();
        for (Map.Entry<Integer, Integer> e : stock.entrySet()) {
            result.put(catalogue.get(e.getKey()), e.getValue());
        }
        return result;
    }

    // view catalogue (names only. would be itemId to name)
    public Map<Integer, String> getCatalogue() {
        return new HashMap<>(catalogue);
    }
}

// i have tests for these in a seperate intellij file ask if you want to test the methods -> Dylan