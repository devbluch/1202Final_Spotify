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


#Find out what the top genre of 2021 was
SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Date` LIKE '2021%'
GROUP BY `Genre`;

