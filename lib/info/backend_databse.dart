/*
{
  "_id": {
    "$oid": "6a57127c0370a5c59ec46ccc"
  },
  "teamAId": {
    "$oid": "6a50cadf691504419e3acef4"
  },
  "teamBId": {
    "$oid": "6a50cc9f691504419e3acf26"
  },
  "totalOvers": 5,
  "venue": "stadium",
  "matchDate": {
    "$date": "2026-07-15T18:00:00.000Z"
  },
  "tournamentId": null,
  "tournamentName": null,
  "creatorId": {
    "$oid": "6a507bf00020aae5db79d6cf"
  },
  "status": "live",
  "tossWinnerId": {
    "$oid": "6a50cadf691504419e3acef4"
  },
  "tossDecision": "Bowl",
  "teamAPlayerIds": [
    {
      "$oid": "6a50cad9691504419e3acee7"
    },
    {
      "$oid": "6a50cada691504419e3aceea"
    },
    {
      "$oid": "6a50cadd691504419e3aceed"
    },
    {
      "$oid": "6a50cade691504419e3acef0"
    },
    {
      "$oid": "6a50cb58691504419e3acefe"
    }
  ],
  "teamBPlayerIds": [
    {
      "$oid": "6a50cc9a691504419e3acf19"
    },
    {
      "$oid": "6a50cc9c691504419e3acf1c"
    },
    {
      "$oid": "6a50cc9d691504419e3acf1f"
    },
    {
      "$oid": "6a50cc9e691504419e3acf22"
    },
    {
      "$oid": "6a50cccc691504419e3acf31"
    }
  ],
  "currentInningsNum": 1,
  "resultString": "",
  "strikerId": {
    "$oid": "6a50cc9a691504419e3acf19"
  },
  "nonStrikerId": {
    "$oid": "6a50cc9c691504419e3acf1c"
  },
  "currentBowlerId": {
    "$oid": "6a50cade691504419e3acef0"
  },
  "playerOfTheMatchId": null,
  "playerOfTheMatchName": "",
  "innings1": {
    "teamId": {
      "$oid": "6a50cc9f691504419e3acf26"
    },
    "runs": 0,
    "wickets": 0,
    "ballsBowled": 1,
    "events": [
      {
        "runs": 0,
        "isWide": false,
        "isNoBall": false,
        "isWicket": false,
        "wicketType": "",
        "bowlerName": "Bhuvneshvar",
        "batsmanName": "Rohit Sharma",
        "description": "Rohit Sharma scores 0 runs.",
        "isRunsOffBat": true,
        "isLegBye": false,
        "isPenalty": false,
        "isBye": false,
        "_id": {
          "$oid": "6a5712970370a5c59ec46cdb"
        }
      }
    ],
    "battingOrder": [
      {
        "$oid": "6a50cc9a691504419e3acf19"
      },
      {
        "$oid": "6a50cc9c691504419e3acf1c"
      }
    ],
    "_id": {
      "$oid": "6a5712970370a5c59ec46cda"
    }
  },
  "innings2": null,
  "isSuperOverPlayed": false,
  "superOverInnings1": null,
  "superOverInnings2": null,
  "playerRuns": {
    "6a50cc9a691504419e3acf19": 0,
    "6a50cc9c691504419e3acf1c": 0
  },
  "playerBallsFaced": {
    "6a50cc9a691504419e3acf19": 1,
    "6a50cc9c691504419e3acf1c": 0
  },
  "bowlerRunsConceded": {
    "6a50cade691504419e3acef0": 0
  },
  "bowlerWickets": {
    "6a50cade691504419e3acef0": 0
  },
  "bowlerBallsBowled": {
    "6a50cade691504419e3acef0": 1
  },
  "createdAt": {
    "$date": "2026-07-15T04:54:20.794Z"
  },
  "updatedAt": {
    "$date": "2026-07-15T04:54:47.806Z"
  },
  "__v": 1
}
 */

