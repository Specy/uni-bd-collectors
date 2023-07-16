-- Procedures
DROP PROCEDURE IF EXISTS create_collection;
DROP PROCEDURE IF EXISTS create_disc;
DROP PROCEDURE IF EXISTS create_track;
DROP PROCEDURE IF EXISTS set_collection_visibility;
DROP PROCEDURE IF EXISTS add_contributor_to_collection;
DROP PROCEDURE IF EXISTS remove_disc_from_collection;
DROP PROCEDURE IF EXISTS remove_collection;
DROP PROCEDURE IF EXISTS get_discs_of_collection;
DROP PROCEDURE IF EXISTS get_disc_tracks;
DROP PROCEDURE IF EXISTS is_collection_visible_by_collector;
DROP PROCEDURE IF EXISTS aggregate_number_of_collections_per_collector;
DROP PROCEDURE IF EXISTS aggregate_number_of_discs_per_genre;
DROP PROCEDURE IF EXISTS find_best_match_of_disc_from;
DROP FUNCTION IF EXISTS get_artist_id;
DROP FUNCTION IF EXISTS count_tracks_of_author_in_public_collections;
DROP FUNCTION IF EXISTS count_total_track_time_of_artist_in_public_collections;
DELIMITER $

-- FN 1
CREATE PROCEDURE create_collection(
	IN collection_name VARCHAR(100),
    IN collector_id INT,
    IN is_public BOOLEAN
)
BEGIN
    INSERT INTO collection(collection_name, collector_id, is_public)
    VALUES (collection_name, collector_id, is_public);
END$


-- FN 2
CREATE PROCEDURE create_disc(
	IN title VARCHAR(100),
    IN barcode VARCHAR(50),
    IN release_year INT,
    IN number_of_copies INT,
    IN genre VARCHAR(40),
    IN disc_format VARCHAR(40),
    IN label_id INT,
    IN collection_id INT,
    IN disc_status VARCHAR(40),
    IN artist_id INT
)
BEGIN 
    INSERT INTO disc(title, barcode, release_year, number_of_copies, genre, disc_format, label_id, collection_id, disc_status, artist_id)
    VALUES (title, barcode, release_year, number_of_copies, genre, disc_format, label_id, collection_id, disc_status, artist_id);
END$

CREATE PROCEDURE create_track(
    IN track_length INT,
    IN title VARCHAR(100),
    IN disc_id INT
)
BEGIN
    INSERT INTO track(track_length, title, disc_id)
    VALUES (track_length, title, disc_id);
END$

-- FN 3

CREATE PROCEDURE set_collection_visibility(
    IN collection_id INT,
    IN is_public BOOLEAN
)
BEGIN
    UPDATE collection c
    SET c.is_public = is_public
    WHERE c.id = collection_id;
END$

CREATE PROCEDURE add_contributor_to_collection(
    IN collection_id INT,
    IN collector_username VARCHAR(100)
)
BEGIN
    SET collector_id = (
        SELECT c.id
        FROM collector c
        WHERE c.username = collector_username
    );

    IF (collector_id IS NULL) THEN
        SET error_message = CONCAT("Collector: ", collector_username, " does not exist");
        SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = error_message;
    END IF;

    INSERT INTO shared_collection(collection_id, collector_id)
    VALUES (collection_id, collector_id);

END$

-- FN 4

CREATE PROCEDURE remove_disc_from_collection(
    IN disc_id INT
)
BEGIN
    DELETE FROM disc d
    WHERE d.id = disc_id;
END$

-- FN 5
CREATE PROCEDURE remove_collection(
    IN collection_id INT
)  
BEGIN
    DELETE FROM collection c
    WHERE c.id = collection_id;
END$

-- FN 6
CREATE PROCEDURE get_discs_of_collection(
    IN collection_id INT
)
BEGIN
    SELECT 
        d.id AS disc_id,
        d.title AS disc_title,
        d.barcode AS disc_barcode,
        d.release_year AS disc_release_year,
        d.number_of_copies AS disc_number_of_copies,
        d.genre AS disc_genre,
        d.disc_format AS disc_format,
        d.disc_status AS disc_status,
        a.stage_name AS artist_stage_name,
        l.label_name AS label_name
    FROM disc d
    JOIN artist a ON d.artist_id = a.id
    JOIN label l ON d.label_id = l.id
	WHERE d.collection_id = collection_id;
END$


-- FN 7
CREATE PROCEDURE get_disc_tracks(
    IN disc_id INT
)
BEGIN 
    SELECT
        t.id AS track_id,
        t.track_length AS track_length,
        t.title AS track_title
    FROM track t
    WHERE t.disc_id = disc_id;
