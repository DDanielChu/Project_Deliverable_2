SET search_path TO public;

-- Hotel Chain 
CREATE TABLE IF NOT EXISTS hotel_chain (
	chain_id 		SERIAL			 PRIMARY KEY,
	hotel_name		VARCHAR(255)	 NOT NULL,
	street_number	INT 			 NOT NULL,
    street_name     VARCHAR(255)	 NOT NULL,
    apt_number      VARCHAR(255),
    city            VARCHAR(255) 	 NOT NULL,
    province        VARCHAR(255)	 NOT NULL,
    zip             VARCHAR(20) 	 NOT NULL
	-- Number of hotels derived from count of hotel rows
);

-- MULTIVALUED ATTRIBUTES FOR HOTEL CHAIN
CREATE TABLE IF NOT EXISTS hotel_chain_email (
    chain_ID    INT             NOT NULL REFERENCES hotel_chain(chain_ID) ON DELETE CASCADE,
    email       VARCHAR(255)    NOT NULL,
    PRIMARY KEY (chain_ID, email)
);
 
CREATE TABLE IF NOT EXISTS hotel_chain_phone (
    chain_ID    	INT             NOT NULL REFERENCES hotel_chain(chain_ID) ON DELETE CASCADE,
    phone_number	VARCHAR(20)   	NOT NULL,
    PRIMARY KEY (chain_ID, phone_number)
);


-- Hotel
CREATE TABLE IF NOT EXISTS hotel (
    hotel_ID        SERIAL          PRIMARY KEY,
    chain_ID        INT             NOT NULL REFERENCES hotel_chain(chain_ID) ON DELETE CASCADE,
    manager_SSN     CHAR(11), 
    street_number	INT             NOT NULL,
    street_name     VARCHAR(100)    NOT NULL,
    apt_number      VARCHAR(20),
    city            VARCHAR(100)    NOT NULL,
    province        VARCHAR(100)    NOT NULL,
    zip             VARCHAR(20)     NOT NULL,
    star_number     INT             NOT NULL CHECK (star_number BETWEEN 1 AND 5)
    -- number_of_rooms derived from COUNT of room rows
);


-- MULTIVALUED ATTRIBUTES FOR HOTEL
CREATE TABLE IF NOT EXISTS hotel_email (
    hotel_ID    INT             NOT NULL REFERENCES hotel(hotel_ID) ON DELETE CASCADE,
    email       VARCHAR(255)    NOT NULL,
    PRIMARY KEY (hotel_ID, email)
);
 
CREATE TABLE IF NOT EXISTS hotel_phone (
    hotel_ID    INT            NOT NULL REFERENCES hotel(hotel_ID) ON DELETE CASCADE,
    phone_number VARCHAR(20)   NOT NULL,
    PRIMARY KEY (hotel_ID, phone_number)
);


-- Room 
CREATE TABLE IF NOT EXISTS room (
    hotel_ID            INT             NOT NULL REFERENCES hotel(hotel_ID) ON DELETE CASCADE,
    room_ID             INT             NOT NULL,
    price               NUMERIC(10,2)   NOT NULL CHECK (price >= 0),
    capacity_of_room    INT             NOT NULL CHECK (capacity_of_room > 0),
    type_of_view        VARCHAR(20)     NOT NULL CHECK (type_of_view IN ('SEA', 'MOUNTAIN', 'NONE')),
    extension_of_bed    INT             NOT NULL CHECK (extension_of_bed >= 0),
    PRIMARY KEY (hotel_ID, room_ID)
);




