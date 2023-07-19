DROP PROCEDURE IF EXISTS create_collection;
DROP PROCEDURE IF EXISTS create_disc;
DROP PROCEDURE IF EXISTS create_track;
DROP PROCEDURE IF EXISTS set_collection_visibility;
DROP PROCEDURE IF EXISTS add_contributor_to_collection;
DROP PROCEDURE IF EXISTS remove_disc_from_collection;
DROP PROCEDURE IF EXISTS remove_collection;
DROP PROCEDURE IF EXISTS get_discs_of_collection;
DROP PROCEDURE IF EXISTS get_disc_tracks;
DROP PROCEDURE IF EXISTS aggregate_number_of_collections_per_collector;
DROP PROCEDURE IF EXISTS aggregate_number_of_discs_per_genre;
DROP PROCEDURE IF EXISTS find_best_match_of_disc_from;
DROP PROCEDURE IF EXISTS search_discs;
DROP FUNCTION IF EXISTS get_artist_id;
DROP FUNCTION IF EXISTS count_tracks_of_author_in_public_collections;
DROP FUNCTION IF EXISTS count_total_track_time_of_artist_in_public_collections;
DROP FUNCTION IF EXISTS is_collection_visible_by_collector;

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
    SELECT LAST_INSERT_ID() AS collection_id;
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
    SELECT LAST_INSERT_ID() AS disc_id;
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
	DECLARE collector_id INT;
	DECLARE error_message VARCHAR(200);
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
        l.label_name AS label_name,
        d.collection_id AS collection_id,
        l.id AS label_id,
        a.id AS artist_id
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
        t.title AS track_title,
        t.disc_id AS disc_id
    FROM track t
    WHERE t.disc_id = disc_id;
END$


-- FN 8 
CREATE PROCEDURE search_discs(
    IN search_disc_title VARCHAR(100),
    IN search_artist_stage_name VARCHAR(100),
    IN collector_id INT,
    IN search_in_owned_collections BOOLEAN,
    IN search_in_shared_collections BOOLEAN,
    IN search_in_public_collections BOOLEAN
)
BEGIN 
    DECLARE artist_id INT;
    SET artist_id = (
        SELECT a.id
        FROM artist a
        WHERE a.stage_name LIKE search_artist_stage_name
    );

    SELECT DISTINCT
        d.id AS disc_id,
        d.title AS disc_title,
        d.barcode AS disc_barcode,
        d.release_year AS disc_release_year,
        d.number_of_copies AS disc_number_of_copies,
        d.genre AS disc_genre,
        d.disc_format AS disc_format,
        d.disc_status AS disc_status,
        a.stage_name AS artist_stage_name,
        l.label_name AS label_name,
        d.collection_id AS collection_id,
        l.id AS label_id,
        a.id AS artist_id
    FROM disc d
    JOIN artist a ON d.artist_id = a.id
    JOIN label l ON d.label_id = l.id
    JOIN collection c ON d.collection_id = c.id
    LEFT JOIN shared_collection sc ON d.collection_id = sc.collection_id AND sc.collector_id = collector_id
    WHERE
        (d.title = COALESCE(search_disc_title, d.title)) AND 
        (d.artist_id = COALESCE(artist_id, d.artist_id)) AND 
        (
            (search_in_owned_collections AND c.collector_id = collector_id) OR
            (search_in_shared_collections AND sc.collector_id = collector_id) OR
            (search_in_public_collections AND c.is_public = TRUE)
        );
END$



