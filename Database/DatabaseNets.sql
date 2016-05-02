set foreign_key_checks=0;
DROP TABLE IF EXISTS Checkins;
DROP TABLE IF EXISTS Nets;
DROP TABLE IF EXISTS NetTemplates;
DROP TABLE IF EXISTS NetTypes;

CREATE TABLE NetTypes (
	NetTypeID INT UNSIGNED,
	NetTypeTSC DATETIME,
	NetTypeTSU TIMESTAMP,
	NetType VARCHAR(64),
	NetTypeIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( NetTypeID )
) ENGINE InnoDB;
CREATE INDEX Index_NetType ON NetTypes (NetType);	


CREATE TABLE NetTemplates (
	NetTemplateID INT UNSIGNED AUTO_INCREMENT,
	NetTemplateTSC DATETIME,
	NetTemplateTSU TIMESTAMP,
	NetTemplateName VARCHAR(64) NOT NULL,
	NetTemplateFrequency DECIMAL(7,3) NOT NULL,
	NetTemplateTime TIME,
	NetTemplateIsValid BOOLEAN DEFAULT 1,
	NetTypeID INT UNSIGNED,
	PRIMARY KEY ( NetTemplateID ),
	FOREIGN KEY (NetTypeID) REFERENCES NetTypes (NetTypeID)
) ENGINE InnoDB;
CREATE INDEX Index_NetTemplate ON NetTemplates (NetTemplateName);


CREATE TABLE Nets (
	NetID INT UNSIGNED AUTO_INCREMENT,
	NetTSC DATETIME,
	NetTSU TIMESTAMP,
	NetDate DATE,
	NetTime TIME,
	NetTemplateID INT UNSIGNED,
	NetNCSCallsignID INT UNSIGNED,
	NetStartDate DATETIME,
	NetEndDate DATETIME,
	NetIsActive BOOLEAN DEFAULT 1,
	NetURL VARCHAR(64),
	NetIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( NetID ),
	UNIQUE KEY (NetURL),
	FOREIGN KEY (NetTemplateID) REFERENCES NetTemplates (NetTemplateID),
	FOREIGN KEY (NetNCSCallsignID) REFERENCES Callsigns (CallsignID)
) ENGINE InnoDB;
CREATE INDEX Index_NetURL ON Nets (NetURL);


CREATE TABLE Checkins (
	CheckinID INT UNSIGNED AUTO_INCREMENT,
	CheckinTSC DATETIME,
	CheckinTSU TIMESTAMP,
	NetID INT UNSIGNED,
	CallsignID INT UNSIGNED,
	CheckinHasTraffic BOOLEAN DEFAULT 0,
	CheckinHasSecured BOOLEAN DEFAULT 0,
	CheckinIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( CheckinID ),
	FOREIGN KEY (CallsignID) REFERENCES Callsigns (CallsignID),
	FOREIGN KEY (NetID) REFERENCES Nets (NetID)
) ENGINE InnoDB;


DROP VIEW IF EXISTS CheckinsView;
CREATE VIEW CheckinsView AS
	SELECT
			Checkins.CheckinID,
			Checkins.CheckinTSC,
			Checkins.CheckinTSU,
			Checkins.NetID,
			Checkins.CheckinHasTraffic,
			IF(Checkins.CheckinHasTraffic, 1, NULL) AS CheckinHasTrafficNullified,
			Checkins.CheckinHasSecured,
			IF(Checkins.CheckinHasSecured, 1, NULL) AS CheckinHasSecuredNullified,
			Checkins.CheckinIsValid,
			IF(Checkins.CheckinIsValid, 1, NULL) AS CheckinIsValidNullified,
			CallsignsList.*
		FROM Checkins
		LEFT JOIN CallsignsList USING (CallsignID);

DROP VIEW IF EXISTS CheckinsList;
CREATE VIEW CheckinsList AS
	SELECT
			*
		FROM CheckinsView
		WHERE CheckinIsValid;



