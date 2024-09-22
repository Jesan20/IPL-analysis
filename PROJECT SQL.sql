CREATE TABLE matches(id int, city varchar(50), date date,player_of_match varchar(50),
venue varchar(200),neutral_venue int,team1 varchar(50),team2 varchar(50),toss_winner varchar(50),
toss_decision varchar(50),winner varchar(50),result varchar(50),result_margin int,
eliminator char(3),method char(3),umpire1 varchar(50),umpire2 varchar(50));

SET datestyle = 'DMY';-- issue of not recognising default datestyle

--loading dataset for matches table
COPY matches(id,city,date,player_of_match,venue,neutral_venue,team1,team2,toss_winner,
toss_decision,winner,result,result_margin,eliminator,method,umpire1,umpire2)
FROM 'C:\Program Files\PostgreSQL\17\bin\IPL\IPL_matches.csv'
DELIMITER ',' CSV HEADER ;
SELECT * FROM matches;

CREATE TABLE deliveries(id int,inning int,over int,ball int,batsman varchar(50),
non_striker varchar(50),bowler varchar(50),batsman_runs int,extra_runs int,total_runs int,
is_wicket int,dismissal_kind varchar(50),player_dismissed varchar(50),feilder varchar(50),
extras_type varchar(50),batting_team varchar(50),bowling_team varchar(50));

-- loading dataset for deliveries table
COPY deliveries(id,inning,over,ball,batsman,non_striker,bowler,batsman_runs,extra_runs,
total_runs,is_wicket,dismissal_kind,player_dismissed,feilder,extras_type,batting_team,
bowling_team)
FROM 'C:\Program Files\PostgreSQL\17\bin\IPL\IPL_Ball.csv'
DELIMITER ',' CSV HEADER;
SELECT * FROM deliveries;


SELECT * FROM deliveries
ORDER BY id ASC, inning ASC, over ASC, ball ASC
LIMIT 20;

SELECT * FROM matches
LIMIT 20;

SELECT * FROM matches
WHERE date = '2013-05-02';

SELECT * FROM matches
WHERE result = 'runs' AND result_margin > 100;

SELECT * FROM matches
WHERE result = 'tie'
ORDER BY date DESC;

SELECT COUNT(DISTINCT city) AS hosted_city FROM matches;

CREATE TABLE deliveries_v02 AS SELECT *, 
                                         CASE WHEN total_runs >= 4 THEN 'Boundary'
										       WHEN total_runs = 0  THEN 'Dot'
											   ELSE 'Other'
										  END AS Balls_count FROM deliveries;	

SELECT Balls_count, COUNT(Balls_count) AS total_count
FROM deliveries_v02
WHERE Balls_count IN ('Dot', 'Boundary')
GROUP BY Balls_count;

SELECT batting_team,COUNT(balls_count) AS BOUNDARIES FROM deliveries_v02
WHERE balls_count = 'Boundary' 
GROUP BY batting_team
ORDER BY BOUNDARIES DESC ;

SELECT bowling_team,COUNT(balls_count) AS DOT FROM deliveries_v02
WHERE balls_count = 'Dot'
GROUP BY bowling_team
ORDER BY DOT DESC;

SELECT dismissal_kind,COUNT(dismissal_kind) FROM DELIVERIES_v02
WHERE dismissal_kind NOT IN('NA')
GROUP BY dismissal_kind;
										
SELECT DISTINCT bowler,SUM(extra_runs) AS FREE_RUNS FROM deliveries
GROUP BY bowler
ORDER BY FREE_RUNS DESC
LIMIT 5;
SELECT * FROM matches;
SELECT * FROM deliveries_v02;

CREATE TABLE deliveries_v03 AS SELECT a.*,b.date AS match_date,b.venue FROM deliveries_v02 AS a
LEFT JOIN matches AS b
ON a.id = b.id ;
SELECT * FROM deliveries_v03;

SELECT venue,SUM(total_runs) AS TOTAL FROM deliveries_v03
GROUP BY venue
ORDER BY TOTAL DESC;

SELECT venue, EXTRACT(YEAR FROM match_date) AS year ,SUM(total_runs) AS TOTAL FROM deliveries_v03
WHERE venue = 'Eden Gardens'
GROUP BY year,venue
ORDER BY TOTAL DESC;

CREATE TABLE matches_corrected AS SELECT *,
                                          CASE 
										        WHEN team1 = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
										        Else team1
										   END AS team1_corr
										  ,CASE  
										        WHEN team2 = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
										        Else team2
										   END AS team2_corr FROM matches;	



-- id::TEXT, inning::TEXT, over::TEXT, ball::TEXT: Each column is explicitly cast to TEXT to
-- ensure compatibility with the STRING_AGG() function.
CREATE TABLE deliveries_v04 AS 
SELECT *,STRING_AGG(CONCAT(id::TEXT, '-', inning::TEXT, '-', over::TEXT, '-', ball::TEXT), ',') AS ball_id
FROM deliveries_v03
GROUP BY id,inning,over,ball,batsman,non_striker,bowler,batsman_runs,extra_runs,total_runs,
is_wicket,dismissal_kind,player_dismissed,feilder,extras_type,batting_team,bowling_team,balls_count,
match_date,venue;

SELECT * FROM deliveries_v04;
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT balls_count) AS balls FROM deliveries_v04;

CREATE TABLE deliveries_v05 AS
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY ball_id ORDER BY match_date) AS r_num  -- Replace 'some_column' with an appropriate column to order by
FROM deliveries_v04;


SELECT * FROM deliveries_v05
WHERE r_num = 2;

SELECT * FROM deliveries_v05
WHERE ball_id IN (SELECT BALL_ID FROM deliveries_v05 WHERE r_num=2);









































