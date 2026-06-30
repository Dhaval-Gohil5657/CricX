# CricX Backend API Reference & Schema Mapping Guide

This document defines the database schemas, NoSQL-to-SQL mapping, authentication API contracts (including registration & login), and business logic rules for the CricX backend team. 

---

## 💡 Recommendation on Firebase Database Access
> [!TIP]
> Yes, it is highly recommended to give **read-only access** (e.g. Firebase Console Viewer role) to your backend developers. Alternatively, you can perform a Firestore JSON export of your collections and share the data dump with them. This allows them to inspect live sandbox data, verify the document patterns, and test their custom API migrations against real-world data shapes.

---

## Part 1. MongoDB Database Design Guidelines

Because the backend team is using **MongoDB** (which is a document NoSQL database like Firebase Firestore), the database schemas map **1-to-1** with the existing Firestore structure. This makes implementation extremely simple and removes the need for complex SQL relational tables or joint tables.

### 1. MongoDB Collections List
The database should contain 5 primary collections:
1. `users`: Stores user profile data, credentials, and app roles.
2. `players`: Central directory of cricket players and their career statistics.
3. `teams`: Stores team profiles, captain ID, and player ID lists (stored as an array of document references).
4. `matches`: Stores match listings, scores, toss details, and live scoring events.
5. `tournaments`: Stores tournament configurations, points tables, and team standings.

### 2. Document Nesting Guidelines
Unlike relational databases, nested objects should be stored directly inside the parent documents:
* **Match Innings**: Innings details (`innings1` and `innings2`) should be stored as nested sub-documents inside the `matches` collection documents.
* **Ball Events**: Deliveries logged ball-by-ball should be stored as an array of sub-documents (`events`) inside their respective Innings sub-document.
* **Points Table**: Standings rows should be stored as an array of sub-documents (`pointsTable`) inside the `tournaments` collection documents.

---

## Part 2. Authentication & User API

### 1. User Registration (Sign Up)
* **Endpoint**: `POST /api/v1/users/register`
* **Description**: Creates a new user login credential and initializes their access role.
* **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123",
    "name": "Dhaval Gohil",
    "role": "organizer"
  }
  ```
  *Field Requirements:*
  - `email` (String, required): Valid email address.
  - `password` (String, required): Minimum 6 characters.
  - `name` (String, required): Full name of the user.
  - `role` (String, default `"guest"`): The initial dashboard view mode requested.
* **Response Body (`201 Created`)**:
  ```json
  {
    "id": "usr_9988aa77",
    "email": "user@example.com",
    "name": "Dhaval Gohil",
    "role": "organizer",
    "createdAt": "2026-06-30T10:30:00.000Z"
  }
  ```

### 2. User Login
* **Endpoint**: `POST /api/v1/users/login`
* **Description**: Verifies credentials and returns a Web Token (JWT) for authentication.
* **Request Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "SecurePassword123"
  }
  ```
* **Response Body (`200 OK`)**:
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiJ1c3JfOTk4OGFhNzciLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJyb2xlIjoib3JnYW5pemVyIn0...",
    "user": {
      "id": "usr_9988aa77",
      "email": "user@example.com",
      "name": "Dhaval Gohil",
      "role": "organizer"
    }
  }
  ```
* **Response Body (`401 Unauthorized`)**:
  ```json
  {
    "error": "Invalid email or password"
  }
  ```

### 3. Get User Profile
* **Endpoint**: `GET /api/v1/users/profile`
* **Headers**: `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (`200 OK`)**: Same as the `"user"` object in login.

### 4. Update User Role
* **Endpoint**: `PATCH /api/v1/users/role`
* **Headers**: `Authorization: Bearer <JWT_TOKEN>`
* **Request Body**:
  ```json
  {
    "role": "scorer"
  }
  ```
* **Response Body (`200 OK`)**:
  ```json
  {
    "id": "usr_9988aa77",
    "role": "scorer",
    "updatedAt": "2026-06-30T10:35:00.000Z"
  }
  ```

---

## Part 3. Core Modules CRUD REST Endpoints

All endpoints below expect a `Bearer <JWT_TOKEN>` header for mutative actions (POST, PUT, DELETE, PATCH).

### 1. Players API

#### Create Player (`POST /api/v1/players`)
* **Request Body**:
  ```json
  {
    "name": "Virat Kohli",
    "role": "Batsman",
    "battingStyle": "Right-hand bat",
    "bowlingStyle": "Right-arm medium"
  }
  ```
* **Response Body (`201 Created`)**:
  ```json
  {
    "id": "player_virat_18",
    "name": "Virat Kohli",
    "role": "Batsman",
    "battingStyle": "Right-hand bat",
    "bowlingStyle": "Right-arm medium",
    "matchesPlayed": 0,
    "runsScored": 0,
    "wicketsTaken": 0,
    "ballsFaced": 0,
    "ballsBowled": 0,
    "runsConceded": 0,
    "highestScore": 0,
    "bestBowling": "-"
  }
  ```

#### Get Players (`GET /api/v1/players`)
* **Response Body (`200 OK`)**: Array of player objects.

#### Update Player Stats (`PUT /api/v1/players/{id}/stats`)
* **Request Body**: Represents incremental additions to career numbers.
  ```json
  {
    "matchesPlayed": 1,
    "runsScored": 82,
    "wicketsTaken": 0,
    "ballsFaced": 53,
    "ballsBowled": 0,
    "runsConceded": 0,
    "highestScore": 82,
    "bestBowling": "-"
  }
  ```

