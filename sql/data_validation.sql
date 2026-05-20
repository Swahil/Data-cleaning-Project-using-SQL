

/*VALIDITY OF DATES*/
--Deletes invalid dates
WITH date_validation AS (
	SELECT 
    *,
	NULLIF(delivery_date, '')::date
    - NULLIF(ship_date, '')::date AS transit_time_days,
    CASE 
	    WHEN NULLIF(delivery_date, '')::date < NULLIF(ship_date, '')::date THEN 'Invalid'
	    ELSE 'Valid'
	END AS validation
FROM shipments)
DELETE FROM shipments 
WHERE shipment_id IN 
(SELECT shipment_id 
FROM date_validation
WHERE validation = 'Invalid')
;



/*DETECTING OUTLIERS*/
--freight_cost / replacing 
WITH bounds AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY freight_cost) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY freight_cost) AS q3,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY freight_cost)
        - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY freight_cost) AS iqr
    FROM cleaned_shipments s
)
SELECT 
    s.freight_cost,
   CASE
        WHEN s.freight_cost > (bounds.q3 + 1.5 * bounds.iqr)
          OR s.freight_cost < (bounds.q1 - 1.5 * bounds.iqr)
        THEN 'YES'
        ELSE 'NO'
    END AS outlier,
    CASE 
    	WHEN s.freight_cost > (bounds.q3 + 1.5 * bounds.iqr) THEN (bounds.q3 + 1.5 * bounds.iqr)
    	WHEN s.freight_cost < (bounds.q1 - 1.5 * bounds.iqr) THEN (bounds.q1 - 1.5 * bounds.iqr)
    	ELSE s.freight_cost
    END AS c_freight_cost  
FROM cleaned_shipments s
CROSS JOIN bounds;--joins all quartiles to all rows in freight_cost

/*DETECTING OUTLIERS*/
--weight_kg
WITH bounds AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY weight_kg  ) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY weight_kg) AS q3,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY weight_kg)
        - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY weight_kg) AS iqr
    FROM shipments
)
SELECT 
    s.weight_kg,
    CASE
        WHEN s.weight_kg > (bounds.q3 + 1.5 * bounds.iqr)
          OR s.weight_kg < (bounds.q1 - 1.5 * bounds.iqr)
        THEN 'YES'
        ELSE 'NO'
    END AS outlier
FROM cleaned_shipments s
CROSS JOIN bounds;--joins all quartiles to all rows in weight_kg

/*DETECTING OUTLIERS*/
--items_count
WITH bounds AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY items_count) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY items_count) AS q3,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY items_count)
        - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY items_count) AS iqr
    FROM cleaned_shipments
)
SELECT 
    s.items_count,
    CASE
        WHEN s.items_count > (bounds.q3 + 1.5 * bounds.iqr)
          OR s.items_count < (bounds.q1 - 1.5 * bounds.iqr)
        THEN 'YES'
        ELSE 'NO'
    END AS outlier
FROM shipments s
CROSS JOIN bounds;--joins all quartiles to all rows in items_count





	
	
	


