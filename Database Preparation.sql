--Create the database
CREATE DATABASE crashrecords;

--Create the tables to import .csv data into. Due to the format of dates and times in the raw data, I will import them as strings and convert to datetime later.

CREATE TABLE crashes (
    `CRASH DATE` varchar(255),
    `CRASH TIME` varchar(255),
    BOROUGH varchar(255),
    `ZIP CODE` varchar(255),
    `NUMBER OF PERSONS INJURED` varchar(255),
    `NUMBER OF PERSONS KILLED` varchar(255),
    `NUMBER OF PEDESTRIANS INJURED` int,
    `NUMBER OF PEDESTRIANS KILLED` int,
    `NUMBER OF CYCLIST INJURED` int,
    `NUMBER OF CYCLIST KILLED` int,
    `NUMBER OF MOTORIST INJURED`int,
    `NUMBER OF MOTORIST KILLED`int,
    `CONTRIBUTING FACTOR VEHICLE 1` varchar(1000),
    `CONTRIBUTING FACTOR VEHICLE 2` varchar(1000),
    `CONTRIBUTING FACTOR VEHICLE 3` varchar(1000),
    `CONTRIBUTING FACTOR VEHICLE 4` varchar(1000),
    `CONTRIBUTING FACTOR VEHICLE 5` varchar(1000),
    COLLISION_ID int,
    `VEHICLE TYPE CODE 1` varchar(255),
    `VEHICLE TYPE CODE 2` varchar(255),
    `VEHICLE TYPE CODE 3` varchar(255),
    `VEHICLE TYPE CODE 4` varchar(255),
    `VEHICLE TYPE CODE 5` varchar(255),
    PRIMARY KEY(COLLISION_ID)
    );
    
CREATE TABLE persons (
    UNIQUE_ID int,
    COLLISION_ID int,
    CRASH_DATE varchar(255),
    CRASH_TIME varchar(255),
    PERSON_ID varchar(255),
    PERSON_TYPE varchar(255),
    PERSON_INJURY varchar(255),
    VEHICLE_ID int,
    PERSON_AGE int,
    BODILY_INJURY varchar(255),
    POSITION_IN_VEHICLE varchar(255),
    SAFETY_EQUIPMENT varchar(255),
    PED_LOCATION varchar(255),
    PED_ACTION varchar(255),
    PED_ROLE varchar(255),
    PERSON_SEX varchar(255),
    PRIMARY KEY(UNIQUE_ID)
    );
    
CREATE TABLE vehicles (
    UNIQUE_ID int,
    COLLISION_ID int,
    CRASH_DATE varchar(255),
    CRASH_TIME varchar(255),
    VEHICLE_ID varchar(1000),
    VEHICLE_TYPE varchar(255),
    VEHICLE_MAKE varchar(255),
    VEHICLE_MODEL varchar(255),
    VEHICLE_YEAR varchar(255),
    VEHICLE_OCCUPANTS varchar(255),
    DRIVER_SEX varchar(255),
    PRE_CRASH text,
    CONTRIBUTING_FACTOR_1 text,
    CONTRIBUTING_FACTOR_2 text,
    PRIMARY KEY(UNIQUE_ID)
    );

-- Load csv data into tables

LOAD DATA LOCAL INFILE 'D:\\CrashRecords\\crashes.csv' INTO TABLE crashes
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\CrashRecords\\Persons.csv' INTO TABLE persons
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

LOAD DATA LOCAL INFILE 'D:\\CrashRecords\\Persons.csv' INTO TABLE persons
FIELDS terminated by ','
ENCLOSED BY '"'
ignore 1 rows;

-- Rename the table columns for better querying syntax

