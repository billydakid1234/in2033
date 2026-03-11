
public interface SA_LOGIN_API {

    /**
    * 
    * @param username 
    * @param password 
    */ 
    abstract void login(String username, String password); 

    abstract void logout(); 

}
