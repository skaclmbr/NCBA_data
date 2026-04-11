# Functions for often-repeated actions associated with NCBA data management and
# analysis
#
# To access these functions, add 'from ncba_functions import XX',
# script, or R markdown document.  If your working directory is not where
# this file is stored, then replace "ncba_functions.R" with the path to the file
# For example, 'source("C:/Code/NCBA/ncba_functions.R").  The functions can

from datetime import datetime, timedelta
from pymongo.mongo_client import MongoClient
from ncba_config import ncba_db_user, ncba_db_pass
import certifi
import json

fmt_dt = "%Y-%m-%d"
atlas_start = datetime.strptime("2021-01-01", fmt_dt)
atlas_end = datetime.strptime("2026-02-28", fmt_dt)
max_timeout = 100000000

connString = f"mongodb+srv://{ncba_db_user}:{ncba_db_pass}@cluster0.rzpx8.mongodb.net/ebd_mgmt?retryWrites=true&w=majority"

client = MongoClient(
    connString, 
    connectTimeoutMS=max_timeout,
    socketTimeoutMS = max_timeout,
    serverSelectionTimeoutMS=max_timeout,
    tlsCAFile=certifi.where()
    )

def get_list_string(item):
    # test if item is string, convert to array

    results = item
    if not isinstance(item, list):
        print(f"Input not a list: {item}")
        results = [item]

    return results

def get_records(
    observer_id = [],
    id_ncba_block = [],
    sampling_event_identifier = [],
    common_name = [],
    breeding_category = [],
    breeding_code = [],
    start_end_date = ["2021-01-01", "2026-02-28"],
    checklists_only = False,
    all_observations = True,
    atlas_only = True
):
    print("running")
    criteria_passed = False
    criteria = [{"$match": {}}]
    criteria_obs = {}

    # OBSERVER_ID
    if observer_id: 
        criteria[0]["$match"]["OBSERVER_ID"] = {
            "$in" : get_list_string(observer_id)
            }
        criteria_passed = True

    # ID_NCBA_BLOCK
    if id_ncba_block: 
        criteria[0]["$match"]["ID_NCBA_BLOCK"] = {
            "$in" : get_list_string(id_ncba_block)
            }
        criteria_passed = True

    # SAMPLING_EVENT_IDENTIFIER
    if sampling_event_identifier: 
        criteria[0]["$match"]["SAMPLING_EVENT_IDENTIFIER"] = {
            "$in" : get_list_string(sampling_event_identifier)
            }
        criteria_passed = True

    # COMMON_NAME
    if common_name:
        criteria_temp = { "$in" : get_list_string(common_name) }
        criteria[0]["$match"]["OBSERVATIONS.COMMON_NAME"] = criteria_temp
        criteria_obs["OBSERVATIONS.COMMON_NAME"] = criteria_temp
        criteria_passed = True

    # BREEDING_CATEGORY
    if breeding_category: 
        criteria_temp = {"$in" : get_list_string(breeding_category)}
        criteria[0]["$match"]["OBSERVATIONS.BREEDING_CATEGORY"] = criteria_temp
        criteria_obs["OBSERVATIONS.BREEDING_CATEGORY"] = criteria_temp
        criteria_passed = True

    # BREEDING_CODE
    if breeding_code: 
        criteria_temp = {"$in" : get_list_string(breeding_code)}
        criteria[0]["$match"]["OBSERVATIONS.BREEDING_CODE"] = criteria_temp
        criteria_obs["OBSERVATIONS.BREEDING_CODE"] = criteria_temp
        criteria_passed = True

    # OBSERVATION_DATE
    start_date_dt = datetime.strptime(start_end_date[0], fmt_dt)
    end_date_dt = datetime.strptime(start_end_date[1], fmt_dt)
    new_dates = [
        max(atlas_start, start_date_dt),
        min(atlas_end, end_date_dt)
    ]
    query_days = (new_dates[1] - new_dates[0]).days
    print(f"days to query:{query_days}") 

    criteria[0]["$match"]["OBSERVATION_DATE"] = {
        "$gte" : datetime.strftime(new_dates[0], fmt_dt),
        "$lte" : datetime.strftime(new_dates[1], fmt_dt)
    }

    # Atlas Only
    if atlas_only:
        criteria[0]["$match"]["PROJECT_CODE"] = "EBIRD_ATL_NC"

    # Checklists Only
    if checklists_only:
        criteria.append(
            {"$project" : {"OBSERVATIONS" : 0}}
        )
    else:
        criteria.append(
            {"$unwind" : "$OBSERVATIONS"}
        )
        if not all_observations:
            criteria.append(
                {"$match" : criteria_obs}
            )
        
        criteria.append(
            {
                "$replaceRoot" : {
                    "newRoot" : {
                        "$mergeObjects" : ["$$ROOT", "$OBSERVATIONS"]
                    }
                }
            }
        )
        # remove NCBA_BC_HISTORY from results
        criteria.append(
            {
                "$project" : {"NCBA_BC_HISTORY" : 0} 
            }
        )

    # check if criteria passed, or query to return too many records
    if (query_days < 366 and not criteria_passed):
        criteria_passed = True

    if criteria_passed:
        results = criteria
        db = client.ebd_mgmt
        ebd = db.ebd
        results = list(ebd.aggregate(criteria))
    else:
        print(f"{query_days} days to be queried. Criteria passed: {criteria_passed}")
        results = False
        print(f"Query will result in too many records. Limit by date or other criteria.")

    return results