CREATE TABLE IF NOT EXISTS room_damage (
    hotel_id INT NOT NULL, 
    room_id INT NOT NULL,
    damage VARCHAR(255) NOT NULL,

    PRIMARY KEY (hotel_id, room_id, damage),
    
    FOREIGN KEY (hotel_id, room_id) 
        REFERENCES room(hotel_id, room_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS room_amenity (
    hotel_id INT NOT NULL,
    room_id INT NOT NULL,
    amenity VARCHAR(255) NOT NULL,

    PRIMARY KEY (hotel_id, room_id, amenity),

    FOREIGN KEY (hotel_id, room_id) 
        REFERENCES room(hotel_id, room_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS customer (
    customer_id SERIAL,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255),
    last_name VARCHAR(255) NOT NULL,
    street_number INT NOT NULL,
    street_name VARCHAR(255) NOT NULL,
    apt_number INT,
    city VARCHAR(255) NOT NULL,
    province VARCHAR(255) NOT NULL,
    zip VARCHAR(255) NOT NULL,
    type_of_id VARCHAR(255) NOT NULL,
    date_of_registration DATE NOT NULL,
	id_value VARCHAR(50) NOT NULL,

    CHECK (type_of_id IN ('SSN', 'SIN', 'DRIVING LSCENCE')),
    CHECK (date_of_registration <= CURRENT_DATE),

    PRIMARY KEY (customer_id)
);

CREATE TABLE IF NOT EXISTS employee (
    ssn VARCHAR(11) NOT NULL,
    hotel_id INT NOT NULL,
    first_name VARCHAR(255) NOT NULL,
    middle_name VARCHAR(255),
    last_name VARCHAR(255) NOT NULL,
    street_number INT NOT NULL,
    street_name VARCHAR(255) NOT NULL,
    apt_number INT,
    city VARCHAR(255) NOT NULL,
    province VARCHAR(255) NOT NULL,
    zip VARCHAR(255) NOT NULL,
    job_role VARCHAR(255) NOT NULL,

    PRIMARY KEY (ssn),

    FOREIGN KEY (hotel_id) 
        REFERENCES hotel(hotel_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS booking (
    booking_id SERIAL,
    customer_id INT NOT NULL,
    hotel_id INT NOT NULL,
    room_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(255) NOT NULL,

	CHECK(status in ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED')),
	
    CHECK (start_date < end_date),

    PRIMARY KEY (booking_id),
    
    FOREIGN KEY (customer_id) 
        REFERENCES customer(customer_id) ON DELETE CASCADE,

    FOREIGN KEY (hotel_id, room_id) 
        REFERENCES room(hotel_id, room_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS renting (
    rent_id SERIAL,
    customer_id INT NOT NULL,
    hotel_id INT NOT NULL, 
    room_id INT NOT NULL,
    employee_ssn VARCHAR(11) NOT NULL,
    booking_id INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(255) NOT NULL,
    is_walk_in BOOL NOT NULL,

    PRIMARY KEY (rent_id),

    FOREIGN KEY (customer_id) 
        REFERENCES customer(customer_id) ON DELETE CASCADE,

    FOREIGN KEY (hotel_id, room_id) 
        REFERENCES room(hotel_id, room_id) ON DELETE CASCADE,

    FOREIGN KEY (employee_ssn) 
        REFERENCES employee(ssn),

    FOREIGN KEY (booking_id) 
        REFERENCES booking(booking_id),

    CHECK (start_date < end_date),
    CHECK (price > 0),
    CHECK (payment_method IN ('CREDIT CARD', 'DEBIT CARD', 'CASH')),
	
	CHECK (
	    (is_walk_in = TRUE AND booking_id IS NULL)
	    OR
	    (is_walk_in = FALSE AND booking_id IS NOT NULL)
	)	
);



-- ARCHIVES
CREATE TABLE IF NOT EXISTS booking_archive (
    booking_ID      INT,
    customer_ID     INT             NOT NULL,
    hotel_ID        INT             NOT NULL,
    room_ID         INT             NOT NULL,
    start_date      DATE            NOT NULL,
    end_date        DATE            NOT NULL,
    status          VARCHAR(20)     NOT NULL
                        CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED')),
    archived_at     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
	archive_id      SERIAL          PRIMARY KEY
);



CREATE TABLE IF NOT EXISTS renting_archive (
    rent_id        INT           NOT NULL,
    customer_id    INT           NOT NULL,
    hotel_id       INT           NOT NULL,
    room_id        INT           NOT NULL,
    employee_ssn   VARCHAR(11)   NOT NULL,
    booking_id     INT,
    start_date     DATE          NOT NULL,
    end_date       DATE          NOT NULL,
    price          DECIMAL(10,2) NOT NULL
                       CHECK (price > 0),
    payment_method VARCHAR(255)  NOT NULL
                       CHECK (payment_method IN ('CREDIT CARD', 'DEBIT CARD', 'CASH')),
    is_walk_in     BOOL          NOT NULL,
    archived_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (start_date < end_date),
	archive_id     SERIAL        PRIMARY KEY
);


-- VIEW 1: Number of available rooms per area
CREATE VIEW available_rooms_per_area AS
SELECT
    h.city,
    h.province,
    COUNT(*) AS available_rooms
FROM room r
JOIN hotel h ON r.hotel_id = h.hotel_id
WHERE
    -- No active booking overlapping today
    NOT EXISTS (
        SELECT 1
        FROM booking b
        WHERE b.hotel_id   = r.hotel_id
          AND b.room_id    = r.room_id
          AND b.status     IN ('PENDING', 'CONFIRMED')
          AND CURRENT_DATE >= b.start_date
          AND CURRENT_DATE <  b.end_date
    )
    AND
    -- No active renting overlapping today
    NOT EXISTS (
        SELECT 1
        FROM renting rt
        WHERE rt.hotel_id  = r.hotel_id
          AND rt.room_id   = r.room_id
          AND CURRENT_DATE >= rt.start_date
          AND CURRENT_DATE <  rt.end_date
    )
GROUP BY h.city, h.province;

-- VIEW 2: Aggregated capacity of all rooms per hotel
CREATE VIEW hotel_total_capacity AS
SELECT
    h.hotel_id,
    h.city,
    h.province,
    h.star_number,
    COUNT(r.room_id)            AS total_rooms,
    SUM(r.capacity_of_room)     AS total_capacity
FROM hotel h
JOIN room r ON h.hotel_id = r.hotel_id
GROUP BY h.hotel_id, h.city, h.province, h.star_number;



-- DERIVED ATTRIBUTE VIEWS
CREATE VIEW hotel_count AS
SELECT
    hc.chain_id,
    hc.hotel_name,
    hc.street_number,
    hc.street_name,
    hc.apt_number,
    hc.city,
    hc.province,
    hc.zip,
    COUNT(h.hotel_id) AS number_of_hotels

FROM hotel_chain hc
LEFT JOIN hotel h ON hc.chain_id = h.chain_id
GROUP BY
    hc.chain_id, hc.hotel_name, hc.street_number, hc.street_name,
    hc.apt_number, hc.city, hc.province, hc.zip;


CREATE VIEW hotel_room_count AS
SELECT
    h.hotel_id,
    h.chain_id,
    h.manager_ssn,
    h.street_number,
    h.street_name,
    h.apt_number,
    h.city,
    h.province,
    h.zip,
    h.star_number,
    COUNT(r.room_id) AS number_of_rooms
FROM hotel h
LEFT JOIN room r ON h.hotel_id = r.hotel_id
GROUP BY
    h.hotel_id, h.chain_id, h.manager_ssn, h.street_number,
    h.street_name, h.apt_number, h.city, h.province,
    h.zip, h.star_number;


-- --------------TRIGGERS ---------------

-- Trigger 1: Manager must work at the hotel they manage and must have role = 'manager'
CREATE OR REPLACE FUNCTION check_hotel_manager()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.manager_ssn IS NULL THEN
        RETURN NEW;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.employee e
        WHERE e.ssn = NEW.manager_ssn
          AND e.hotel_id = NEW.hotel_id
          AND LOWER(e.job_role) = 'manager'
    ) THEN
        RAISE EXCEPTION 'Manager must work at the hotel they manage and must have job_role = manager';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


 
-- Trigger 2: No overlapping BOOKINGS for the same room
CREATE OR REPLACE FUNCTION check_no_overlapping_bookings()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('PENDING', 'CONFIRMED') THEN
        IF EXISTS (
            SELECT 1
            FROM booking b
            WHERE b.hotel_id = NEW.hotel_id
              AND b.room_id = NEW.room_id
              AND b.status IN ('PENDING', 'CONFIRMED')
              AND b.booking_id <> NEW.booking_id
              AND NEW.start_date < b.end_date
              AND NEW.end_date > b.start_date
        ) THEN
            RAISE EXCEPTION 'Overlapping active booking exists for this room';
        END IF;
	END IF;
    
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_no_overlapping_bookings
BEFORE INSERT OR UPDATE ON booking
FOR EACH ROW
EXECUTE FUNCTION check_no_overlapping_bookings();
 
 
-- Trigger 3: A booking cannot overlap with an active renting for the same room was missing from original
CREATE OR REPLACE FUNCTION check_booking_not_overlap_renting()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('PENDING', 'CONFIRMED') THEN
        IF EXISTS (
            SELECT 1
            FROM renting r
            WHERE r.hotel_id = NEW.hotel_id
              AND r.room_id = NEW.room_id
              AND NEW.start_date < r.end_date
              AND NEW.end_date > r.start_date
        ) THEN
            RAISE EXCEPTION 'Booking cannot overlap with an active renting for the same room';
        END IF;
    END IF;
	
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_booking_not_overlap_renting
BEFORE INSERT OR UPDATE ON booking
FOR EACH ROW
EXECUTE FUNCTION check_booking_not_overlap_renting();


-- Trigger 4: No overlapping rentings for the same room
CREATE OR REPLACE FUNCTION check_renting_overlap()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM renting
        WHERE hotel_id  = NEW.hotel_id
          AND room_id   = NEW.room_id
          AND rent_id  <> COALESCE(NEW.rent_id, -1)
          AND start_date < NEW.end_date
          AND end_date   > NEW.start_date
    ) THEN
        RAISE EXCEPTION
            'Room (hotel %, room %) is already rented during % to %.',
            NEW.hotel_id, NEW.room_id, NEW.start_date, NEW.end_date;
    END IF;
	
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_renting_overlap
BEFORE INSERT OR UPDATE ON renting
FOR EACH ROW EXECUTE FUNCTION check_renting_overlap();

 
-- Trigger 5: Auto-archive bookings before deletion
CREATE OR REPLACE FUNCTION archive_booking()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO booking_archive
        (booking_ID, customer_ID, hotel_ID, room_ID,
         start_date, end_date, status, archived_at)
    VALUES
        (OLD.booking_ID, OLD.customer_ID, OLD.hotel_ID, OLD.room_ID,
         OLD.start_date, OLD.end_date, OLD.status, CURRENT_TIMESTAMP);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_archive_booking
BEFORE DELETE ON booking
FOR EACH ROW EXECUTE FUNCTION archive_booking();
 
 
-- Trigger 6: Auto-archive rentings before deletion
CREATE OR REPLACE FUNCTION archive_renting()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO renting_archive
        (rent_ID, customer_ID, hotel_ID, room_ID, employee_SSN,
         booking_ID, start_date, end_date, price, payment_method,
         is_walk_in, archived_at)
    VALUES
        (OLD.rent_ID, OLD.customer_ID, OLD.hotel_ID, OLD.room_ID, OLD.employee_SSN,
         OLD.booking_ID, OLD.start_date, OLD.end_date, OLD.price, OLD.payment_method,
         OLD.is_walk_in, CURRENT_TIMESTAMP);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
 
CREATE TRIGGER trg_archive_renting
BEFORE DELETE ON renting
FOR EACH ROW EXECUTE FUNCTION archive_renting();



-- INDEXES

-- INDEX 1: Availability check on booking (hotel_id, room_id, start_date, end_date)
-- Speeds up room availability check.
-- Without this index, every INSERT into booking causes a full scan of the entire booking table.
CREATE INDEX idx_booking_availability
    ON booking (hotel_id, room_id, start_date, end_date)
    WHERE status IN ('PENDING', 'CONFIRMED');
 
 
-- INDEX 2: Availability check on renting (hotel_id, room_id, start_date, end_date)
-- Speeds up renting overlap check.
-- Avoids full scan of renting table.
CREATE INDEX idx_renting_availability
    ON renting (hotel_id, room_id, start_date, end_date);


-- INDEX 3: Customer lookup on booking (customer_id)
-- Speeds up finding bookings for one customer.
-- Avoids full scan of booking table.
CREATE INDEX idx_booking_customer
    ON booking (customer_id);







-- ======================
-- DATA POPULATION
-- =====================

BEGIN;


-- 1) HOTEL CHAINS
INSERT INTO hotel_chain (
    chain_id, hotel_name, street_number, street_name, apt_number, city, province, zip
) OVERRIDING SYSTEM VALUE
VALUES
    (1, 'Maple Leaf Hotels',     100, 'King St W',       NULL, 'Toronto',   'Ontario',          'M5H1A1'),
    (2, 'Northern Star Inns',    200, 'Georgia St W',    NULL, 'Vancouver', 'British Columbia', 'V6B1A1'),
    (3, 'Blue Harbor Resorts',   300, 'Rue Sherbrooke',  NULL, 'Montreal',  'Quebec',           'H3A1A1'),
    (4, 'Prairie Crown Suites',  400, 'Portage Ave',     NULL, 'Winnipeg',  'Manitoba',         'R3B1A1'),
    (5, 'Summit Stay Group',     500, '8 Ave SW',        NULL, 'Calgary',   'Alberta',          'T2P1A1')
ON CONFLICT (chain_id) DO NOTHING;

INSERT INTO hotel_chain_email (chain_id, email) VALUES
    (1, 'info@mapleleafhotels.ca'),
    (1, 'support@mapleleafhotels.ca'),
    (2, 'info@northernstarinns.ca'),
    (2, 'support@northernstarinns.ca'),
    (3, 'info@blueharborresorts.ca'),
    (3, 'support@blueharborresorts.ca'),
    (4, 'info@prairiecrownsuites.ca'),
    (4, 'support@prairiecrownsuites.ca'),
    (5, 'info@summitstaygroup.ca'),
    (5, 'support@summitstaygroup.ca')
ON CONFLICT DO NOTHING;

INSERT INTO hotel_chain_phone (chain_id, phone_number) VALUES
    (1, '416-555-1001'),
    (1, '416-555-1002'),
    (2, '604-555-2001'),
    (2, '604-555-2002'),
    (3, '514-555-3001'),
    (3, '514-555-3002'),
    (4, '204-555-4001'),
    (4, '204-555-4002'),
    (5, '403-555-5001'),
    (5, '403-555-5002')
ON CONFLICT DO NOTHING;


-- 2) HOTELS
INSERT INTO hotel (
    hotel_id, chain_id, manager_ssn, street_number, street_name, apt_number, city, province, zip, star_number
) OVERRIDING SYSTEM VALUE
VALUES
    -- Chain 1
    (101, 1, NULL, 101, 'King St W',       NULL, 'Toronto',     'Ontario',          'M5H1B1', 3),
    (102, 1, NULL, 102, 'Queen St W',      NULL, 'Toronto',     'Ontario',          'M5H1B2', 4),
    (103, 1, NULL, 103, 'Rideau St',       NULL, 'Ottawa',      'Ontario',          'K1N1A1', 5),
    (104, 1, NULL, 104, 'Bloor St W',      NULL, 'Hamilton',    'Ontario',          'L8P1A1', 3),
    (105, 1, NULL, 105, 'Dundas St',       NULL, 'London',      'Ontario',          'N6A1A1', 4),
    (106, 1, NULL, 106, 'Princess St',     NULL, 'Kingston',    'Ontario',          'K7L1A1', 5),
    (107, 1, NULL, 107, 'Main St',         NULL, 'Windsor',     'Ontario',          'N9A1A1', 3),
    (108, 1, NULL, 108, 'George St',       NULL, 'Peterborough','Ontario',          'K9J1A1', 4),

    -- Chain 2
    (201, 2, NULL, 201, 'Georgia St W',    NULL, 'Vancouver',   'British Columbia', 'V6B1B1', 5),
    (202, 2, NULL, 202, 'Robson St',       NULL, 'Vancouver',   'British Columbia', 'V6B1B2', 4),
    (203, 2, NULL, 203, 'Douglas St',      NULL, 'Victoria',    'British Columbia', 'V8W1A1', 3),
    (204, 2, NULL, 204, 'Bernard Ave',     NULL, 'Kelowna',     'British Columbia', 'V1Y1A1', 4),
    (205, 2, NULL, 205, 'King George Blvd',NULL, 'Surrey',      'British Columbia', 'V3T1A1', 5),
    (206, 2, NULL, 206, 'Kingsway',        NULL, 'Burnaby',     'British Columbia', 'V5H1A1', 3),
    (207, 2, NULL, 207, 'No 3 Rd',         NULL, 'Richmond',    'British Columbia', 'V6X1A1', 4),
    (208, 2, NULL, 208, 'Victoria St',     NULL, 'Kamloops',    'British Columbia', 'V2C1A1', 5),

    -- Chain 3
    (301, 3, NULL, 301, 'Rue Sherbrooke',  NULL, 'Montreal',    'Quebec',           'H3A1B1', 3),
    (302, 3, NULL, 302, 'Rue Sainte-Catherine', NULL, 'Montreal','Quebec',          'H3A1B2', 4),
    (303, 3, NULL, 303, 'Grande Allee',    NULL, 'Quebec City', 'Quebec',           'G1R1A1', 5),
    (304, 3, NULL, 304, 'Boul Saint-Martin',NULL,'Laval',       'Quebec',           'H7N1A1', 3),
    (305, 3, NULL, 305, 'Boul Maisonneuve',NULL, 'Gatineau',    'Quebec',           'J8X1A1', 4),
    (306, 3, NULL, 306, 'Boul Taschereau', NULL, 'Longueuil',   'Quebec',           'J4K1A1', 5),
    (307, 3, NULL, 307, 'Rue King O',      NULL, 'Sherbrooke',  'Quebec',           'J1H1A1', 3),
    (308, 3, NULL, 308, 'Rue des Forges',  NULL, 'Trois-Rivieres','Quebec',         'G9A1A1', 4),

    -- Chain 4
    (401, 4, NULL, 401, 'Portage Ave',     NULL, 'Winnipeg',    'Manitoba',         'R3B1B1', 4),
    (402, 4, NULL, 402, 'Main St',         NULL, 'Winnipeg',    'Manitoba',         'R3B1B2', 5),
    (403, 4, NULL, 403, 'Rosser Ave',      NULL, 'Brandon',     'Manitoba',         'R7A1A1', 3),
    (404, 4, NULL, 404, 'Mystery Lake Rd', NULL, 'Thompson',    'Manitoba',         'R8N1A1', 4),
    (405, 4, NULL, 405, 'Main St',         NULL, 'Steinbach',   'Manitoba',         'R5G1A1', 5),
    (406, 4, NULL, 406, 'Manitoba Ave',    NULL, 'Selkirk',     'Manitoba',         'R1A1A1', 3),
    (407, 4, NULL, 407, '1st Ave NW',      NULL, 'Dauphin',     'Manitoba',         'R7N1A1', 4),
    (408, 4, NULL, 408, '3rd Ave',         NULL, 'Flin Flon',   'Manitoba',         'R8A1A1', 5),

    -- Chain 5
    (501, 5, NULL, 501, '8 Ave SW',        NULL, 'Calgary',     'Alberta',          'T2P1B1', 5),
    (502, 5, NULL, 502, '9 Ave SW',        NULL, 'Calgary',     'Alberta',          'T2P1B2', 4),
    (503, 5, NULL, 503, 'Jasper Ave',      NULL, 'Edmonton',    'Alberta',          'T5J1A1', 3),
    (504, 5, NULL, 504, 'Whyte Ave',       NULL, 'Edmonton',    'Alberta',          'T6E1A1', 4),
    (505, 5, NULL, 505, 'Mayor Magrath Dr',NULL, 'Lethbridge',  'Alberta',          'T1J1A1', 5),
    (506, 5, NULL, 506, 'Ross St',         NULL, 'Red Deer',    'Alberta',          'T4N1A1', 3),
    (507, 5, NULL, 507, 'Franklin Ave',    NULL, 'Fort McMurray','Alberta',         'T9H1A1', 4),
    (508, 5, NULL, 508, 'Banff Ave',       NULL, 'Banff',       'Alberta',          'T1L1A1', 5)
ON CONFLICT (hotel_id) DO NOTHING;

INSERT INTO hotel_email (hotel_id, email)
SELECT hotel_id, LOWER('hotel' || hotel_id || '@hotel.example')
FROM hotel
ON CONFLICT DO NOTHING;

INSERT INTO hotel_phone (hotel_id, phone_number)
SELECT hotel_id, '555-' || LPAD(hotel_id::text, 4, '0')
FROM hotel
ON CONFLICT DO NOTHING;


-- 3) ROOMS
INSERT INTO room (hotel_id, room_id, price, capacity_of_room, type_of_view, extension_of_bed)
SELECT hotel_id, 1, 109.99, 1, 'NONE',     0 FROM hotel
ON CONFLICT DO NOTHING;

INSERT INTO room (hotel_id, room_id, price, capacity_of_room, type_of_view, extension_of_bed)
SELECT hotel_id, 2, 149.99, 2, 'SEA',      1 FROM hotel
ON CONFLICT DO NOTHING;

INSERT INTO room (hotel_id, room_id, price, capacity_of_room, type_of_view, extension_of_bed)
SELECT hotel_id, 3, 189.99, 3, 'MOUNTAIN', 1 FROM hotel
ON CONFLICT DO NOTHING;

INSERT INTO room (hotel_id, room_id, price, capacity_of_room, type_of_view, extension_of_bed)
SELECT hotel_id, 4, 229.99, 4, 'SEA',      2 FROM hotel
ON CONFLICT DO NOTHING;

INSERT INTO room (hotel_id, room_id, price, capacity_of_room, type_of_view, extension_of_bed)
SELECT hotel_id, 5, 269.99, 5, 'MOUNTAIN', 2 FROM hotel
ON CONFLICT DO NOTHING;


-- 4) ROOM AMENITIES
INSERT INTO room_amenity (hotel_id, room_id, amenity)
SELECT hotel_id, room_id, 'WiFi'
FROM room
ON CONFLICT DO NOTHING;

INSERT INTO room_amenity (hotel_id, room_id, amenity)
SELECT hotel_id, room_id, 'TV'
FROM room
ON CONFLICT DO NOTHING;

INSERT INTO room_amenity (hotel_id, room_id, amenity)
SELECT hotel_id, room_id, 'Mini Fridge'
FROM room
WHERE room_id IN (2, 3, 4, 5)
ON CONFLICT DO NOTHING;

INSERT INTO room_amenity (hotel_id, room_id, amenity)
SELECT hotel_id, room_id, 'Balcony'
FROM room
WHERE room_id IN (4, 5)
ON CONFLICT DO NOTHING;

INSERT INTO room_amenity (hotel_id, room_id, amenity)
SELECT hotel_id, room_id, 'Kitchenette'
FROM room
WHERE room_id = 5
ON CONFLICT DO NOTHING;


-- 5) ROOM DAMAGES
INSERT INTO room_damage (hotel_id, room_id, damage) VALUES
    (101, 2, 'Broken lamp'),
    (102, 4, 'Scratched wall'),
    (201, 3, 'Leaking faucet'),
    (302, 5, 'Cracked mirror'),
    (401, 1, 'Stained carpet'),
    (502, 2, 'Broken window'),
    (503, 3, 'Loose door handle'),
    (308, 4, 'Damaged curtain')
ON CONFLICT DO NOTHING;





-- 6) CUSTIOMERS
INSERT INTO customer (
    customer_id, first_name, middle_name, last_name,
    street_number, street_name, apt_number, city, province, zip,
    type_of_id, date_of_registration
) OVERRIDING SYSTEM VALUE
VALUES
    (1,  'Alice',  NULL, 'Nguyen',  11, 'Elm St',      NULL, 'Toronto',   'Ontario',          'M4A1A1', 'SIN',             '2025-01-10', '315-728-946'),
    (2,  'Brian',  NULL, 'Lee',     22, 'Pine St',     NULL, 'Ottawa',    'Ontario',          'K1A1A1', 'SSN',             '2025-01-15', '421-56-7893'),
    (3,  'Chloe',  NULL, 'Tran',    33, 'Oak St',      NULL, 'Hamilton',  'Ontario',          'L8P1B1', 'DRIVING LSCENCE', '2025-02-01', 'ON-DL-4837-2916'),
    (4,  'Daniel', NULL, 'Kim',     44, 'Cedar St',    NULL, 'London',    'Ontario',          'N6A1B1', 'SIN',             '2025-02-05', '628-194-357'),
    (5,  'Emma',   NULL, 'Chen',    55, 'Birch St',    NULL, 'Kingston',  'Ontario',          'K7L1B1', 'SSN',             '2025-02-09', '534-82-1706'),
    (6,  'Farah',  NULL, 'Ali',     66, 'Maple St',    NULL, 'Vancouver', 'British Columbia', 'V6B1C1', 'SIN',             '2025-02-12', '741-305-628'),
    (7,  'Grace',  NULL, 'Wong',    77, 'Ash St',      NULL, 'Burnaby',   'British Columbia', 'V5H1B1', 'DRIVING LSCENCE', '2025-02-15', 'BC-DL-5829-1047'),
    (8,  'Henry',  NULL, 'Patel',   88, 'Lake St',     NULL, 'Richmond',  'British Columbia', 'V6X1B1', 'SSN',             '2025-02-20', '692-41-8357'),
    (9,  'Ivy',    NULL, 'Singh',   99, 'Hill St',     NULL, 'Montreal',  'Quebec',           'H3A1C1', 'SIN',             '2025-03-01', '857-263-914'),
    (10, 'Jason',  NULL, 'Lopez',  111, 'Park St',     NULL, 'Laval',     'Quebec',           'H7N1B1', 'DRIVING LSCENCE', '2025-03-03', 'QC-DL-7315-4682'),
    (11, 'Karen',  NULL, 'Martin', 122, 'River St',    NULL, 'Winnipeg',  'Manitoba',         'R3B1C1', 'SSN',             '2025-03-07', '318-74-9256'),
    (12, 'Liam',   NULL, 'Brown',  133, 'Hillcrest',   NULL, 'Calgary',   'Alberta',          'T2P1C1', 'SIN',             '2025-03-10', '904-586-231')
