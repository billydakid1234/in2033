package Backend;

import java.nio.file.Paths;
import java.sql.*;

public class DBTest {
    public static void main(String[] args) {

        try {
            Connection conn = DriverManager.getConnection("jdbc:sqlite:/workspaces/IN-2033/SQL/CA_db.db");

            System.out.println("Connected ✅");

            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT name FROM sqlite_master WHERE type='table'");

            System.out.println("Tables:");

            while (rs.next()) {
                System.out.println(rs.getString("name"));
            }

        } catch (Exception e) {
            System.out.println("Connection failed ❌");
            e.printStackTrace();
        }
    }
}