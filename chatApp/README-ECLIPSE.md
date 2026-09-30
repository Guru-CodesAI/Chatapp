# IRONCHAT — Eclipse Setup

## Requirements
- JDK 21
- Eclipse IDE for Enterprise Java and Web Developers
- Apache Tomcat 10.1.x
- MySQL 8+
- Maven 3.9+ (Eclipse m2e can resolve the Maven dependencies)

## Import into Eclipse
1. Extract this ZIP.
2. In Eclipse choose **File → Import → Existing Maven Projects**.
3. Select the `Chatsystem` folder.
4. Finish the import and wait for Maven dependencies to resolve.
5. Add **Apache Tomcat 10.1.x** under Eclipse Servers.
6. Right-click `Chatsystem` → **Run As → Run on Server**.

## Database
Run `database.sql` in the target MySQL database.

The project is preconfigured for the hosted MySQL database supplied for this deployment:
- Host: `db01.dbhost.dev`
- Port: `5051`
- Database: `db_454ruhspn`
- Username: `user_454ruhspn`

The password is configured in `Database.java` for this requested Eclipse package. For a public repository or production deployment, move the password to the `CHAT_DB_PASSWORD` environment variable instead.

The application also supports these environment variables, which override the packaged defaults:
- `CHAT_DB_URL`
- `CHAT_DB_USER`
- `CHAT_DB_PASSWORD`

## Project structure
- `src/main/java/com/chat/` — Servlet and database code
- `src/main/webapp/` — JSP pages and CSS
- `database.sql` — schema and demo users
- `pom.xml` — Maven WAR build
- `.project`, `.classpath`, `.settings/` — Eclipse project metadata

## Main fixes
- Removed duplicate legacy Java files from the project root.
- Removed generated `target/` build output.
- Standardized on Jakarta Servlet 6.0 / Tomcat 10.1.
- Centralized database connection configuration.
- Fixed recursive user-selection/loading behavior in the chat UI.
- Added robust JSON/API error handling and session checks.
- Added message length validation and safer request handling.
- Preserved `textContent` rendering for chat messages to prevent HTML injection.
- Added responsive Iron Man / Stark HUD-inspired UI with no external CSS/JS dependencies.

## MySQL JDBC Driver / Tomcat Deployment

If the application shows `No suitable driver found`, Eclipse has compiled the project but has not copied the MySQL Connector/J JAR into Tomcat.

1. Right-click the project -> **Maven -> Update Project**.
2. Open **Project -> Properties -> Deployment Assembly**.
3. Confirm **Maven Dependencies** is mapped to `/WEB-INF/lib`.
4. Remove the application from Tomcat, then add it again.
5. Clean and Publish the server.
6. Verify the deployed application contains `WEB-INF/lib/mysql-connector-j-9.4.0.jar`.

The project also explicitly loads `com.mysql.cj.jdbc.Driver` so a missing JDBC driver produces a clear diagnostic instead of a generic connection failure.
