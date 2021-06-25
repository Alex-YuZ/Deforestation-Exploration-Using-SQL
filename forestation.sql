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


-- PART I. GLOBAL SITUATION
-- Difference and percentage drop in forestation area from 1990 to 2016
WITH t1 AS (
  SELECT *
  FROM forestation
  WHERE country_code='WLD' and year in (1990, 2016)
  ORDER BY year)
   
SELECT year,
  forest_area_sqkm,
  LEAD(forest_area_sqkm) OVER (order by year) AS lead,
  LEAD(forest_area_sqkm) OVER (order by year)-forest_area_sqkm AS abs_diff,
  ROUND((100*(LEAD(forest_area_sqkm) OVER (order by year)-forest_area_sqkm)/forest_area_sqkm)::NUMERIC, 3) AS pct_diff
FROM t1



-- Find the country with its land area in 2016 closest to the deforestation area between 1990 and 2016
WITH t1 AS (
  SELECT *
  FROM forestation
  WHERE country_code='WLD' and year in (1990, 2016)
  ORDER BY year), 
  t2 AS (
    SELECT year,
      forest_area_sqkm,
      LEAD(forest_area_sqkm) OVER (order by year) AS lead,
      LEAD(forest_area_sqkm) OVER (order by year)-forest_area_sqkm AS abs_diff,
      ROUND((100*(LEAD(forest_area_sqkm) OVER (order by year)-forest_area_sqkm)/forest_area_sqkm)::NUMERIC, 3) AS pct_diff
    FROM t1)
  
SELECT DISTINCT country_name,
                total_area_sq_km, 
                (SELECT ABS(t2.abs_diff) FROM t2 ORDER BY year LIMIT 1) AS abs_diff,
                ABS(total_area_sq_km-(SELECT ABS(t2.abs_diff) FROM t2 ORDER BY year LIMIT 1)) AS diff
FROM forestation
ORDER BY 4

-- Part II. Regional Outlook
-- Find the world's forestation area percentage in 2016
SELECT country_code,
       country_name,
       year,
       forest_area_sqkm,
       total_area_sq_km,
       ROUND(pct_forestation::NUMERIC, 2) pct_forestation
FROM forestation
WHERE year=2016 AND country_code='WLD';

-- Find the region with the highest relative forestation
