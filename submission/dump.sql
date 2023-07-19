CREATE DATABASE IF NOT EXISTS collectors;
USE collectors;

CREATE TABLE IF NOT EXISTS condition_status(
	condition_name VARCHAR(40) PRIMARY KEY 
);
CREATE TABLE IF NOT EXISTS artist_role(
	role_name VARCHAR(40) PRIMARY KEY
);
CREATE TABLE IF NOT EXISTS image_type(
	type_name VARCHAR(40) PRIMARY KEY
);
CREATE TABLE IF NOT EXISTS disc_genre(
	genre_name VARCHAR(40) PRIMARY KEY
);
CREATE TABLE IF NOT EXISTS disc_format(
	format_name VARCHAR(40) PRIMARY KEY
);
CREATE TABLE IF NOT EXISTS artist(
	id INT AUTO_INCREMENT PRIMARY KEY, 
    stage_name VARCHAR(100) UNIQUE NOT NULL, 
    artist_name VARCHAR(100) NOT NULL
);
CREATE TABLE IF NOT EXISTS label(
	id INT AUTO_INCREMENT PRIMARY KEY,
    label_name VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS collector(
	id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS collection(
	id INT AUTO_INCREMENT PRIMARY KEY,
    collection_name VARCHAR(100) NOT NULL, #collectin name is unique for the owner
    collector_id INT NOT NULL,
    is_public BOOLEAN NOT NULL,
    FOREIGN KEY (collector_id) REFERENCES collector(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE TABLE IF NOT EXISTS disc(
	id INT AUTO_INCREMENT PRIMARY KEY, 
    title VARCHAR(100) NOT NULL, 
    barcode VARCHAR(50),
    release_year INT NOT NULL, 
    number_of_copies INT NOT NULL, 
    genre VARCHAR(40) NOT NULL,
    disc_format VARCHAR(40) NOT NULL,
    label_id INT NOT NULL, 
    collection_id INT NOT NULL, 
    disc_status varchar(40) NOT NULL,
    artist_id INT NOT NULL,
    FOREIGN KEY (artist_id) REFERENCES artist(id)
		ON UPDATE CASCADE
        ON DELETE RESTRICT,
	FOREIGN KEY (disc_status) REFERENCES condition_status(condition_name)
		ON UPDATE CASCADE
        ON DELETE RESTRICT,
	FOREIGN KEY (collection_id) REFERENCES collection(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (label_id) REFERENCES label(id)
		ON UPDATE CASCADE
        ON DELETE RESTRICT,
	FOREIGN KEY (disc_format) REFERENCES disc_format(format_name)
		ON UPDATE CASCADE
        ON DELETE RESTRICT,
	FOREIGN KEY (genre) REFERENCES disc_genre(genre_name)
		ON UPDATE CASCADE
        ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS image(
	id INT AUTO_INCREMENT PRIMARY KEY,
    image_path VARCHAR(200) NOT NULL,
    image_format VARCHAR(40),
    disc_id INT NOT NULL,
    FOREIGN KEY (disc_id) REFERENCES disc(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (image_format) REFERENCES image_type(type_name) 
		ON UPDATE CASCADE 
        ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS shared_collection(
	collection_id INT NOT NULL,
    collector_id INT NOT NULL,
    FOREIGN KEY (collection_id) REFERENCES collection(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE,
	FOREIGN KEY (collector_id) REFERENCES collector(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE,
	PRIMARY KEY (collection_id, collector_id)
);
CREATE TABLE IF NOT EXISTS track(
	id INT AUTO_INCREMENT PRIMARY KEY,
    track_length INT NOT NULL,
    title VARCHAR(100) NOT NULL,
	disc_id INT NOT NULL,
    FOREIGN KEY (disc_id) REFERENCES disc(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS track_contribution(
	track_id INT NOT NULL,
	artist_id INT NOT NULL,
    contribution_type VARCHAR(40) NOT NULL,

	FOREIGN KEY (track_id) REFERENCES track(id)
		ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES artist(id)        
		ON UPDATE CASCADE
		ON DELETE CASCADE,
	FOREIGN KEY (contribution_type) REFERENCES artist_role(role_name)
		ON UPDATE CASCADE
        ON DELETE CASCADE,
	PRIMARY KEY (track_id, artist_id, contribution_type)
);

DELIMITER $

CREATE TRIGGER check_collection_uniqueness BEFORE INSERT ON collection FOR EACH ROW
BEGIN
	DECLARE number_of_collections INT;
    DECLARE collector_name varchar(100);
    DECLARE exists_collection BOOLEAN;
    DECLARE error_message varchar(200);
	SET exists_collection = (
		SELECT COUNT(*)
		FROM collection c
        WHERE c.collector_id = NEW.collector_id AND c.collection_name = NEW.collection_name
    );
	IF (number_of_collections > 0) THEN
		SET collector_name = (
			SELECT c.username
            FROM collector c
            WHERE c.id = NEW.collector_id
        );
        SET error_message = CONCAT("Collection: ", NEW.collection_name, " Already exists for collector: ", collector_name);
		SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = error_message;
    END IF;
END$

CREATE TRIGGER check_collection_share BEFORE INSERT ON shared_collection FOR EACH ROW
BEGIN
    DECLARE owner_id INT;
    DECLARE error_message VARCHAR(200);
    SET owner_id = (
        SELECT c.collector_id
        FROM collection c
        WHERE c.id = NEW.collection_id
    );
    IF (owner_id = NEW.collector_id) THEN
        SET error_message = CONCAT("Collector: ", NEW.collector_id, " is already the owner of collection: ", NEW.collection_id);
        SIGNAL SQLSTATE "45000" SET MESSAGE_TEXT = error_message;
    END IF;
END$

DELIMITER ;

INSERT INTO condition_status (condition_name) VALUES
    ('New'),
    ('Good'),
    ('Scratched'),
    ('Damaged');

INSERT INTO artist_role (role_name) VALUES
    ('Lead Singer'),
    ('Guitarist'),
    ('Bassist'),
    ('Drummer'),
    ('Keyboardist'),
    ('Producer'),
    ('Writer');
INSERT INTO image_type (type_name) VALUES
    ('Front'),
    ('Back'),
    ('Disc'),
    ('Booklet'),
    ('Other');

INSERT INTO disc_genre (genre_name) VALUES
    ('Rock'),
    ('Pop'),
    ('Metal'),
    ('Jazz'),
    ('Hip Hop'),
    ('Electronic'),
    ('Classical'),
    ('Country'),
    ('Indie'),
    ('Folk'),
    ('Rap');

INSERT INTO disc_format (format_name) VALUES
    ('Vinyl'),
    ('CD'),
    ('Cassette'),
    ('Digital');
INSERT INTO artist (stage_name, artist_name) VALUES
    ('Freddie Mercury', 'Freddie Mercury'),
    ('John Lennon', 'John Lennon'),
    ('Michael Jackson', 'Michael Jackson'),
    ('Elvis', 'Elvis Presley'),
    ('David Bowie', 'David Bowie'),
    ('Madonna', 'Madonna Louise Veronica');

INSERT INTO label (label_name) VALUES
    ('EMI'),
    ('Sony Music'),
    ('Warner Bros'),
    ('Universal Music'),
    ('Atlantic Records'),
    ('Columbia Records');

INSERT INTO collector (username, email) VALUES
    ('test-user', 'test-user@example.com'),
    ('vinyljunkie', 'vinyljunkie@example.com'),
    ('cdcollector', 'cdcollector@example.com'),
    ('metalhead88', 'metalhead88@example.com');

INSERT INTO collection (collection_name, collector_id, is_public) VALUES
    ('My Vinyl Collection', 1, 0),
    ('Favorite CDs', 3, 0),
    ('Metal Albums', 4, 1),
    ('Classic Rock', 2, 1),
    ('Madonna', 2, 0);


INSERT INTO shared_collection (collection_id, collector_id) VALUES
    (1, 2),
    (2, 1),
    (3, 3),
    (4, 1);

INSERT INTO disc (title, barcode, release_year, number_of_copies, genre, disc_format, label_id, collection_id, disc_status, artist_id) VALUES
    ('Bohemian Rhapsody', '1234567890', 1975, 1, 'Rock', 'Vinyl', 1, 1, 'New', 1),
    ('Thriller', '9876543210', 1982, 15, 'Pop', 'Vinyl', 2, 2, 'Good', 3),
    ('Black Album', '4567890123', 1991, 3, 'Metal', 'CD', 3, 3, 'Scratched', 4),
    ('Sgt. Pepper', '1111111111', 1967, 14, 'Rock', 'Vinyl', 4, 4, 'Good', 2),
    ('Like a Virgin', '2222222222', 1984, 8, 'Pop', 'CD', 5, 2, 'New', 6),
    ('Space Oddity', '3333333333', 1969, 4, 'Rock', 'Vinyl', 6, 4, 'Damaged', 5);

INSERT INTO image (image_path, image_format, disc_id) VALUES
    ('https://picsum.photos/500/500', 'Front', 1),
    ('https://picsum.photos/500/500', 'Back', 1),
    ('https://picsum.photos/500/500', 'Front', 2),
    ('https://picsum.photos/500/500', 'Back', 2),    
    ('https://picsum.photos/500/500', 'Front', 3),
    ('https://picsum.photos/500/500', 'Back', 4),    
    ('https://picsum.photos/500/500', 'Front', 4),
    ('https://picsum.photos/500/500', 'Back', 5);




INSERT INTO track (track_length, title, disc_id) VALUES
    (355, 'Bohemian Rhapsody', 1),
    (398, 'Another One Bites the Dust', 1),
    (402, 'Thriller', 2),
    (320, 'Beat It', 2),
    (500, 'Enter Sandman', 3),
    (312, 'Sad but True', 3),
    (177, 'Sgt. Pepper', 4),
    (52, 'With a Little Help from My Friends', 4),
    (389, 'Like a Virgin', 5),
    (322, 'Material Girl', 5),
    (312, 'Space Oddity', 6),
    (237, 'Starman', 6);

INSERT INTO track_contribution (track_id, artist_id, contribution_type) VALUES
    (1, 1, 'Lead Singer'),
    (1, 2, 'Guitarist'),
    (2, 1, 'Lead Singer'),
    (2, 2, 'Guitarist'),
    (3, 3, 'Lead Singer'),
    (4, 3, 'Lead Singer'),
    (5, 4, 'Lead Singer'),
    (5, 4, 'Guitarist'),
    (6, 4, 'Lead Singer'),
    (6, 4, 'Guitarist'),
    (7, 2, 'Lead Singer'),
    (7, 2, 'Guitarist'),
    (8, 2, 'Lead Singer'),
    (8, 2, 'Guitarist'),
    (9, 5, 'Lead Singer'),
    (10, 5, 'Lead Singer'),
    (11, 6, 'Lead Singer'),
    (12, 6, 'Lead Singer');

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


-- Other procedures for the GUI

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