package com.chat;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/ChatEndpoint")
public class ChatEndpoint extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int MAX_MESSAGE_LENGTH = 1000;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("username") == null) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "Session expired. Please log in again.");
            return;
        }

        response.setHeader("Cache-Control", "no-store");
        response.setHeader("Pragma", "no-cache");

        String action = trim(request.getParameter("action"));

        if ("users".equals(action)) {
            getUsers(session, response);
        } else if ("messages".equals(action)) {
            getMessages(session, request, response);
        } else {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, "Unknown chat action.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("username") == null) {
            writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "Session expired. Please log in again.");
            return;
        }

        request.setCharacterEncoding("UTF-8");

        String sender = (String) session.getAttribute("username");
        String receiver = trim(request.getParameter("receiver"));
        String message = trim(request.getParameter("message"));

        if (receiver.isEmpty() || message.isEmpty()) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, "Receiver and message are required.");
            return;
        }

        if (receiver.equals(sender)) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, "You cannot send a message to yourself.");
            return;
        }

        if (message.length() > MAX_MESSAGE_LENGTH) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST,
                    "Message must be " + MAX_MESSAGE_LENGTH + " characters or fewer.");
            return;
        }

        String sql = "INSERT INTO messages (sender, receiver, message) VALUES (?, ?, ?)";

        try (Connection con = Database.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, sender);
            ps.setString(2, receiver);
            ps.setString(3, message);
            ps.executeUpdate();

            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"status\":\"success\"}");

        } catch (Exception e) {
            getServletContext().log("Send message database error", e);
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "The message could not be saved.");
        }
    }

    private void getUsers(HttpSession session, HttpServletResponse response) throws IOException {
        String currentUser = (String) session.getAttribute("username");
        String sql = "SELECT username FROM users WHERE username <> ? ORDER BY username";

        response.setContentType("application/json;charset=UTF-8");

        StringBuilder json = new StringBuilder("[");

        try (Connection con = Database.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, currentUser);

            try (ResultSet rs = ps.executeQuery()) {
                boolean first = true;

                while (rs.next()) {
                    if (!first) {
                        json.append(',');
                    }
                    first = false;

                    json.append('"')
                        .append(escapeJson(rs.getString("username")))
                        .append('"');
                }
            }

            json.append(']');
            response.getWriter().write(json.toString());

        } catch (Exception e) {
            getServletContext().log("Load users database error", e);
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Unable to load users.");
        }
    }

    private void getMessages(HttpSession session,
                             HttpServletRequest request,
                             HttpServletResponse response) throws IOException {

        String currentUser = (String) session.getAttribute("username");
        String receiver = trim(request.getParameter("receiver"));

        if (receiver.isEmpty()) {
            writeError(response, HttpServletResponse.SC_BAD_REQUEST, "Receiver is required.");
            return;
        }

        String sql =
                "SELECT sender, receiver, message, message_time " +
                "FROM messages " +
                "WHERE (sender = ? AND receiver = ?) " +
                "OR (sender = ? AND receiver = ?) " +
                "ORDER BY message_time ASC";

        response.setContentType("application/json;charset=UTF-8");

        StringBuilder json = new StringBuilder("[");
        SimpleDateFormat format = new SimpleDateFormat("dd MMM yyyy, HH:mm");

        try (Connection con = Database.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, currentUser);
            ps.setString(2, receiver);
            ps.setString(3, receiver);
            ps.setString(4, currentUser);

            try (ResultSet rs = ps.executeQuery()) {
                boolean first = true;

                while (rs.next()) {
                    if (!first) {
                        json.append(',');
                    }
                    first = false;

                    String sender = rs.getString("sender");
                    String receiverName = rs.getString("receiver");
                    String message = rs.getString("message");
                    Timestamp timestamp = rs.getTimestamp("message_time");
                    String time = timestamp == null ? "" : format.format(timestamp);

                    json.append('{')
                        .append("\"sender\":\"").append(escapeJson(sender)).append("\",")
                        .append("\"receiver\":\"").append(escapeJson(receiverName)).append("\",")
                        .append("\"message\":\"").append(escapeJson(message)).append("\",")
                        .append("\"time\":\"").append(escapeJson(time)).append("\"")
                        .append('}');
                }
            }

            json.append(']');
            response.getWriter().write(json.toString());

        } catch (Exception e) {
            getServletContext().log("Load messages database error", e);
            writeError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "Unable to load messages.");
        }
    }

    private void writeError(HttpServletResponse response, int status, String message)
            throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(
                "{\"status\":\"error\",\"message\":\"" + escapeJson(message) + "\"}"
        );
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private static String escapeJson(String text) {
        if (text == null) {
            return "";
        }

        return text.replace("\\", "\\\\")
                   .replace("\"", "\\\"")
                   .replace("\b", "\\b")
                   .replace("\f", "\\f")
                   .replace("\n", "\\n")
                   .replace("\r", "\\r")
                   .replace("\t", "\\t");
    }
}
