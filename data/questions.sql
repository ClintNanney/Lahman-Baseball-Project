--Q1
SELECT DISTINCT(yearid)
FROM teams
ORDER BY yearid desc;

select min(yearid), max(yearid)
from teams;

-- 146 years (1871-2016)

--Q2 Find the name and height of the shortest player in the database. 
--How many games did he play in? What is the name of the team for which he played?
SELECT height, playerid, namegiven, namelast
FROM people
ORDER BY height;
-- Shortest player: Edward Carl Gaedel(gaedeed01)-43 inches - 3'7"

--How many games did he play in? 
SELECT g_all AS games, people.playerid AS pp, appearances.playerid AS ap, namegiven
from appearances
LEFT JOIN people
ON appearances.playerid = people.playerid
WHERE appearances.playerid = 'gaedeed01'
ORDER BY games;
-- 1 GAME

--What is the name of the team for which he played?
SELECT teamid
FROM appearances
WHERE playerid = 'gaedeed01';
--SLA
select name
FROM teams
WHERE teamid = 'SLA';
-- St. Louis Browns

SELECT namelast, namefirst, height, appearances.g_all as games_played, appearances.teamid as team, 
FROM people
INNER JOIN appearances
ON people.playerid = appearances.playerid
WHERE height IS NOT null
ORDER BY height;

--Q2
WITH shortest_player AS (SELECT *
						FROM people
						ORDER BY height
						LIMIT 1),
sp_total_games AS (SELECT *
				  FROM shortest_player
				  LEFT JOIN appearances
				  USING(playerid))
SELECT DISTINCT(name), namelast, namefirst, height, g_all as games_played, sp_total_games.yearid
FROM sp_total_games
LEFT JOIN teams
USING(teamid);

--#3--Find all players in the database who played at Vanderbilt University 
SELECT distinct concat(p.namefirst, ' ', p.namelast) as name, sc.schoolname,
  sum(sa.salary)
  OVER (partition by concat(p.namefirst, ' ', p.namelast)) as total_salary
  FROM (people p JOIN collegeplaying cp ON p.playerid = cp.playerid)
  JOIN schools sc ON cp.schoolid = sc.schoolid
  JOIN salaries sa ON p.playerid = sa.playerid
  where cp.schoolid = 'vandy'
  group by name, schoolname, sa.salary, sa.yearid
  ORDER BY total_salary desc;

--Q4
SELECT SUM(po) as put_out,
	   CASE WHEN pos='OF' THEN 'outfield'
	   	   	WHEN pos='1B' OR pos='2B' OR pos='3B' OR pos='SS' THEN 'infield'
	   	    ELSE 'battery' END AS position_group
FROM fielding
WHERE yearid=2016
GROUP BY position_group
ORDER BY SUM(po) DESC;


-- Q5:Find the average number of strikeouts per game by decade since 1920. 
--Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
WITH decades as (	
	SELECT 	generate_series(1920,2010,10) as low_b,
			generate_series(1929,2019,10) as high_b)
			
SELECT 	low_b as decade,
		--SUM(so) as strikeouts,
		--SUM(g)/2 as games,  -- used last 2 lines to check that each step adds correctly
		ROUND(SUM(so::numeric)/(sum(g::numeric)/2),2) as SO_per_game,  -- note divide by 2, since games are played by 2 teams
		ROUND(SUM(hr::numeric)/(sum(g::numeric)/2),2) as hr_per_game
FROM decades LEFT JOIN teams
	ON yearid BETWEEN low_b AND high_b
GROUP BY decade
ORDER BY decade

/* Q6:
Find the player who had the most success stealing bases in 2016, 
where success is measured as the percentage of stolen base attempts which are successful. 
(A stolen base attempt results either in a stolen base or being caught stealing.) 
Consider only players who attempted at least 20 stolen bases.
*/

SELECT DISTINCT(batting.playerid) as player, namefirst, namelast, teamid, SUM(cs+sb) as sb_attempts, SUM((sb::float/(sb::float+cs::float)))*100 AS sb_success, yearid
FROM batting
LEFT JOIN people
ON batting.playerid = people.playerid 
WHERE yearid = '2016' AND cs > 0 AND sb > 0 AND (cs + sb)>=20
GROUP BY player, namefirst, namelast, yearid, teamid
ORDER BY sb_success desc
LIMIT 1;
--Chris Owings - (91.304)

--Q6 Alternate
SELECT Concat(namefirst,' ',namelast), batting.yearid, ROUND(MAX(sb::decimal/(cs::decimal+sb::decimal))*100,2) as sb_success_percentage
FROM batting
INNER JOIN people on batting.playerid = people.playerid
WHERE yearid = '2016'
AND (sb+cs) >= 20
GROUP BY namefirst, namelast, batting.yearid
ORDER BY sb_success_percentage DESC;

/* Question 7
From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
Then redo your query, excluding the problem year. 
How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
What percentage of the time?
*/

