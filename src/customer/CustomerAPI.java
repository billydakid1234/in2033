/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package customer;

import java.util.List;

/**
 *
 * @author laraashour
 */

public interface CustomerAPI {
    boolean addCustomer(String firstName,
                        String surname,
                        String dob,
                        String email,
                        String phone,
                        int houseNumber,
                        String postcode,
                        double creditLimit) throws Exception;

    List<Customer> getAllCustomers() throws Exception;

    boolean deleteCustomer(String accountId) throws Exception;

    boolean customerExists(String accountId) throws Exception;

    void normaliseStatuses() throws Exception;
    
    void updateAccountStatuses() throws Exception;
    
    boolean setDiscountPlan(String accountId, String planType, double discountValue) throws Exception;

    boolean modifyDiscountPlan(String accountId, String planType, double discountValue) throws Exception;

    boolean deleteDiscountPlan(String accountId) throws Exception;

    String getDiscountPlan(String accountId) throws Exception;
    
    void updateReminderStatuses() throws Exception;
    
    int generateReminders() throws Exception;
    
    void clearReminderStatusesIfPaid(String accountId) throws Exception;
    




}