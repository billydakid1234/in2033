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
}