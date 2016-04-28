DROP TABLE IF EXISTS SiteTokens;
CREATE TABLE SiteTokens (
	SiteTokenID INT UNSIGNED NOT NULL AUTO_INCREMENT,
	SiteTokenTSC DATETIME,
	SiteTokenTSU TIMESTAMP,
	SiteToken VARCHAR(128),
	SiteUserID INT UNSIGNED,
	SiteTokenIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY(SiteTokenID)
) ENGINE InnoDB;

DROP TABLE IF EXISTS SiteUsers;
CREATE TABLE SiteUsers (
	SiteUserID INT UNSIGNED NOT NULL AUTO_INCREMENT,
	SiteUserTSC DATETIME,
	SiteUserTSU TIMESTAMP,
	SiteUserTypeID TINYINT UNSIGNED,
	CallsignID INT UNSIGNED,
	SiteUserEmailAddress VARCHAR(64),
	SiteUserPasswordHash VARCHAR(128),
	SiteUserIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY(SiteUserID),
	FOREIGN KEY (CallsignID) REFERENCES Callsigns (CallsignID)
) ENGINE InnoDB;

DROP TABLE IF EXISTS SiteUserAgents;
CREATE TABLE SiteUserAgents (
	SiteUserAgentID INT UNSIGNED NOT NULL AUTO_INCREMENT,
	SiteUserAgentTSC DATETIME,
	SiteUserAgentTSU TIMESTAMP,
	SiteUserAgent VARCHAR(256),
	PRIMARY KEY(SiteUserAgentID)
) ENGINE InnoDB;


DROP TABLE IF EXISTS SiteUserTypes;
CREATE TABLE SiteUserTypes (
	SiteUserTypeID TINYINT UNSIGNED NOT NULL,
	SiteUserType VARCHAR(32),
	SiteUserTypeIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY(SiteUserTypeID)
) ENGINE InnoDB;


DROP TABLE IF EXISTS SiteVisits;
CREATE TABLE SiteVisits (
	SiteVisitID INT UNSIGNED NOT NULL AUTO_INCREMENT,
	SiteVisitTSC DATETIME,
	SiteVisitTSU TIMESTAMP,
	SiteVisitURL VARCHAR(2048),
	SiteVisitIP BINARY(16),
	SiteUserAgentID INT UNSIGNED,
	SiteTokenID INT UNSIGNED,
	PRIMARY KEY(SiteVisitID)
) ENGINE InnoDB;


DROP TABLE IF EXISTS SiteBlockedIPs;
CREATE TABLE SiteBlockedIPs (
	SiteBlockedIPID INT UNSIGNED AUTO_INCREMENT,
	SiteBlockedIPTSC DATETIME,
	SiteBlockedIPTSU TIMESTAMP,
	SiteBlockedIP BINARY(16),
	SiteBlockedIPIsValid BOOLEAN DEFAULT 1,
	PRIMARY KEY ( SiteBlockedIPID )
) ENGINE InnoDB;
CREATE INDEX Index_SiteBlockedIP ON SiteBlockedIPs (SiteBlockedIP);

-- 
-- PROCEDURES
-- 

DROP PROCEDURE IF EXISTS SiteUserLogin;
DELIMITER //
CREATE PROCEDURE SiteUserLogin( IN _SiteUserID INT UNSIGNED )
BEGIN

	UPDATE SiteTokens
		SET
			SiteUserID = _SiteUserID
		WHERE SiteTokenID = @SiteTokenID;

	SET @SiteUserID = _SiteUserID;

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS SiteUserNewAccount;
DELIMITER //
CREATE PROCEDURE SiteUserNewAccount	(
																				IN _Callsign VARCHAR(16),
																				IN _PasswordHash VARCHAR(64)
																		)