END$


-- FN 8
-- TODO
-- FN 9
CREATE PROCEDURE is_collection_visible_by_collector(
    IN collection_id INT,
    IN collector_id INT
)
BEGIN
    SELECT
        CASE 
            WHEN 
                c.is_public OR 
                c.collector_id = collector_id OR 
                EXISTS (
                    SELECT *
                    FROM shared_collection sc
                    WHERE sc.collection_id = c.id AND sc.collector_id = collector_id
                )
            THEN TRUE
            ELSE FALSE 
        END AS is_visible 
    FROM collection c;
END$

-- FN 10

CREATE FUNCTION get_artist_id(
    artist_stage_name VARCHAR(100)
)
RETURNS INT DETERMINISTIC
BEGIN
    DECLARE artist_id INT;
    SET artist_id = (
        SELECT a.id
        FROM artist a
        WHERE a.stage_name LIKE artist_stage_name
    );
    RETURN artist_id;
END$


CREATE FUNCTION count_tracks_of_author_in_public_collections(
    artist_stage_name VARCHAR(100)
)
RETURNS INT DETERMINISTIC
BEGIN
    DECLARE artist_id INT;
    DECLARE number_of_tracks INT;
    SET artist_id = get_artist_id(artist_stage_name);
    IF (artist_id IS NULL) THEN
        SET error_message = CONCAT("Artist: ", artist_stage_name, " does not exist");
        SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = error_message;
    END IF;

    SET number_of_tracks = (
        SELECT COUNT(DISTINCT t.id)
        FROM track t
        JOIN track_contribution tc ON t.id = tc.track_id
        JOIN disc d ON t.disc_id = d.id
        JOIN collection c ON d.collection_id = c.id
        WHERE c.is_public = TRUE AND tc.artist_id = artist_id
    );
    IF (number_of_tracks IS NULL) THEN
        RETURN 0;
    ELSE 
        RETURN number_of_tracks;
    END IF;        
END$

-- FN 11
CREATE FUNCTION count_total_track_time_of_artist_in_public_collections(
    artist_stage_name VARCHAR(100)
)
RETURNS INT DETERMINISTIC
BEGIN
    DECLARE artist_id INT;
    DECLARE total_track_time INT;
    SET artist_id = get_artist_id(artist_stage_name);
    IF (artist_id IS NULL) THEN
        SET error_message = CONCAT("Artist: ", artist_stage_name, " does not exist");
        SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = error_message;
    END IF;

    SET total_track_time = (
        SELECT SUM(t.track_length)
        FROM track t
        JOIN track_contribution tc ON t.id = tc.track_id
        JOIN disc d ON t.disc_id = d.id
        JOIN collection c ON d.collection_id = c.id
        WHERE c.is_public = TRUE AND tc.artist_id = artist_id
    );
    IF (total_track_time IS NULL) THEN
        RETURN 0;
    ELSE 
        RETURN total_track_time;
    END IF;
END $

-- FN 12

CREATE PROCEDURE aggregate_number_of_collections_per_collector()
BEGIN
    SELECT
        collector.username AS collector_username,
        COUNT(c.id) AS number_of_collections
    FROM collection c
    RIGHT JOIN collector ON collector.id = c.collector_id
    GROUP BY collector.username;
END$

CREATE PROCEDURE aggregate_number_of_discs_per_genre()
BEGIN
    SELECT
        g.genre AS genre,
        COUNT(d.id) AS number_of_discs
    FROM disc d
    RIGHT JOIN genre g ON g.genre_name = d.genre
    GROUP BY d.genre;
END$

-- FN 13
CREATE PROCEDURE find_best_match_of_disc_from(
    IN barcode VARCHAR(50),
    IN title VARCHAR(100),
    IN artist_stage_name VARCHAR(100)
)
BEGIN
    SELECT
        d.id AS disc_id,
        d.title AS disc_title,
        d.barcode AS disc_barcode,
        d.release_year AS disc_release_year,
        d.number_of_copies AS disc_number_of_copies,
        d.genre AS disc_genre,
        d.disc_format AS disc_format,
        d.disc_status AS disc_status,
        a.stage_name AS artist_stage_name,
        l.label_name AS label_name
    FROM disc d
    JOIN artist a ON d.artist_id = a.id
    JOIN label l ON d.label_id = l.id
    WHERE d.barcode = COALESCE(barcode, d.barcode) OR d.title = title
    ORDER BY CASE 
        WHEN d.barcode = barcode THEN 1
        WHEN d.title = title AND a.stage_name = artist_stage_name THEN 2
        ELSE 3
    END, barcode ASC
    LIMIT 50;
END$

DELIMITER ;
