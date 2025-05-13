-- Query 1: Creating the Schema
CREATE SCHEMA IF NOT EXISTS fars_crashes

-- Query 2: Creating Tables
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

-- Query 3: Importing Data (Change file path as necessary)
LOAD DATA LOCAL INFILE "D:\\FARS Data\\states_vmt.csv" INTO TABLE states
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\FARS Data\\ncsa_makes.csv' INTO TABLE ncsa_makes
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\FARS Data\\county.csv' INTO TABLE counties
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\FARS Data\\restraint.csv' INTO TABLE restraints
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\FARS Data\\Crashes.csv' INTO TABLE crashes
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\FARS Data\\vehicle.csv' INTO TABLE vehicles
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\FARS Data\\People.csv' INTO TABLE people
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

-- Query 4: Calculate non-motorist fatalities by state and road type

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

-- Query 5 Count of fatal non-motorist crashes by month and time of day
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

-- Query 6: Count of drivers involved in crashes where a non-motorist was killed, by age and sex

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