BEGIN
	
	SET @SiteUserID = NULL;
	SET @CallsignID = NULL;
	SET @FCCCallsignID = NULL;

	-- Get FCC Callsign ID
	SELECT FCCCallsignID INTO @FCCCallsignID FROM FCCCallsigns WHERE FCCCallsign LIKE _Callsign;


	CASE
		-- Check if FCC Callsign Exists
		WHEN @FCCCallsignID IS NULL THEN
			SET @Error = 'error: Callsign not found in FCC Database';
		ELSE
			-- Check for Callsign ID
			SELECT CallsignID INTO @CallsignID FROM Callsigns WHERE Callsign LIKE _Callsign;
			-- Add Callsign if missing
			IF @CallsignID IS NULL THEN
				INSERT INTO Callsigns ( CallsignTSC, Callsign, CallsignName, ZipCodeID )
					SELECT NOW(), FCCCallsign, FCCCallsignFirstName, ZipCodeID
					FROM FCCCallsigns WHERE FCCCallsign LIKE _Callsign;
				SET @CallsignID = LAST_INSERT_ID();
			END IF;
			CASE
				-- Make sure Callsign was added
				WHEN @CallsignID IS NULL THEN
					SET @Error = 'error: Callsign could not be added';
				ELSE
					SELECT
							SiteUserID INTO @SiteUserID
						FROM SiteUsers
						WHERE CallsignID = @CallsignID;
					CASE
						-- See if account already exists
						WHEN @SiteUserID IS NOT NULL THEN
							SET @Error = 'error: Acount already exists.';
						ELSE
							-- Create account
							INSERT INTO SiteUsers ( SiteUserTSC, CallsignID,  SiteUserTypeID, SiteUserPasswordHash)
								VALUES (NOW(), @CallsignID,  1, _PasswordHash);
							SET @SiteUserID = LAST_INSERT_ID();
							CASE
								-- Ensure account was created
								WHEN @SiteUserID IS NULL THEN
									SET @Error = 'error: Account could not be created';
								ELSE
									SELECT Callsign INTO @Callsign FROM Callsigns WHERE CallsignID = @CallsignID;
									SET @Error = 'NONE';
							END CASE;
					END CASE;
			END CASE;
	END CASE;


END//
DELIMITER ;



DROP PROCEDURE IF EXISTS SiteUserPasswordSet;
DELIMITER //
CREATE PROCEDURE SiteUserPasswordSet	( _SiteUserID INT UNSIGNED, _PasswordHash VARCHAR(128) )
BEGIN
	UPDATE SiteUsers SET SiteUserPasswordHash = _PasswordHash WHERE SiteUserID = _SiteUserID;
END//
DELIMITER ;




DROP PROCEDURE IF EXISTS SiteVisit;
DELIMITER //
CREATE PROCEDURE SiteVisit (
								IN _IP VARCHAR(64),
								IN _SiteUserAgent VARCHAR(1024),
								IN _SiteToken VARCHAR(128),
								IN _URL VARCHAR(2048)
							)
