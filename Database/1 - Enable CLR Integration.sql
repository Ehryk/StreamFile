
--Enable Advanced Options
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

--Enable CLR
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO

/*
--Disable CLR
sp_configure 'clr enabled', 0;
GO
RECONFIGURE;
GO
*/
