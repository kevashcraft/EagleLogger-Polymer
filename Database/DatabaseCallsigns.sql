DROP TABLE IF EXISTS FCCCallsigns;
CREATE TABLE FCCCallsigns (
	FCCCallsignID INT UNSIGNED AUTO_INCREMENT,
	FCCCallsignTSC DATETIME,
	FCCCallsignTSU TIMESTAMP,
	FCCCallsignULSID INT UNSIGNED,
	FCCCallsign VARCHAR(16),
	FCCCallsignDateIssued DATE,
	FCCCallsignDateExpired DATE,
	FCCCallsignFirstName VARCHAR(32),
	FCCCallsignLastName VARCHAR(32),
	FCCCallsignMiddleName VARCHAR(32),
	FCCCallsignStreetAddress VARCHAR(128),
	ZipCodeID INT UNSIGNED,
	FCCCallsignIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( FCCCallsignID ),
	FOREIGN KEY (ZipCodeID) REFERENCES ZipCodes (ZipCodeID)
) ENGINE InnoDB;
CREATE INDEX Index_FCCCallsign ON FCCCallsigns (FCCCallsign);
CREATE INDEX Index_FCCCallsignULSID ON FCCCallsigns (FCCCallsignULSID);

DROP TABLE IF EXISTS Callsigns;
CREATE TABLE Callsigns (
	CallsignID INT UNSIGNED AUTO_INCREMENT,
	CallsignTSC DATETIME,
	CallsignTSU TIMESTAMP,
	Callsign VARCHAR(16),
	CallsignName VARCHAR(32),
	CallsignRadio VARCHAR(64),
	CallsignAntenna VARCHAR(64),
	ZipCodeID INT UNSIGNED,
	CallsignIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( CallsignID ),
	FOREIGN KEY (ZipCodeID) REFERENCES ZipCodes (ZipCodeID)
) ENGINE InnoDB;
CREATE INDEX Index_Callsign ON Callsigns (Callsign);
CREATE INDEX Index_CallsignName ON Callsigns (CallsignName);

DROP TABLE IF EXISTS Officials;
CREATE TABLE Officials (
	OfficialID INT UNSIGNED AUTO_INCREMENT,
	OfficialTSC DATETIME,
 	OfficialTSU TIMESTAMP,
	OfficialTitle VARCHAR(64),
	OfficialIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( OfficialID )
) ENGINE InnoDB;

DROP TABLE IF EXISTS OfficialCallsigns;
CREATE TABLE OfficialCallsigns (
	OfficialCallsignID INT UNSIGNED AUTO_INCREMENT,
	OfficialCallsignTSC DATETIME,
	OfficialCallsignTSU TIMESTAMP,
	OfficialID INT UNSIGNED,
	CallsignID INT UNSIGNED,	
	OfficialCallsignIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( OfficialCallsignID ),
	FOREIGN KEY (CallsignID) REFERENCES Callsigns (CallsignID),
	FOREIGN KEY (OfficialID) REFERENCES Officials (OfficialID)
) ENGINE InnoDB;

DROP VIEW IF EXISTS OfficialTitlesView;
CREATE VIEW OfficialTitlesView AS
	SELECT
			OfficialCallsigns.CallsignID,
			GROUP_CONCAT(Officials.OfficialTitle SEPARATOR ', ') AS OfficialTitles
		FROM OfficialCallsigns
		LEFT JOIN Officials USING (OfficialID);
	

DROP VIEW IF EXISTS CallsignsView;
CREATE VIEW CallsignsView AS
	SELECT
			Callsigns.CallsignID,
			Callsigns.CallsignTSC,
			Callsigns.CallsignTSU,
			Callsigns.Callsign,
			Callsigns.CallsignName,
			Callsigns.CallsignRadio,
			Callsigns.CallsignAntenna,
			Callsigns.CallsignIsValid,
			(
				SELECT
						GROUP_CONCAT(Officials.OfficialTitle SEPARATOR ', ')
					FROM OfficialCallsigns
					LEFT JOIN Officials USING(OfficialID)
					WHERE OfficialCallsigns.CallsignID = Callsigns.CallsignID
			) AS OfficialTitles,
			IF(Callsigns.CallsignIsValid, 1, NULL) CallsignIsValidNullified,
			ZipCodesView.*
		FROM Callsigns
		LEFT JOIN ZipCodesView USING (ZipCodeID)
		ORDER BY Callsign;

DROP VIEW IF EXISTS CallsignsList;
CREATE VIEW CallsignsList AS
	SELECT
			*
		FROM CallsignsView
		WHERE CallsignIsValid;