BEGIN

	-- Check for too much activity
	SELECT
			COUNT(*) INTO @RecentVisitCount
		FROM SiteVisits
		WHERE SiteVisitIP = INET_ATON(_IP)
			AND SiteVisitTSC > NOW() - INTERVAL 1 MINUTE;

	SELECT
			COUNT(*) INTO @IPBlocked
			FROM SiteBlockedIPs
			WHERE SiteBlockedIP = INET_ATON(_IP)
				AND SiteBlockedIPIsValid;

	CASE
		-- Reject too much activity
		WHEN @RecentVisitCount > 120 OR @IPBlocked > 0 THEN
			INSERT INTO SiteBlockedIPs ( SiteBlockedIPTSC, SiteBlockedIP )
				VALUES (NOW(), INET_ATON(_IP));
			SET @ShouldReject = "YES";
		ELSE
			SET @ShouldReject = "NO";
			-- get/set the user agent id
			SET @SiteUserAgentID = (SELECT SiteUserAgentID FROM SiteUserAgents WHERE SiteUserAgent = _SiteUserAgent);
			CASE
				WHEN @SiteUserAgentID IS NULL THEN
					INSERT INTO SiteUserAgents ( SiteUserAgent ) VALUES (_SiteUserAgent);
					SET @SiteUserAgentID = LAST_INSERT_ID();
				ELSE
					BEGIN
					END;
			END CASE;
		 
			-- get/set the token id
			SET @SiteTokenID = (SELECT SiteTokenID FROM SiteTokens WHERE SiteToken = _SiteToken);
			CASE
				WHEN @SiteTokenID IS NULL THEN
					-- add a new user
					INSERT INTO SiteUsers ( SiteUserTSC, SiteUserTypeID ) VALUES ( NOW(), 1 );
					-- add a new token
					INSERT INTO SiteTokens ( SiteTokenTSC, SiteToken, SiteUserID ) VALUES ( NOW(), UUID(), LAST_INSERT_ID() );
					SET @SiteTokenID = LAST_INSERT_ID();
				ELSE
					BEGIN
					END;
			END CASE;

			INSERT INTO SiteVisits ( SiteVisitTSC, SiteVisitIP, SiteTokenID, SiteUserAgentID, SiteVisitURL)
				VALUES ( NOW(), INET_ATON(_IP), @SiteTokenID, @SiteUserAgentID, @SiteVisitURL);

			SELECT SiteToken INTO @SiteToken FROM SiteTokens WHERE SiteTokenID = @SiteTokenID;
	END CASE;

END//
DELIMITER ;




DROP PROCEDURE IF EXISTS SiteUserPasswordHash;
DELIMITER //
CREATE PROCEDURE SiteUserPasswordHash	( IN _Callsign VARCHAR(6) )
BEGIN

	SELECT
			SiteUsers.SiteUserID, SiteUsers.SiteUserPasswordHash
		FROM Callsigns
		LEFT JOIN SiteUsers USING (CallsignID)
		WHERE Callsign LIKE _Callsign;

END//
DELIMITER ;



DROP PROCEDURE IF EXISTS SiteUserInfo;
DELIMITER //
CREATE PROCEDURE SiteUserInfo	( IN _SiteUserID INT UNSIGNED )
BEGIN
	SELECT
			SiteUsers.SiteUserID,
			SiteUsers.SiteUserTypeID,
			SiteUserTypes.SiteUserType,
			Callsigns.Callsign,
			Callsigns.CallsignName,
			Callsigns.CallsignRadio,
			Callsigns.CallsignAntenna,
			'unchangedpassword' AS SiteUserPassword
		FROM SiteUsers
		LEFT JOIN SiteUserTypes USING (SiteUserTypeID)
		LEFT JOIN Callsigns USING (CallsignID)
		WHERE SiteUsers.SiteUserID = _SiteUserID;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS SiteUserInfoUpdate;
DELIMITER //
CREATE PROCEDURE SiteUserInfoUpdate	(
																				IN _SiteUserID INT UNSIGNED,
																				IN _CallsignName VARCHAR(64),
																				IN _CallsignRadio VARCHAR(64),
																				IN _CallsignAntenna VARCHAR(64),
																				IN _SiteUserPasswordHash VARCHAR(64)
																		)
BEGIN
	UPDATE SiteUsers
		LEFT JOIN Callsigns USING (CallsignID)
		SET
				CallsignName = _CallsignName,
				CallsignRadio = _CallsignRadio,
				CallsignAntenna = _CallsignAntenna,
				SiteUserPasswordHash = IF(_SiteUserPasswordHash = 'unchangedpassword', SiteUserPasswordHash, _SiteUserPasswordHash)
			WHERE SiteUserID = SiteUserID;

END//
DELIMITER ;


INSERT INTO SiteUserTypes ( SiteUserTypeID, SiteUserType ) VALUES ( 0, 'Visitor' );
INSERT INTO SiteUserTypes ( SiteUserTypeID, SiteUserType ) VALUES ( 1, 'Initial' );
INSERT INTO SiteUserTypes ( SiteUserTypeID, SiteUserType ) VALUES ( 10, 'Normal' );
