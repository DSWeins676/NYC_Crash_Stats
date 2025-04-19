# Notes on Data Cleaning

## Persons Table

### Person Types
The dataset contains the column Ped_Role, which lists the role of the listed person somehow involved in the crash. 

This can be any of the following:

```
SELECT DISTINCT ped_Role, COUNT(*) AS count FROM persons_wk GROUP BY ped_role ORDER BY COUNT(*) DESC;
```

| ped_role         | count   |
|------------------|---------|
| Registrant       | 779,201 |
| Driver           | 679,359 |
| Passenger        | 263,991 |
| Pedestrian       | 45,767  |
| Witness          | 28,556  |
| Owner            | 14,766  |
| Notified Person  | 4,813   |
| Other            | 851     |
| In-Line Skater   | 181     |
| *null*           | 3       |

Some of these, such as "Witness" or "Notified Person," are not relevant to our analysis. I further investigated "Registrants," since they are the most frequent entry, and "Owners" to avoid duplicate records.

The following query did not return any results, indicating that no persons listed as "Registrants" were present in the crash, and hence could also be excluded
```
SELECT * FROM persons WHERE Ped_Role IN ('Registrant', 'Owner') AND POSITION_IN_VEHICLE != '';
```
So, I kept only those entries in the persons table where the ped_role was Driver, Pedestrian, Passenger, or In-Line Skater

```
-- Removing rows in which a record is not a Driver, Passenger, Pedestrian, or In-Line Skater:

DELETE FROM persons WHERE ped_role NOT IN ('Driver', 'Pedestrian', 'Passenger', 'In-Line Skater');
```

## Crashes Table

### Removing Crashes With Only 1 Moving Vehicle Hitting Parked Car(s)

I wanted to identify those crashes where there was only one moving vehicle and one or more parked cars. There were also some instances where a crash was recorded as involving only parked cars, and I wanted to locate those as well. The following query served these purposes:

```
SELECT collision_id 
FROM (
    -- Joining the total vehicle count and parked vehicle count from each collision
    SELECT 
        a.collision_id, 
        a.num_cars, 
        b.num_parked
    FROM (
        -- Counting all vehicles involved in each collision where at least one vehicle was parked
        SELECT 
            collision_id, 
            COUNT(*) AS num_cars
        FROM vehicles
        WHERE collision_id IN (
            SELECT DISTINCT collision_id 
            FROM vehicles 
            WHERE pre_crash = 'PARKED'
        )
        GROUP BY collision_id
    ) a
    INNER JOIN (
        -- Counting all PARKED vehicles involved in each collision where at least one vehicle was parked
        SELECT 
            collision_id, 
            COUNT(*) AS num_parked
        FROM vehicles
        WHERE pre_crash = 'PARKED'
        GROUP BY collision_id
    ) b 
    ON a.collision_id = b.collision_id
    -- Keeping collisions where all or all but one vehicles were parked
    WHERE a.num_cars - b.num_parked <= 1
) c;

```

To exclude these collisions, I first had to  delete them from crashes and persons, otherwise, the subquery will not return any results

```

DELETE FROM crashes 
WHERE collision_id IN (
    SELECT collision_id FROM (
        SELECT a.collision_id
        FROM (
            SELECT collision_id, COUNT(*) AS num_cars
            FROM vehicles
            WHERE collision_id IN (
                SELECT DISTINCT collision_id
                FROM vehicles
                WHERE pre_crash = 'PARKED'
            )
            GROUP BY collision_id
        ) a
        INNER JOIN (
            SELECT collision_id, COUNT(*) AS num_parked
            FROM vehicles
            WHERE pre_crash = 'PARKED'
            GROUP BY collision_id
        ) b 
        ON a.collision_id = b.collision_id
        WHERE a.num_cars - b.num_parked <= 1
    ) c
);

-- And similar for the persons and vehicles tables, replacing only the table name in the DELETE FROM clause.

```

This removes 336,976 rows from the vehicles table, 156,486 rows from the crashes table, and 399,831 rows from the persons table.
