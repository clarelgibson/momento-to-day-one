# Packages
library(here)

# Scripts
source(here("code/01-utils.R"))

# Read data ---------------------------------------------------------------

# Text files
dir <- here("data/src")
df <- read_text_as_tibble(dir)

# JPEG metadata
photo_dir <- here("data/src/attachments")
photos <- list.files(
  photo_dir,
  full.names = TRUE
)

photos_test <- photos[2:3]

media_metadata <- read_exif(
  path = photos_test
)

media_metadata <- media_metadata |> 
  pivot_longer(
    everything(),
    names_to = "tag_name",
    values_to = "tag_value"
  )
