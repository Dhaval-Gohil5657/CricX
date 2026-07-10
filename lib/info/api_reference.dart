/*
CricX Backend API Reference & Schema Mapping Guide

This document defines the database schemas, NoSQL-to-SQL mapping, authentication API contracts (including registration & login), and business logic rules for the CricX backend team.

---
Part 1. MongoDB Database Design Guidelines
1. MongoDB Collections List
The database should contain 5 primary collections:
1. `users`: Stores user profile data, credentials, and app roles.
2. `players`: Central directory of cricket players and their career statistics.
3. `teams`: Stores team profiles, captain ID, player ID lists (stored as an array of document references), and creator ID (`creatorId`).
4. `matches`: Stores match listings, scores, toss details, live scoring events, creator ID (`creatorId`), and Player of the Match (`playerOfTheMatchId`, `playerOfTheMatchName`).
5. `tournaments`: Stores tournament configurations, points tables, team standings, winner ID (`winnerTeamId`), creator ID (`creatorId`), and Player of the Tournament (`playerOfTheTournamentId`, `playerOfTheTournamentName`).

2. Document Nesting Guidelines
Unlike relational databases, nested objects should be stored directly inside the parent documents:
* **Match Innings**: Innings details (`innings1`, `innings2`, and optional Super Over innings `superOverInnings1`, `superOverInnings2`) should be stored as nested sub-documents inside the `matches` collection documents.
* **Ball Events**: Deliveries logged ball-by-ball should be stored as an array of sub-documents (`events`) inside their respective Innings sub-document.
* **Points Table**: Standings rows should be stored as an array of sub-documents (`pointsTable`) inside the `tournaments` collection documents.

---

Part 2. Authentication & User API

1. User Registration (Sign Up)
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

2. User Login
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

3. Get User Profile
* **Endpoint**: `GET /api/v1/users/profile`
* **Headers**: `Authorization: Bearer <JWT_TOKEN>`
* **Response Body (`200 OK`)**: Same as the `"user"` object in login.

4. Update User Role
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

Part 3. Core Modules CRUD REST Endpoints

All endpoints below expect a `Bearer <JWT_TOKEN>` header for mutative actions (POST, PUT, DELETE, PATCH).

1. Players API

Create Player (`POST /api/v1/players`)
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

Get Players (`GET /api/v1/players`)
* **Query Params**:
  - `q` (String, optional): Search query to filter players by name, role, batting style, or bowling style.
  - `role` (String, optional): Filter by player role (`Batsman`, `Bowler`, `All-Rounder`, `Wicketkeeper`).
  - `sortBy` (String, optional): Sort the results (`runs` | `wickets` | `matches`).
  - `creatorId` (String, optional): Filter players who belong to teams created by a specific user ID.
* **Response Body (`200 OK`)**: Array of player objects.

Update Player Stats (`PUT /api/v1/players/{id}/stats`)
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

2. Teams API

Create Team (`POST /api/v1/teams`)
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

Add Player to Team (`POST /api/v1/teams/{teamId}/players`)
* **Request Body**:
  ```json
  {
    "playerId": "player_siraj_73"
  }
  ```

Get Teams (`GET /api/v1/teams`)
* **Description**: Retrieves list of teams with optional search and creator filters.
* **Query Params**:
  - `q` (String, optional): Search query to filter teams by name or abbreviation.
  - `creatorId` (String, optional): Filter teams created by a specific user (the Scorer/Organizer filter).
* **Response Body (`200 OK`)**: Array of team objects.

---

3. Matches API

Schedule Match (`POST /api/v1/matches`)
* **Request Body**:
  ```json
  {
    "teamAId": "team_mumbai_001",
    "teamBId": "team_rcb_002",
    "totalOvers": 10,
    "venue": "Chinnaswamy Stadium, Bengaluru",
    "matchDate": "2026-07-02T19:30:00.000Z",
    "tournamentId": null,
    "tournamentName": null,
    "creatorId": "usr_9988aa77"
  }
  ```

Get Matches (`GET /api/v1/matches`)
* **Query Params**:
  - `status` (String, optional): Filter by status (`upcoming` | `live` | `completed`).
  - `q` (String, optional): Search query to filter matches by team names, venue, or tournament name.
  - `creatorId` (String, optional): Filter matches created by a specific user (the Scorer/Organizer filter).
* **Response Body (`200 OK`)**: Array of match objects.

Update Match State (`PUT /api/v1/matches/{id}`)
*Represents updates to scoring, batsman runs conceded, balls faced, inning totals, and player of the match.*
* **Request Body**:
  ```json
  {
    "status": "live",
    "tossWinnerId": "team_rcb_002",
    "tossDecision": "Bowl",
    "teamAPlayerIds": ["player_rohit_45", "player_ishan_23"],
    "teamBPlayerIds": ["player_siraj_73"],
    "currentInningsNum": 1,
    "resultString": "Royal Challengers won toss & elected to bowl first",
    "strikerId": "player_rohit_45",
    "nonStrikerId": "player_ishan_23",
    "currentBowlerId": "player_siraj_73",
    "playerOfTheMatchId": "player_virat_18",
    "playerOfTheMatchName": "Virat Kohli",
    "creatorId": "usr_9988aa77",
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
    "isSuperOverPlayed": false,
    "isOnBreak": false,
    "breakReason": null,
    "superOverInnings1": null,
    "superOverInnings2": null,
    "playerRuns": { "player_rohit_45": 5, "player_ishan_23": 7 },
    "playerBallsFaced": { "player_rohit_45": 3, "player_ishan_23": 3 },
    "bowlerRunsConceded": { "player_siraj_73": 12 },
    "bowlerWickets": { "player_siraj_73": 0 },
    "bowlerBallsBowled": { "player_siraj_73": 6 }
  }
  ```

Declare Player of the Match (`PATCH /api/v1/matches/{id}/player-of-the-match`)
* **Description**: Declares the Player of the Match.
* **Request Body**:
  ```json
  {
    "playerOfTheMatchId": "player_virat_18",
    "playerOfTheMatchName": "Virat Kohli"
  }
  ```
* **Response Body (`200 OK`)**:
  ```json
  {
    "id": "match_mumbai_rcb_001",
    "playerOfTheMatchId": "player_virat_18",
    "playerOfTheMatchName": "Virat Kohli",
    "updatedAt": "2026-07-03T10:35:00.000Z"
  }
  ```

---

4. Tournaments API

Create Tournament (`POST /api/v1/tournaments`)
* **Request Body**:
  ```json
  {
    "name": "CricX Premier League 2026",
    "type": "League",
    "teamIds": ["team_mumbai_001", "team_rcb_002"],
    "playoffType": "Direct Final",
    "defaultOvers": 10,
    "startDate": "2026-07-02T10:00:00.000Z",
    "venue": "BCCI Stadium",
    "creatorId": "usr_9988aa77"
  }
  ```

Get Tournaments (`GET /api/v1/tournaments`)
* **Query Params**:
  - `q` (String, optional): Search query to filter tournaments by name.
  - `creatorId` (String, optional): Filter tournaments created by a specific user (the Scorer/Organizer filter).
* **Response Body (`200 OK`)**: Array of Tournament objects.

Update Tournament (`PUT /api/v1/tournaments/{id}`)
* **Description**: Updates tournament state, winner, and awards.
* **Request Body**:
  ```json
  {
    "winnerTeamId": "team_rcb_002",
    "playerOfTheTournamentId": "player_virat_18",
    "playerOfTheTournamentName": "Virat Kohli",
    "status": "Completed"
  }
  ```
* **Response Body (`200 OK`)**: Updated Tournament object.

Declare Player of the Tournament (`PATCH /api/v1/tournaments/{id}/player-of-the-tournament`)
* **Description**: Declares the Player of the Tournament.
* **Request Body**:
  ```json
  {
    "playerOfTheTournamentId": "player_virat_18",
    "playerOfTheTournamentName": "Virat Kohli"
  }
  ```
* **Response Body (`200 OK`)**:
  ```json
  {
    "id": "tour_cpl_2026",
    "playerOfTheTournamentId": "player_virat_18",
    "playerOfTheTournamentName": "Virat Kohli",
    "updatedAt": "2026-07-03T10:35:00.000Z"
  }
  ```

---

Part 4. Match Scoring Calculations Rules

Ball Event Runs Addition
1. **Team Runs Added**: `runs + (isWide || isNoBall ? 1 : 0)`.
   - E.g. A wide ball that runs to the boundary (4 runs) adds 5 runs to the team score (4 runs + 1 penalty run for wide).
2. **Batsman Runs Added**:
   - If the ball is a Wide (`isWide = true`), Leg Bye (`isLegBye = true`), Bye (`isBye = true`), or Penalty (`isPenalty = true`), the batsman scores **0 runs**.
   - If the ball is a No Ball (`isNoBall = true`), the batsman only scores runs if they hit the ball off the bat (`isRunsOffBat = true`).
   - Otherwise, the batsman scores exactly the `runs` value.

Ball Count Calculation
* A delivery **does not count** towards the over (balls bowled in the over does not increment) if:
  - `isWide = true`
  - `isNoBall = true`
  - `isPenalty = true`

Net Run Rate (NRR) Formula
When matches in a tournament are completed, recalculate team NRR using:
$$\text{NRR} = \left( \frac{\text{Total runs scored by team}}{\text{Total overs faced by team}} \right) - \left( \frac{\text{Total runs conceded by team}}{\text{Total overs bowled by team}} \right)$$

*Note: If a team is bowled out before completing their full quota of overs, the calculation must use the **full quota of overs** scheduled for that innings (e.g. 10.0 overs instead of 8.3 overs).*


 */