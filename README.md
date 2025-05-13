# Non-motorist fatalities in vehicle crashes

## Objectives

The killing of pedestrians, cyclists, and other users of micromobility devices by motor vehicles has been an increasingly pressing issue. Various city and local governments have pursued "Vision Zero" campaigns to implement systems to prevent all traffic-related deaths. A core focus of a Vision Zero project is strategically targeting resources and efforts towards groups, either of people or places, that have the highest risk for causing traffic-related fatalities. In this analysis, I utilize the data from the National Highway Traffic Safety Administration's (NHTSA) Fatality Analysis Reporting System (FARS) to identify risk factors associated with traffic fatalities, focusing on the fatalities of non-motorists caused by a motor vehicle in some capacity. 

## Data

I downloaded raw data from the FARS FTP site for the year 2023 in .csv format. For the the ncsa_makes and restraints tables, their numerical codes and respective names were taken from the text of the FARS Analytical User's Manual. For counties, FARS utilizes the General Service Administration's (GSA) Geographic Location Codes (GLCs). The counties table utilizes data taken directly from the GSA's dataset of GLCs in the United States. 

[FARS Data Access](https://www.nhtsa.gov/research-data/fatality-analysis-reporting-system-fars)
[FARS Analytical User's Manual](https://crashstats.nhtsa.dot.gov/Api/Public/ViewPublication/813706)
[GSA Geographic Locator Codes](https://www.gsa.gov/reference/geographic-locator-codes/glcs-for-the-us-and-us-territories)

Using MySQL, I created various tables and imported data from the .csv files into them. 

Since these datasets were likely extracted from a relational database, certain modifications were necessary to import them back into a database while maintaining integrity and reducing redundancy. For example, the accidents, vehicles, and person files all contain repeating information about the date/time of their associated crash, and hence this information was removed to only exist in the crashes table. Oftentimes, unknown or unreported data was given a numeric code (i.e. For example, each make or group of makes in the NCSA Makes columns of the dataset represent a make, but there is also a code "99" for "Unknown Make."). Such codes would not be suitable to include in dimensional tables such as ncsa_makes, states, counties, and restraints, and hence they were not included in the dimensional tables and were converted to null values in the facts tables. 

As for database design, I created unique ID columns for the crashes, vehicles, and people tables (crash_id, vehicle_id, and person_id, respectively). However, these unique IDs do not associate entities between tables. Composites of st_case, veh_no, and per_no connect crashes, vehicles, and people. Adding primary/foreign key references among these, however, presented issues. The foreign key associating a person to a vehicle is a composite of st_case and veh_no (a person was in vehicle 1, 2, or 3 of crash 10001, 10002, or 10003). However, a person can also have veh_no = 0, indicating they were not in a vehicle. However, no entry in the vehicles table will ever have veh_no = 0, hence adding a foreign key constraint referencing the vehicles table in the people table would invalidate those entries. For the purposes of this analysis, and since there is not an intention to add/delete further entities in this, I avoided adding in foreign key constraints to the tables.

```
CREATE TABLE ncsa_makes (
    make_code INT NOT NULL,
    make VARCHAR(255) NOT NULL,
    PRIMARY KEY (make_code)
);

CREATE TABLE restraints(
    restraint_code INT NOT NULL,
    restraint_name VARCHAR(255) NOT NULL,
    PRIMARY KEY (restraint_code)
);

CREATE TABLE states (
    state_code INT NOT NULL,
    state_name VARCHAR(30) NOT NULL,
    rural_vmt INT NOT NULL,
    urban_vmt INT NOT NULL,
    PRIMARY KEY (state_code)
);

CREATE TABLE counties (
    state_code INT NOT NULL,
    county_code INT NOT NULL,
    county_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (state_code, county_code)
);

CREATE TABLE crashes (
    st_case INT NOT NULL,
    state_code INT NOT NULL,
    county_code INT NOT NULL,
    crash_date DATE NULL,
    crash_time TIME NULL,
    rural_urban VARCHAR(255),
    latitude DECIMAL(12,9),
    longitude DECIMAL(12,9),
    light_cond VARCHAR(255),
    weather VARCHAR(255),
    PRIMARY KEY (st_case),
    FOREIGN KEY (state_code) REFERENCES states(state_code)
);

CREATE TABLE vehicles (
	vehicle_id INT NOT NULL,
    st_case INT NOT NULL,
    veh_no INT NOT NULL,
    hit_run VARCHAR(255),
    reg_stat INT NULL,
    veh_owner TEXT,
    vin VARCHAR(255),
    mod_year INT NULL,
    make_code INT NULL,
    body_typ TEXT,
    trav_sp INT NULL,
    PRIMARY KEY (vehicle_id),
	FOREIGN KEY (st_case) REFERENCES crashes(st_case)
);

CREATE TABLE people (
	person_id INT NOT NULL,
    st_case INT NOT NULL,
    veh_no INT NOT NULL,
    per_no INT NOT NULL,
    age INT NULL,
    sex VARCHAR(10),
    per_typ VARCHAR(255),
    inj_sev VARCHAR(255),
    seat_pos VARCHAR(255),
    restraint_code INT NULL,
    rest_mis VARCHAR(255),
    drinking VARCHAR(255),
    alc_res DECIMAL(5,3) NULL,
    PRIMARY KEY (person_id),
    FOREIGN KEY (st_case) REFERENCES crashes(st_case)
    );
```
```
-- Calculate non-motorist fatalities by state and road type

SELECT 
    s.state_name AS State,

    -- Count of urban non-motorist fatalities
    COUNT(CASE 
        WHEN c.rural_urban = 'Urban' THEN 1 
    END) AS Urban_Fatalities,

    -- Percentage of urban non-motorist fatalities
    ROUND(
        100.0 * COUNT(CASE 
            WHEN c.rural_urban = 'Urban' THEN 1 
        END) / COUNT(*), 2
    ) AS Percent_Urban,

    -- Count of rural non-motorist fatalities
    COUNT(CASE 
        WHEN c.rural_urban = 'Rural' THEN 1 
    END) AS Rural_Fatalities,

    -- Percentage of rural non-motorist fatalities
    ROUND(
        100.0 * COUNT(CASE 
            WHEN c.rural_urban = 'Rural' THEN 1 
        END) / COUNT(*), 2
    ) AS Percent_Rural,

    -- Count of non-motorist fatalities in unknown road types
    COUNT(CASE 
        WHEN c.rural_urban NOT IN ('Urban', 'Rural') THEN 1 
    END) AS Unknown_Fatalities,

    -- Percentage of non-motorist fatalities in unknown road types
    ROUND(
        100.0 * COUNT(CASE 
            WHEN c.rural_urban NOT IN ('Urban', 'Rural') THEN 1 
        END) / COUNT(*), 2
    ) AS Percent_Unknown,

    -- Total non-motorist fatalities
    COUNT(*) AS Total_Pedestrian_Fatalities

FROM 
    people p
    INNER JOIN crashes c ON p.st_case = c.st_case
    INNER JOIN states s ON c.state_code = s.state_code

-- Filter to include only non-motorist fatalities
WHERE 
    p.veh_no = 0  -- Non-motorist indicator
    AND p.inj_sev = 'Fatal Injury (K)'  -- Fatality Indicator

GROUP BY 
    s.state_name
ORDER BY 
    s.state_name ASC;

```

```
-- Count of fatal non-motorist crashes by month and time of day
SELECT
 
    DATE_FORMAT(c.crash_date, '%Y-%m') AS crash_month,

    -- Categorize crash as Daytime (between 7:00 and 18:59) or Nighttime (between 19:00 and 6:59 based on crash hour
    CASE 
        WHEN HOUR(c.crash_time) BETWEEN 7 AND 18 THEN 'Daytime'
        ELSE 'Nighttime'
    END AS time_of_day,

    -- Total number of non-motorist fatalities
    COUNT(*) AS total_nonmotorist_fatal

FROM crashes c
INNER JOIN people p ON c.st_case = p.st_case

-- Filter to include only fatal injuries of non-motorists
WHERE 
    p.veh_no = 0 -- Non-motorist indicator
    
    AND p.inj_sev = 'Fatal Injury (K)' -- Fatality Indicator

GROUP BY 
    crash_month, time_of_day
ORDER BY 
    crash_month;

```
```
-- Count of drivers involved in crashes where a non-motorist was killed, by age and sex

SELECT 
    age_group,
    sex,

    -- Total number of drivers in this age group and sex
    COUNT(*) AS total_drivers,

    -- Total number of drivers in this age group (across all sexes)
    SUM(COUNT(*)) OVER (PARTITION BY age_group) AS total_per_age_group

FROM (
    -- Subquery: select only drivers from crashes where a non-motorist was killed
    SELECT 
        p1.sex,
        p1.per_typ,
        p1.st_case,

        -- Organize ages into categories
        CASE 
            WHEN age BETWEEN 15 AND 19 THEN '15-19'
            WHEN age BETWEEN 20 AND 24 THEN '20-24'
            WHEN age BETWEEN 25 AND 29 THEN '25-29'
            WHEN age BETWEEN 30 AND 34 THEN '30-34'
            WHEN age BETWEEN 35 AND 39 THEN '35-39'
            WHEN age BETWEEN 40 AND 44 THEN '40-44'
            WHEN age BETWEEN 45 AND 49 THEN '45-49'
            WHEN age BETWEEN 50 AND 54 THEN '50-54'
            WHEN age BETWEEN 55 AND 59 THEN '55-59'
            WHEN age BETWEEN 60 AND 64 THEN '60-64'
            WHEN age BETWEEN 65 AND 69 THEN '65-69'
            WHEN age BETWEEN 70 AND 74 THEN '70-74'
            WHEN age BETWEEN 75 AND 79 THEN '75-79'
            WHEN age BETWEEN 80 AND 84 THEN '80-84'
            WHEN age BETWEEN 85 AND 89 THEN '85-89'
            WHEN age >= 90 THEN '90+'
            ELSE 'Unknown'
        END AS age_group

    FROM people p1

    -- Filter: only include this person if their crash (st_case) involved a non-motorist fatality
    WHERE EXISTS (
        SELECT 1 
        FROM people p2 
        WHERE p2.st_case = p1.st_case
          AND p2.veh_no = 0
          AND p2.inj_sev = 'Fatal Injury (K)'
    )
) AS c

-- Remove drivers for whom sex is unknown/not reported.
WHERE 
    per_typ = 'Driver of a Motor Vehicle In-Transport'
    AND sex IN ('Male', 'Female')


GROUP BY 
    age_group, sex
ORDER BY 
    age_group, sex;

```
