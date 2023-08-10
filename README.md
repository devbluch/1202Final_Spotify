# 1202 Final: ETL
## This repo documents my ETL process for a dataset on Spotify streaming history from 2017 to 2021. 

## The Data

The data used for this project comes from Ivan Natarov on [Kaggle](https://www.kaggle.com/datasets/ivannatarov/spotify-daily-top-200-songs-with-genres-20172021)

It describes the daily top 200 songs streamed on Spotify over a 4 year window including information on:
- Song title
- Artist
- All key genres classifications
- Position on charts
- Date reflected by position
- Number of streams on that day

I wanted to analyze the role of genre in song popularity over time. As a hypothetical business case, consider a new music production company that wants to find a market niche that offers an opportuntiy for long-term audience retention. They are still in the early stages of deciding on their strategy and long-term goals and want to ensure they target a genre niche that will allow for long-term growth.
By identifying year-over-year trends in genre popularity, the company can focus their efforts towards a sustainble genre focus for their future projects. 

***

To practice joining tables for the purposes of this project, I split the existing table into 2 new tables in Excel. I added a column called `Track ID` that contained the row number for each entry in order to ensure each line stayed unique once then table was split. Then, I created *spotify_dim* which contained the columns for track names, artists, and genres as well as *spotify_fct* which contained the columns for chart position, number of streams, and dates. Both tables also contained the Track ID column to enable joins.

## Loading The Data
The dataset initially contained 1 048 475 rows, which made it difficult to load the full tables directly into MySQL workbench. 
To ensure no data was lost, I used the following python script, replacing the _file_name & _table_name variables with the appropriate inputs, to open the tables:
```py

#   Load data from CSV to MySQL 
import pandas as pd
from sqlalchemy import create_engine


_table_name = "spotify_dim" # Enter table name here
_uname = 'root' # Enter username here
_pw = 'hello' # Enter password here
_db_name = 'spotifystreams' #  enter database name here
_file_name = 'Spotify_DIM.csv' # Enter file name here


########################################

# Create an engine to the MySQL database
engine = create_engine('mysql+mysqlconnector://{}:{}@localhost/{}'.format(_uname, _pw, _db_name), echo=False)

# Read the CSV file
data = pd.read_csv(_file_name, encoding='latin-1')

# Write the data from the CSV file to the database
data.to_sql(_table_name, con=engine, index=False, if_exists='replace')


```
Once the data was all accessible from my SQL server, I was able to view both tables and begin the transformation process. 
![1202_SELECT_dim.png](https://github.com/devbluch/1202Final_Spotify/blob/d0000a8408173ed77193dcc819e5185a9c2b8b56/screenshots/1202_SELECT_dim.png)
***
![1202_SELECT_fct.png](https://github.com/devbluch/1202Final_Spotify/blob/d0000a8408173ed77193dcc819e5185a9c2b8b56/screenshots/1202_SELECT_fct.png)

***

## Transforming and Loading the Data

Before making any changes to either table, I aggregated them back together using an inner join. I chose an inner join because all rows in both datasets should have had exact matches since I hadn't started altering their contents yet and I wanted to merge the entirity of both tables. I loaded the output of the join into a new table (spotify_joined) in order to enable future transformation to apply to the entire dataset at once and avoid any data loss or redundancies from transforming the tables seperately. 

From there, I cleaned the data by removing any incomplete entries. Several rows had a track name and chart position but were missing stream counts or artists and genres. I removed all rows with **null** values in the Streams or Genre columns. 
Several rows in the Track Name column also had text errors, with special characters replacing apostrophes. Since many songs appear multiple times throughout the data as they stayed in the top 200 for multiple days, I did not want to risk losing insights into trends over time by removing every instance of songs with apostrophes in their title. I used a REPLACE function to fix the errors and put apostrophes in the appropriate places in track names. 
![1202_PreApostropheFix](https://github.com/devbluch/1202Final_Spotify/blob/d0000a8408173ed77193dcc819e5185a9c2b8b56/screenshots/1202_PreApostropheFix.png)
![1202_PostApostropheFix](https://github.com/devbluch/1202Final_Spotify/blob/d0000a8408173ed77193dcc819e5185a9c2b8b56/screenshots/1202_PostApostropheFix.png)

With the tables transformed and joined, I wanted to determine which genre was the most popular in 2021. To find out, I selected the genre column with a count of each genre, grouped by genre, and filtered for the year 2021. The output indicated that pop was the most popular genre, with 754 of the daily top songs in 2021 listing pop as their primary genre.
![1202_TopGenre2021](https://github.com/devbluch/1202Final_Spotify/blob/d0000a8408173ed77193dcc819e5185a9c2b8b56/screenshots/1202_TopGenre2021.png)

***

### Analysis - Preliminary Findings
The outputs of an analysis of the top 5 genres each year indicates that while the Pop genre is at the top of the charts each year, the range of genres in the top 200s appears to be consistently diversifying over time. While in 2017, pop made up 23% of the top tracks, by 2021 the genre had fallen to 18% of the daily top 200. The second through fifth most popular genres on the other hand saw a considerable amount of fluctuation each year. Pop subgenres however were the most common amongst the top 5 genres in total and appear consistently as secondary genre tags. 

Hip hop, rap, and related sub-genres (ie. Pop rap, Trap, etc) appear second most frequently amongst the top genres. The proportion of daily top 200 tracks in these genre categories increases over time in comparisson to the decreased proportion of pop songs. 


### MySQL Script:
```sql
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
WHERE `Date` LIKE '2017%'
GROUP BY `Genre`;
#OUTPUT = 1: Pop (3091), 2: Rap (1012), 3: UK Pop (620), 4: Canadian Pop (517), 5: Reggaeton Colombiano (454)


SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Date` LIKE '2018%'
GROUP BY `Genre`;
#OUTPUT = 1: Pop (2150), 2: Rap (664), 3: Melodic Rap (441), 4: Miami Hip Hop (439), 5: DFW Rap (423)

SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Date` LIKE '2019%'
GROUP BY `Genre`;
#OUTPUT = 1: Pop (2612), 2: Melodic Rap (582), 3: UK Pop (537), 4. DFW Rap (425), 5: Reggaeton Colombiano (352)

SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Date` LIKE '2020%'
GROUP BY `Genre`;
#OUTPUT = 1. Pop (1787), 2: Melodic Rap (732), 3: Trap Latino (525), 4: UK Pop (472), 5: Reggaeton Colombiano (448)

SELECT * FROM spotify_joined
WHERE `Year` = 2021;
#Total songs: 4055

SELECT `Genre`, COUNT(`Genre`)
FROM spotify_joined
WHERE `Date` LIKE '2021%'
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
```


## Reflection

I found working with MySQL to be a good review for key functions in SQL Workbench, as I was able to practice loading large datasets as well as creating joins and aggregrates in my script. I encountered a few errors while trying to load the data into a new table because I hadn't created a destination table before trying to insert the output from the join into *spotify_joined* and my initial attempts to create an empty table didn't generate the right number of columns for the INSERT function to work. By referring to online documentation, however, I was able to identify where the errors were coming from and create an empty table with enough columns to avoid the error. 
I also found splitting the tables in Excel to be challenging initially, as I wasn't sure how to best create an ID column to allow for accurate joining, given the size of the dataset. I initially tried to use the Flash Fill function to give each entry a unique code that reflected its position and the year, but because of the size of the dataset and the null values mixed in along several columns, the output often had blank or repeating numbers. I ultimately decided that using **=ROW()** to populate a column with its row number would be the most streamlined option and went with that. 
For similar projects in the future, I would likely use the **CREATE VIEW** command in MySQL, rather than combining **CREATE TABLE** with **INSERT INTO** to have a more streamlined loading process. Now that I'm more familiar with how to number rows in Excel, I wouldn't spend as much time trying to come up with overly involved numbering systems to create ID rows for joining tables. In the future, I would also like to expand on my analysis further by linking my Workbench server to PowerBI and creating visualizations that allow for more effective, in-depth analysis of multiple variables. 
