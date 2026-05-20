

/*CLEANING*/
CREATE TABLE cleaned_shipments AS
SELECT 
    REGEXP_REPLACE(shipment_id, 'SHP-', '') AS shipment_id,
    
    REGEXP_REPLACE(INITCAP(TRIM(origin_warehouse)),'Warehouse','')   AS origin_warehouse,
    
    INITCAP(COALESCE(NULLIF(TRIM(destination_city),''),'Unknown')) AS destination_city,
        
    UPPER(TRIM(destination_state)) AS destination_state,
    
    INITCAP(TRIM(carrier))AS carrier,
    
   CASE 
   		WHEN ship_date ~ '^\d{1,2}/\d{1,2}/\d{4}$' 
   			THEN TO_DATE(ship_date,'MM/DD/YYYY')
   		--FEB 10 2024
   		WHEN ship_date ~ '^[A-Za-z]{3} \d{1,2} \d{4}$'
   			THEN TO_DATE(ship_date,'Mon DD YYYY')
   		--March 12 2024
   		WHEN ship_date ~ '^[A-Za-z]{5} \d{1,2} \d{4}$'
   				THEN TO_DATE(ship_date,'Month DD YYYY')
   		ELSE NULL
   		END AS ship_date,
   
    CASE 
    -- Format: M/D/YYYY or MM/DD/YYYY
    WHEN delivery_date ~ '^\d{1,2}/\d{1,2}/\d{4}$'
      THEN TO_DATE(delivery_date, 'MM/DD/YYYY')

    -- Format: Feb 15 2024 (short month)
    WHEN delivery_date ~ '^[A-Za-z]{3} \d{1,2} \d{4}$'
      THEN TO_DATE(delivery_date, 'Mon DD YYYY')

    -- Format: March 12 2024 (full month)
    WHEN delivery_date ~ '^[A-Za-z]+ \d{1,2} \d{4}$'
      THEN TO_DATE(delivery_date, 'Month DD YYYY')
    ELSE NULL
  END AS delivery_date,
    
    ABS(weight_kg) AS weight_kg,
    
    COALESCE(freight_cost,0) AS freight_cost,
    
    INITCAP(shipment_status) AS shipment_status,
    
    CASE  
	    WHEN items_count = '0' THEN NULL
	    ELSE ABS(items_count) 
	END AS items_count,
    
    damage_reported
FROM shipments;

SELECT * FROM cleaned_shipments;

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

	
	
	


