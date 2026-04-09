
public interface PU_COMMS_API {

    /**
     * Sends card payment details securely to PU subsystem.
     * @param cardNumber Full card number (temporarily, must be encrypted in transit)
     * @param expiry Expiry date (MM/YY)
     * @param amount Payment amount
     * @param orderID Associated order ID
     *
     * @param recipient
     * @param subject
     * @param content
     */
    boolean processCardPayment(String cardNumber, String expiry, double amount, String orderID);

    abstract boolean sendEmail(String recipient, String subject, String content);

}
