-- GOAL ANALYSIS--
-- 1. Which player scored the most goals in each season?
SELECT m.season, p.last_name AS player, COUNT(*) AS goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN players p ON g.pid = p.player_id
GROUP BY m.season, player
ORDER BY m.season, goals DESC;

-- 2. How many goals did each player score in a given season?
SELECT m.season,  p.last_name AS player, COUNT(*) AS goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN players p ON g.pid = p.player_id
WHERE m.season = '2021-2022'
GROUP BY m.season, player;

-- 3. Total goals in match 'mt403'
SELECT COUNT(*) AS total_goals
FROM goals
WHERE match_id = 'mt403';

-- 4. Which player assisted the most goals in each season?
SELECT m.season, p.last_name AS player, COUNT(*) AS assists
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN players p ON g.assist = p.player_id
GROUP BY m.season, player
ORDER BY m.season, assists DESC;

-- 5. Players who scored in more than 10 matches
SELECT g.pid,  p.last_name AS player, COUNT(DISTINCT g.match_id) AS matches_scored
FROM goals g
JOIN players p ON g.pid = p.player_id
GROUP BY g.pid, player
HAVING COUNT(DISTINCT g.match_id) > 10;

-- 6. Average goals per match in a season
SELECT season, ROUND(COUNT(g.goal_id)::NUMERIC / COUNT(DISTINCT m.match_id), 2) AS avg_goals_per_match
FROM matches m
LEFT JOIN goals g ON m.match_id = g.match_id
GROUP BY season;

-- 7. Player with most goals in a single match
SELECT g.match_id,  p.last_name AS player, COUNT(*) AS goals
FROM goals g
JOIN players p ON g.pid = p.player_id
GROUP BY g.match_id, player
ORDER BY goals DESC
LIMIT 1;

-- 8. Team with most goals across all seasons
SELECT t.team_name, COUNT(*) AS total_goals
FROM goals g
JOIN players p ON g.pid = p.player_id
JOIN teams t ON p.team = t.team_name
GROUP BY t.team_name
ORDER BY total_goals DESC
LIMIT 1;

-- 9. Stadium hosting most goals in a single season
SELECT m.season, m.stadium, COUNT(*) AS total_goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
GROUP BY m.season, m.stadium
ORDER BY total_goals DESC;


--- MATCH ANALYSIS ---
-- 1. Highest scoring match in a season
SELECT season, match_id, home_team, away_team, home_team_score + away_team_score AS total_goals
FROM matches
WHERE season = '2021-2022'
ORDER BY total_goals DESC
LIMIT 1;

-- 2. Matches ending in draw
SELECT season, COUNT(*) AS draws
FROM matches
WHERE home_team_score = away_team_score
GROUP BY season;

-- 3. Team with highest average score (2021-2022)
SELECT team, ROUND(AVG(score),2) AS avg_score
FROM (
  SELECT home_team AS team, home_team_score AS score FROM matches WHERE season='2021-2022'
  UNION ALL
  SELECT away_team, away_team_score FROM matches WHERE season='2021-2022'
) t
GROUP BY team
ORDER BY avg_score DESC;

-- 4. Penalty shootouts per season
SELECT season, COUNT(*) AS shootouts
FROM matches
WHERE penalty_shoot_out = 1
GROUP BY season;

-- 5. Average attendance for home teams (2021-2022)
SELECT ROUND(AVG(attendance),0) AS avg_attendance
FROM matches
WHERE season = '2021-2022';

-- 6. Stadium hosting most matches each season
SELECT season, stadium, COUNT(*) AS matches_played
FROM matches
GROUP BY season, stadium
ORDER BY season, matches_played DESC;

-- 7. Match distribution by country in a season
SELECT m.season, s.country, COUNT(*) AS matches
FROM matches m
JOIN stadiums s ON m.stadium = s.name
WHERE m.season = '2021-2022'
GROUP BY m.season, s.country;

-- 8. Most common result (home win, away win, draw)
SELECT result, COUNT(*) AS total
FROM (
  SELECT CASE 
           WHEN home_team_score > away_team_score THEN 'Home Win'
           WHEN home_team_score < away_team_score THEN 'Away Win'
           ELSE 'Draw'
         END AS result
  FROM matches
) sub
GROUP BY result
ORDER BY total DESC;

---  PLAYER ANALYSIS  ---
-- 1. Players with highest total goals + assists
SELECT p.first_name || ' ' || p.last_name AS player,
       COUNT(DISTINCT g.goal_id) + COUNT(DISTINCT a.goal_id) AS total_contribution
FROM players p
LEFT JOIN goals g ON p.player_id = g.pid
LEFT JOIN goals a ON p.player_id = a.assist
GROUP BY player
ORDER BY total_contribution DESC;

-- 2. Average height & weight per position
SELECT position, ROUND(AVG(height),2) AS avg_height, ROUND(AVG(weight),2) AS avg_weight
FROM players
GROUP BY position;

-- 3. Player with most goals by left foot
SELECT p.first_name || ' ' || p.last_name AS player, COUNT(*) AS left_goals
FROM goals g
JOIN players p ON g.pid = p.player_id
WHERE p.foot = 'L'
GROUP BY player
ORDER BY left_goals DESC
LIMIT 1;

