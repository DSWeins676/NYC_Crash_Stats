# Notes on Data Cleaning

## Persons

### Person Types
The dataset contains the column Ped_Role, which lists the role of the listed person somehow involved in the crash. 

This can be any of the following:

```
SELECT DISTINCT ped_Role, COUNT(*) AS count FROM persons_wk GROUP BY ped_role ORDER BY COUNT(*) DESC;

ped_role        count

Registrant	    779201
Driver	        679359
Passenger	      263991
Pedestrian	    45767
Witness	        28556
Owner	          14766
Notified Person	4813
Other	          851
In-Line Skater	181
NULL             3

```

Some of these, such as "Witness" or "Notified Person," are not relevant to our analysis. I further investigated "Registrants," since they are the most frequent entry, and "Owners" to avoid duplicate records.

The following query did not return any results, indicating that no persons listed as "Registrants" were present in the crash, and hence could also be excluded:
SELECT * FROM persons WHERE Ped_Role IN ('Registrant', 'Owner') AND POSITION_IN_VEHICLE != '';

Removing rows in which a record is not a Driver, Passenger, Pedestrian, or In-Line Skater:

DELETE FROM persons WHERE ped_role NOT IN ('Driver', 'Pedestrian', 'Passenger', 'In-Line Skater');
