
SET foreign_key_checks = 0;

source DatabaseDatabase.sql

source DatabaseFunctions.sql

source DatabaseZipCodes.sql

source DatabaseSite.sql

source DatabaseCallsigns.sql

source DatabaseNets.sql

-- Exported Data
source data/export/ZipCodes.sql
source data/export/FCCCallsigns.sql

source DatabasePost.sql

SET foreign_key_checks = 1;
