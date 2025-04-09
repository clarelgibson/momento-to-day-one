# Momento to Day One
# A script to take the export files from the Momento app and transform the data
# into a structure that can be accepted by Day One for import

# Packages ----------------------------------------------------------------

library(tidyverse)
library(here)

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
      str_detect(value, "^[a-zA-Z]+:") ~ "Tag",
      TRUE ~ "Text"
    )
  )

# Initialize new columns with NA
momento_labelled <- momento_labelled |> 
  mutate(
    date = NA,
    time = NA
  )

# Initialize variables to store the current date and time
current_date <- NA
current_time <- NA

# Iterate through the data frame to assign dates and times to "Text" entries
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
  filter(!(label %in% c("Date", "Time")))
