# Packages
library(tidyverse)
library(janitor)
library(exifr)


# Read data ---------------------------------------------------------------

read_text_as_tibble <- function(dir) {
  # Takes a directory containing one or more text (.txt) files containing 
  # entries exported from Momento and returns a tibble where each row
  # represents one line from the text file
  
  # Get list of files to read
  files <- list.files(
    dir,
    pattern = ".+\\.txt",
    full.names = TRUE
  )
  
  # Get short filenames to use as labels
  short_files <- list.files(
    dir,
    pattern = ".+\\.txt"
  )
  
  # Read each file into a vector, and store the vectors in a list
  list <- map(files, ~read_lines(., skip_empty_rows = TRUE))
  names(list) <- short_files
  
  # Convert the list into a tibble with one row per vector element
  data <- tibble(
    source_file = rep(names(list), lengths(list)),
    value = unlist(list)
  )
}



# Process data ------------------------------------------------------------

make_momento_structured <- function(df) {
  # Takes a tibble containing contents of exported text files from Momento
  # and returns a new tibble with one row per entry and with all metadata
  # associated with that entry contained in separate columns
  
  df_structured <- df |> 
    
    # Remove the "====" dividers
    filter(str_detect(value, "^=+", negate = TRUE)) |> 
    
    # Add labels for each type of data
    mutate(
      label = case_when(
        str_detect(value, "\\d+\\s{1}\\w+\\s{1}\\d{4}") ~ "Date",
        str_detect(value, "\\d{2}:\\d{2}") ~ "Time",
        str_detect(value, "^Events:") ~ "Event",
        str_detect(value, "^Media:") ~ "Media",
        str_detect(value, "^At:") ~ "At",
        str_detect(value, "^With:") ~ "With",
        str_detect(value, "^Tags:") ~ "Tags",
        TRUE ~ "Text"
      )
    ) |> 
    
    # Remove label keywords from value column
    mutate(
      value = str_replace(
        value,
        "^Events: |^Media: |^At: |^With: |^Tags: ",
        ""
      )
    ) |> 
    
    # Initialise new columns for each element with NA
    mutate(
      date = NA,
      time = NA
    )
  
  # Initialize variables to store the current value of each element
  current_date <- NA
  current_time <- NA
  
  # Iterate through the tibble to assign all elements associated with each
  # "Text" entry
  for (i in 1:nrow(df_structured)) {
    if (df_structured$label[i] == "Date") {
      current_date <- df_structured$value[i]
    } else if (df_structured$label[i] == "Time") {
      current_time <- df_structured$value[i]
    } else if (!(df_structured$label[i] %in% c("Date", "Time"))) {
      df_structured$date[i] <- current_date
      df_structured$time[i] <- current_time
    }
  }
  
  df_structured <- df_structured |> 
    
    # Remove rows labelled date and time since we now have date and time
    # stored in columns
    filter(!label %in% c("Date", "Time")) |> 
    
    # Collapse text to one row per date/time
    group_by(date, time, label) |> 
    summarise(
      source_file = first(source_file),
      value = paste(value, collapse = "\n")
    ) |> 
    ungroup() |> 
    
    # Pivot wider to bring other elements into their own columns
    pivot_wider(
      id_cols = c(source_file, date, time),
      names_from = label,
      values_from = value
    ) |> 
    clean_names() |> 
    
    # Create a new column to merge date and time into datetime
    mutate(entry_date = dmy_hm(paste0(date, time))) |> 
    mutate(entry_date = format(with_tz(entry_date, "UTC"), "%Y-%m-%dT%H:%M:%S.000Z")) |> 

    # Select final set of columns in logical order
    select(
      entry_date,
      text,
      media,
      event,
      at,
      with,
      source_file
    ) |> 
    arrange(entry_date)
  
  return(df_structured)
}
