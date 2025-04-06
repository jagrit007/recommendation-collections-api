# Importing Sample Data

This document provides instructions for importing the sample data into your PostgreSQL database.

## Using PSQL Command Line

If you're using the PostgreSQL command line tool (`psql`), you can use the following commands:

1. Connect to your database:
   ```bash
   psql -h your_host -d your_database -U your_username
   ```

2. Import the data using the COPY command:
   ```sql
   -- Import users data
   COPY public.users(id, fname, sname, profile_picture, bio, created_at)
   FROM '/path/to/users.csv'
   DELIMITER ','
   CSV HEADER;

   -- Import recommendations data
   COPY public.recommendations(id, user_id, title, caption, category, created_at)
   FROM '/path/to/recommendations.csv'
   DELIMITER ','
   CSV HEADER;

   -- Import collections data
   COPY public.collections(id, user_id, title, created_at)
   FROM '/path/to/collections.csv'
   DELIMITER ','
   CSV HEADER;
   ```

## Using pgAdmin

If you're using pgAdmin, follow these steps:

1. Right-click on your table (e.g., `users`)
2. Select "Import/Export" option
3. In the dialog that appears:
   - Switch to "Import" mode
   - Select your CSV file
   - Set format to "CSV"
   - Check "Header" if your CSV has a header row
   - Set delimiter to ","
   - Select the appropriate columns
4. Click "OK" to start the import
5. Repeat for each table