DROP VIEW IF EXISTS NetTemplatesView;
CREATE VIEW NetTemplatesView AS
	SELECT
			NetTemplates.NetTemplateID,
			NetTemplates.NetTemplateTSC,
			NetTemplates.NetTemplateTSU,
			NetTemplates.NetTemplateName,
			NetTemplates.NetTemplateFrequency,
			NetTemplates.NetTemplateTime,
			NetTemplates.NetTemplateIsValid,
			IF(NetTemplates.NetTemplateIsValid, 1, NULL) AS NetTemplateIsValidNullified
		FROM NetTemplates
		ORDER BY NetTemplateName;

DROP VIEW IF EXISTS NetTemplatesList;
CREATE VIEW NetTemplatesList AS
	SELECT * FROM NetTemplatesView
		WHERE NetTemplateIsValid;


DROP VIEW IF EXISTS NetsView;
CREATE VIEW NetsView AS
	SELECT
			Nets.NetID,
			Nets.NetTSC,
			Nets.NetTSU,
			Nets.NetDate,
			DAYNAME(Nets.NetDate) AS NetDateDayName,
			DATE_FORMAT(CONCAT(Nets.NetDate, ' ', NetTemplatesView.NetTemplateTime), '%W %b %D %I:%i%p') AS NetDateFormatted,
			Nets.NetNCSCallsignID,
			Nets.NetIsActive,
			Nets.NetStartDate,
			Nets.NetEndDate,
			Nets.NetURL,
			Nets.NetIsValid,
			IF(Nets.NetIsValid, 1, NULL) AS NetIsValidNullified,
			NetTemplatesView.*
		FROM Nets
		LEFT JOIN NetTemplatesView USING (NetTemplateID)
		ORDER BY NetTemplateName;

DROP VIEW IF EXISTS NetsList;
CREATE VIEW NetsList AS
	SELECT
			*
		FROM NetsView
		WHERE NetIsValid;

DROP VIEW IF EXISTS NetTypesView;
CREATE VIEW NetTypesView AS
	SELECT
			NetTypes.NetTypeID,
			NetTypes.NetTypeTSC,
			NetTypes.NetTypeTSU,
			NetTypes.NetType,
			NetTypes.NetTypeIsValid,
			IF(NetTypes.NetTypeIsValid, 1, NULL) AS NetTypeIsValidNullified
		FROM NetTypes
		ORDER BY NetTypeID;

DROP VIEW IF EXISTS NetTypesList;
CREATE VIEW NetTypesList AS
	SELECT
			*
		FROM NetTypesView
		WHERE NetTypeIsValid;


DROP PROCEDURE IF EXISTS CheckinAdd;
DELIMITER //
CREATE PROCEDURE CheckinAdd	(
															IN _NetID INT UNSIGNED,
															IN _CallsignID INT UNSIGNED,
															IN _Callsign VARCHAR(16),
															IN _CallsignName VARCHAR(36),
															IN _OfficialIDsCSL TEXT,
															IN _ZipCodeID INT UNSIGNED
														)
BEGIN

	SET @Callsign = TRIM(IFNULL(_Callsign, ''));
	CASE
		WHEN _CallsignID IS NOT NULL OR _Callsign != '' THEN
			CASE
				WHEN _CallsignID IS NULL THEN
					SELECT CallsignID INTO @CallsignID FROM CallsignsList WHERE Callsign LIKE @Callsign;
					CASE
						WHEN @CallsignID IS NULL THEN
							INSERT INTO Callsigns (
									Callsign, CallsignName, ZipCodeID
								) VALUES (
									UPPER(@Callsign), _CallsignName, _ZipCodeID
								);
							SELECT LAST_INSERT_ID() INTO @CallsignID;
						ELSE
							UPDATE Callsigns
								SET
										CallsignName = _CallsignName,
										ZipCodeID = _ZipCodeID
									WHERE CallsignID = @CallsignID;
					END CASE;
				ELSE
					UPDATE Callsigns
						SET
								CallsignName = _CallsignName,
								ZipCodeID = _ZipCodeID
							WHERE CallsignID = _CallsignID;
					SET @CallsignID = _CallsignID;
			END CASE;


			CASE
				WHEN (SELECT COUNT(*) FROM CheckinsList WHERE CallsignID = @CallsignID AND NetID = _NetID) > 0 THEN
					SET @Error = 'Callsign already checked in';
				ELSE

					DELETE FROM OfficialCallsigns WHERE CallsignID = @CallsignID;

					add_officials:
						LOOP
							IF _OfficialIDsCSL = '' OR _OfficialIDsCSL = ',' OR _OfficialIDsCSL IS NULL THEN
								LEAVE add_officials;
							END IF;
							SET @OfficialID = SUBSTRING_INDEX(_OfficialIDsCSL, ',', 1);
							SET _OfficialIDsCSL = SUBSTRING(_OfficialIDsCSL, CHAR_LENGTH(@OfficialID) + 2);
							INSERT INTO OfficialCallsigns (
									OfficialID, CallsignID
								) VALUES (
									@OfficialID, @CallsignID
								);
						END LOOP add_officials;

					SET @Error = 'NONE';
					INSERT INTO Checkins (
							NetID, CallsignID
						) VALUES (
							_NetID, @CallsignID
						);
					CALL EventAdd(10, _NetID);
			END CASE;
		ELSE
			SET @Error = 'Cannot checkin empty callsign';
	END CASE;


