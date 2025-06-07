# Momento to Day One

## Objective
To take exported journal entries (including their associated timestamp, images and location) from Momento and import them into Day One using the Day One command line interface `dayone2`.

## Steps to take

1. Export data from Momento as a text file
2. Transform Momento data into dataframe (one row per entry)
3. Write a CLI command for each entry to import image, location and text into a Journal called `cli_test_journal`
4. Batch execute the CLI commands

### 1. Export data from Momento
The data that was exported from Momento is located in `/data/input`. This directory contains a text file for each month along with a subirecory `/photos` that contains all of the images associated with the entries.

### 2. Transform data
The R scripts in this repository contain the code needed to transform the raw data from Momento. The processed data is included in `/data/output/momento_structured_media.csv`.

### 3 Write CLI commands
The required format for each command is:

```
dayone2 -j [journalName] -isoDate [entryDate] -a [imageFilePath] --coordinate [latitude] [longitude] -- new [text]
```

The journal name, entry date and text are required fields for every CLI command. Coordinate and image file path should only be included if they exist.

#### Example input
|entries_creationDate|source_media|entries_text|entries_location_latitude|entries_location_longitude|
|:---|:---|:---|:---|:---|
|2017-10-27T15:47:00.000Z|6CC389AE-3FCF-4947-946F-14A401E42BFD_original.jpg|We are going for a walk!! Sun shining ☀️|51.2324361111111|-0.789208333333333|
|2017-11-03T16:07:00.000Z|026F7405-6304-4A17-ABBE-A58603D76E4A_original.jpg|Mum took this one at the registry office. I love the expression on Rowan’s face. And mine!|||

#### Expected output
```
dayone2 -j cli_test_journal -isoDate 2017-10-27T15:47:00.000Z -a ~/data/inputs/photos/6CC389AE-3FCF-4947-946F-14A401E42BFD_original.jpg --coordinate 51.2324361111111 -0.789208333333333 -- new We are going for a walk!! Sun shining ☀️

dayone2 -j cli_test_journal -isoDate 2017-11-03T16:07:00.000Z -a ~/data/inputs/photos/026F7405-6304-4A17-ABBE-A58603D76E4A_original.jpg -- new Mum took this one at the registry office. I love the expression on Rowan’s face. And mine!
```