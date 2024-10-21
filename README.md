# Autovault Database Project

## Overview

**Autovault** is a SQL-based vehicle rental management system designed to handle client reservations, ensuring age compliance, and maintaining important statistics for business insights. The database manages client reservations, archives completed reservations, and includes mechanisms to blacklist clients when necessary.

## Features

- **Client Management**: Tracks client information, including age and city, to validate eligibility for rentals.
- **Vehicle Management**: Manages the availability and cost per day for each vehicle.
- **Reservation System**: Handles reservation creation, managing start and end dates, total cost, and client and vehicle associations.
- **Archiving**: Automatically archives completed reservations for historical tracking.
- **Blacklisting**: Blacklists clients who violate terms, preventing them from making future reservations.
- **Statistics Generation**: Provides yearly statistics on reservations, including client activity and vehicle rentals.

## Usage

### Key Functions and Procedures:

- **IssueCar**: This function manages the reservation process by assigning a vehicle to a client and ensuring all validation checks are performed.
- **ReturnCar**: Handles the process when a client returns a rented vehicle, calculating the total cost and marking the reservation as complete.
- **CheckClientAgeTrigger**: A trigger that ensures clients meet the minimum age requirement before booking a vehicle. If the client is underage, the booking will be blocked.
- **ArchiveReservations**: This procedure moves completed reservations into the `Archived_Reservation` table, keeping the active reservations clean and organized.
- **BlackListClient**: This procedure adds clients who have violated terms to the blacklist, preventing further bookings.
- **GenerateYearlyStats**: This function generates yearly statistics, summarizing trends for reservations, clients, and vehicle usage.

### Example Queries:

- **Create a new reservation:**
  ```sql
  CALL IssueCar(client_id, vehicle_id, start_date, end_date);
