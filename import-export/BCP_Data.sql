/* =====================================================================================
////////////////////////////    DESIGNED BY REAMAZ    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
////////////////////////////    === SQLDATA.RU ===    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
 ===================================================================================== */

--Need details on creating a batch file and running it. Include a "PAUSE" and newline at the end.

--Note - need to create the appropriate folders. Default is "C:\bcp\databasename".
--Source
SELECT 'bcp ' + DB_NAME() + '.dbo.' + Table_name + ' OUT "C:\bcp\' + DB_NAME() + '\' + Table_name + '.bcp" -S' + @@servername + ' -N -T -E -b 100000'
FROM Information_Schema.Tables
WHERE Table_Schema = 'dbo'
ORDER BY TABLE_NAME
SELECT 'PAUSE
'
--Target --Assumes completely empty tables. This should be run on the target server to catch the proper servername.
-- add a -q parameter to support quoted identifiers.
SELECT 'bcp ' + DB_NAME() + '.dbo.' + Table_name + ' IN "C:\bcp\' + DB_NAME() + '\' + Table_name + '.bcp" -S' + @@servername + ' -N -T -E -b 100000'
FROM Information_Schema.Tables
WHERE Table_Schema = 'dbo'
ORDER BY TABLE_NAME
--Note - use this carefully, especially if any constraints are disabled before copying the data.
--Target - should probably run this before trying to BCP the data in.
EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'
--Target - should run this after trying to BCP the data in.
EXEC sp_msforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'
