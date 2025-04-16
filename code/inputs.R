# Read data ---------------------------------------------------------------

# Text files
text_dir <- here("data/input")
text <- read_text_as_tibble(text_dir)

# JPEG metadata
media_dir <- here("data/input/attachments")
media <- read_media_metadata(
  dir = media_dir,
  tags = c("FileName", "FileType", "Duration", "Make", "CreateDate",
           "ImageHeight", "ImageWidth", "FNumber", "FocalLength",
           "Model", "LensModel", "GPSLongitude", "GPSLatitude", "FileSize")
)