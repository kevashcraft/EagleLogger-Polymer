
DROP TABLE IF EXISTS CitiesAndCounties;
CREATE TABLE CitiesAndCounties AS
	SELECT
			ZipCodes.ZipCodeID AS ACID,
			CONCAT(
				IFNULL(CONCAT(Cities.City, ', '), ''),
				IFNULL(CONCAT(Counties.County, ', '), ' '),
				IFNULL(StateAbbreviation, ' ')
			) AS ACName
		FROM ZipCodes
		LEFT JOIN Cities USING (CityID)
		LEFT JOIN Counties ON Cities.CountyID = Counties.CountyID
		LEFT JOIN States ON Cities.StateID = States.StateID;

ALTER TABLE CitiesAndCounties ENGINE MyISAM;
ALTER IGNORE TABLE CitiesAndCounties ADD UNIQUE INDEX CitiesAndCounties_Index (ACName);
ALTER TABLE CitiesAndCounties ENGINE InnoDB;
CREATE INDEX CitiesAndCounties_ACName ON CitiesAndCounties (ACName);
-- SELECT * FROM CitiesAndCounties WHERE ACName like '%pinell%';


DROP PROCEDURE IF EXISTS CitiesAndCountiesListAC;
DELIMITER //
CREATE PROCEDURE CitiesAndCountiesListAC	( IN _query TEXT, _ACID INT UNSIGNED )
BEGIN

	CASE
		WHEN _ACID IS NULL THEN
			SET @InitQuery = SUBSTRING_INDEX(_query, ' ', 1);
			SET @RemainingQuery = SUBSTRING(_query, CHAR_LENGTH(@InitQuery) + 2);
			SET @Query = CONCAT('%', @InitQuery, '%');

			DROP TABLE IF EXISTS _ACResults;
			CREATE TEMPORARY TABLE _ACResults AS
				SELECT
						*
					FROM CitiesAndCounties
					WHERE ACName LIKE @Query;

			loop_space:
				LOOP
					SET @ThisQuery = SUBSTRING_INDEX(@RemainingQuery, ' ', 1);
					SET @RemainingQuery = SUBSTRING(@RemainingQuery, CHAR_LENGTH(@ThisQuery) + 2);
					SET @Query = CONCAT('%', @ThisQuery, '%');
	
					DELETE FROM _ACResults
						WHERE ACName NOT LIKE @Query;

					IF @RemainingQuery = '' THEN
						LEAVE loop_space;
					END IF;
				END LOOP loop_space;

			SELECT * FROM _ACResults LIMIT 15;
		ELSE
			SELECT
					ZipCodeID AS ACID,
					CONCAT(
						IFNULL(CONCAT(City, ', '), ''),
						IFNULL(CONCAT(County, ', '), ' '),
						IFNULL(StateAbbreviation, ' ')
					) AS ACName
				FROM ZipCodesView
				WHERE ZipCodeID = _ACID;
	END CASE;
END//
DELIMITER ;



-- CALL SiteUserNewAccount('KM4FPA', '$2y$10$FyeRjH5bc7MqJIK8zFv23eJ4.dqdAsPdTFtGuQ.i3fCngilTQBMvG');
-- call CitiesAndCountiesListAC('auburndale', NULL);
