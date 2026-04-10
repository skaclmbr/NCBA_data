# Functions for often-repeated actions associated with NCBA data management and
# analysis
#
# To access these functions, run "source("ncba_functions.R")" in your R console,
# script, or R markdown document.  If your working directory is not where
# this file is stored, then replace "ncba_functions.R" with the path to the file
# For example, "source("C:/Code/NCBA/ncba_functions.R").  The functions can
# then be called by their names.

# this package loads the working directory from the R Studio Project
# be sure to open in R Studio and create a project from the root
if (!require(here)) install.packages(
  "here", repos = "http://cran.us.r-project.org"
)
# alternatively, you can set the working directory explicitly
# setwd("C:/Users/skanderson/OneDrive - State of North Carolina/@@ncba/ncba/Code/NCBA/resources")

if (!require(docstring)) install.packages(
  "docstring", repos = "http://cran.us.r-project.org"
)
if (!require(tidyverse)) install.packages(
  "tidyverse", repos = "http://cran.us.r-project.org"
)
if (!require(dplyr)) install.packages(
  "dplyr", repos = "http://cran.us.r-project.org"
)
if (!require(mongolite)) install.packages(
  "mongolite", repos = "http://cran.us.r-project.org"
)
# if (!require(auk)) install.packages(
#   "auk", repos = "http://cran.us.r-project.org"
# )
# if (!require(tmap)) install.packages(
#   "tmap", repos = "http://cran.us.r-project.org"
# )
# if (!require(sf)) install.packages(
#   "sf", repos = "http://cran.us.r-project.org"
# )

# Load the config file
source(here("ncba_config.r"))
library(lubridate)
library(dplyr)
library(mongolite)
library(tmap)
library(tidyverse)
library(jsonlite)

dt_fmt <- "%Y-%m-%d"
atlas_start <- "2021-01-01"
atlas_end <- "2026-02-28"

# -----------------------------------------------------------------------------
connect_ncba_db <- function(collection, database = "ebd_mgmt"){
  # Connect to the NCBA MongoDB database
  #
  # Description:
  # Returns a mongolite connection to the database for use in queries.  Username
  # and password are retrieved from a config file containing variables that can
  # retrieved from the working directory (default) or a user-specified location.
  #
  # Arguments:
  # database -- the database (within MongoDB) to query, likely "ebd_management"
  # collection -- collection name (e.g., "ebd")
  #
  # Example:
  # conn <- connect_ncba_db(collection = "ebd")
  # mongodata <- conn$find({})

  # Database info
  host <- "cluster0-shard-00-00.rzpx8.mongodb.net:27017"
  uri <- sprintf(
    paste0(
      "mongodb://%s:%s@%s/%s?authSource=admin&",
      "replicaSet=atlas-3olgg1-shard-0&readPreference=primary&ssl=true"
    ),
    ncba_db_user,
    ncba_db_pass,
    host,
    database
  )

  # Connect to a specific collection (table)
  m <- mongo(collection = collection, db = database, url = uri)
}


get_mongodb_data <- function(pipeline, collection = "ebd") {
  db_conn <- connect_ncba_db(collection)
  db_conn$aggregate(pipeline)
}

# ------------------------------------------------------------------------------
clean_ending_comma <- function(text){
  # check if end of string ends in "," or ", "
  end_2_chars <- substr(text, nchar(text)-1, nchar(text))
  end_1_char <- substr(text, nchar(text), nchar(text))

  if (end_2_chars == ", "){
    chars_to_remove <- 2
  } else if (end_1_char == ",") {
    chars_to_remove <- 1
  } else {
    chars_to_remove <- 0
  }
  
  substr(text, 1, nchar(text) - chars_to_remove)

}

get_list_string <- function(item) {
  # checks if passed item is a list,
  # returns a string representation of a list
  
  if (!is.list(item) & !is.vector(item)) {
    # not a list, only one item
    paste0('"', item, '"')
  } else if (is.character(item)) {
    # list of characters, add quotes
    paste('"', item, '"', collapse=", ", sep = "")
    # toString(cat(dQuote(item, FALSE)))
  } else {
    # list of non-characters
    toString(item)
  }
}

