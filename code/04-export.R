# Packages
library(here)

# Scripts
source(here("code/03-process.R"))


# Export data -------------------------------------------------------------

write_csv(momento_structured, here("data/cln/momento_structured.csv"))

momento_structured_media <- momento_structured |> 
  filter(!is.na(media))

write_csv(momento_structured_media, here("data/cln/momento_structured_media.csv"))