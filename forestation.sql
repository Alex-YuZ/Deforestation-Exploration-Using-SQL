-- Create the VIEW
DROP VIEW IF EXISTS forestation;

CREATE VIEW forestation AS
  SELECT f.country_code country_code,
         f.country_name country_name,
         f.year,
         f.forest_area_sqkm,
         l.total_area_sq_mi*2.59 total_area_sq_km,
         100*f.forest_area_sqkm/(l.total_area_sq_mi*2.59) pct_forestation,
         r.region,
         r.income_group
  FROM forest_area f
  JOIN land_area l
    ON f.country_code=l.country_code and f.year=l.year
  JOIN regions r
    ON r.country_code=f.country_code;

select count(*)
from forestation;



