DROP TABLE IF EXISTS ZipCodes;
DROP TABLE IF EXISTS Cities;
DROP TABLE IF EXISTS CityTypes;
DROP TABLE IF EXISTS Counties;
DROP TABLE IF EXISTS States;

CREATE TABLE States (
	StateID INT UNSIGNED AUTO_INCREMENT,
	StateFIPS INT UNSIGNED,
	StateAbbreviation CHAR(2),
	State VARCHAR(64),
	PRIMARY KEY (StateID),
	UNIQUE KEY (State)
) ENGINE InnoDB;
CREATE INDEX Index_State ON States(State);
CREATE INDEX Index_StateAbbreviation ON States(StateAbbreviation);

CREATE TABLE Counties (
	CountyID INT UNSIGNED AUTO_INCREMENT,
	CountyFIPS INT UNSIGNED,
	StateID INT UNSIGNED,
	County VARCHAR(64),
	PRIMARY KEY (CountyID),
	UNIQUE KEY (County, StateID),
	FOREIGN KEY (StateID) REFERENCES States (StateID)
) ENGINE InnoDB;
CREATE INDEX Index_County ON Counties(County);

CREATE TABLE CityTypes (
	CityTypeID INT UNSIGNED AUTO_INCREMENT,
	CityTypeTS TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	CityType VARCHAR(64),
	PRIMARY KEY (CityTypeID),
	UNIQUE KEY (CityType)
) ENGINE InnoDB;

CREATE TABLE Cities (
	CityID INT UNSIGNED AUTO_INCREMENT,
	CityFIPS INT UNSIGNED,
	City VARCHAR(128),
	CityTypeID INT UNSIGNED,
	CountyID INT UNSIGNED,
	StateID INT UNSIGNED,
	PRIMARY KEY ( CityID ),
	UNIQUE KEY (City, StateID),
	FOREIGN KEY (StateID) REFERENCES States(StateID),
	FOREIGN KEY (CountyID) REFERENCES Counties(CountyID),
	FOREIGN KEY (CityTypeID) REFERENCES CityTypes(CityTypeID)
) ENGINE InnoDB;
CREATE INDEX Cities_CityIndex ON Cities (City);


CREATE TABLE ZipCodes (
	ZipCodeID INT UNSIGNED AUTO_INCREMENT,
	ZipCode CHAR(5),
	CityID INT UNSIGNED,
	PRIMARY KEY (ZipCodeID),
	FOREIGN KEY (CityID) REFERENCES Cities (CityID)
) ENGINE InnoDB;
CREATE INDEX ZipCodes_ZipCode ON ZipCodes (ZipCode);


DROP VIEW IF EXISTS ZipCodesView;
CREATE VIEW ZipCodesView AS
	SELECT
			ZipCodes.ZipCodeID,
			ZipCodes.ZipCode,
			Cities.CityID,
			Cities.City,
			Counties.CountyID,
			Counties.County,
			States.StateID,
			States.StateAbbreviation,
			States.State
		FROM ZipCodes
		LEFT JOIN Cities USING (CityID)
		LEFT JOIN Counties ON Cities.CountyID = Counties.CountyID
		LEFT JOIN States ON Cities.StateID = States.StateID;



DROP PROCEDURE IF EXISTS ZipCodeListAC;
DELIMITER //
CREATE PROCEDURE ZipCodeListAC	( IN _query TEXT, _ACID INT UNSIGNED )
BEGIN

	CASE
		WHEN _ACID IS NULL THEN
			SELECT
					ZipCodeID AS ACID,
					CONCAT(ZipCode, ' - ', IFNULL(CONCAT(City, ', '),' '), IFNULL(StateAbbreviation, ' ')) AS ACName
				FROM ZipCodesView
				WHERE ZipCode LIKE CONCAT(_query, '%')
					OR City LIKE CONCAT(_query, '%')
				LIMIT 15;

		ELSE
			SELECT
					ZipCodeID AS ACID,
					CONCAT(ZipCode, ' - ', IFNULL(CONCAT(City, ', '),' '), IFNULL(StateAbbreviation, ' ')) AS ACName
				FROM ZipCodesView
				WHERE ZipCodeID = _ACID;

	END CASE;
END//
DELIMITER ;