-- FN 9 
CREATE FUNCTION is_collection_visible_by_collector(
    collection_id INT,
    collector_id INT
) 
RETURNS BOOLEAN DETERMINISTIC
BEGIN
    DECLARE is_visible BOOLEAN;
    SET is_visible = (SELECT
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
        END
    FROM collection c
    WHERE c.id = collection_id);
    IF (is_visible IS NULL) THEN
        RETURN FALSE;
    ELSE 
        RETURN is_visible;
    END IF;
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
	DECLARE error_message VARCHAR(200);
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
	DECLARE error_message VARCHAR(200);
    SET artist_id = get_artist_id(artist_stage_name);
    IF (artist_id IS NULL) THEN
        SET error_message = CONCAT("Artist: ", artist_stage_name, " does not exist");
        SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = error_message;
    END IF;

    SET total_track_time = (
        SELECT SUM(track_length)
        FROM (
            SELECT DISTINCT t.id, t.track_length
            FROM track t
            JOIN track_contribution tc ON t.id = tc.track_id
            JOIN disc d ON t.disc_id = d.id
            JOIN collection c ON d.collection_id = c.id
            WHERE c.is_public = TRUE AND tc.artist_id = artist_id
        ) AS unique_tracks
    );
    IF (total_track_time IS NULL) THEN
        RETURN 0;
    ELSE 
        RETURN total_track_time;
    END IF;
END$

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
        g.genre_name AS genre,
        COUNT(d.id) AS number_of_discs
    FROM disc d
    RIGHT JOIN disc_genre g ON g.genre_name = d.genre
    GROUP BY g.genre_name;
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
        l.label_name AS label_name,
        d.collection_id AS collection_id,
        l.id AS label_id,
        a.id AS artist_id
    FROM disc d
    JOIN artist a ON d.artist_id = a.id
    JOIN label l ON d.label_id = l.id
    WHERE d.barcode = barcode OR d.title LIKE CONCAT('%', title, '%')
    ORDER BY CASE 
        WHEN d.barcode = barcode THEN 1
        WHEN d.title LIKE CONCAT('%', title, '%') AND a.stage_name NOT LIKE CONCAT('%', artist_stage_name, '%') THEN 2
        WHEN d.title LIKE CONCAT('%', title, '%') AND a.stage_name LIKE CONCAT('%', artist_stage_name, '%') THEN 3
        ELSE 4
    END
    LIMIT 25;
END$


-- Other queries for the GUI
DROP PROCEDURE IF EXISTS get_collections_of_collector;
DROP PROCEDURE IF EXISTS get_visible_collections_of_collector;
DROP PROCEDURE IF EXISTS get_collection;
DROP PROCEDURE IF EXISTS get_collectors_of_collection;
DROP PROCEDURE IF EXISTS get_collector;
DROP PROCEDURE IF EXISTS get_disc;
DROP PROCEDURE IF EXISTS get_artist;
DROP PROCEDURE IF EXISTS get_images_of_disc;
DROP PROCEDURE IF EXISTS login_user;
DROP PROCEDURE IF EXISTS get_collector_by_mail;
DROP PROCEDURE IF EXISTS set_collector_in_collection;
DROP PROCEDURE IF EXISTS add_collector;
DROP PROCEDURE IF EXISTS get_track_contributors;
DROP PROCEDURE IF EXISTS get_track;
DROP PROCEDURE IF EXISTS get_genres;
DROP PROCEDURE IF EXISTS get_formats;
DROP PROCEDURE IF EXISTS get_conditions;
DROP PROCEDURE IF EXISTS get_image_types;
DROP PROCEDURE IF EXISTS get_artist_autocomplete;
DROP PROCEDURE IF EXISTS get_label_autocomplete;
DROP PROCEDURE IF EXISTS create_label;
DROP PROCEDURE IF EXISTS create_artist;
DROP PROCEDURE IF EXISTS create_image;
DROP PROCEDURE IF EXISTS get_artist_by_stage_name;
DROP PROCEDURE IF EXISTS remove_track;
DROP PROCEDURE IF EXISTS remove_disc;
DROP PROCEDURE IF EXISTS get_label;


CREATE PROCEDURE get_collections_of_collector(
    IN collector_id INT
)
BEGIN
    SELECT
        c.id AS collection_id,
        c.collection_name AS collection_name,
        c.is_public AS is_public,
        c.collector_id AS collector_id
    FROM collection c
    WHERE c.collector_id = collector_id;
