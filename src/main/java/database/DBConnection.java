package database;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DBConnection {

    private static final String URL = "jdbc:sqlite:SQL/CA_db.db";

    public static Connection getConnection() {
        try {
<<<<<<< HEAD:src/main/java/database/DBConnection.java
            
=======
            Class.forName("org.sqlite.JDBC");

>>>>>>> 9bd6be519d3ec58c8e0ccc92c9c28106a09f9af9:src/database/DBConnection.java
            Connection conn = DriverManager.getConnection(URL);

            try (Statement stmt = conn.createStatement()) {
                stmt.execute("PRAGMA busy_timeout = 5000");
                stmt.execute("PRAGMA journal_mode = WAL");
            }

            System.out.println("Connected to database");
            return conn;

        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Connection failed");
            e.printStackTrace();
            return null;
        }
    }
}