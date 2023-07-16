DROP TRIGGER IF EXISTS check_collection_uniqueness;
DROP TRIGGER IF EXISTS check_collection_share;
DELIMITER $

CREATE TRIGGER check_collection_uniqueness BEFORE INSERT ON collection FOR EACH ROW
BEGIN
	DECLARE number_of_collections INT;
    DECLARE collector_name varchar(100);
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