END//
DELIMITER ;


DROP PROCEDURE IF EXISTS CheckinInfo;
DELIMITER //
CREATE PROCEDURE CheckinInfo	( IN _CheckinID INT UNSIGNED )
BEGIN
	DROP TABLE IF EXISTS _Checkin;
	CREATE TEMPORARY TABLE _Checkin AS
		SELECT * FROM CheckinsView WHERE CheckinID = _CheckinID;

	DROP TABLE IF EXISTS _OfficialIDs;
	CREATE TEMPORARY TABLE _OfficialIDs AS
		SELECT
				OfficialID
			FROM _Checkin
			LEFT JOIN OfficialCallsigns USING (CallsignID);

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS CheckinUpdate;
DELIMITER //
CREATE PROCEDURE CheckinUpdate	(
																		IN _CheckinID INT UNSIGNED,
																		IN _CallsignName VARCHAR(36),
																		IN _OfficialIDsCSL TEXT,
																		IN _ZipCodeID INT UNSIGNED,
																		IN _CheckinIsValid BOOLEAN
																)
BEGIN
	
	SELECT NetID INTO @NetID FROM Checkins WHERE CheckinID = _CheckinID;

	UPDATE Checkins
		LEFT JOIN Callsigns USING (CallsignID)
		SET
			Callsigns.CallsignName = _CallsignName,
			Callsigns.ZipCodeID = _ZipCodeID,
			Checkins.CheckinIsValid = IF(!_CheckinIsValid, 0, 1)
		WHERE CheckinID = _CheckinID;

	SELECT CallsignID INTO @CallsignID FROM Checkins WHERE CheckinID = _CheckinID;

	DELETE FROM OfficialCallsigns WHERE CallsignID = @CallsignID;

	add_officials:
		LOOP
			IF _OfficialIDsCSL = '' OR _OfficialIDsCSL = ',' OR _OfficialIDsCSL IS NULL THEN
				LEAVE add_officials;
			END IF;
			SET @OfficialID = SUBSTRING_INDEX(_OfficialIDsCSL, ',', 1);
			SET _OfficialIDsCSL = SUBSTRING(_OfficialIDsCSL, CHAR_LENGTH(@OfficialID) + 2);
			INSERT INTO OfficialCallsigns (
					OfficialID, CallsignID
				) VALUES (
					@OfficialID, @CallsignID
				);
		END LOOP add_officials;


	CALL EventAdd(10, @NetID);
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS CheckinsListForNet;
DELIMITER //
CREATE PROCEDURE CheckinsListForNet	( IN _NetID INT UNSIGNED )
BEGIN
	SELECT
			*
		FROM CheckinsList
		LEFT JOIN Nets USING (NetID)
		WHERE NetID = _NetID
		ORDER BY
			CASE WHEN Nets.NetIsActive THEN CheckinID END DESC,
			CASE WHEN !Nets.NetIsActive THEN CheckinID END ASC;
END//
DELIMITER ;



