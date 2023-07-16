DROP TABLE IF EXISTS track_contribution;
DROP TABLE IF EXISTS track;
DROP TABLE IF EXISTS disc;
DROP TABLE IF EXISTS shared_collection;
DROP TABLE IF EXISTS collection;
DROP TABLE IF EXISTS artist;
DROP TABLE IF EXISTS label;
DROP TABLE IF EXISTS collector;
DROP TABLE IF EXISTS image;
DROP TABLE IF EXISTS disc_genre;
DROP TABLE IF EXISTS disc_format;
DROP TABLE IF EXISTS condition_status;

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
CREATE TABLE IF NOT EXISTS image(
	id INT AUTO_INCREMENT PRIMARY KEY,
    image_path VARCHAR(200) NOT NULL,
    image_format VARCHAR(40),
    FOREIGN KEY (image_format) REFERENCES image_type(type_name) 
		ON UPDATE CASCADE 
        ON DELETE RESTRICT
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




