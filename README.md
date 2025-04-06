# Recommendation Collections API

This API allows users to group recommendations into collections. Users can add recommendations to collections, remove them, and view all recommendations within a collection.

## Setup

### Prerequisites
- Node.js (v18 or higher)
- npm
- PostgreSQL database (or a Neon.tech account)

### Installation

1. Clone the repository
```bash
git clone https://github.com/jagrit007/recommendation-collections-api.git
cd recommendation-collections-api
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
   - Create a `.env` file in the project root
   - Add the following variables:
   ```
   DATABASE_URL=your_neon_connection_string
   PORT=3000
   ```

4. Set up the database
   - Create a database in Neon.tech
   - Run the SQL scripts in `database/schema.sql` to create the tables
   - Import the sample data using the instructions in `database/import.md`

5. Start the server
```bash
npm start
```

## API Endpoints

### Add Recommendation to Collection
- **URL**: `/collections/:collectionId/recommendations`
- **Method**: `POST`
- **Body**:
  ```json
  {
    "userId": 5,
    "recommendationId": 10
  }
  ```
- **Success Response**: `201 Created`
  ```json
  {
    "message": "Recommendation added to collection successfully",
    "collectionId": "1",
    "recommendationId": 10
    }
  ```
- **Error Responses**:
  - `400 Bad Request`: Missing required fields
  - `403 Forbidden`: Collection or recommendation not found or doesn't belong to the user
  - `409 Conflict`: Recommendation is already in the collection
  - `500 Server Error`: Server error

### Remove Recommendation from Collection
- **URL**: `/collections/:collectionId/recommendations/:recommendationId`
- **Method**: `DELETE`
- **Body**:
  ```json
  {
    "userId": 5
  }
  ```
- **Success Response**: `200 OK`
  ```json
  {
    "message": "Recommendation removed from collection successfully",
    "collectionId": "1",
    "recommendationId": "10"
    }
  ```
- **Error Responses**:
  - `400 Bad Request`: Missing required fields
  - `403 Forbidden`: Collection not found or doesn't belong to the user
  - `404 Not Found`: Recommendation not found in the collection
  - `500 Server Error`: Server error

### View Recommendations of a Collection
- **URL**: `/collections/:collectionId/recommendations`
- **Method**: `GET`
- **Query Parameters**:
  - `userId`: User ID (required)
  - `page`: Page number (optional, default: 1)
  - `limit`: Items per page (optional, default: 10)
- **Success Response**: `200 OK`
  ```json
  {
    "collection": {
        "id": "1",
        "user_id": "5",
        "title": "My Favorite Movies",
        "created_at": "2023-11-24T08:56:05.000Z"
    },
    "recommendations": [
        {
            "id": "10",
            "user_id": "5",
            "title": "Science Vs",
            "caption": "Debunking popular myths.",
            "category": "podcast",
            "created_at": "2023-05-10T14:10:15.000Z",
            "added_at": "2025-04-06T18:36:36.275Z"
        }
    ],
    "pagination": {
        "totalCount": 1,
        "totalPages": 1,
        "currentPage": 1,
        "limit": 10
    }
    }
  ```
- **Error Responses**:
  - `400 Bad Request`: Missing required fields
  - `403 Forbidden`: Collection not found or doesn't belong to the user
  - `500 Server Error`: Server error

### View All Collections with Their Recommendations
- **URL**: `/collections`
- **Method**: `GET`
- **Query Parameters**:
  - `userId`: User ID (required)
- **Success Response**: `200 OK`
  ```json
  {
    "user": {
        "id": "5",
        "fname": "Ella",
        "sname": "Davis",
        "profile_picture": "https://picsum.photos/200",
        "bio": "Outdoor adventurer and photographer.",
        "created_at": "2023-04-05T14:15:15.000Z"
    },
    "collections": [
        {
            "id": "1",
            "user_id": "5",
            "title": "My Favorite Movies",
            "created_at": "2023-11-24T08:56:05.000Z",
            "recommendations": [
                {
                    "id": "10",
                    "user_id": "5",
                    "title": "Science Vs",
                    "caption": "Debunking popular myths.",
                    "category": "podcast",
                    "created_at": "2023-05-10T14:10:15.000Z"
                }
            ],
            "totalRecommendations": 1
        },
        {
            "id": "3",
            "user_id": "5",
            "title": "Travel Bucket List",
            "created_at": "2023-04-21T01:35:31.000Z",
            "recommendations": [],
            "totalRecommendations": 0
        }
    ]
    }
  ```
- **Error Responses**:
  - `400 Bad Request`: Missing required fields
  - `404 Not Found`: User not found
  - `500 Server Error`: Server error

## Error Handling

The API handles the following error scenarios:
- Attempting to add a recommendation that doesn't belong to the user
- Trying to view collections for a non-existent user
- Invalid input validation
- Database connection issues
- Server errors

## Database Schema

The database consists of four tables:
- `users`: Stores user information
- `recommendations`: Stores recommendation information
- `collections`: Stores collection information
- `collection_recommendations`: Maps recommendations to collections (many-to-many relationship)

---
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