-- 4. Average age of players per team
SELECT team, ROUND(AVG(EXTRACT(YEAR FROM AGE(DOB))),2) AS avg_age
FROM players
GROUP BY team;

-- 5. Number of players per team in a season
SELECT m.season, p.team, COUNT(DISTINCT p.player_id) AS total_players
FROM players p
JOIN matches m ON p.team IN (m.home_team, m.away_team)
GROUP BY m.season, p.team;

-- 6. Player with most matches played per season
SELECT season, player, COUNT(*) AS matches_played
FROM (
  SELECT m.season, p.first_name || ' ' || p.last_name AS player, m.match_id
  FROM matches m
  JOIN players p ON p.team IN (m.home_team, m.away_team)
) sub
GROUP BY season, player
ORDER BY season, matches_played DESC;

-- 7. Most common position
SELECT position, COUNT(*) AS count
FROM players
GROUP BY position
ORDER BY count DESC
LIMIT 1;

-- 8. Players who never scored a goal
SELECT p.first_name || ' ' || p.last_name AS player
FROM players p
LEFT JOIN goals g ON p.player_id = g.pid
WHERE g.goal_id IS NULL;


--- TEAM ANALYSIS ---
-- 1. Team with largest home stadium
SELECT t.team_name, s.name, s.capacity
FROM teams t
JOIN stadiums s ON t.home_stadium = s.name
ORDER BY s.capacity DESC
LIMIT 1;

-- 2. Teams from each country in a season
SELECT DISTINCT m.season, t.country, t.team_name
FROM teams t
JOIN matches m ON t.team_name IN (m.home_team, m.away_team)
ORDER BY season, country;

-- 3. Team scoring most goals in a season
SELECT season, team, SUM(goals) AS total_goals
FROM (
  SELECT m.season, m.home_team AS team, m.home_team_score AS goals FROM matches m
  UNION ALL
  SELECT m.season, m.away_team, m.away_team_score FROM matches m
) sub
GROUP BY season, team
ORDER BY season, total_goals DESC;

-- 4. Number of teams with home stadiums per city/country
SELECT s.city, s.country, COUNT(DISTINCT t.team_name) AS teams_count
FROM teams t
JOIN stadiums s ON t.home_stadium = s.name
GROUP BY s.city, s.country;

-- 5. Teams with most home wins (2021-2022)
SELECT home_team, COUNT(*) AS wins
FROM matches
WHERE season = '2021-2022'
  AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY wins DESC;


--- STADIUM ANALYSIS ---
-- 1. Stadium with highest capacity
SELECT name, capacity
FROM stadiums
ORDER BY capacity DESC
LIMIT 1;

-- 2. Stadiums in Russia or London
SELECT *
FROM stadiums
WHERE country = 'Russia' OR city = 'London';

-- 3. Stadium hosting most matches in a season
SELECT season, stadium, COUNT(*) AS matches
FROM matches
GROUP BY season, stadium
ORDER BY matches DESC;

-- 4. Average stadium capacity per season
SELECT m.season, ROUND(AVG(s.capacity),0) AS avg_capacity
FROM matches m
JOIN stadiums s ON m.stadium = s.name
GROUP BY m.season;

-- 5. Teams playing in stadiums with capacity > 50000
SELECT DISTINCT t.team_name, s.capacity
FROM teams t
JOIN stadiums s ON t.home_stadium = s.name
WHERE s.capacity > 50000;

-- 6. Stadium with highest average attendance per season
SELECT m.season, m.stadium, ROUND(AVG(m.attendance),0) AS avg_attendance
FROM matches m
GROUP BY m.season, m.stadium
ORDER BY avg_attendance DESC;

-- 7. Stadium capacity distribution by country
SELECT country, ROUND(AVG(capacity),0) AS avg_capacity, COUNT(*) AS total_stadiums
FROM stadiums
GROUP BY country
ORDER BY avg_capacity DESC;


--- CROSS-TABLE ANALYSIS ---
-- 1. Players scoring most goals at a stadium
SELECT m.stadium, p.first_name || ' ' || p.last_name AS player, COUNT(*) AS goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN players p ON g.pid = p.player_id
GROUP BY m.stadium, player
ORDER BY goals DESC;

-- 2. Team with most home wins in 2021-2022
SELECT home_team, COUNT(*) AS wins
FROM matches
WHERE season = '2021-2022'
  AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY wins DESC;

-- 3. Players in team with most goals in 2021-2022
WITH team_goals AS (
  SELECT team, SUM(goals) AS total_goals
  FROM (
    SELECT home_team AS team, home_team_score AS goals FROM matches WHERE season='2021-2022'
    UNION ALL
    SELECT away_team, away_team_score FROM matches WHERE season='2021-2022'
  ) t
  GROUP BY team
  ORDER BY total_goals DESC
  LIMIT 1
)
SELECT p.first_name || ' ' || p.last_name AS player, p.team
FROM players p
JOIN team_goals tg ON p.team = tg.team;