ON CONFLICT (customer_id) DO NOTHING;


-- 7) EMPLOYEES
INSERT INTO employee (
    ssn, hotel_id, first_name, middle_name, last_name,
    street_number, street_name, apt_number, city, province, zip, job_role
)
SELECT
    '900-00-' || LPAD(hotel_id::text, 4, '0') AS ssn,
    hotel_id,
    'Manager' || hotel_id,
    NULL,
    'Smith',
    hotel_id,
    'Manager Ave',
    NULL,
    city,
    province,
    zip,
    'manager'
FROM hotel
ON CONFLICT (ssn) DO NOTHING;

INSERT INTO employee (
    ssn, hotel_id, first_name, middle_name, last_name,
    street_number, street_name, apt_number, city, province, zip, job_role
)
SELECT
    '800-00-' || LPAD(hotel_id::text, 4, '0') AS ssn,
    hotel_id,
    'Clerk' || hotel_id,
    NULL,
    'Jones',
    hotel_id + 1000,
    'Staff Rd',
    NULL,
    city,
    province,
    zip,
    'receptionist'
FROM hotel
ON CONFLICT (ssn) DO NOTHING;

-- Now update hotel.manager_ssn after managers exist
UPDATE hotel
SET manager_ssn = '900-00-' || LPAD(hotel_id::text, 4, '0')
WHERE manager_ssn IS NULL;



