# Momento to Day One
# A script to take the export files from the Momento app and transform the data
# into a structure that can be accepted by Day One for import

# Packages ----------------------------------------------------------------

library(tidyverse)
library(here)
library(parsedate)

# Read in Momento data ----------------------------------------------------

# Get a list of text files to read
momento_files <- list.files(
  here("data/src"),
  pattern = ".+\\.txt",
  full.names = TRUE
)

# Read each file into a vector, and store the vectors in a list
momento_list <- map(momento_files, ~read_lines(., skip_empty_rows = TRUE))

# Convert the list to a single data frame
momento_data <- momento_list |> 
  unlist() |> 
  as_tibble()

# Process data ------------------------------------------------------------

# Add a label to each line to say what type of data it is
momento_labelled <- momento_data |> 
  filter(str_detect(value, "^=+", negate = TRUE)) |> 
  mutate(
    label = case_when(
      str_detect(value, "\\d+\\s{1}\\w+\\s{1}\\d{4}") ~ "Date",
      str_detect(value, "\\d{2}:\\d{2}") ~ "Time",
      str_detect(value, "^Events:") ~ "Event",
      str_detect(value, "^Media:") ~ "Media",
      str_detect(value, "^At:") ~ "At",
      str_detect(value, "^With:") ~ "With",
      TRUE ~ "Text"
    )
  ) |> 
  # Initialise new columns with NA
  mutate(
    date = NA,
    time = NA
  )

# Initialize variables to store the current date and time
current_date <- NA
current_time <- NA

# Iterate through the data frame to assign dates, times and media to "Text"
# entries
for (i in 1:nrow(momento_labelled)) {
  if (momento_labelled$label[i] == "Date") {
    current_date <- momento_labelled$value[i]
  } else if (momento_labelled$label[i] == "Time") {
    current_time <- momento_labelled$value[i]
  } else if (!(momento_labelled$label[i] %in% c("Date", "Time"))) {
    momento_labelled$date[i] <- current_date
    momento_labelled$time[i] <- current_time
  }
}

# Get the resulting data frame in the correct format for CSV import
momento_csv <- momento_labelled |> 
  # Remove the date and time labels since we now have date and time stored in
  # columns
  filter(!(label %in% c("Date", "Time"))) |> 
  # Create a new column to store the date and time
  mutate(datetime = dmy_hm(paste0(date, time))) |> 
  mutate(datetime = format(with_tz(datetime, "UTC"), "%Y-%m-%dT%H:%M:%S.000Z")) |> 
  # rename columns in line with Day One import requirements
  select(date = datetime, text = value, tag = label) |> 
  # add columns to store media details
  mutate(
    media = case_when(
      tag == "Media" ~ text,
      TRUE ~ NA
    )
  ) |> 
  group_by(date) |> 
  mutate(media = first(media, na_rm = TRUE)) |> 
  # keep only items with tag == "Text"
  filter(tag == "Text") |> 
  select(!tag) |> 
  # create one single record for each instance of date
  group_by(date) |> 
  summarise(
    text = paste(text, collapse = "\n"),
    media = first(media, na_rm = TRUE)
  )

# Split the data frame into entries with and without media
momento_no_media <- 
  momento_csv |> 
  filter(is.na(media)) |> 
  select(date, text)

momento_media <- 
  momento_csv |> 
  filter(!is.na(media))

# Export data -------------------------------------------------------------

export <- momento_no_media

write_csv(export, here("data/cln/export.csv"))
