# Export data -------------------------------------------------------------

write_csv(momento, here("data/output/momento_structured.csv"))

momento_structured_media <- momento |> 
  filter(!is.na(source_media))

write_csv(
  momento_structured_media,
  here("data/output/momento_structured_media.csv"),
  na = ""
)
