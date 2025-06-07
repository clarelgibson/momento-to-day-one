# Process data ------------------------------------------------------------

# Take the raw text data from Momento and put it into a table structure
text_structured <- make_momento_structured(text)

# Add media metadata to table
text_and_media <- join_meta_to_text(text_structured, media)

# Build or read table of geo data from lat/longs in media metadata
geo <- 
  if(file.exists(here("data/output/geo.csv"))) {
    read_csv(here("data/output/geo.csv"))
  } else (
    get_location_data(text_and_media) 
  )

# Add geo data to table
momento <- join_geo_to_text(text_and_media, geo)

# Create format for CSV import
momento_csv <- create_csv_import(momento)