---

### 2. Teams API

#### Create Team (`POST /api/v1/teams`)
* **Request Body**:
  ```json
  {
    "name": "Royal Challengers",
    "abbreviation": "RCB",
    "logoEmoji": "👕",
    "logoColorHex": 4293918720,
    "playerIds": ["player_virat_18"],
    "captainId": "player_virat_18"
  }
  ```
* **Response Body (`201 Created`)**:
  ```json
  {
    "id": "team_rcb_002",
    "name": "Royal Challengers",
    "abbreviation": "RCB",
    "logoEmoji": "👕",
    "logoColorHex": 4293918720,
    "playerIds": ["player_virat_18"],
    "matchesPlayed": 0,
    "matchesWon": 0,
    "matchesLost": 0,
    "netRunRate": 0.0,
    "creatorId": "usr_9988aa77",
    "captainId": "player_virat_18"
  }
  ```

#### Add Player to Team (`POST /api/v1/teams/{teamId}/players`)
* **Request Body**:
  ```json
  {
    "playerId": "player_siraj_73"
  }
  ```

---

### 3. Matches API

#### Schedule Match (`POST /api/v1/matches`)
* **Request Body**:
  ```json
  {
    "teamAId": "team_mumbai_001",
    "teamBId": "team_rcb_002",
    "totalOvers": 10,
    "venue": "Chinnaswamy Stadium, Bengaluru",
    "matchDate": "2026-07-02T19:30:00.000Z",
    "tournamentId": null,
    "tournamentName": null
  }
  ```

#### Get Matches (`GET /api/v1/matches`)
* **Query Params**: `status` (`upcoming` | `live` | `completed`)

#### Update Match State (`PUT /api/v1/matches/{id}`)
*Represents updates to scoring, batsman runs conceeded, balls faced, and inning totals during match scoring.*
* **Request Body**:
  ```json
  {
    "status": "live",
    "tossWinnerId": "team_rcb_002",
    "tossDecision": "Bowl",
    "currentInningsNum": 1,
    "resultString": "Royal Challengers won toss & elected to bowl first",
    "strikerId": "player_rohit_45",
    "nonStrikerId": "player_ishan_23",
    "currentBowlerId": "player_siraj_73",
    "innings1": {
      "teamId": "team_mumbai_001",
      "runs": 12,
      "wickets": 0,
      "ballsBowled": 6,
      "events": [
        { "runs": 1, "isWide": false, "isNoBall": false, "isWicket": false, "wicketType": "", "bowlerName": "Siraj", "batsmanName": "Rohit", "description": "1 run", "isRunsOffBat": true, "isLegBye": false, "isPenalty": false, "isBye": false },
        { "runs": 4, "isWide": false, "isNoBall": false, "isWicket": false, "wicketType": "", "bowlerName": "Siraj", "batsmanName": "Ishan", "description": "Four off the bat!", "isRunsOffBat": true, "isLegBye": false, "isPenalty": false, "isBye": false }
      ],
      "battingOrder": ["player_rohit_45", "player_ishan_23"]
    },
    "innings2": null,
    "playerRuns": { "player_rohit_45": 5, "player_ishan_23": 7 },
    "playerBallsFaced": { "player_rohit_45": 3, "player_ishan_23": 3 },
    "bowlerRunsConceded": { "player_siraj_73": 12 },
    "bowlerWickets": { "player_siraj_73": 0 },
    "bowlerBallsBowled": { "player_siraj_73": 6 }
  }
  ```

---

### 4. Tournaments API

#### Create Tournament (`POST /api/v1/tournaments`)
* **Request Body**:
  ```json
  {
    "name": "CricX Premier League 2026",
    "type": "League",
    "teamIds": ["team_mumbai_001", "team_rcb_002"],
    "playoffType": "Direct Final",
    "defaultOvers": 10,
    "startDate": "2026-07-02T10:00:00.000Z",
    "venue": "BCCI Stadium"
  }
  ```

#### Get Tournaments (`GET /api/v1/tournaments`)
* **Response Body (`200 OK`)**: Array of Tournament objects.

---

## Part 4. Match Scoring Calculations Rules

### Ball Event Runs Addition
1. **Team Runs Added**: `runs + (isWide || isNoBall ? 1 : 0)`.
   - E.g. A wide ball that runs to the boundary (4 runs) adds 5 runs to the team score (4 runs + 1 penalty run for wide).
2. **Batsman Runs Added**:
   - If the ball is a Wide (`isWide = true`), Leg Bye (`isLegBye = true`), Bye (`isBye = true`), or Penalty (`isPenalty = true`), the batsman scores **0 runs**.
   - If the ball is a No Ball (`isNoBall = true`), the batsman only scores runs if they hit the ball off the bat (`isRunsOffBat = true`).
   - Otherwise, the batsman scores exactly the `runs` value.

### Ball Count Calculation
* A delivery **does not count** towards the over (balls bowled in the over does not increment) if:
  - `isWide = true`
  - `isNoBall = true`
  - `isPenalty = true`

### Net Run Rate (NRR) Formula
When matches in a tournament are completed, recalculate team NRR using:
$$\text{NRR} = \left( \frac{\text{Total runs scored by team}}{\text{Total overs faced by team}} \right) - \left( \frac{\text{Total runs conceded by team}}{\text{Total overs bowled by team}} \right)$$

*Note: If a team is bowled out before completing their full quota of overs, the calculation must use the **full quota of overs** scheduled for that innings (e.g. 10.0 overs instead of 8.3 overs).*
