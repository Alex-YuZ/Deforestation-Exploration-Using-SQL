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

-- Find the region with the highest relative forestation in 2016
SELECT year,
       region,
       SUM(forest_area_sqkm) total_forestation,
       SUM(total_area_sq_km) total_land,
       ROUND((100*SUM(forest_area_sqkm)/SUM(total_area_sq_km))::NUMERIC,2) forestation_pct
FROM forestation
GROUP BY 1,2
HAVING year=2016
ORDER BY forestation_pct DESC
LIMIT 1;

-- Find the region with the lowest relative forestation in 2016
SELECT year,
       region,
       SUM(forest_area_sqkm) total_forestation,
       SUM(total_area_sq_km) total_land,
       ROUND((100*SUM(forest_area_sqkm)/SUM(total_area_sq_km))::NUMERIC,2) forestation_pct
FROM forestation
GROUP BY 1,2
HAVING year=2016
ORDER BY forestation_pct
LIMIT 1;

-- Find the world's forestation area percentage in 1990
SELECT country_code,
       country_name,
       year,
       forest_area_sqkm,
       total_area_sq_km,
       ROUND(pct_forestation::NUMERIC, 2) pct_forestation
FROM forestation
WHERE year=1990 AND country_code='WLD';

-- Find the region with the highest relative forestation in 1990
SELECT year,
       region,
       SUM(forest_area_sqkm) total_forestation,
       SUM(total_area_sq_km) total_land,
       ROUND((100*SUM(forest_area_sqkm)/SUM(total_area_sq_km))::NUMERIC,2) forestation_pct
FROM forestation
GROUP BY 1,2
HAVING year=1990
ORDER BY forestation_pct DESC
LIMIT 1;

-- Find the region with the lowest relative forestation in 1990
SELECT year,
       region,
       SUM(forest_area_sqkm) total_forestation,
       SUM(total_area_sq_km) total_land,
       ROUND((100*SUM(forest_area_sqkm)/SUM(total_area_sq_km))::NUMERIC,2) forestation_pct
FROM forestation
GROUP BY 1,2
HAVING year=1990
ORDER BY forestation_pct
LIMIT 1;

-----Table 2.1: Percent FOrest Area by Region, 1990 & 2016
DROP VIEW IF EXISTS t1;
CREATE VIEW t1 AS (
SELECT year yr,
       region,
       SUM(forest_area_sqkm) total_forestation,
       SUM(total_area_sq_km) total_land,
       ROUND((100*SUM(forest_area_sqkm)/SUM(total_area_sq_km))::NUMERIC,2) forestation_pct
FROM forestation
GROUP BY 1,2
HAVING year in (1990, 2016)
ORDER BY region, yr);

WITH tab1 AS (
    SELECT region,
    forestation_pct
    FROM t1
    where yr=1990),
  
    tab2 AS (
      SELECT region,
      forestation_pct
      FROM t1
      where yr=2016)

SELECT tab1.region,
tab1.forestation_pct AS pct_1990,
tab2.forestation_pct AS pct_2019
FROM tab1
JOIN tab2 ON tab1.region=tab2.region
    
-- Part III. Country-level Detail
-- A. Success Stories
-- Largest change in terms of forest_area
WITH tab_1990 AS (
  SELECT country_code,
         country_name, 
         forest_area_sqkm, 
         total_area_sq_km, 
         pct_forestation
  FROM forestation
  WHERE year=1990
  ORDER BY country_name),

  tab_2016 AS (
    SELECT country_code, 
           country_name, 
           forest_area_sqkm, 
           total_area_sq_km, 
           pct_forestation
    FROM forestation
    WHERE year=2016
    ORDER BY country_name),

  tab_join AS (
    SELECT tab_1990.country_name, 
           tab_1990.forest_area_sqkm forest_1990, 
           tab_2016.forest_area_sqkm forest_2016, 
           tab_1990.total_area_sq_km land_1990, 
           tab_2016.total_area_sq_km land_2016, 
           tab_1990.pct_forestation pct_1990, 
           tab_2016.pct_forestation pct_2016
    FROM tab_1990
    JOIN tab_2016 ON tab_1990.country_code=tab_2016.country_code)
    
