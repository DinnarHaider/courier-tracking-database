# Courier and Package Tracking System

A database-driven courier management project built with Java Swing and MySQL. It combines a graphical interface for connecting to a database and running queries with a relational database schema for managing courier operations.

## Features

- **Customer Management:** Store customer information and associated addresses.
- **Parcel Management:** Maintain parcel details and tracking status.
- **Shipment Management:** Organize shipment information, origins, and destinations.
- **Hub and Route Management:** Represent courier hubs and delivery routes.
- **Delivery Operations:** Manage delivery agents and vehicle assignments.
- **Tracking Logs:** Record parcel movements and tracking events.
- **Billing and Payments:** Store invoice and payment information.
- **Complaints and Notifications:** Manage customer complaints, resolutions, and notifications.
- **Reporting:** Include a report table for storing report-related information.
- **Java GUI:** Connect to the MySQL database and execute SQL queries through a graphical interface.

## Technologies Used

- Java
- Java Swing
- JDBC (Java Database Connectivity)
- MySQL
- SQL

## Project Structure

```text
courier-tracking-database/
├── CourierTrackingGUI.java
├── courier_and_package_tracking_system.sql
└── README.md
```

## Requirements

- Java Development Kit (JDK)
- MySQL Server
- MySQL Connector/J JDBC driver
- A Java-compatible terminal or IDE

## Database Setup

1. Start your MySQL server.
2. Open MySQL Workbench or another MySQL client.
3. Open `courier_and_package_tracking_system.sql`.
4. Execute the SQL script to create the `courier_tracking` database, its tables, and the included sample data.

Review the SQL script before execution, particularly if you already have a database with the same name.

## Running the Java Application

### 1. Configure the database connection

The application uses the following default JDBC URL:

```text
jdbc:mysql://localhost:3306/courier_tracking?serverTimezone=UTC
```

The GUI includes fields for the database URL, username, and password. Ensure the URL, credentials, and database server settings match your local MySQL installation.

### 2. Compile the Java source

Ensure the MySQL Connector/J JAR is available locally. Replace `/path/to/mysql-connector-j.jar` with its actual location.

```bash
javac -cp ".:/path/to/mysql-connector-j.jar" CourierTrackingGUI.java
```

### 3. Run the application

```bash
java -cp ".:/path/to/mysql-connector-j.jar" CourierTrackingGUI
```

These commands assume the source file is in the current directory and that no additional project dependencies are required.

## Database Design

The SQL script defines relational tables including:

- Customer
- Address
- Parcel
- Hub
- Shipment
- Route
- DeliveryAgent
- VehicleAssignment
- TrackingLog
- UserRole
- Invoice
- Payment
- Complaint
- ComplaintResolution
- Notification
- Report

Primary keys and foreign keys are used to identify records and establish relationships between related entities.

The SQL script also includes sample records and additional database operations.

## Learning Objectives

This project demonstrates practical work with:

- Relational database design
- Primary and foreign key relationships
- SQL table creation and data manipulation
- JDBC database connectivity
- Java Swing interfaces
- Modeling a real-world courier and parcel tracking workflow

## Future Improvements

- Add more comprehensive input validation and error handling.
- Improve database access security and credential management.
- Add automated tests for database operations.
- Improve the interface and user experience.
- Expand tracking and reporting functionality.

## Author

Developed as an academic database project.
