# Packages
library(tidyverse)
library(janitor)
library(exifr)
library(tidygeocoder)

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
  
  return(data)
}

read_media_metadata <- function(dir, pattern="*.jpg|*.jpeg|*.mp4", tags) {
  # Takes a directory containing one or more media (.jpg or .mp4) files
  # and returns a tibble where each row contains requested metadata tags
  # for one media file
  
  # Get list of files to read
  files <- list.files(
    dir,
    pattern = pattern,
    full.names = TRUE
  )
  
  # Read the selected metadata tags for each file in the list
  metadata <- read_exif(
    path = files,
    tags = tags
  )
  
  return(metadata)
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
    
    # Keep only one media value per entry
    mutate(
      media = str_split_i(media, "\n", 1)
    ) |> 
    
    # Create a new column to merge date and time into datetime
    mutate(entry_date = dmy_hm(paste0(date, time))) |> 
    mutate(entry_date = format(with_tz(entry_date, "UTC"), "%Y-%m-%dT%H:%M:%S.000Z")) |> 
    select(!c(date, time)) |> 

    # Select final set of columns in logical order
    select(
      entry_date,
      text,
      everything()
    ) |> 
    relocate(source_file, .after = last_col()) |> 
    arrange(entry_date)
  
  return(df_structured)
}

join_meta_to_text <- function(structured_df, metadata) {
  # Takes the structured tibble created using make_momento_structured() and
  # adds the media metadata created using read_media_metadata()
  
  df_structured <- structured_df |> 
    
    # Join media metadata to momento text data
    left_join(
      metadata,
      by = join_by(media == FileName)
    ) |> 
    
    # Select and rename columns in accordance with Day One JSON tags
    select(
      source_text = source_file,
      source_media = media,
      entries_creationDate = entry_date,
      entries_text = text,
      entries_photos_fileSize = FileSize,
      entries_photos_type = FileType,
      entries_photos_duration = Duration,
      entries_photos_date = CreateDate,
      entries_photos_height = ImageHeight,
      entries_photos_width = ImageWidth,
      entries_photos_cameraMake = Make,
      entries_photos_cameraModel = Model,
      entries_photos_lensModel = LensModel,
      entries_photos_fnumber = FNumber,
      entries_photos_focalLength = FocalLength,
      entries_location_longitude = GPSLongitude,
      entries_location_latitude = GPSLatitude,
      event,
      at,
      with
    ) |> 
    
    # Adjust type and format of fields to fit expected JSON structure
    mutate(
      entries_photos_duration = case_when(
        !is.na(source_media) & is.na(entries_photos_duration) ~ 0,
        TRUE ~ entries_photos_duration
      ),
      entries_photos_date = case_when(
        !is.na(entries_photos_date) ~ ymd_hms(entries_photos_date),
        TRUE ~ NA
      ),
      entries_photos_date = case_when(
        !is.na(entries_photos_date) ~ format(with_tz(entries_photos_date, "UTC"), "%Y-%m-%dT%H:%M:%S.000Z"),
        TRUE ~ NA
      )
    )
  
  return(df_structured)
}

get_location_data <- function(joined_df) {
  # Takes the structured tibble created using join_meta_to_text() and
  # returns a new tibble containing geo data for each unique lat/long value
  
  # Extract lat/long from structured tibble
  coords <- 
    joined_df |> 
    select(
      lat = entries_location_latitude,
      long = entries_location_longitude
    ) |> 
    filter(!is.na(lat)) |> 
    distinct()
  
  # Make a new tibble containing geo data for all lat/longs
  df_geo <- 
    reverse_geo(
      lat = coords$lat,
      long = coords$long,
      full_results = TRUE
    ) |> 
    mutate(across(everything(), ~ifelse(.=="", NA, as.character(.)))) |>
    mutate(
      localityName = coalesce(town, city, village, county, state),
      placeName = coalesce(name, commercial, quarter, neighbourhood, road,
                           village, suburb, town)
    ) |>
    mutate(
      entries_location_latitude = as.double(lat),
      entries_location_longitude = as.double(long)
    )
  
  write_csv(df_geo, here("data/output/geo.csv"), na = "")
  
  return(df_geo)
}

join_geo_to_text <- function(joined_df, geo_df) {
  # Takes the structured tibble created using join_meta_to_text() and
  # adds the geo data created using get_location_data()
  
  df_structured <- joined_df |> 
    left_join(
      select(
        geo_df,
        entries_location_latitude,
        entries_location_longitude,
        entries_location_country = country,
        entries_location_administrativeArea = state,
        entries_location_placeName = placeName,
        entries_location_localityName = localityName
      ),
      by = join_by(
        entries_location_latitude,
        entries_location_longitude
      )
    )
  
  return(df_structured)
}

create_csv_import <- function(df) {
  # Takes structured tibble created using join_geo_to_text() and returns
  # a tibble in the required format for a CSV import into Day One
  
  csv <- df |> 
    select(
      date = entries_creationDate,
      text = entries_text
    )
  
  return(csv)
}