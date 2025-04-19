-- Duplicating the original tables to preserve them prior to data cleaning and filtering

CREATE TABLE crashes_wk LIKE crashes;
INSERT INTO crashes_wk SELECT * FROM crashes;
 
CREATE TABLE persons_wk LIKE persons;
INSERT INTO persons_wk SELECT * FROM persons;

CREATE TABLE vehicles_wk LIKE vehicles;
INSERT INTO vehicles_wk SELECT * FROM vehicles;


SELECT Ped_role, COUNT(*) FROM backup_persons GROUP BY Ped_Role ORDER BY COUNT(*) DESC;
