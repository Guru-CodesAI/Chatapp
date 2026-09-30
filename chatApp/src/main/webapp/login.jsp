<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#05070b">
    <title>STARK // Secure Chat Login</title>
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body class="login-page">
    <div class="hud-grid"></div>
    <div class="hud-scanline"></div>
    <div class="ambient ambient-red"></div>
    <div class="ambient ambient-gold"></div>

    <main class="login-shell">
        <section class="login-showcase">
            <div class="brand-topline">
                <span class="status-pulse"></span>
                STARK NETWORK // ONLINE
            </div>

            <div class="arc-reactor arc-reactor-large" aria-hidden="true">
                <span class="reactor-core"></span>
                <span class="reactor-ring ring-a"></span>
                <span class="reactor-ring ring-b"></span>
                <span class="reactor-ring ring-c"></span>
            </div>

            <div class="hero-copy">
                <span class="eyebrow">MARK // COMMUNICATION PROTOCOL</span>
                <h1>IRON<span>CHAT</span></h1>
                <p>High-speed messaging with a cinematic Stark-inspired command interface.</p>
            </div>

            <div class="system-readout">
                <div><span>CORE</span><strong>98.7%</strong></div>
                <div><span>LINK</span><strong>SECURE</strong></div>
                <div><span>MODE</span><strong>REALTIME</strong></div>
            </div>
        </section>

        <section class="login-panel">
            <div class="panel-corner panel-corner-tl"></div>
            <div class="panel-corner panel-corner-br"></div>

            <div class="panel-header">
                <div class="mini-reactor">
                    <span></span>
                </div>
                <div>
                    <span class="eyebrow">IDENTITY CHECK</span>
                    <h2>Access the Network</h2>
                </div>
            </div>

            <% if (error != null && !error.isBlank()) { %>
                <div class="login-error" role="alert">
                    <span class="error-icon">!</span>
                    <span><%= error %></span>
                </div>
            <% } %>

            <form action="<%= request.getContextPath() %>/LoginServlet" method="post" class="login-form">
                <label class="hud-label" for="username">USER ID</label>
                <div class="hud-input">
                    <span class="input-icon">◈</span>
                    <input id="username" name="username" type="text"
                           placeholder="Enter username" maxlength="50"
                           autocomplete="username" required autofocus>
                    <span class="input-line"></span>
                </div>

                <label class="hud-label" for="password">ACCESS KEY</label>
                <div class="hud-input">
                    <span class="input-icon">◆</span>
                    <input id="password" name="password" type="password"
                           placeholder="Enter password" maxlength="100"
                           autocomplete="current-password" required>
                    <button class="password-toggle" type="button" onclick="togglePassword()"
                            aria-label="Show password" title="Show password">◉</button>
                    <span class="input-line"></span>
                </div>

                <button class="stark-button" type="submit">
                    <span>INITIALIZE SESSION</span>
                    <b>↗</b>
                </button>
            </form>

            <div class="login-footer">
                <span class="status-pulse"></span>
                ENCRYPTED SESSION CHANNEL READY
            </div>
        </section>
    </main>

    <script>
        function togglePassword() {
            const input = document.getElementById("password");
            const button = document.querySelector(".password-toggle");
            const visible = input.type === "text";
            input.type = visible ? "password" : "text";
            button.textContent = visible ? "◉" : "◎";
            button.setAttribute("aria-label", visible ? "Show password" : "Hide password");
        }
    </script>
</body>
</html>
