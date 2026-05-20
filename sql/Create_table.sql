CREATE TABLE shipments (
    shipment_id        TEXT,
    origin_warehouse   TEXT,
    destination_city   TEXT,
    destination_state  TEXT,
    carrier            TEXT,
    ship_date          DATE,
    delivery_date      DATE,
    weight_kg          NUMERIC,
    freight_cost       NUMERIC,
    shipment_status    TEXT,
    items_count        INTEGER,
    damage_reported    BOOLEAN
);

SELECT  * FROM shipments;




	
	
	



