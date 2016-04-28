
DROP FUNCTION IF EXISTS STRIP_NON_DIGIT;
DELIMITER $$
CREATE FUNCTION STRIP_NON_DIGIT(input VARCHAR(255))
   RETURNS VARCHAR(255)
   DETERMINISTIC
BEGIN
   DECLARE output   VARCHAR(255) DEFAULT '';
   DECLARE iterator INT          DEFAULT 1;
   WHILE iterator < (LENGTH(input) + 1) DO
      IF SUBSTRING(input, iterator, 1) REGEXP '[[:digit:]]' THEN
         SET output = CONCAT(output, SUBSTRING(input, iterator, 1));
      END IF;
      SET iterator = iterator + 1;
   END WHILE;
   RETURN output;
END
$$
DELIMITER ;


DROP FUNCTION IF EXISTS STRIP_NON_ALPHA;
DELIMITER $$
CREATE FUNCTION STRIP_NON_ALPHA(input VARCHAR(255))
	RETURNS VARCHAR(255)
	DETERMINISTIC
BEGIN
   DECLARE output   VARCHAR(255) DEFAULT '';
   DECLARE iterator INT          DEFAULT 1;
   WHILE iterator < (LENGTH(input) + 1) DO
      IF SUBSTRING(input, iterator, 1) REGEXP '[[:alpha:]]' THEN
         SET output = CONCAT(output, SUBSTRING(input, iterator, 1));
      END IF;
      SET iterator = iterator + 1;
   END WHILE;
   RETURN output;
END
$$
DELIMITER ;