-- BOOKINGS
INSERT INTO booking (
    booking_id, customer_id, hotel_id, room_id, start_date, end_date, status
) OVERRIDING SYSTEM VALUE
VALUES
    (1,  1, 101, 1, '2026-04-10', '2026-04-14', 'CONFIRMED'),
    (2,  2, 102, 2, '2026-04-12', '2026-04-15', 'PENDING'),
    (3,  3, 103, 3, '2026-04-18', '2026-04-22', 'CONFIRMED'),
    (4,  4, 201, 1, '2026-04-09', '2026-04-11', 'COMPLETED'),
    (5,  5, 202, 2, '2026-04-20', '2026-04-23', 'CONFIRMED'),
    (6,  6, 203, 4, '2026-04-15', '2026-04-19', 'CANCELLED'),
    (7,  7, 301, 5, '2026-04-25', '2026-04-28', 'PENDING'),
    (8,  8, 302, 1, '2026-04-14', '2026-04-17', 'CONFIRMED'),
    (9,  9, 401, 3, '2026-04-21', '2026-04-24', 'CONFIRMED'),
    (10, 10, 402, 2, '2026-04-26', '2026-04-29', 'PENDING'),
    (11, 11, 501, 4, '2026-04-08', '2026-04-12', 'CONFIRMED'),
    (12, 12, 502, 5, '2026-04-30', '2026-05-03', 'CONFIRMED')
