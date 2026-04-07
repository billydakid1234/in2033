/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package customer;

/**
 *
 * @author laraashour
 */


public class Customer {

    private String accountId;
    private String firstName;
    private String surname;
    private String email;
    private String phone;
    private double creditLimit;
    private String accountStatus;
    private double outstandingBalance;
    private String firstReminderStatus;
    private String secondReminderStatus;
    private String firstReminderDate;
    private String secondReminderDate;

    public Customer(String accountId,
                    String firstName,
                    String surname,
                    String email,
                    String phone,
                    double creditLimit,
                    String accountStatus,
                    double outstandingBalance,
                    String firstReminderStatus,
                    String secondReminderStatus,
                    String firstReminderDate,
                    String secondReminderDate) {
        this.accountId = accountId;
        this.firstName = firstName;
        this.surname = surname;
        this.email = email;
        this.phone = phone;
        this.creditLimit = creditLimit;
        this.accountStatus = accountStatus;
        this.outstandingBalance = outstandingBalance;
        this.firstReminderStatus = firstReminderStatus;
        this.secondReminderStatus = secondReminderStatus;
        this.firstReminderDate = firstReminderDate;
        this.secondReminderDate = secondReminderDate;
    }

    public String getAccountId() {
        return accountId;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getSurname() {
        return surname;
    }

    public String getFullName() {
        if (surname == null || surname.isBlank()) {
            return firstName;
        }
        return firstName + " " + surname;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }

    public double getCreditLimit() {
        return creditLimit;
    }

    public String getAccountStatus() {
        return accountStatus;
    }

    public double getOutstandingBalance() {
        return outstandingBalance;
    }

    public String getFirstReminderStatus() {
        return firstReminderStatus;
    }

    public String getSecondReminderStatus() {
        return secondReminderStatus;
    }

    public String getFirstReminderDate() {
        return firstReminderDate;
    }

    public String getSecondReminderDate() {
        return secondReminderDate;
    }

}