--question #7
--part1
SELECT yearid, sum(w) as wins, wswin, franchid
from teams
WHERE wswin IS NOT null
and wswin = 'N'
and yearid between 1970 and 2016
group by wswin, franchid, yearid
order by wins DESC;
--largest = SEA, 116 wins for 2001
--part2
SELECT yearid, sum(w) as wins, wswin, franchid
from teams
WHERE wswin IS NOT null
and wswin = 'N'
and yearid between 1970 and 2016
group by wswin, franchid, yearid
order by wins;
--smallest = TOR, 37 win for 1981
--part3
SELECT yearid, sum(w) as wins, wswin, franchid
from teams
WHERE wswin IS NOT null
and wswin = 'Y'
and yearid between 1970 and 2016
group by wswin, franchid, yearid
order by wins;
-- players strike in 1981

--part4
WITH ws_winners AS (SELECT yearid,
						MAX(w)
					FROM teams
					WHERE yearid BETWEEN 1970 and 2016
					AND wswin = 'Y'
					GROUP BY yearid
					INTERSECT
					SELECT yearid,
						MAX(w)
					FROM teams
					WHERE yearid BETWEEN 1970 and 2016
					GROUP BY yearid
					ORDER BY yearid)
SELECT (COUNT(ws.yearid)/COUNT(t.yearid)::float)*100 AS percentage
FROM teams as t LEFT JOIN ws_winners AS ws ON t.yearid = ws.yearid
WHERE t.wswin IS NOT NULL
AND t.yearid BETWEEN 1970 AND 2016;

--Q7 My Version
SELECT DISTINCT(teamid), name, yearid, max(w) as wins, wswin
FROM teams
WHERE yearid BETWEEN 1970 and 2016 AND wswin = 'N'
GROUP BY teamid, name, yearid, wswin
order by wins desc
LIMIT 1;
--
--What is the smallest number of wins for a team that did win the world series? 
SELECT DISTINCT(teamid), name, yearid, min(w) as wins, wswin
FROM teams
WHERE yearid BETWEEN 1970 and 2016 AND wswin = 'Y'
GROUP BY teamid, name, yearid, wswin
order by wins 
LIMIT 1;
--LA Dodgers, 1981, 63wins
/*
Doing this will probably result in an unusually small number of wins for a world series champion – 
determine why this is the case. 
--the 1981 Major League Baseball strike, which caused the cancellation of roughly one-third of the regular season between June 12 and August 9; 
by the time play was resumed, it was decided that the best approach was to have the first-half leaders automatically qualify for postseason play, 
and allow all the teams to begin the second half with a clean slate. 
The series were best-of-five games.
*/

--Then redo your query, excluding the problem year.
SELECT DISTINCT(teamid), name, yearid, min(w) as wins, wswin
FROM teams
WHERE yearid BETWEEN 1970 and 2016 AND wswin = 'Y' AND yearid <> '1981'
GROUP BY teamid, name, yearid, wswin
order by wins 
LIMIT 1;
-- Without a strike, the team with the fewest wins in a season and a ws win was the 2006 St. Louis Cardinals.

--Q8
SELECT DISTINCT p.park_name, h.team,
	(h.attendance/h.games) as avg_attendance, t.name		
FROM homegames as h JOIN parks as p ON h.park = p.park
LEFT JOIN teams as t on h.team = t.teamid AND t.yearid = h.year
WHERE year = 2016
AND games >= 10
ORDER BY avg_attendance DESC
LIMIT 5;

-- Q9
--Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award.
WITH manager_both AS (SELECT playerid, al.lgid AS al_lg, nl.lgid AS nl_lg,
					  al.yearid AS al_year, nl.yearid AS nl_year,
					  al.awardid AS al_award, nl.awardid AS nl_award
	FROM awardsmanagers AS al INNER JOIN awardsmanagers AS nl
	USING(playerid)
	WHERE al.awardid LIKE 'TSN%'
	AND nl.awardid LIKE 'TSN%'
	AND al.lgid LIKE 'AL'
	AND nl.lgid LIKE 'NL')
	
SELECT DISTINCT(people.playerid), namefirst, namelast, managers.teamid,
		managers.yearid AS year, managers.lgid
FROM manager_both AS mb LEFT JOIN people USING(playerid)
LEFT JOIN salaries USING(playerid)
LEFT JOIN managers USING(playerid)
WHERE managers.yearid = al_year OR managers.yearid = nl_year;

--Bonus 
WITH mngr_list AS (SELECT playerid, awardid, COUNT(DISTINCT lgid) AS lg_count
				   FROM awardsmanagers
				   WHERE awardid = ‘TSN Manager of the Year’
				   		 AND lgid IN (‘NL’, ‘AL’)
				   GROUP BY playerid, awardid
				   HAVING COUNT(DISTINCT lgid) = 2),
	 mngr_full AS (SELECT playerid, awardid, lg_count, yearid, lgid
				   FROM mngr_list INNER JOIN awardsmanagers USING(playerid, awardid))
SELECT namegiven, namelast, name AS team_name
FROM mngr_full INNER JOIN people USING(playerid)
	 INNER JOIN managers USING(playerid, yearid, lgid)
	 INNER JOIN teams ON mngr_full.yearid = teams.yearid AND mngr_full.lgid = teams.lgid AND managers.teamid = teams.teamid
GROUP BY namegiven, namelast, name;