END$
-- ----------------------------------
CREATE PROCEDURE get_visible_collections_of_collector(
    IN collector_id INT
)
BEGIN
    SELECT DISTINCT
        c.id AS collection_id,
        c.collection_name AS collection_name,
        c.is_public AS is_public,
        c.collector_id AS collector_id
    FROM collection c
    LEFT JOIN shared_collection sc ON c.id = sc.collection_id
    WHERE c.collector_id = collector_id OR c.is_public = TRUE;
END$
-- ----------------------------------
CREATE PROCEDURE get_collection(
    IN collection_id INT
)
BEGIN
    SELECT
        c.id AS collection_id,
        c.collection_name AS collection_name,
        c.is_public AS is_public,
        c.collector_id AS collector_id,
        co.username AS collector_username,
        co.email AS collector_email
    FROM collection c
    JOIN collector co ON c.collector_id = co.id
    WHERE c.id = collection_id;
END$
-- ----------------------------------
CREATE PROCEDURE get_collectors_of_collection(
    IN collection_id INT
)
BEGIN
    SELECT
        co.id AS collector_id,
        co.username AS collector_username,
        co.email AS collector_email
    FROM shared_collection sc
    JOIN collector co ON sc.collector_id = co.id
    WHERE sc.collection_id = collection_id;
END$
-- ----------------------------------
CREATE PROCEDURE get_collector(
    IN collector_id INT
)
BEGIN
    SELECT
        co.id AS collector_id,
        co.username AS collector_username,
        co.email AS collector_email
    FROM collector co
    WHERE co.id = collector_id;
