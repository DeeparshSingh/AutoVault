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

  Return a vehicle:

sql
Copy code
CALL ReturnCar(reservation_id, return_date);
Archive completed reservations:

sql
Copy code
CALL ArchiveReservations;
Blacklist a client:

sql
Copy code
CALL BlackListClient(client_id);
Generate yearly statistics:

sql
Copy code
SELECT * FROM GenerateYearlyStats(year);
Structure
The database consists of the following main tables:

Client
Stores client details including their name, date of birth, city, and gender.

Columns:
C_ID (Primary Key)
F_NAME (First Name)
L_NAME (Last Name)
DOB (Date of Birth)
CITY (City)
GENDER (Gender)
Vehicle
Manages vehicle details like model, make, cost per day, and availability.

Columns:
V_ID (Primary Key)
V_MODEL (Vehicle Model)
V_MAKE (Vehicle Make)
COST_PER_DAY (Cost per day for rental)
Availability (Indicates if the vehicle is available for rent)
Reservation
Handles the reservation details, linking clients and vehicles, including dates and total cost.

Columns:
R_ID (Primary Key)
START_DATE (Reservation start date)
END_DATE (Planned end date of reservation)
RETURN_DATE (Actual return date of vehicle)
C_ID (Foreign Key to Client)
V_ID (Foreign Key to Vehicle)
TOTAL_COST (Total cost for the rental period)
Archived_Reservation
Stores past reservation records for historical purposes.

Columns:
R_ID (Reservation ID)
START_DATE (Reservation start date)
END_DATE (Reservation end date)
RETURN_DATE (Actual return date)
C_ID (Client ID)
V_ID (Vehicle ID)
TOTAL_COST (Total rental cost)
ADDED_BY (Name of the admin who archived the record)
ADDED_DATE (Timestamp when the record was archived)
