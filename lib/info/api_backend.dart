/*CricX API Documentation (v1.0.0)
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
Response (201 Created): { "user": { ... }, "token": "JWT String" }
* Note: A refreshToken (7d expiry) is also automatically set as a secure HTTP-Only cookie named 'jwt'.

POST /api/v1/users/login
Access: Public
Description: Authenticates an existing user and returns access/refresh tokens.
Request Body:
{
  "email": "String, Optional (Requires phone if empty)",
  "phone": "String, Optional (Requires email if empty)",
  "password": "String, Required."
}
Response (200 OK): { "user": { ... }, "token": "..." }

POST /api/v1/users/guest
Access: Public
Description: Instantly creates a temporary guest account (auto-generates name/ID).
Response (201 Created): { "_id": "...", "name": "Guest_XYZ", "role": "guest", "token": "..." }

POST /api/v1/users/refresh
Access: Public
Description: Generates a new access token using a valid refresh token.
Request Body: { "token": "String, Required. The refresh token previously issued." }
Response (200 OK): { "token": "..." }

POST /api/v1/users/logout
Access: Public
Description: Logs out the user by clearing the JWT HTTP-Only cookie.
Response (200 OK): { "message": "Logged out successfully" }

GET /api/v1/users/profile
Access: Protected (Requires Valid Access Token)
Description: Retrieves the currently authenticated user's profile information.
Response (200 OK): { "user": { "_id": "...", "name": "...", "email": "...", "role": "..." } }

PATCH /api/v1/users/role
Access: Protected
Description: Updates the currently authenticated user's role.
Request Body: { "role": "String, Required. Enum: ['organizer']" }
Response (200 OK): { "success": true, "user": { "_id": "...", "role": "organizer" } }


--------------------------------------------------------------------------------
2. Teams (/api/v1/teams)
--------------------------------------------------------------------------------

GET /api/v1/teams
Access: Public
Description: Fetches teams, optionally filtered by search term or creator.
Query Params: ?q=searchString & creatorId=objectId
Response (200 OK): Array of Team documents.

POST /api/v1/teams
Access: Protected (Organizer Only)
Description: Creates a new team under the organizer's profile.
Request Body:
{
  "name": "String, Required. Must be unique.",
  "abbreviation": "String, Optional. Max 5 characters.",
  "logoEmoji": "String, Optional. Defaults to '👕'.",
  "logoColorHex": "Number, Optional.",
  "captainId": "ObjectId, Optional.",
  "playerIds": ["ObjectId", ...]
}
Response (201 Created): Full Team document.

PUT /api/v1/teams/:teamId
Access: Protected (Organizer Only)
Description: Updates an existing team's core information.
Request Body: Any valid fields from POST request.
Response (200 OK): Updated Team document.

POST /api/v1/teams/:teamId/players
Access: Protected (Organizer Only)
Description: Adds a single player to the team's roster.
Request Body: { "playerId": "ObjectId, Required." }
Response (200 OK): Updated Team document.

DELETE /api/v1/teams/:teamId/players/:playerId
Access: Protected (Organizer Only)
Description: Removes a player from the team's roster.
Response (200 OK): Updated Team document.


--------------------------------------------------------------------------------
3. Players (/api/v1/players)
--------------------------------------------------------------------------------

GET /api/v1/players
Access: Public
Description: Fetches a list of all players. Supports search via ?q=searchTerm.
Response (200 OK): Array of Player documents.

GET /api/v1/players/:playerId
Access: Public
Description: Fetches a specific player by their ID.
Response (200 OK): Player document.

POST /api/v1/players
Access: Protected (Organizer Only)
Description: Creates a new player profile.
Request Body:
{
  "name": "String, Required.",
  "playingRole": "String, Optional. Enum: ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper'].",
  "battingStyle": "String, Optional. Enum: ['Right-hand bat', 'Left-hand bat']",
  "bowlingStyle": "String, Optional."
}
Response (201 Created): Player document.

PUT /api/v1/players/:playerId
Access: Protected (Organizer Only)
Description: Updates player biographical details.
Request Body: Any valid fields from POST request.
Response (200 OK): Updated Player document.

PUT /api/v1/players/:playerId/stats
Access: Protected (Organizer Only)
Description: Manually overrides or updates a player's career statistics.
Request Body: { "careerStats": { "matches": 10, "runs": 500, "wickets": 15, ... } }
Response (200 OK): Updated Player document.


--------------------------------------------------------------------------------
4. Tournaments (/api/v1/tournaments)
--------------------------------------------------------------------------------

GET /api/v1/tournaments
Access: Public
Description: Fetches all tournaments. Supports search via ?q=searchTerm and ?creatorId=...
Response (200 OK): Array of Tournament documents.

GET /api/v1/tournaments/:tournamentId/points-table
Access: Public
Description: Fetches the sorted points table for a specific tournament.
Response (200 OK): Array of points table objects sorted by points and NRR.

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
Response (201 Created): Tournament document.

PUT /api/v1/tournaments/:tournamentId
Access: Protected (Organizer Only)
Description: Updates tournament details, status, and fixtures.
Request Body:
{
  "status": "String, Enum: ['Upcoming', 'Ongoing', 'Completed']",
  "winnerTeamId": "ObjectId, Optional.",
  "fixtures": ["ObjectId"] // OR Array of objects: [{ "matchId": "ObjectId", "stage": "String" }] to bulk update
}
Response (200 OK): Updated Tournament.

PATCH /api/v1/tournaments/:tournamentId/player-of-the-tournament
Access: Protected (Organizer Only)
Description: Declares the Player of the Tournament.
Request Body: { "playerOfTheTournamentId": "ObjectId", "playerOfTheTournamentName": "String" }
Response (200 OK): Updated Tournament.

POST /api/v1/tournaments/:tournamentId/teams
Access: Protected (Organizer Only)
Description: Bulk adds teams to the tournament and initializes their points table rows.
Request Body: { "teamIds": ["ObjectId", ...] }
Response (200 OK): Tournament document.

POST /api/v1/tournaments/:tournamentId/fixtures
Access: Protected (Organizer Only)
Description: Manually adds a single fixture to the tournament.
Request Body: { "matchId": "ObjectId", "stage": "String", "matchDate": "Date" }
Response (201 Created): Updated Tournament.


--------------------------------------------------------------------------------
5. Matches (/api/v1/matches)
--------------------------------------------------------------------------------

GET /api/v1/matches
Access: Public
Description: Fetches a list of matches. Supports filtering by ?tournamentId=...
Response (200 OK): Array of Match documents.

POST /api/v1/matches
Access: Protected (Organizer Only)
Description: Schedules a new match. Automatically injects into Tournament fixtures if tournamentId provided.
Request Body:
{
  "teamAId": "ObjectId, Required.",
  "teamBId": "ObjectId, Required.",
  "totalOvers": "Number, Required.",
  "venue": "String, Optional.",
  "matchDate": "Date String (ISO), Required.",
  "tournamentId": "ObjectId, Optional.",
  "tournamentName": "String, Optional.",
  "stage": "String, Optional. Enum: ['League', 'Semifinal', 'Final']. Defaults to 'League'."
}
Response (201 Created): Match document.

PUT /api/v1/matches/:matchId
Access: Protected (Organizer Only)
Description: Performs a monolithic, deep update on the entire Match state (including maps and arrays).
Request Body: Any full or partial Match schema fields.
Response (200 OK): Updated Match document.

PUT /api/v1/matches/:matchId/start
Access: Protected (Organizer Only)
Description: Starts the match. Transitions status to 'live' and initializes playing XI.
Request Body: { "playingXI": { "teamA": ["ObjectId"], "teamB": ["ObjectId"] }, "tossWinnerId": "ObjectId", "tossDecision": "Bat/Bowl" }
Response (200 OK): Match document.

POST /api/v1/matches/:matchId/score
Access: Protected (Organizer Only)
Description: Appends a ball event to the innings, recalculates runs/wickets, and emits live socket update.
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
Response (200 OK): Updated Match document.

PATCH /api/v1/matches/:matchId/player-of-the-match
Access: Protected (Organizer Only)
Description: Declares the Player of the Match.
Request Body: { "playerOfTheMatchId": "ObjectId", "playerOfTheMatchName": "String" }
Response (200 OK): Updated Match document.


--------------------------------------------------------------------------------
6. Global Stats & Discovery (/api/v1/stats & /api/v1/discovery)
--------------------------------------------------------------------------------

GET /api/v1/stats/teams
Access: Public
Description: Returns team leaderboards based on total stats.

GET /api/v1/stats/players
Access: Public
Description: Returns player leaderboards based on total stats.

GET /api/v1/discovery/live-matches
Access: Public
Description: Returns all currently ongoing matches globally (status: 'live').

GET /api/v1/discovery/search
Access: Public
Description: Performs a global regex search across Players, Teams, and Tournaments simultaneously.
Query Params: ?q=searchString
Response (200 OK): { "players": [...], "teams": [...], "tournaments": [...] }


--------------------------------------------------------------------------------
7. Notifications (/api/v1/notifications)
--------------------------------------------------------------------------------

GET /api/v1/notifications
Access: Protected
Description: Retrieves all notifications for the currently authenticated user.

PUT /api/v1/notifications/:id/read
Access: Protected
Description: Marks a specific notification as read.

*/