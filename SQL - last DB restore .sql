use master

go
/* 
 :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::
::::::	Script to identify when databases were last restored and their status
::::::	The second and third resultsets are application data specific (Portia & LVTS)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

--	SELECT * FROM dbo.vMIPL_restbackhistory

*/
DECLARE @dbname sysname, @days int

SET @dbname = NULL  --substitute for whatever database name you want
SET @days = -100	--previous number of days, script will default to 3


--// This gives an overview of all database restores in the last @days number of dayS
SELECT
		 rsh.destination_database_name	 AS [Database],
		 rsh.user_name					 AS [Restored By],
		 CASE WHEN rsh.restore_type = 'D' THEN 'Database'
			  WHEN rsh.restore_type = 'F' THEN 'File'
			  WHEN rsh.restore_type = 'G' THEN 'Filegroup'
			  WHEN rsh.restore_type = 'I' THEN 'Differential'
			  WHEN rsh.restore_type = 'L' THEN 'Log'
			  WHEN rsh.restore_type = 'V' THEN 'Verifyonly'
			  WHEN rsh.restore_type = 'R' THEN 'Revert'
			  ELSE rsh.restore_type 
		 END							AS [Restore Type],
		 rsh.restore_date				AS [Restore Started],
		 bmf.physical_device_name		AS [Restored From], 
		 rf.destination_phys_name		AS [Restored To]
		 ,DATABASEPROPERTYEX(rsh.destination_database_name,'status' )
FROM		msdb.dbo.restorehistory rsh
INNER JOIN	msdb.dbo.backupset			as bs	ON rsh.backup_set_id = bs.backup_set_id
INNER JOIN	msdb.dbo.restorefile		as rf	ON rsh.restore_history_id = rf.restore_history_id
INNER JOIN	msdb.dbo.backupmediafamily	as bmf	ON bmf.media_set_id = bs.media_set_id
WHERE		rsh.restore_date >= DATEADD(dd, ISNULL(@days, @days), GETDATE())			--search for previous @days
AND			destination_database_name = ISNULL(@dbname, destination_database_name)		--if no dbname, then return all
and destination_database_name not like 'fxi%'
ORDER BY	rsh.restore_history_id DESC



	----// Portia specific data
	select		convert(varchar,date_stamp,106) As 'Portia_Date'
				,COUNT(*)						As '# Transactions'
	From		dc1sql01c.Portia.dbo.mtf
	Where		date_stamp >= GETDATE() + @days
	group by	convert(varchar,date_stamp,106)
	order by	max(date_stamp) desc


	--// Landmark specific data
	--select		convert(varchar,Created_time,106) LVTS_Date
	--			,COUNT(*) LVTS_Orders

	--from		dc1sql01c.Landmark.dbo.Orders
	--where		Created_time >= GETDATE() + @days
	--group by	convert(varchar,Created_time,106)
	--order by	max(Created_time) desc