END$
-- ----------------------------------
CREATE PROCEDURE get_disc(
    IN disc_id INT
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
        l.label_name AS label_name,
        d.collection_id AS collection_id,
        l.id AS label_id,
        a.id AS artist_id
    FROM disc d
    JOIN artist a ON d.artist_id = a.id
    JOIN label l ON d.label_id = l.id
    WHERE d.id = disc_id;
END$
-- ----------------------------------

CREATE PROCEDURE get_artist(
    IN artist_id INT
)
BEGIN
    SELECT
        a.id AS artist_id,
        a.stage_name AS artist_stage_name,
        a.artist_name AS artist_name
    FROM artist a
    WHERE a.id = artist_id;
END$
-- ----------------------------------
CREATE PROCEDURE get_images_of_disc(
    IN disc_id INT
)
BEGIN
    SELECT
        i.id AS image_id,
        i.image_path AS image_path,
        i.image_format AS image_format
    FROM image i
    WHERE i.disc_id = disc_id;
END$
-- ----------------------------------
CREATE PROCEDURE login_user(
    IN username VARCHAR(100),
    IN email VARCHAR(100)
)
BEGIN
    SELECT
        c.id AS collector_id,
        c.username AS collector_username,
        c.email AS collector_email
    FROM collector c
    WHERE c.username = username AND c.email = email;
END$
-- ----------------------------------
CREATE PROCEDURE get_collector_by_mail(
    IN email VARCHAR(100)
)
BEGIN
    SELECT
        c.id AS collector_id,
        c.username AS collector_username,
        c.email AS collector_email
    FROM collector c
    WHERE c.email = email;
END$
-- ----------------------------------
CREATE PROCEDURE set_collector_in_collection(
    IN collection_id INT,
    IN collector_id INT,
    IN is_part BOOLEAN
)
BEGIN
    IF (is_part) THEN
        INSERT IGNORE INTO shared_collection(collection_id, collector_id)
        VALUES (collection_id, collector_id);
    ELSE
        DELETE FROM shared_collection
        WHERE collection_id = collection_id AND collector_id = collector_id;
    END IF;
END$
-- ----------------------------------
CREATE PROCEDURE add_collector(
    IN username VARCHAR(100),
    IN email VARCHAR(100)
)
BEGIN
    INSERT IGNORE INTO collector(username, email)
    VALUES (username, email);
END$
-- ----------------------------------
CREATE PROCEDURE get_track_contributors(
    IN track_id INT
)
BEGIN
    SELECT

        tc.artist_id AS artist_id,
        tc.contribution_type AS contribution_type,
        a.stage_name AS artist_stage_name,
        a.artist_name AS artist_name
    FROM track_contribution tc
    JOIN artist a ON tc.artist_id = a.id
    WHERE tc.track_id = track_id;
END$
-- ----------------------------------
CREATE PROCEDURE get_track(
    IN track_id INT
)
BEGIN 
    SELECT 
        t.id AS track_id,
        t.track_length AS track_length,
        t.title AS track_title,
        t.disc_id AS disc_id
    FROM track t    
    WHERE t.id = track_id;
END$

-- ----------------------------------
CREATE PROCEDURE get_genres()
BEGIN
    SELECT
        g.genre_name AS genre_name
    FROM disc_genre g;
END$
-- ----------------------------------
CREATE PROCEDURE get_formats()
BEGIN
    SELECT
        f.format_name AS format_name
    FROM disc_format f;
END$
-- ----------------------------------
CREATE PROCEDURE get_conditions()
BEGIN
    SELECT
        c.condition_name AS condition_name
    FROM condition_status c;
END$
-- ----------------------------------
CREATE PROCEDURE get_image_types()
BEGIN
    SELECT
        i.type_name AS image_type_name
    FROM image_type i;
END$

-- ----------------------------------
CREATE PROCEDURE get_artist_autocomplete(
    IN search_text VARCHAR(100)
)
BEGIN
    SELECT
        a.stage_name AS artist_stage_name,
        a.artist_name AS artist_name,
        a.id AS artist_id
    FROM artist a
    WHERE a.stage_name LIKE CONCAT('%', search_text, '%') OR a.artist_name LIKE CONCAT('%', search_text, '%');
END$
-- ----------------------------------
CREATE PROCEDURE get_label_autocomplete(
    IN search_text VARCHAR(100)
)
BEGIN
    SELECT
        l.label_name AS label_name,
        l.id AS label_id
    FROM label l
    WHERE l.label_name LIKE CONCAT('%', search_text, '%');
END$
-- ----------------------------------
CREATE PROCEDURE create_label(
    IN label_name VARCHAR(100)
)
BEGIN
    INSERT IGNORE INTO label(label_name)
    VALUES (label_name);
END$
-- ----------------------------------
CREATE PROCEDURE create_artist(
    IN stage_name VARCHAR(100),
    IN artist_name VARCHAR(100)
)
BEGIN
    INSERT IGNORE INTO artist(stage_name, artist_name)
    VALUES (stage_name, artist_name);
END$
-- ----------------------------------
CREATE PROCEDURE create_image(
    IN image_path VARCHAR(200),
    IN image_format VARCHAR(40),
    IN disc_id INT
)
BEGIN
    INSERT INTO image(image_path, image_format, disc_id)
    VALUES (image_path, image_format, disc_id);
END$
-- ----------------------------------
CREATE PROCEDURE get_artist_by_stage_name(
    IN stage_name VARCHAR(100)
)
BEGIN
    SELECT
        a.id AS artist_id,
        a.stage_name AS artist_stage_name,
        a.artist_name AS artist_name
    FROM artist a
    WHERE a.stage_name = stage_name;
END$
-- ----------------------------------
CREATE PROCEDURE remove_track(
    IN track_id INT
)
BEGIN
    DELETE FROM track
    WHERE track.id = track_id;
END$
-- ----------------------------------
CREATE PROCEDURE remove_disc(
    IN disc_id INT
)
BEGIN
    DELETE FROM disc
    WHERE disc.id = disc_id;
END$

-- ----------------------------------
CREATE PROCEDURE get_label(
    IN label_id INT
)
BEGIN
    SELECT
        l.id AS label_id,
        l.label_name AS label_name
    FROM label l
    WHERE l.id = label_id;
END$

DELIMITER ;