SELECT country_name, 
       forest_1990, 
       forest_2016, 
       (forest_2016-forest_1990) AS forest_area_change,
       (100*(pct_2016-pct_1990)/pct_1990) AS pct_change, 
       land_1990, 
       land_2016
FROM tab_join
WHERE forest_1990 IS NOT NULL AND forest_2016 IS NOT NULL AND country_name!='World'
ORDER BY forest_area_change DESC

-- Largest change in terms of forest_area percentage
WITH tab_1990 AS (
  SELECT country_code,
         country_name, 
         forest_area_sqkm, 
         total_area_sq_km, 
         pct_forestation
  FROM forestation
  WHERE year=1990
  ORDER BY country_name),

  tab_2016 AS (
    SELECT country_code, 
           country_name, 
           forest_area_sqkm, 
           total_area_sq_km, 
           pct_forestation
    FROM forestation
    WHERE year=2016
    ORDER BY country_name),

  tab_join AS (
    SELECT tab_1990.country_name, 
           tab_1990.forest_area_sqkm forest_1990, 
           tab_2016.forest_area_sqkm forest_2016, 
           tab_1990.total_area_sq_km land_1990, 
           tab_2016.total_area_sq_km land_2016, 
           tab_1990.pct_forestation pct_1990, 
           tab_2016.pct_forestation pct_2016
    FROM tab_1990
    JOIN tab_2016 ON tab_1990.country_code=tab_2016.country_code)
    
SELECT country_name, 
       forest_1990, 
       forest_2016, 
       (forest_2016-forest_1990) AS forest_area_change,
       (100*(pct_2016-pct_1990)/pct_1990) AS pct_change, 
       land_1990, 
       land_2016
FROM tab_join
WHERE forest_1990 IS NOT NULL AND forest_2016 IS NOT NULL AND country_name!='World'
ORDER BY pct_change DESC

-- B. Largest Concerns
--Table 3.1 Top 5 Amount Decrease in Forest Area by Country, 1990 & 2016
WITH tab_1990 AS (
  SELECT country_code,
         country_name, 
         region,
         forest_area_sqkm, 
         total_area_sq_km, 
         pct_forestation
  FROM forestation
  WHERE year=1990
  ORDER BY country_name),

  tab_2016 AS (
    SELECT country_code, 
           country_name, 
           region,
           forest_area_sqkm, 
           total_area_sq_km, 
           pct_forestation
    FROM forestation
    WHERE year=2016
    ORDER BY country_name),

  tab_join AS (
    SELECT tab_1990.country_name, 
           tab_1990.region,
           tab_1990.forest_area_sqkm forest_1990, 
           tab_2016.forest_area_sqkm forest_2016, 
           tab_1990.total_area_sq_km land_1990, 
           tab_2016.total_area_sq_km land_2016, 
           tab_1990.pct_forestation pct_1990, 
           tab_2016.pct_forestation pct_2016
    FROM tab_1990
    JOIN tab_2016 ON tab_1990.country_code=tab_2016.country_code)
    
SELECT country_name, 
       region,
       forest_1990, 
       forest_2016, 
       (forest_2016-forest_1990) AS forest_area_change,
       (100*(pct_2016-pct_1990)/pct_1990) AS pct_change, 
       land_1990, 
       land_2016
FROM tab_join
WHERE forest_1990 IS NOT NULL AND forest_2016 IS NOT NULL AND country_name!='World'
ORDER BY forest_area_change

