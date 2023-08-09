# 1202 Final: ETL
## This repo documents my ETL process for a dataset on spotify streaming history from 2017 to 2021. 

## The Data

The data used for this project comes from Ivan Natarov on [Kaggle](https://www.kaggle.com/datasets/ivannatarov/spotify-daily-top-200-songs-with-genres-20172021)

It describes the daily top 200 songs streamed on Spotify over a 4 year window including information on:
- Song title
- Artist
- All key genres classifications
- Position on charts
- Date reflected by position
- Number of streams on that day

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

## Transforming the Data




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
```
