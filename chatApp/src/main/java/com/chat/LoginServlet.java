package com.chat;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding(StandardCharsets.UTF_8.name());

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (isBlank(username) || isBlank(password)) {
            redirectWithError(request, response, "Please enter username and password.");
            return;
        }

        username = username.trim();

        String sql = "SELECT username FROM users WHERE username = ? AND password = ? LIMIT 1";

        try (Connection con = Database.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, username);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    HttpSession session = request.getSession(true);
                    session.setAttribute("username", rs.getString("username"));
                    session.setMaxInactiveInterval(30 * 60);

                    response.sendRedirect(request.getContextPath() + "/chat.jsp");
                } else {
                    redirectWithError(request, response, "Invalid username or password.");
                }
            }

        } catch (Exception e) {
            getServletContext().log("Login database error", e);
            redirectWithError(request, response,
                    "Unable to connect to the chat database. Check the server configuration.");
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private void redirectWithError(HttpServletRequest request,
                                   HttpServletResponse response,
                                   String message) throws IOException {
        String encoded = URLEncoder.encode(message, StandardCharsets.UTF_8);
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=" + encoded);
    }
}