-- 4. Goals by home teams with attendance > 50000
SELECT SUM(home_team_score) AS total_goals
FROM matches
WHERE attendance > 50000;

-- 5. Players in matches with highest score difference
WITH max_diff AS (
  SELECT MAX(ABS(home_team_score - away_team_score)) AS diff FROM matches
)
SELECT DISTINCT p.first_name || ' ' || p.last_name AS player
FROM players p
JOIN matches m ON p.team IN (m.home_team, m.away_team)
JOIN max_diff d ON ABS(m.home_team_score - m.away_team_score) = d.diff;

-- 6. Goals in matches with penalty shootouts
SELECT COUNT(*) AS goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
WHERE m.penalty_shoot_out = 1;

-- 7. Home vs Away wins by country
SELECT s.country,
       SUM(CASE WHEN home_team_score > away_team_score THEN 1 ELSE 0 END) AS home_wins,
       SUM(CASE WHEN away_team_score > home_team_score THEN 1 ELSE 0 END) AS away_wins
FROM matches m
JOIN stadiums s ON m.stadium = s.name
GROUP BY s.country;

-- 8. Team with most goals in highest-attended matches
SELECT team, SUM(goals) AS total_goals
FROM (
  SELECT home_team AS team, home_team_score AS goals, attendance FROM matches
  UNION ALL
  SELECT away_team, away_team_score, attendance FROM matches
) t
WHERE attendance = (SELECT MAX(attendance) FROM matches)
GROUP BY team
ORDER BY total_goals DESC;

-- 9. Players with most assists when team lost (Top 3)
SELECT p.first_name || ' ' || p.last_name AS player, COUNT(*) AS assists
FROM goals g
JOIN players p ON g.assist = p.player_id
JOIN matches m ON g.match_id = m.match_id
WHERE (p.team = m.home_team AND m.home_team_score < m.away_team_score)
   OR (p.team = m.away_team AND m.away_team_score < m.home_team_score)
GROUP BY player
ORDER BY assists DESC
LIMIT 3;

-- 10. Total goals by defenders
SELECT COUNT(*) AS goals
FROM goals g
JOIN players p ON g.pid = p.player_id
WHERE p.position = 'Defender';

-- 11. Goals in stadiums with capacity > 60000
SELECT COUNT(*) AS goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN stadiums s ON m.stadium = s.name
WHERE s.capacity > 60000;

-- 12. Goals in matches played in cities (per season)
SELECT m.season, s.city, COUNT(*) AS goals
FROM goals g
JOIN matches m ON g.match_id = m.match_id
JOIN stadiums s ON m.stadium = s.name
GROUP BY m.season, s.city;

-- 13. Players scoring goals in matches with attendance > 100000
SELECT DISTINCT p.first_name || ' ' || p.last_name AS player
FROM goals g
JOIN players p ON g.pid = p.player_id
JOIN matches m ON g.match_id = m.match_id
WHERE m.attendance > 100000;


---  COMPLEX QUERIES ---
-- 1. Avg goals by each team in first 30 min
SELECT team, ROUND(AVG(goals),2) AS avg_goals
FROM (
  SELECT p.team, COUNT(*) AS goals
  FROM goals g
  JOIN players p ON g.pid = p.player_id
  WHERE g.duration <= 30
  GROUP BY p.team, g.match_id
) sub
GROUP BY team;

-- 2. Stadium with highest avg score difference
SELECT m.stadium, ROUND(AVG(ABS(home_team_score - away_team_score)),2) AS avg_diff
FROM matches m
GROUP BY m.stadium
ORDER BY avg_diff DESC
LIMIT 1;

-- 3. Players who scored in every match they played (per season)
SELECT season, player
FROM (
  SELECT m.season, p.player_id, p.first_name || ' ' || p.last_name AS player,
         COUNT(DISTINCT m.match_id) AS matches_played,
         COUNT(DISTINCT g.match_id) AS matches_scored
  FROM matches m
  JOIN players p ON p.team IN (m.home_team, m.away_team)
  LEFT JOIN goals g ON g.pid = p.player_id AND g.match_id = m.match_id
  GROUP BY m.season, p.player_id, player
) sub
WHERE matches_played = matches_scored;

-- 4. Teams with most wins by 3+ goals (2021-2022)
SELECT winner, COUNT(*) AS big_wins
FROM (
  SELECT season,
         CASE WHEN home_team_score - away_team_score >= 3 THEN home_team
              WHEN away_team_score - home_team_score >= 3 THEN away_team END AS winner
  FROM matches
  WHERE season='2021-2022'
) sub
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY big_wins DESC;

-- 5. Player from a country with highest goals per match
SELECT p.nationality, p.first_name || ' ' || p.last_name AS player,
       ROUND(COUNT(g.goal_id)::NUMERIC / COUNT(DISTINCT m.match_id),2) AS goals_per_match
FROM players p
JOIN goals g ON p.player_id = g.pid
JOIN matches m ON g.match_id = m.match_id
GROUP BY p.nationality, player
ORDER BY goals_per_match DESC
LIMIT 1;

