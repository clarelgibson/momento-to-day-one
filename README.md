# Momento to Day One

This tool helps you to transfer your journal entries from [Momento](https://momentoapp.com) to [Day One](https://dayoneapp.com). It takes the exported data from Momento and converts it into a JSON format that can be imported into Day One.

![Momento and Day One logos on an image of an open paper journal with pen](ref/momento-to-day-one.png)

## Getting started

Before you run any code, you will need to export the data you wish to transfer from Momento. Follow [Momento's instructions](https://momento.zendesk.com/hc/en-us/articles/207965865-Export-FAQ) to do this, and be sure to include media in your export so that your images and video files will be transferred along with your text.

## How to use?

Using this tool requires familiarity with running R and python scripts. It is recommended to run the scripts within an R project (e.g. using RStudio).

### 1. Clone the repo

Clone this repo to your local working directory.

``` bash
# Clone with SSH
$ git clone git@github.com:clarelgibson/momento-to-day-one.git
```

### 2. Gather the Momento data

-   Place your exported Momento text (.txt) files into directory `data/input/`
-   Place your exported Moment media (.jpg and .mp4) files into directory `data/input/photos/`

### 3. Run the code

Run `code/momento-to-day-one.R`. This script sources the other scripts in the correct order. The output of this script will be placed into `data/output`.

## Acknowledgements

-   [Alan Gibson](https://github.com/a-gibson) for support with the python scripts to prepare the JSON files.
