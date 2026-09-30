package com.chat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * Centralized database configuration.
 *
 * Environment variables are supported so credentials do not need to be
 * hard-coded when deploying the application:
 * CHAT_DB_URL, CHAT_DB_USER, CHAT_DB_PASSWORD
 */
public final class Database {

    private static final String DEFAULT_URL =
            "jdbc:mysql://db01.dbhost.dev:5051/db_454ruhspn"
            + "?useSSL=false"
            + "&allowPublicKeyRetrieval=true"
            + "&serverTimezone=UTC";

    private static final String DEFAULT_USER = "user_454ruhspn";
    private static final String DEFAULT_PASSWORD = "p454ruhspn";

    private Database() {
    }

    public static Connection getConnection() throws SQLException {
        String url = envOrDefault("CHAT_DB_URL", DEFAULT_URL);
        String user = envOrDefault("CHAT_DB_USER", DEFAULT_USER);
        String password = envOrDefault("CHAT_DB_PASSWORD", DEFAULT_PASSWORD);

        // Explicitly load the MySQL driver. This also makes failures clearer
        // when the JDBC driver has not been deployed by Eclipse/WTP.
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException(
                    "MySQL JDBC driver is missing from WEB-INF/lib. "
                    + "In Eclipse, run Maven > Update Project and ensure Maven Dependencies "
                    + "are included in the Tomcat Deployment Assembly.", e);
        }

        return DriverManager.getConnection(url, user, password);
    }

    private static String envOrDefault(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isBlank() ? fallback : value;
    }
}
