#Review Data
SELECT * FROM spotify_dim;
SELECT * FROM spotify_fct;

#Clean column names
ALTER TABLE spotify_fct
	RENAME COLUMN ï»¿Position to `Position`;



#Join into new table
CREATE TABLE spotify_joined LIKE spotify_dim;

INSERT INTO spotify_joined
SELECT * FROM spotifystreams.spotify_dim
JOIN spotify_fct
ON spotifystreams.spotify_dim.`Track ID` = spotify_fct.`Track ID`;

SELECT * FROM spotify_joined;



#Remove incomplete entries
DELETE FROM spotify_joined
WHERE `Streams` IS null;
DELETE FROM spotify_joined
WHERE `Genre` IS null;

#Fix character errors on apostrophes 
UPDATE spotify_joined
SET `Track Name`=replace(`Track Name`,"Ã¢ÂÂ","'");

#Add column to allow for easy sorting by year
ALTER TABLE spotify_joined
ADD `Year` numeric(4) NOT NULL
AFTER `Date`;
UPDATE spotify_joined
SET `Year` = LEFT(`Date`, 4);


#Find out what the top genre of each year was
SELECT * FROM spotify_joined
WHERE `Year` = 2017;
#Total songs: 13157

SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Year` = 2017
GROUP BY `Genre`;
#OUTPUT = 1: Pop (3091), 2: Rap (1012), 3: UK Pop (620), 4: Canadian Pop (517), 5: Reggaeton Colombiano (454)


SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Year` = 2018
GROUP BY `Genre`;
#OUTPUT = 1: Pop (2150), 2: Rap (664), 3: Melodic Rap (441), 4: Miami Hip Hop (439), 5: DFW Rap (423)

SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Year` = 2019
GROUP BY `Genre`;
#OUTPUT = 1: Pop (2612), 2: Melodic Rap (582), 3: UK Pop (537), 4. DFW Rap (425), 5: Reggaeton Colombiano (352)

SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Year` =  2020
GROUP BY `Genre`;
#OUTPUT = 1. Pop (1787), 2: Melodic Rap (732), 3: Trap Latino (525), 4: UK Pop (472), 5: Reggaeton Colombiano (448)

SELECT * FROM spotify_joined
WHERE `Year` = 2021;
#Total songs: 4055

SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Year` = 2021
GROUP BY `Genre`;
#OUPUT = 1:Pop (754), 2: UK Pop (234), 3: Canadian Pop (211), 4: Reggaeton Colombiano (208), 5: Melodic Rap (201)


SELECT COUNT(`Genre`) AS 'Number of Top 200s Pop Songs', `Year`
FROM spotify_joined
WHERE `Genre` = 'pop'
GROUP BY `Year`;
#Output indicates a general decline in proportion of top 200s tracks classified primarily as Pop songs

#Take a look a secondary genre tags in 2020 & 2021
SELECT `Secondary Genre`, COUNT(`Secondary Genre`)
FROM spotify_joined
WHERE `Year` = 2020
GROUP BY `Secondary Genre`;
#OUTPUT = 1: Post-teen pop (30), 2: Reggaeton flow (25), 3: Latin (23), 4: Urban contemporary (17), 5: Dance pop (17)

SELECT `Secondary Genre`, COUNT(`Secondary Genre`)
FROM spotify_joined
WHERE `Year` = 2021
GROUP BY `Secondary Genre`;
#OUTPUT = 1. Tropical house (21), 2: Art rock (14), 3: Pop (7), 4: Sertanejo Universitario (5), 5: Pop rap (4)