ALTER TABLE crashes 
RENAME COLUMN `CRASH DATE` to crash_date,
RENAME COLUMN `CRASH TIME` to crash_time,
RENAME COLUMN `BOROUGH` to borough,
RENAME COLUMN `ZIP CODE` to zip_code,
RENAME COLUMN `NUMBER OF PERSONS INJURED` to num_person_injured,
RENAME COLUMN `NUMBER OF PERSONS KILLED` to num_person_killed,
RENAME COLUMN `NUMBER OF PEDESTRIANS INJURED` to num_ped_injured,
RENAME COLUMN `NUMBER OF PEDESTRIANS KILLED` to num_ped_killed,
RENAME COLUMN `NUMBER OF CYCLIST INJURED` to num_cycle_injured,
RENAME COLUMN `NUMBER OF CYCLIST KILLED` to num_cycle_killed,
RENAME COLUMN `NUMBER OF MOTORIST INJURED` to num_motor_injured,
RENAME COLUMN `NUMBER OF MOTORIST KILLED` to num_motor_killed,
RENAME COLUMN `CONTRIBUTING FACTOR VEHICLE 1` to cf1,
RENAME COLUMN `CONTRIBUTING FACTOR VEHICLE 2` to cf2,
RENAME COLUMN `CONTRIBUTING FACTOR VEHICLE 3` to cf3,
RENAME COLUMN `CONTRIBUTING FACTOR VEHICLE 4` to cf4,
RENAME COLUMN `CONTRIBUTING FACTOR VEHICLE 5` to cf5,
RENAME COLUMN `COLLISION_ID` to collision_id,
RENAME COLUMN `VEHICLE TYPE CODE 1` to veh_type_code1,
RENAME COLUMN `VEHICLE TYPE CODE 2` to veh_type_code2,
RENAME COLUMN `VEHICLE TYPE CODE 3` to veh_type_code3,
RENAME COLUMN `VEHICLE TYPE CODE 4` to veh_type_code4,
RENAME COLUMN `VEHICLE TYPE CODE 5` to veh_type_code5;

ALTER TABLE persons 
RENAME COLUMN UNIQUE_ID to unique_id, 
RENAME COLUMN COLLISION_ID to collision_id, 
RENAME COLUMN CRASH_DATE to crash_date, 
RENAME COLUMN CRASH_TIME to crash_time, 
RENAME COLUMN PERSON_ID to person_id, 
RENAME COLUMN PERSON_TYPE to person_type, 
RENAME COLUMN PERSON_INJURY to person_injury, 
RENAME COLUMN VEHICLE_ID to vehicle_id, 
RENAME COLUMN PERSON_AGE to person_age, 
RENAME COLUMN BODILY_INJURY to bodily_injury, 
RENAME COLUMN POSITION_IN_VEHICLE to position_in_vehicle, 
RENAME COLUMN SAFETY_EQUIPMENT to safety_equipment, 
RENAME COLUMN PED_LOCATION to ped_location,
RENAME COLUMN PED_ACTION to ped_action, 
RENAME COLUMN PED_ROLE to ped_role, 
RENAME COLUMN PERSON_SEX to person_sex;

ALTER TABLE vehicles 
RENAME COLUMN UNIQUE_ID to unique_id, 
RENAME COLUMN COLLISION_ID to collision_id, 
RENAME COLUMN CRASH_DATE to crash_date, 
RENAME COLUMN CRASH_TIME to crash_time, 
RENAME COLUMN VEHICLE_ID to vehicle_id, 
RENAME COLUMN VEHICLE_TYPE to vehicle_type, 
RENAME COLUMN VEHICLE_MAKE to vehicle_make, 
RENAME COLUMN VEHICLE_MODEL to vehicle_model, 
RENAME COLUMN VEHICLE_YEAR to vehicle_year, 
RENAME COLUMN VEHICLE_OCCUPANTS to vehicle_occupants, 
RENAME COLUMN DRIVER_SEX to driver_sex, 
RENAME COLUMN PRE_CRASH to pre_crash, 
RENAME COLUMN CONTRIBUTING_FACTOR_1 to cf1, 
RENAME COLUMN CONTRIBUTING_FACTOR_2 to cf2;

-- Convert dates/times imported as strings into DATETIME format in crashes table. Drop crash_date and crash_time from persons/vehicles since this has already been captured in the crashes table by collision_id.

UPDATE crashes SET crash_date = date_format(str_to_date(crash_date, '%m/%d/%Y'), '%Y-%m-%d');

ALTER TABLE crashes 
	MODIFY COLUMN crash_date DATE, 
	MODIFY COLUMN crash_time TIME;

-- Drop crash_date and crash_time from persons/vehicles since this has already been captured in the crashes table by collision_id.

ALTER TABLE persons 
	DROP COLUMN crash_date,
	DROP COLUMN crash_time;

ALTER TABLE vehicles
	DROP COLUMN crash_date,
	DROP COLUMN crash_time;
