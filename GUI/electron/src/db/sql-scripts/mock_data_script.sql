
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE track_contribution;
TRUNCATE TABLE track;
TRUNCATE TABLE disc;
TRUNCATE TABLE shared_collection;
TRUNCATE TABLE collection;
TRUNCATE TABLE artist;
TRUNCATE TABLE label;
TRUNCATE TABLE collector;
TRUNCATE TABLE image;
TRUNCATE TABLE disc_genre;
TRUNCATE TABLE disc_format;
TRUNCATE TABLE condition_status;
SET FOREIGN_KEY_CHECKS = 1;

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
    ('DJ'),
    ('Producer'),
    ('Backup Singer');

INSERT INTO image_type (type_name) VALUES
    ('Front Image'),
    ('Back Image');

INSERT INTO disc_genre (genre_name) VALUES
    ('Rock'),
    ('Pop'),
    ('Metal'),
    ('Jazz'),
    ('Hip Hop'),
    ('Electronic'),
    ('Classical'),
    ('Country');

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
    ('musiclover123', 'musiclover123@example.com'),
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

INSERT INTO image (image_path, image_format) VALUES
    ('/images/bohemian_rhapsody_front.jpg', 'Front Image'),
    ('/images/bohemian_rhapsody_back.jpg', 'Back Image'),
    ('/images/thriller_front.jpg', 'Front Image'),
    ('/images/thriller_back.jpg', 'Back Image'),
    ('/images/black_album_front.jpg', 'Front Image'),
    ('/images/black_album_back.jpg', 'Back Image'),
    ('/images/sgt_pepper_front.jpg', 'Front Image'),
    ('/images/sgt_pepper_back.jpg', 'Back Image'),
    ('/images/like_a_virgin_front.jpg', 'Front Image'),
    ('/images/like_a_virgin_back.jpg', 'Back Image'),
    ('/images/space_oddity_front.jpg', 'Front Image'),
    ('/images/space_oddity_back.jpg', 'Back Image');

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
