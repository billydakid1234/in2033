
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.Map;

public class SA_LOGIN_API {

    private final Map<String, String> users = new HashMap<>(); // temp way to store the users till i figure out how to link it to bens data base

    public SA_LOGIN_API() {
        createAccount("admin", "pass"); // test account
    }

    // Hash passwords using sha 256
    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] bytes = md.digest(password.getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 not available");
        }
    }

    // Returns true if login is successful more needed in the gui to check and all that
    public boolean login(String username, String password) {
        String storedHash = users.get(username);
        return storedHash != null && storedHash.equals(hashPassword(password));
    }

    // Returns true if account created
    public boolean createAccount(String username, String password) {
        if (users.containsKey(username)) return false;
        users.put(username, hashPassword(password));
        return true;
    }

    // Returns true if account removed
    public boolean removeAccount(String username) {
        if (!users.containsKey(username)) return false;
        users.remove(username);
        return true;
    }
}

/* log out button removed as it should be made in the front end where it will just remove the current page and replace it with the log in screen for ease of use--
    -- and i cant figure out a way to do it from here... code below can be used or we can make another one as i havent checked the gui yet

    private void logoutButtonActionPerformed(java.awt.event.ActionEvent evt) {
    this.setVisible(false);           // hide main page
    loginScreen.setVisible(true);     // show login screen again
}
 */
