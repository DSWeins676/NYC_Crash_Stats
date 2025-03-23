I wanted to determine those crashes where there was only one moving vehicle, and one or more parked cars. There were also some instances where a crash was recorded as involving only parked cars, and I wanted to locate those as well. The following query served these purposes:

SELECT collision_id FROM (SELECT a.collision_id, a.num_cars, b.num_parked
FROM (SELECT collision_id, COUNT(*) AS num_cars FROM vehicles WHERE collision_id IN (SELECT DISTINCT collision_id FROM vehicles WHERE pre_crash = "PARKED") GROUP BY collision_id) a
INNER JOIN
(SELECT collision_id, COUNT(*) AS num_parked FROM vehicles WHERE pre_crash = "PARKED" GROUP BY collision_id) b
ON a.collision_id = b.collision_id
WHERE a.num_cars - b.num_parked <= 1

I also used ChatGPT to have it try and design a query that accomplishes the same thing. After some back-and-forth, it generated the following, using CASE WHEHN instead of nested subqueries:

WITH vehicle_counts AS (
    SELECT 
        collision_id,
        SUM(CASE WHEN pre_crash <> 'Parked' THEN 1 ELSE 0 END) AS moving_vehicles,
        SUM(CASE WHEN pre_crash = 'Parked' THEN 1 ELSE 0 END) AS parked_vehicles
    FROM backup_vehicles
    GROUP BY collision_id
)
SELECT DISTINCT v.collision_id
FROM backup_vehicles v
JOIN vehicle_counts vc ON v.collision_id = vc.collision_id
WHERE vc.moving_vehicles <= 1 AND vc.parked_vehicles >= 1;

These collisions must first be deleted from crashes and persons, otherwise the subquery will not return any results!

DELETE FROM crashes WHERE collision_id IN (SELECT collision_id FROM (SELECT a.collision_id, a.num_cars, b.num_parked
FROM (SELECT collision_id, COUNT(*) AS num_cars FROM vehicles WHERE collision_id IN (SELECT DISTINCT collision_id FROM vehicles WHERE pre_crash = "PARKED") GROUP BY collision_id) a
INNER JOIN
(SELECT collision_id, COUNT(*) AS num_parked FROM vehicles WHERE pre_crash = "PARKED" GROUP BY collision_id) b
ON a.collision_id = b.collision_id
WHERE a.num_cars - b.num_parked <= 1) c)

This removes 336,976 rows from the vehicles table, 156,486 rows from the crashes table, and 399,831 rows from the persons table.
