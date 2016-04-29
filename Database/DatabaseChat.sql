
DROP TABLE IF EXISTS ChatMessages;
CREATE TABLE ChatMessages (
	ChatMessageID INT UNSIGNED AUTO_INCREMENT,
	ChatMessageTSC DATETIME,
	ChatMessageTSU TIMESTAMP,
	ChatMessage TEXT,
	SiteUserID INT UNSIGNED,
	NetID INT UNSIGNED,
	ChatMessageIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( ChatMessageID ),
	FOREIGN KEY (SiteUserID) REFERENCES SiteUsers (SiteUserID),
	FOREIGN KEY (NetID) REFERENCES Nets (NetID)
) ENGINE InnoDB;

DROP VIEW IF EXISTS ChatMessagesView;
CREATE VIEW ChatMessagesView AS
	SELECT
			ChatMessages.ChatMessageID,
			ChatMessages.ChatMessageTSC,
			ChatMessages.ChatMessageTSU,
			ChatMessages.ChatMessage,
			ChatMessages.SiteUserID,
			ChatMessages.NetID,
			ChatMessages.ChatMessageIsValid,
			Callsigns.Callsign
		FROM ChatMessages
		LEFT JOIN SiteUsers USING (SiteUserID)
		LEFT JOIN Callsigns USING (CallsignID);

DROP VIEW IF EXISTS ChatMessagesList;
CREATE VIEW ChatMessagesList AS
	SELECT
			*
		FROM ChatMessagesView
		WHERE ChatMessageIsValid;

DROP PROCEDURE IF EXISTS ChatMessagesForNet;
DELIMITER //
CREATE PROCEDURE ChatMessagesForNet	( IN _NetID INT UNSIGNED )
BEGIN
	SELECT * FROM ChatMessagesList WHERE NetID = _NetID;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS ChatMessageNew;
DELIMITER //
CREATE PROCEDURE ChatMessageNew	(
																	IN _NetID INT UNSIGNED,
																	IN _ChatMessage TEXT
																)
BEGIN

	SELECT SiteUserID INTO @SiteUserID FROM SiteTokens WHERE SiteTokenID = @SiteTokenID;

	INSERT INTO ChatMessages (
			ChatMessageTSC, SiteUserID, NetID, ChatMessage
		) VALUES (
			NOW(), @SiteUserID, _NetID, _ChatMessage
		);

	SET @ChatMessageID = LAST_INSERT_ID();

	CALL EventAdd(80, _NetID);
END//
DELIMITER ;
















