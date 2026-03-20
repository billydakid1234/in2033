
public interface PU_COMMS_API {
    
    /** 
    * 
    * @param recipient 
    * @param subject 
    * @param content 
    */ 
    abstract boolean sendEmail(String recipient, String subject, String content); 

} 
