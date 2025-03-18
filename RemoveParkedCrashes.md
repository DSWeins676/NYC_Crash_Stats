
SELECT collision_id FROM (SELECT a.collision_id, a.num_cars, b.num_parked
FROM (SELECT collision_id, COUNT(*) AS num_cars FROM vehicles WHERE collision_id IN (SELECT DISTINCT collision_id FROM vehicles WHERE pre_crash = "PARKED") GROUP BY collision_id) a
INNER JOIN
(SELECT collision_id, COUNT(*) AS num_parked FROM vehicles WHERE pre_crash = "PARKED" GROUP BY collision_id) b
ON a.collision_id = b.collision_id
WHERE a.num_cars - b.num_parked <= 1

These collisions must first be deleted from crashes and persons, otherwise the subquery will not return any results!

DELETE FROM crashes WHERE collision_id IN (SELECT collision_id FROM (SELECT a.collision_id, a.num_cars, b.num_parked
FROM (SELECT collision_id, COUNT(*) AS num_cars FROM vehicles WHERE collision_id IN (SELECT DISTINCT collision_id FROM vehicles WHERE pre_crash = "PARKED") GROUP BY collision_id) a
INNER JOIN
(SELECT collision_id, COUNT(*) AS num_parked FROM vehicles WHERE pre_crash = "PARKED" GROUP BY collision_id) b
ON a.collision_id = b.collision_id
WHERE a.num_cars - b.num_parked <= 1) c)
