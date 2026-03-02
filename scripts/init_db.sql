--Create DataWarehouse db

/* Create Db and Schema*/

/* purpose of this script:
This Script create a new Db called 'Datawarehouse' after checking if the db already exist.
If the db exist, it is dropped and recreated. Additionally, the script will set up three schemas
within the Db:"bronze","silver","gold".*/

/* notice:
Running this script will drop the entire "DataWarehouse" database if it exist.
all data in the Db will be permanently deleted. Proceed with caution
and ensure you have proper backups before running this script.*/

USE master;
GO

--Drop and recreacte the "DataWarehouse" Db
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse set SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--Create Db
CREATE DATABASE DataWarehouse;

USE DataWarehouse;

--Creating schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