DROP VIEW IF EXISTS FCCCallsignsView;
CREATE VIEW FCCCallsignsView AS
	SELECT
			FCCCallsigns.FCCCallsignID,
			FCCCallsigns.FCCCallsignTSC,
			FCCCallsigns.FCCCallsignTSU,
			FCCCallsigns.FCCCallsignULSID,
			FCCCallsigns.FCCCallsign,
			FCCCallsigns.FCCCallsignDateIssued,
			FCCCallsigns.FCCCallsignDateExpired,
			FCCCallsigns.FCCCallsignFirstName,
			CONCAT(
				UCASE(
					LEFT(FCCCallsigns.FCCCallsignFirstName, 1)),
				LCASE(
					SUBSTRING(FCCCallsigns.FCCCallsignFirstName, 2))) AS FCCCallsignFirstNameFormatted,
			FCCCallsigns.FCCCallsignLastName,
			FCCCallsigns.FCCCallsignMiddleName,
			FCCCallsigns.FCCCallsignStreetAddress,
			FCCCallsigns.FCCCallsignIsValid,
			IF(FCCCallsigns.FCCCallsignIsValid, 1, NULL) AS FCCCallsignIsValidNullified,
			ZipCodesView.*
		FROM FCCCallsigns
		LEFT JOIN ZipCodesView USING (ZipCodeID)
		ORDER BY FCCCallsigns.FCCCallsign;

DROP VIEW IF EXISTS FCCCallsignsList;
CREATE VIEW FCCCallsignsList AS
	SELECT
			*
		FROM FCCCallsignsView
		WHERE FCCCallsignIsValid;


DROP VIEW IF EXISTS OfficialsView;
CREATE VIEW OfficialsView AS
	SELECT
			Officials.OfficialID,
			Officials.OfficialTSC,
			Officials.OfficialTSU,
			Officials.OfficialTitle,
			Officials.OfficialIsValid,
			IF(Officials.OfficialIsValid, 1, NULL) AS OfficialIsValidNullified
		FROM Officials;
	
DROP VIEW IF EXISTS OfficialsList;
CREATE VIEW OfficialsList AS
	SELECT
			*
		FROM OfficialsView
		WHERE OfficialIsValid
		ORDER BY OfficialTitle;


DROP PROCEDURE IF EXISTS CallsignsAC;
DELIMITER //
CREATE PROCEDURE CallsignsAC	(
																IN _query VARCHAR(16),
																IN _ACID INT UNSIGNED
															)
BEGIN
	CASE
		WHEN _ACID IS NULL THEN
			SET @Query = CONCAT('%', _query, '%');
			SELECT
					CONCAT(IFNULL(CONCAT(CallsignName, ' - '),''), Callsign) AS ACName,
					CallsignID AS ACID
				FROM CallsignsList
				WHERE
					(CallsignName LIKE @Query)
					OR
					(Callsign LIKE @Query)
				LIMIT 15;
		ELSE
			SELECT
					CONCAT(CallsignName, ' - ', Callsign) AS ACName,
					CallsignID AS ACID
				FROM CallsignsList
				WHERE CallsignID = _ACID;
	END CASE;
END//
DELIMITER ;



DROP PROCEDURE IF EXISTS CallsignInfo;
DELIMITER //
CREATE PROCEDURE CallsignInfo	( IN _CallsignID INT UNSIGNED )
BEGIN
	DROP TABLE IF EXISTS _Callsign;
	CREATE TEMPORARY TABLE _Callsign AS
		SELECT * FROM CallsignsView WHERE CallsignID = _CallsignID;

	DROP TABLE IF EXISTS _OfficialIDs;
	CREATE TEMPORARY TABLE _OfficialIDs AS
		SELECT
				OfficialID
			FROM _Callsign
			LEFT JOIN OfficialCallsigns USING (CallsignID);

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS FCCCallsignInfo;
DELIMITER //
CREATE PROCEDURE FCCCallsignInfo	( IN _Callsign VARCHAR(12) )
BEGIN
	SELECT
			*
		FROM FCCCallsignsList
		WHERE FCCCallsign = _Callsign
		AND FCCCallsignDateExpired > NOW();
END//
DELIMITER ;








INSERT INTO Officials (OfficialTitle) VALUES ('Sunday NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Monday NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Tuesday NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Wednesday NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Thursday NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Friday NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Saturday NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Alternate NCS');

INSERT INTO Officials (OfficialTitle) VALUES ('Section Manager');

INSERT INTO Officials (OfficialTitle) VALUES ('Public Information Officer');

INSERT INTO Officials (OfficialTitle) VALUES ('Section Youth Coordination');

INSERT INTO Officials (OfficialTitle) VALUES ('Technical Specialist');

INSERT INTO Officials (OfficialTitle) VALUES ('Official Relay Station');



