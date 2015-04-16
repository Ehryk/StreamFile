StreamFile v1.3
================

This repository contains various ways to save or stream a file to a SQL Server instance through stored procedures. Non streamed versions load the entire file into memory and pass it in a single block, however this has memory consequences and is vulnerable to large files. Streamed versions break the file(s) into smaller units for transferring and lead to much lower memory demands.

The `StreamFile` Windows console application will stream a file to the designed SQL Server database (included) with a configurable buffer size (default: 4K / 4096 bytes).

The `CLR` Project includes a set of C# CLR Stored Procedures that enable access to the local file system in SQL Server stored procedures.

Usage:
---
 - ``StreamFile file.ext``
 - ``StreamFile.exe (File) [BufferSize]``

Latest Changes:
---
 - Moved to C# CLR Stored Procedures

Release History:
---
 - v1.4 (In Development)
 - v1.3 2015.04.05 Shifted to CLR based procedures
 - v1.2 2015.04.04 Adding OLE Error handling and Exception returning
 - v1.1 2015.04.02 Reworking due to OLE single batch limitation
 - v1.0 2015.04.15 Initial Build, OLE COM based solution

Author:
 - Eric Menze ([@Ehryk42](https://twitter.com/Ehryk42))

Build Requirements:
---
 - Visual Studio (Built with Visual Studio 2013)

Contact:
---
Eric Menze
 - [Email Me](mailto:rhaistlin+gh@gmail.com)
 - [Portfolio](http://ericmenze.com)
 - [Github](https://github.com/Ehryk)
 - [Twitter](https://twitter.com/Ehryk42)
 - [Source Code](https://github.com/Ehryk/HashCompute)
