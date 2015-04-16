
--Show Advanced Options (required)
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

--View Current Configuration
EXEC sp_configure 'Ole Automation Procedures';
GO

--Enable Ole Automation
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;

/*
--Disable Ole Automation
sp_configure 'Ole Automation Procedures', 0;
GO
RECONFIGURE;
*/
