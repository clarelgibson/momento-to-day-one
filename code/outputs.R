# Export data -------------------------------------------------------------

write_csv(momento, here("data/output/momento_structured.csv"))

momento_structured_media <- momento |> 
  filter(!is.na(source_media))

write_csv(
  momento_structured_media,
  here("data/output/momento_structured_media.csv"),
  na = ""
)

# Create a Bash script
bash_file <- here("data/output/run_dayone_commands.sh")

write_lines("#!/bin/bash\n\n", bash_file)
write_lines(commands, bash_file, append = TRUE)