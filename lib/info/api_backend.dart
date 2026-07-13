/*
CricX API Endpoints Reference
===============================
This document provides a comprehensive technical reference for all REST API endpoints available in the CricX Backend.

Render URl = cricx-kcid.onrender.com


CricX API Documentation (v1.0.0)
================================
This document provides a highly detailed, comprehensive reference for all REST API endpoints available in the CricX Backend. It covers required fields, optional fields, validation constraints, default values, and role-based access control.

--------------------------------------------------------------------------------
1. Authentication & Users (/api/v1/users)
--------------------------------------------------------------------------------

POST /api/v1/users/register
Access: Public
Description: Registers a new user. Supports standard users and direct organizer registration.
Request Headers:
  - Content-Type: application/json
Request Body:
{
  "name": "String, Required. E.g., 'John Doe'",
  "email": "String, Optional (Requires phone if empty). Must be unique.",
  "phone": "String, Optional (Requires email if empty). Must be unique.",
  "password": "String, Required. Min length determined by bcrypt.",
  "role": "String, Optional. Enum: ['user', 'organizer']. Defaults to 'user'."
}
Response (201 Created):
{
  "user": { "_id": "...", "name": "...", "email": "...", "role": "user/organizer" },
  "accessToken": "JWT String (15m expiry)",
  "refreshToken": "JWT String (7d expiry, saved to DB)"
}
Error Codes:
  - 400: User already exists
  - 400: Validation Error (Missing password, email/phone, or name)


POST /api/v1/users/login
Access: Public
Description: Authenticates an existing user and returns access/refresh tokens.
Request Headers:
  - Content-Type: application/json
Request Body:
{
  "email": "String, Optional (Requires phone if empty)",
  "phone": "String, Optional (Requires email if empty)",
  "password": "String, Required."
}
Response (200 OK): Identical to Register response.
Error Codes:
  - 400: Missing password or email/phone
  - 401: Invalid credentials


POST /api/v1/users/guest
Access: Public
Description: Instantly creates a temporary guest account (auto-generates name/ID).
Request Body: None
Response (201 Created):
{
  "user": { "_id": "...", "name": "Guest_XYZ", "role": "guest", "isGuest": true },
  "accessToken": "...",
  "refreshToken": "..."
}


POST /api/v1/users/refresh
Access: Public
Description: Generates a new access token using a valid refresh token.
Request Headers:
  - Content-Type: application/json
Request Body:
{
  "token": "String, Required. The refresh token previously issued."
}
Response (200 OK):
{
  "user": { ... },
  "accessToken": "...",
  "refreshToken": "..." // Rotated refresh token
}
Error Codes:
  - 401: No refresh token provided
  - 403: Invalid or expired refresh token


PATCH /api/v1/users/role
Access: Protected (Requires Valid Access Token)
Description: Updates the currently authenticated user's role.
Request Headers:
  - Content-Type: application/json
  - Authorization: Bearer <Token>
Request Body:
{
  "role": "String, Required. Enum: ['organizer']"
}
Response (200 OK):
{
  "success": true,
  "user": { "_id": "...", "role": "organizer" }
}


--------------------------------------------------------------------------------
2. Teams (/api/v1/teams)
--------------------------------------------------------------------------------

POST /api/v1/teams
Access: Protected (Organizer Only)
Description: Creates a new team under the organizer's profile.
Request Headers:
  - Content-Type: application/json
  - Authorization: Bearer <Token>
Request Body:
{
  "name": "String, Required. Must be unique across all teams.",
  "abbreviation": "String, Optional. Max 5 characters. Automatically uppercased.",
  "logoEmoji": "String, Optional. Defaults to '👕'.",
  "logoColorHex": "Number, Optional. Defaults to 4293918720.",
  "captainId": "ObjectId, Optional. Must reference a valid Player ID.",
  "playerIds": ["ObjectId", ...] // Optional array of Player IDs
}
Response (201 Created): Full Team document including default `teamStats` (played: 0, won: 0, etc).
Error Codes:
  - 400: Team name already exists
  - 403: User role is not authorized (Must be organizer)


GET /api/v1/teams
Access: Public
Description: Fetches teams, optionally filtered by search term or creator.
Query Params:
  - q: String (Searches team name and abbreviation via Regex)
  - creatorId: ObjectId (Filters by the organizer who created it)
Response (200 OK): Array of Team documents (populates captainId with name & role).


POST /api/v1/teams/:teamId/players
Access: Protected (Organizer Only - Must be the team's creator)
Description: Adds a single player to the team's roster.
Request Headers:
  - Content-Type: application/json
  - Authorization: Bearer <Token>
Request Body:
{
  "playerId": "ObjectId, Required."
}
Response (200 OK): Updated Team document.
Error Codes:
  - 403: Forbidden: You do not have permission to add players to this team
  - 404: Team not found


--------------------------------------------------------------------------------
3. Players (/api/v1/players)
--------------------------------------------------------------------------------

POST /api/v1/players
Access: Protected (Organizer Only)
Description: Creates a new player profile.
Request Body:
{
  "name": "String, Required.",
  "playingRole": "String, Optional. Enum: ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper']. Defaults to 'Batsman'",
  "battingStyle": "String, Optional. Enum: ['Right-hand bat', 'Left-hand bat']",
  "bowlingStyle": "String, Optional."
}
Response (201 Created): Player document with initialized career stats (all 0).


PUT /api/v1/players/:playerId
Access: Protected (Organizer Only - Must be the creator, if linked to user)
Description: Updates player details.
Request Body: Any valid fields from POST request.
Response (200 OK): Updated Player document.


--------------------------------------------------------------------------------
4. Tournaments (/api/v1/tournaments)
--------------------------------------------------------------------------------

POST /api/v1/tournaments
Access: Protected (Organizer Only)
Description: Initializes a new tournament.
Request Body:
{
  "name": "String, Required.",
  "type": "String, Optional. Defaults to 'League'.",
  "playoffType": "String, Optional. Defaults to 'Direct Final'.",
  "defaultOvers": "Number, Optional. Defaults to 20.",
  "venue": "String, Optional.",
  "startDate": "Date String (ISO), Required.",
  "endDate": "Date String (ISO), Optional."
}
Response (201 Created): Tournament document (status: 'Upcoming').


PUT /api/v1/tournaments/:tournamentId
Access: Protected (Organizer Only - Must be creator)
Description: Updates tournament details and status.
Request Body:
{
  "status": "String, Enum: ['Upcoming', 'Ongoing', 'Completed']",
  "winnerTeamId": "ObjectId, Optional."
}
Response (200 OK): Updated Tournament.


POST /api/v1/tournaments/:tournamentId/teams
Access: Protected (Organizer Only)
Description: Bulk adds teams to the tournament and initializes their points table rows.
Request Body:
{
  "teamIds": ["ObjectId", ...] // Array of Team IDs
}
Response (200 OK): Tournament document.


--------------------------------------------------------------------------------
5. Matches (/api/v1/matches)
--------------------------------------------------------------------------------

POST /api/v1/matches
Access: Protected (Organizer Only)
Description: Schedules a new match between two teams.
Request Body:
{
  "teamAId": "ObjectId, Required.",
  "teamBId": "ObjectId, Required.",
  "totalOvers": "Number, Required.",
  "venue": "String, Optional.",
  "matchDate": "Date String (ISO), Required.",
  "tournamentId": "ObjectId, Optional.",
  "tournamentName": "String, Optional."
}
Response (201 Created): Match document (status: 'upcoming').


PUT /api/v1/matches/:matchId/start
Access: Protected (Organizer Only - Must be creator)
Description: Starts the match. Transitions status to 'live'.
Request Body:
{
  "playingXI": {
    "teamA": ["ObjectId", ...],
    "teamB": ["ObjectId", ...]
  }
}
Response (200 OK): Match document.


POST /api/v1/matches/:matchId/score
Access: Protected (Organizer Only)
Description: Emits WebSocket score updates and saves live ball-by-ball details.
Request Body:
{
  "striker": "ObjectId",
  "nonStriker": "ObjectId",
  "bowler": "ObjectId",
  "runs": "Number",
  "extras": { "type": "String", "runs": "Number" },
  "isWicket": "Boolean",
  "wicketType": "String"
}
Response (200 OK): Deeply updated Match document.

--------------------------------------------------------------------------------
6. Global Stats (/api/v1/stats)
--------------------------------------------------------------------------------

GET /api/v1/stats/teams
Access: Public
Description: Returns an array of Team documents, usually for leaderboard purposes.
Query Params: None currently required.

GET /api/v1/stats/players
Access: Public
Description: Returns an array of Player documents.
 */