# Useful functions and packages

# Libraries
library(tidyverse)
library(here)

# Read a single .txt file
read_txt <- readLines(here("data/src/2017.02 - February 2017.txt"))

print(read_txt)
