
SET foreign_key_checks = 0;

source DatabaseDatabase.sql

source DatabaseFunctions.sql

source DatabaseZipCodes.sql

source DatabaseSite.sql

source DatabaseEvents.sql

source DatabaseCallsigns.sql

source DatabaseNets.sql

source DatabaseChat.sql


-- Exported Data
source data/export/ZipCodes.sql
source data/export/FCCCallsigns.sql



source DatabasePost.sql

SET foreign_key_checks = 1;

COMMIT;