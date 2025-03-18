update crashes set
crash_date = date_format(str_to_date(crash_date, '%m/%d/%Y'), '%Y-%m-%d');

ALTER TABLE crashes
MODIFY COLUMN crash_date DATE
MODIFY COLUMN crash_time TIME;

And likewise for the other tables.