get_records <- function(
    observer_id = NULL,
    id_ncba_block = NULL,
    sampling_event_identifier = NULL,
    common_name = NULL,
    breeding_category = NULL,
    breeding_code = NULL,
    start_end_date = c("2021-01-01", "2026-02-28"),
    checklists_only = FALSE,
    all_observations = TRUE,
    atlas_only = TRUE
){
  
  #' get_records function
  #' 
  #' Retrieves records from the NC Bird Atlas Database
  #' and returns them as a dataframe.
  #' 
  #' Inputs:
  #'  @param observer_id = single value or list of observer ids
  #'    (e.g., observer_id = c("obsr1234567", "obsr39485694"))
  #'    
  #'  @param id_ncba_block = single value or list of block ids
  #'    (e.g., id_ncba_block = c("SCOTTS_HILL-CW", "WAKE_EAST-SE"))
  #'    
  #'  @param sampling_event_identifier = single value or list of checklist ids
  #'    (e.g., sampling_event_identifier = c("S292131468", "S297472480"))
  #'    
  #'  @param common_name = single value or list of species common names
  #'    (e.g., common_name = c("American Crow", "Eastern Bluebird"))
  #'    
  #'  @param breeding_category = single value or list of breeding categories
  #'    (e.g., breeding_category = c("C3", "C4"))
  #'    "" = Observed
  #'    C1 = Flyover
  #'    C2 = Possible
  #'    C3 = Probable
  #'    C4 = Confirmed
  #'    
  #'  @param breeding_code = single value or list of breeding codes
  #'    (e.g., breeding_code = c("S", "S7"))
  #'    
  #'  @param start_end_date = vector of start and end dates
  #'    (e.g., start_end_date = c("2026-01-01", "2026-02-28"))
  #'    
  #'  @param checklists_only = TRUE or FALSE - indicates if observation fields should
  #'    be returned.
  #'    (e.g., checklists_only = TRUE)
  #'    
  #'  @param all_observations = TRUE or FALSE - indicates if all observations from 
  #'    checklist or only specified species (see common_name above) are
  #'    returned.
  #'    
  #'  @param atlas_only = TRUE or FALSE - indicates if only Atlas records returned
  
  # params <- formals()
  # add variable to make sure at least some criteria passed
  criteria_passed <- FALSE
  
  # start output criteria string
  criteria <- paste0('[{"$match":{')
  
  # check for each input parameter, add to string if value passed
  
  # OBSERVER_ID
  if (!is.null(observer_id)) {
    criteria <- paste0(
      criteria,
      '"OBSERVER_ID": {"$in":[', get_list_string(observer_id), ']}, '
    )
    criteria_passed <- TRUE
  }
  
  # COMMON_NAME
  if (!is.null(common_name)) {
    criteria <- paste0(
      criteria,
      '"OBSERVATIONS.COMMON_NAME": {"$in":[',
      get_list_string(common_name),
      ']}, '
    )
    criteria_passed <- TRUE
  }
  
  # ID_NCBA_BLOCK
  if (!is.null(id_ncba_block)) {
    criteria <- paste0(
      criteria,
      '"ID_NCBA_BLOCK": {"$in":[',
      get_list_string(id_ncba_block),
      ']}, '
    )
    criteria_passed <- TRUE    
  }
  
  # SAMPLING_EVENT_IDENTIFIER
  if (!is.null(sampling_event_identifier)) {
    criteria <- paste0(
      criteria,
      '"SAMPLING_EVENT_IDENTIFIER": {"$in":[',
      get_list_string(sampling_event_identifier),
      ']}, '
    )
    criteria_passed <- TRUE
  }
  
  # BREEDING_CODE
  if (!is.null(breeding_code)) {
    criteria <- paste0(
      criteria,
      '"OBSERVATIONS.BREEDING_CODE": {"$in":[',
      get_list_string(breeding_code),
      ']}, '
    )
    criteria_passed <- TRUE
  }
  
  # BREEDING_CATEGORY
  if (!is.null(breeding_category)) {
    criteria <- paste0(
      criteria,
      '"OBERSVATIONS.BREEDING_CATEGORY": {"$in":[',
      get_list_string(breeding_category),
      ']}, '
    )
    criteria_passed <- TRUE
  }
  
  
  # Date Bounds
  ## make sure passed bounds not outside of Atlas dates
  start_date_dt <- as.Date(start_end_date[1], format = dt_fmt)
  end_date_dt <- as.Date(start_end_date[2], format = dt_fmt)
  query_days <- difftime(end_date_dt, start_date_dt, units = "days")
  new_dates <- c(
    max(c(start_date_dt, as.Date(atlas_start, format = dt_fmt))),
    min(c(end_date_dt, as.Date(atlas_end, format = dt_fmt)))
  )

  if (query_days < 366 && !criteria_passed) {
    criteria_passed <- TRUE
  }
  
  ## add date criteria
  criteria <- paste0(
    criteria,
    '"OBSERVATION_DATE" : {',
    '"$gte" : "', new_dates[1], '",',
    '"$lte" : "', new_dates[2], '"}'
  )
  
  # Atlas Only
  if (atlas_only){
    criteria <- paste0(
      criteria,
      ', "PROJECT_CODE" : "EBIRD_ATL_NC"}'
    )
    
  }
  criteria <- paste0(criteria, '}')
  
  ## Done with initial match criteria
  
  # Checklists only
  ## if 
  if (checklists_only) {
    criteria <- paste0(
      criteria,
      ', {"$project": {"OBSERVATIONS" : 0}}'
    )
  } else {
    # All Observations
    # if not all observations insert criteria after unwind
    criteria <- paste0(
      criteria,
      ', {"$unwind": "$OBSERVATIONS"}'
    )
    if (!all_observations) {
      criteria <- paste0(
        criteria,
        ', {"$match": {"OBSERVATIONS.COMMON_NAME": {"$in":[',
        get_list_string(common_name),
        ']}}}'
      )
    }
    
    # project fields to be remapped
    criteria <- paste0(
      criteria,
      ', {"$replaceRoot":{ "newRoot": {',
      '"$mergeObjects":["$$ROOT","$OBSERVATIONS"]}}}'
    )
  }
  
  # close criteria query
  criteria <- paste0(criteria, ']')
  if (criteria_passed){
    # retrieve data from database
    get_mongodb_data(criteria)
  } else {
    print(
      paste0("get_records: Query returns too many records. ",
      "Please request less than a year or add criteria.")
    )
  }
}