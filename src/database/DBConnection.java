package database;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DBConnection {

    private static final String JDBC_PREFIX = "jdbc:sqlite:";

    private static Path resolveDatabasePath() {
        Path[] candidates = new Path[] {
            Paths.get("CA_db.db"),
            Paths.get("SQL", "CA_db.db"),
            Paths.get("..", "CA_db.db"),
            Paths.get("..", "SQL", "CA_db.db")
        };

        for (Path candidate : candidates) {
            if (Files.exists(candidate)) {
                return candidate.toAbsolutePath().normalize();
            }
        }
        return null;
    }

    public static Connection getConnection() {
        Path dbPath = resolveDatabasePath();

        if (dbPath == null) {
            System.out.println("Database file not found in expected paths.");
            return null;
        }

        String url = JDBC_PREFIX + dbPath;

        try {
            Class.forName("org.sqlite.JDBC");

            Connection conn = DriverManager.getConnection(url);

            try (Statement stmt = conn.createStatement()) {
                stmt.execute("PRAGMA busy_timeout = 5000");
                stmt.execute("PRAGMA journal_mode = WAL");
            }

            System.out.println("Connected to database at " + dbPath);
            return conn;

        } catch (ClassNotFoundException | SQLException e) {
            System.out.println("Connection failed for " + url);
            e.printStackTrace();
            return null;
        }
    }
}