ON CONFLICT (booking_id) DO NOTHING;


-- RENTINGS
INSERT INTO renting (
    rent_id, customer_id, hotel_id, room_id, employee_ssn, booking_id,
    start_date, end_date, price, payment_method, is_walk_in
) OVERRIDING SYSTEM VALUE
VALUES
    (1,  1, 104, 1, '800-00-0104', NULL, '2026-04-01', '2026-04-05', 439.96, 'CREDIT CARD', TRUE),
    (2,  2, 204, 2, '800-00-0204', NULL, '2026-04-02', '2026-04-06', 599.96, 'DEBIT CARD',  TRUE),
    (3,  3, 304, 3, '800-00-0304', NULL, '2026-04-03', '2026-04-07', 759.96, 'CASH',        TRUE),
    (4,  4, 404, 4, '800-00-0404', NULL, '2026-04-04', '2026-04-08', 919.96, 'CREDIT CARD', TRUE),
    (5,  5, 504, 5, '800-00-0504', NULL, '2026-04-05', '2026-04-09',1079.96, 'DEBIT CARD',  TRUE),

    (6,  6, 101, 1, '800-00-0101', 1,    '2026-04-10', '2026-04-14', 439.96, 'CREDIT CARD', FALSE),
    (7,  7, 103, 3, '800-00-0103', 3,    '2026-04-18', '2026-04-22', 759.96, 'DEBIT CARD',  FALSE),
    (8,  8, 202, 2, '800-00-0202', 5,    '2026-04-20', '2026-04-23', 599.96, 'CASH',        FALSE),
    (9,  9, 302, 1, '800-00-0302', 8,    '2026-04-14', '2026-04-17', 439.96, 'CREDIT CARD', FALSE),
    (10, 10, 401, 3,'800-00-0401', 9,    '2026-04-21', '2026-04-24', 759.96, 'DEBIT CARD',  FALSE)
ON CONFLICT (rent_id) DO NOTHING;

COMMIT;

