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
source("ncba_functions")
```

## Usage
