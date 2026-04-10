# NC Bird Atlas Data Access Tools

This repository contains functions to access the NC Bird Atlas dataset.

== STILL IN DEVELOPMENT ==

## Setup

Contact Scott K. Anderson ([skaclmbr](https://github.com/skaclmbr), [scott.anderson@ncwildlife.gov](mailto:scott.anderson@ncwildlife.org)) for username and password access to the database.

Create a file in the default folder called "ncba_config.r", and include the following:

```{r}
ncba_db_user = "username"
ncba_db_pass = "password"
```

### Add to existing script

To enable the functions provide, place the following at the top of your r script:

```{r}
source("ncba_functions.R")
```

## Usage

The 'get_records' function allows retrieval of records from the NC Bird Atlas Database. You can query with the following options and parameters:

### get_records function

Retrieves records from the NC Bird Atlas Database and returns them as a dataframe.
   
#### Inputs:

- observer_id = single value or list of observer ids (e.g., observer_id = c("obsr1234567", "obsr39485694"))
- id_ncba_block = single value or list of block ids (e.g., id_ncba_block = c("SCOTTS_HILL-CW", "WAKE_EAST-SE")) 
- sampling_event_identifier = single value or list of checklist ids (e.g., sampling_event_identifier = c("S292131468", "S297472480")) 
- common_name = single value or list of species common names (e.g., common_name = c("American Crow", "Eastern Bluebird")) 
- breeding_category = single value or list of breeding categories (e.g., breeding_category = c("C3", "C4")) "" = Observed C1 = Flyover C2 = Possible C3 = Probable C4 = Confirmed 
- breeding_code = single value or list of breeding codes (e.g., breeding_code = c("S", "S7")) 
- start_end_date = vector of start and end dates (e.g., start_end_date = c("2026-01-01", "2026-02-28")) 
- checklists_only = TRUE or FALSE - indicates if observation fields should be returned. (e.g., checklists_only = TRUE) 
- all_observations = TRUE or FALSE - indicates if all observations from  checklist or only specified species (see common_name above) are returned. 
- atlas_only = TRUE or FALSE - indicates if only Atlas records returned