DROP PROCEDURE IF EXISTS NetAdd;
DELIMITER //
CREATE PROCEDURE NetAdd	(
													IN _NetTemplateID INT UNSIGNED,
													IN _NetDate DATE,
													IN _NetTime TIME
												)
BEGIN


	-- Sanitize name for url - remove non alpha-numeric characters, ussing AAAAAAAA as a place holder for
	-- a space which is then replaced by an underscore
	SET @NetName = 
		REPLACE(
			STRIP_NON_ALPHA(
				REPLACE(
					(SELECT NetTemplateName FROM NetTemplates WHERE NetTemplateID = _NetTemplateID),
					' ',
					'AAAAAAAA'
				)
			),
			'AAAAAAAA',
			'_'
		);

	SET @NetURL = CONCAT(@NetName, '-', MONTHNAME(NOW()), '-', DAY(NOW()), '-', YEAR(NOW()));

	SET @NetNCSCallsignID = (
		SELECT
				SiteUsers.CallsignID
			FROM SiteTokens
			LEFT JOIN SiteUsers USING (SiteUserID)
			WHERE SiteTokenID = @SiteTokenID
	  );

	CASE
		WHEN (SELECT NetURL FROM Nets WHERE NetURL LIKE @NetURL) IS NULL THEN
			SELECT LAST_INSERT_ID(0);
			INSERT INTO Nets (
					NetTSC, NetDate, NetTime, NetTemplateID, NetNCSCallsignID, NetURL
				) VALUES (
					NOW(), _NetDate, _NetTime, _NetTemplateID, @NetNCSCallsignID, @NetURL
				);
			SET @Error = IF(LAST_INSERT_ID() > 0, "NONE", 'Could not add net');
		ELSE
			SET @Error = 'Net URL already exists';
	END CASE;

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS NetTemplateAdd;
DELIMITER //
CREATE PROCEDURE NetTemplateAdd	(
																		IN _NetTemplateName VARCHAR(64),
																		IN _NetTemplateFrequency DECIMAL(7, 3),
																		IN _NetTemplateTime TIME,
																		IN _NetTypeID INT UNSIGNED
																)
BEGIN

	CASE
		WHEN (SELECT NetTemplateID FROM NetTemplates WHERE NetTemplateName LIKE _NetTemplateName) IS NULL THEN
			SELECT LAST_INSERT_ID(0);
			INSERT INTO NetTemplates (
					NetTemplateTSC, NetTemplateName, NetTemplateFrequency, NetTemplateTime, NetTypeID
				) VALUES ( NOW(), _NetTemplateName, _NetTemplateFrequency, _NetTemplateTime, _NetTypeID);
			SET @NetTemplateID = LAST_INSERT_ID();
			SET @Error = IF(LAST_INSERT_ID() > 0, "NONE", 'Could not create template');
		ELSE
			SET @Error = "Name already exists in database";
	END CASE;

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS NetInfo;
DELIMITER //
CREATE PROCEDURE NetInfo	( IN _NetID INT UNSIGNED )
BEGIN

		SELECT
				*
			FROM NetsList
			WHERE NetID LIKE _NetID;

END//
DELIMITER ;



DROP PROCEDURE IF EXISTS NetInfoFromURL;
DELIMITER //
CREATE PROCEDURE NetInfoFromURL	( IN _NetURL VARCHAR(64) )
BEGIN

		SELECT
				*
			FROM NetsList
			WHERE NetURL LIKE _NetURL;

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS NetInfoUpdate;
DELIMITER //
CREATE PROCEDURE NetInfoUpdate	(
																	IN _NetID INT UNSIGNED,
																	IN _NetIsActive BOOLEAN
																)
BEGIN
	UPDATE Nets
		SET
				NetIsActive = _NetIsActive
			WHERE NetID = _NetID;

	CALL EventAdd(20, _NetID);

END//
DELIMITER ;




INSERT INTO NetTypes (NetTypeID, NetType)
	VALUES (10, 'General');

INSERT INTO NetTypes (NetTypeID, NetType)
	VALUES (20, 'NTS');

INSERT INTO NetTypes (NetTypeID, NetType)
	VALUES (30, 'SKYWARN');



set foreign_key_checks=1;