/* tournament database collection
{
  "_id": {
    "$oid": "6a54c1c970d984dea1a31b3e"
  },
  "name": "CricX Tournament",
  "type": "League",
  "playoffType": "Direct Final",
  "defaultOvers": 10,
  "venue": "CricX Turf Arena",
  "startDate": {
    "$date": "2026-07-15T00:00:00.000Z"
  },
  "status": "Ongoing",
  "participatingTeams": [
    {
      "$oid": "6a50cadf691504419e3acef4"
    },
    {
      "$oid": "6a50cc9f691504419e3acf26"
    },
    {
      "$oid": "6a53f2c065d367101053ddc0"
    },
    {
      "$oid": "6a53f2c065d367101053ddc4"
    },
    {
      "$oid": "6a54b57f70d984dea1a319b9"
    }
  ],
  "creatorId": {
    "$oid": "6a507bf00020aae5db79d6cf"
  },
  "winnerTeamId": null,
  "playerOfTheTournamentId": null,
  "playerOfTheTournamentName": "",
  "fixtures": [
    {
      "matchId": {
        "$oid": "6a571e4f0370a5c59ec48f6e"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec4900f"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e500370a5c59ec48f78"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49010"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e510370a5c59ec48f83"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49011"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e540370a5c59ec48f8f"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49012"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e5a0370a5c59ec48f9c"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49013"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e5c0370a5c59ec48faa"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49014"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e5d0370a5c59ec48fb9"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49015"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e5f0370a5c59ec48fc9"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49016"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e600370a5c59ec48fda"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49017"
      }
    },
    {
      "matchId": {
        "$oid": "6a571e620370a5c59ec48fec"
      },
      "stage": "League",
      "_id": {
        "$oid": "6a571e640370a5c59ec49018"
      }
    }
  ],
  "pointsTable": [
    {
      "team": {
        "$oid": "6a50cadf691504419e3acef4"
      },
      "matchesPlayed": 0,
      "won": 0,
      "lost": 0,
      "tied": 0,
      "points": 0,
      "netRunRate": 0,
      "_id": {
        "$oid": "6a54c1ca70d984dea1a31b42"
      }
    },
    {
      "team": {
        "$oid": "6a50cc9f691504419e3acf26"
      },
      "matchesPlayed": 0,
      "won": 0,
      "lost": 0,
      "tied": 0,
      "points": 0,
      "netRunRate": 0,
      "_id": {
        "$oid": "6a54c1ca70d984dea1a31b43"
      }
    },
    {
      "team": {
        "$oid": "6a53f2c065d367101053ddc0"
      },
      "matchesPlayed": 0,
      "won": 0,
      "lost": 0,
      "tied": 0,
      "points": 0,
      "netRunRate": 0,
      "_id": {
        "$oid": "6a54c1ca70d984dea1a31b44"
      }
    },
    {
      "team": {
        "$oid": "6a53f2c065d367101053ddc4"
      },
      "matchesPlayed": 0,
      "won": 0,
      "lost": 0,
      "tied": 0,
      "points": 0,
      "netRunRate": 0,
      "_id": {
        "$oid": "6a54c1ca70d984dea1a31b45"
      }
    },
    {
      "team": {
        "$oid": "6a54b57f70d984dea1a319b9"
      },
      "matchesPlayed": 0,
      "won": 0,
      "lost": 0,
      "tied": 0,
      "points": 0,
      "netRunRate": 0,
      "_id": {
        "$oid": "6a54c1ca70d984dea1a31b46"
      }
    }
  ],
  "createdAt": {
    "$date": "2026-07-13T10:45:29.458Z"
  },
  "updatedAt": {
    "$date": "2026-07-15T05:45:08.055Z"
  },
  "__v": 2
}
 */

/* gust user data

{
  "_id": {
    "$oid": "6a58b272a559b62df9030540"
  },
  "name": "Guest_8d73h",
  "role": "guest",
  "isGuest": true,
  "isActive": true,
  "createdAt": {
    "$date": "2026-07-16T10:29:06.981Z"
  },
  "updatedAt": {
    "$date": "2026-07-16T10:29:07.226Z"
  },
  "__v": 0,
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhNThiMjcyYTU1OWI2MmRmOTAzMDU0MCIsImlhdCI6MTc4NDE5Nzc0NywiZXhwIjoxNzg0ODAyNTQ3fQ.FzXHso3WVXqPBr-spqGVEr6Q1T5Axwy62igopAD_1Zs"
}
 */