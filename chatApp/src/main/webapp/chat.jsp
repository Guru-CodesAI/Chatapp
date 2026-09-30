<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String username = (String) session.getAttribute("username");
    if (username == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    String safeUsername = username
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\r", "\\r")
            .replace("\n", "\\n");
    String initial = username.substring(0, 1).toUpperCase();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#05070b">
    <title>IRONCHAT // Command Center</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body class="chat-page">
    <div class="hud-grid"></div>
    <div class="hud-scanline"></div>

    <div class="chat-app">
        <aside class="chat-sidebar">
            <div class="sidebar-brand">
                <div class="mini-reactor"><span></span></div>
                <div>
                    <strong>IRONCHAT</strong>
                    <span>STARK COMMUNICATIONS</span>
                </div>
            </div>

            <div class="operator-card">
                <div class="avatar avatar-gold"><%= initial %></div>
                <div class="operator-info">
                    <span class="eyebrow">CURRENT OPERATOR</span>
                    <strong><%= username %></strong>
                    <small><span class="status-pulse"></span> SYSTEM ONLINE</small>
                </div>
            </div>

            <div class="contacts-head">
                <div>
                    <span class="eyebrow">NETWORK NODES</span>
                    <strong>Available Contacts</strong>
                </div>
                <span id="userCount" class="node-count">0</span>
            </div>

            <div id="userList" class="user-list">
                <div class="loading-users">
                    <span class="loader"></span>
                    Scanning network...
                </div>
            </div>

            <div class="sidebar-footer">
                <div class="system-mini">
                    <span>CORE</span><b>ONLINE</b>
                </div>
                <a href="<%= request.getContextPath() %>/LogoutServlet" class="logout-btn">
                    <span>⏻</span> TERMINATE SESSION
                </a>
            </div>
        </aside>

        <main class="chat-main">
            <div id="emptyChat" class="empty-chat">
                <div class="target-ring">
                    <div class="target-cross"></div>
                    <div class="target-core">+</div>
                </div>
                <span class="eyebrow">STARK HUD // STANDBY</span>
                <h1>Select a communication node</h1>
                <p>Choose an operator from the network panel to open a secure conversation.</p>
                <div class="shortcut-hint">TIP <span>Enter</span> SENDS MESSAGE</div>
            </div>

            <div id="activeChat" class="active-chat hidden">
                <header class="chat-header">
                    <div class="chat-user-info">
                        <div id="chatAvatar" class="avatar avatar-red">?</div>
                        <div>
                            <span class="eyebrow">SECURE CHANNEL</span>
                            <h2 id="chatUser">Select User</h2>
                            <span id="chatStatus" class="channel-status">
                                <i class="status-pulse"></i> READY
                            </span>
                        </div>
                    </div>
                    <div id="connectionStatus" class="connection-status">
                        <span class="status-pulse"></span>
                        LINK ESTABLISHED
                    </div>
                </header>

                <section id="messages" class="messages-area" aria-live="polite">
                    <div class="no-messages">
                        <div class="message-reactor">✦</div>
                        <span class="eyebrow">CHANNEL OPEN</span>
                        <h3>No transmission history</h3>
                        <p>Send the first message to initialize this channel.</p>
                    </div>
                </section>

                <footer class="message-area">
                    <form id="messageForm" class="message-form">
                        <div class="message-input-wrapper">
                            <span class="input-prefix">TX</span>
                            <input type="text" id="messageInput"
                                   placeholder="Transmit secure message..."
                                   autocomplete="off" maxlength="1000"
                                   aria-label="Message">
                            <span id="charCount" class="char-count">0/1000</span>
                        </div>
                        <button type="submit" class="send-button" id="sendButton">
                            <span>TRANSMIT</span>
                            <b>➤</b>
                        </button>
                    </form>
                    <div class="message-hint">
                        <span>SECURE CHANNEL</span>
                        <span>MESSAGES ARE STORED IN MYSQL</span>
                    </div>
                </footer>
            </div>
        </main>
    </div>

<script>
"use strict";

const contextPath = "<%= request.getContextPath() %>";
const currentUser = "<%= safeUsername %>";
let selectedUser = null;
let refreshTimer = null;
let isLoadingMessages = false;

const userList = document.getElementById("userList");
const userCount = document.getElementById("userCount");
const emptyChat = document.getElementById("emptyChat");
const activeChat = document.getElementById("activeChat");
const chatUser = document.getElementById("chatUser");
const chatAvatar = document.getElementById("chatAvatar");
const chatStatus = document.getElementById("chatStatus");
const connectionStatus = document.getElementById("connectionStatus");
const messages = document.getElementById("messages");
const messageForm = document.getElementById("messageForm");
const messageInput = document.getElementById("messageInput");
const charCount = document.getElementById("charCount");
const sendButton = document.getElementById("sendButton");

function apiUrl(path) {
    return contextPath + path;
}

async function readJson(response) {
    const text = await response.text();
    let data = {};
    try {
        data = text ? JSON.parse(text) : {};
    } catch (error) {
        throw new Error("The server returned an invalid response.");
    }

    if (!response.ok) {
        if (response.status === 401) {
            window.location.href = contextPath + "/login.jsp?error=Session%20expired.%20Please%20log%20in%20again.";
        }
        throw new Error(data.message || "Request failed.");
    }

    return data;
}

async function loadUsers() {
    try {
        const response = await fetch(apiUrl("/ChatEndpoint?action=users"), {
            cache: "no-store",
            credentials: "same-origin"
        });
        const users = await readJson(response);

        renderUsers(Array.isArray(users) ? users : []);
        connectionStatus.classList.remove("offline");
        connectionStatus.innerHTML = '<span class="status-pulse"></span> LINK ESTABLISHED';
    } catch (error) {
        console.error(error);
        userList.innerHTML = '<div class="user-error"><b>NETWORK ERROR</b><br>Unable to scan contacts.</div>';
        connectionStatus.classList.add("offline");
        connectionStatus.innerHTML = '<span class="status-pulse"></span> LINK DEGRADED';
    }
}

function renderUsers(users) {
    userList.innerHTML = "";
    userCount.textContent = users.length;

    if (users.length === 0) {
        userList.innerHTML = '<div class="no-users">No other operators detected.</div>';
        return;
    }

    users.forEach(user => {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "user-item" + (user === selectedUser ? " active" : "");
        button.addEventListener("click", () => selectUser(user));

        const avatar = document.createElement("div");
        avatar.className = "avatar avatar-red";
        avatar.textContent = (user || "?").charAt(0).toUpperCase();

        const details = document.createElement("div");
        details.className = "user-item-details";

        const name = document.createElement("strong");
        name.textContent = user;

        const status = document.createElement("span");
        status.innerHTML = '<i class="status-pulse"></i> AVAILABLE';

        details.append(name, status);
        button.append(avatar, details);
        userList.appendChild(button);
    });
}

function selectUser(user) {
    if (!user) return;

    selectedUser = user;
    emptyChat.classList.add("hidden");
    activeChat.classList.remove("hidden");

    chatUser.textContent = user;
    chatAvatar.textContent = user.charAt(0).toUpperCase();
    chatStatus.innerHTML = '<i class="status-pulse"></i> SECURE CHANNEL READY';

    renderUsersFromSelection();
    loadMessages();
    startAutoRefresh();

    requestAnimationFrame(() => messageInput.focus());
}

function renderUsersFromSelection() {
    document.querySelectorAll(".user-item").forEach(item => {
        const name = item.querySelector(".user-item-details strong");
        item.classList.toggle("active", !!name && name.textContent === selectedUser);
    });
}

async function loadMessages() {
    if (!selectedUser || isLoadingMessages) return;

    isLoadingMessages = true;

    try {
        const response = await fetch(
            apiUrl("/ChatEndpoint?action=messages&receiver=" + encodeURIComponent(selectedUser)),
            { cache: "no-store", credentials: "same-origin" }
        );

        const data = await readJson(response);
        displayMessages(Array.isArray(data) ? data : []);
    } catch (error) {
        console.error(error);
        if (messages.children.length === 0) {
            showInlineError("Unable to load the conversation.");
        }
    } finally {
        isLoadingMessages = false;
    }
}

function displayMessages(data) {
    const wasNearBottom =
        messages.scrollHeight - messages.scrollTop - messages.clientHeight < 120;

    if (!data.length) {
        messages.innerHTML = `
            <div class="no-messages">
                <div class="message-reactor">✦</div>
                <span class="eyebrow">CHANNEL OPEN</span>
                <h3>No transmission history</h3>
                <p>Send the first message to initialize this channel.</p>
            </div>`;
        return;
    }

    messages.innerHTML = "";

    data.forEach(item => {
        const isMine = item.sender === currentUser;
        const row = document.createElement("div");
        row.className = "message-row " + (isMine ? "sent" : "received");

        const bubble = document.createElement("div");
        bubble.className = "message-bubble";

        const sender = document.createElement("div");
        sender.className = "message-sender";
        sender.textContent = isMine ? "YOU" : (item.sender || "UNKNOWN");

        const text = document.createElement("div");
        text.className = "message-text";
        text.textContent = item.message || "";

        const time = document.createElement("div");
        time.className = "message-time";
        time.textContent = item.time || "";

        bubble.append(sender, text, time);
        row.appendChild(bubble);
        messages.appendChild(row);
    });

    if (wasNearBottom) {
        messages.scrollTop = messages.scrollHeight;
    }
}

messageForm.addEventListener("submit", async event => {
    event.preventDefault();

    if (!selectedUser) return;

    const message = messageInput.value.trim();
    if (!message) {
        messageInput.focus();
        return;
    }

    sendButton.disabled = true;

    try {
        const body = new URLSearchParams({
            receiver: selectedUser,
            message: message
        });

        const response = await fetch(apiUrl("/ChatEndpoint"), {
            method: "POST",
            headers: {
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
            },
            body,
            credentials: "same-origin"
        });

        await readJson(response);
        messageInput.value = "";
        updateCharCount();
        await loadMessages();
        messageInput.focus();
    } catch (error) {
        console.error(error);
        showInlineError(error.message || "Unable to transmit message.");
    } finally {
        sendButton.disabled = false;
    }
});

messageInput.addEventListener("keydown", event => {
    if (event.key === "Enter" && !event.shiftKey) {
        event.preventDefault();
        messageForm.requestSubmit();
    }
});

messageInput.addEventListener("input", updateCharCount);

function updateCharCount() {
    charCount.textContent = messageInput.value.length + "/1000";
}

function startAutoRefresh() {
    if (refreshTimer) clearInterval(refreshTimer);
    refreshTimer = setInterval(loadMessages, 2500);
}

function showInlineError(message) {
    messages.innerHTML =
        '<div class="no-messages error-state">' +
        '<div class="message-reactor">!</div>' +
        '<span class="eyebrow">SYSTEM ALERT</span>' +
        '<h3>Transmission interrupted</h3>' +
        '<p>' + escapeHtml(message) + '</p>' +
        '</div>';
}

function escapeHtml(value) {
    const div = document.createElement("div");
    div.textContent = value || "";
    return div.innerHTML;
}

updateCharCount();
loadUsers();
</script>
</body>
</html>