--Table 3.2 Top 5 Percent Decrease in Forest Area by Country, 1990 & 2016
WITH tab_1990 AS (
  SELECT country_code,
         country_name, 
         region,
         forest_area_sqkm, 
         total_area_sq_km, 
         pct_forestation
  FROM forestation
  WHERE year=1990
  ORDER BY country_name),

  tab_2016 AS (
    SELECT country_code, 
           country_name, 
           region,
           forest_area_sqkm, 
           total_area_sq_km, 
           pct_forestation
    FROM forestation
    WHERE year=2016
    ORDER BY country_name),

  tab_join AS (
    SELECT tab_1990.country_name, 
           tab_1990.region,
           tab_1990.forest_area_sqkm forest_1990, 
           tab_2016.forest_area_sqkm forest_2016, 
           tab_1990.total_area_sq_km land_1990, 
           tab_2016.total_area_sq_km land_2016, 
           tab_1990.pct_forestation pct_1990, 
           tab_2016.pct_forestation pct_2016
    FROM tab_1990
    JOIN tab_2016 ON tab_1990.country_code=tab_2016.country_code)
    
SELECT country_name, 
       region,
       forest_1990, 
       forest_2016, 
       (forest_2016-forest_1990) AS forest_area_change,
       ROUND((100*(pct_2016-pct_1990)/pct_1990)::NUMERIC, 2) AS pct_change, 
       land_1990, 
       land_2016
FROM tab_join
WHERE forest_1990 IS NOT NULL AND forest_2016 IS NOT NULL AND country_name!='World'
ORDER BY pct_change


--C. Quartiles
-- Table 3.3 Count of Countries Grouped by Forestation Percent Quartiles, 2016
WITH tab_quartile AS (
  SELECT country_name,
         pct_forestation
  FROM forestation
  WHERE year=2016 AND pct_forestation IS NOT NULL
  ORDER BY 2),

  tab_quartile1 AS (
    SELECT country_name,
           pct_forestation,
           CASE
             WHEN pct_forestation<=25 THEN '0 - 25%'
             WHEN pct_forestation<=50 THEN '25% - 50%'
             WHEN pct_forestation<=75 THEN '50% - 75%'
             ELSE '75% - 100%'
           END AS quartiles
    FROM tab_quartile)

SELECT quartiles, count(country_name) number_of_countries
FROM tab_quartile1
GROUP BY 1
ORDER BY 1


-- List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
WITH tab_quartile AS (
  SELECT country_name,
  		 region,
         pct_forestation
  FROM forestation
  WHERE year=2016 AND pct_forestation IS NOT NULL
  ORDER BY 2),

  tab_quartile1 AS (
    SELECT country_name,
    	   region,
           pct_forestation,
           CASE
             WHEN pct_forestation<=25 THEN '0 - 25%'
             WHEN pct_forestation<=50 THEN '25% - 50%'
             WHEN pct_forestation<=75 THEN '50% - 75%'
             ELSE '75% - 100%'
           END AS quartiles
    FROM tab_quartile)

SELECT country_name, region, ROUND(pct_forestation::NUMERIC, 2) Pct_Designated_as_Forest
FROM tab_quartile1
WHERE quartiles='75% - 100%'
ORDER BY 1



-- How many countries had a percent forestation higher than the United States in 2016?
WITH tab_quartile AS (
  SELECT country_name,
  		 region,
         pct_forestation
  FROM forestation
  WHERE year=2016 AND pct_forestation IS NOT NULL
  ORDER BY 2),

  tab_quartile1 AS (
    SELECT country_name,
    	   region,
           pct_forestation,
           CASE
             WHEN pct_forestation<=25 THEN '0 - 25%'
             WHEN pct_forestation<=50 THEN '25% - 50%'
             WHEN pct_forestation<=75 THEN '50% - 75%'
             ELSE '75% - 100%'
           END AS quartiles
    FROM tab_quartile)

SELECT COUNT(*)
FROM tab_quartile1
WHERE pct_forestation>
(SELECT pct_forestation
FROM tab_quartile1
where country_name='United States');
