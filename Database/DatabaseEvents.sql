DROP TABLE IF EXISTS Events;
DROP TABLE IF EXISTS EventTypes;


CREATE TABLE EventTypes (
	EventTypeID TINYINT UNSIGNED,
	EventType VARCHAR(32),
	PRIMARY KEY ( EventTypeID )
) ENGINE InnoDB;



CREATE TABLE Events (
	EventID INT UNSIGNED AUTO_INCREMENT,
	EventTSC DATETIME,
	EventTSU TIMESTAMP,
	EventTypeID TINYINT UNSIGNED,
	EventData TEXT,
	PRIMARY KEY ( EventID ),
	FOREIGN KEY (EventTypeID) REFERENCES EventTypes (EventTypeID)
) ENGINE InnoDB;


DROP VIEW IF EXISTS EventsView;
CREATE VIEW EventsView AS
	SELECT
			Events.*,
			EventTypes.EventType
		FROM Events
		LEFT JOIN EventTypes USING ( EventTypeID )
		ORDER BY EventID ASC;
	


DROP VIEW IF EXISTS EventsList;
CREATE VIEW EventsList AS
	SELECT
			*
		FROM EventsView
		WHERE EventTSC > NOW() - INTERVAL 1 HOUR;



DROP PROCEDURE IF EXISTS EventAdd;
DELIMITER //
CREATE PROCEDURE EventAdd	( IN _EventTypeID INT UNSIGNED, IN _EventData TEXT )
BEGIN
	INSERT INTO Events ( EventTSC, EventTypeID, EventData ) VALUES ( NOW(), _EventTypeID, _EventData );
END//
DELIMITER ;



-- EVENT TYPES
INSERT INTO EventTypes ( EventTypeID, EventType ) VALUES ( 10, 'CheckinAdded' );
INSERT INTO EventTypes ( EventTypeID, EventType ) VALUES ( 80, 'ChatMessage' );
