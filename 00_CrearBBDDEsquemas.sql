Use master
go

IF NOT EXISTS ( SELECT name FROM master.dbo.sysdatabases WHERE name =
'Com2900G16')
BEGIN
	CREATE DATABASE Com2900G16
	COLLATE Modern_Spanish_CI_AS;
END
go
use Com2900G16
go
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name =
'ventas')
BEGIN
	EXEC('CREATE SCHEMA ventas')
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name =
'catalogo')
BEGIN
	EXEC('CREATE SCHEMA catalogo')
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name =
'tienda')
BEGIN
	EXEC('CREATE SCHEMA tienda')
END
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name =
'informe')
BEGIN
	EXEC('CREATE SCHEMA informe')
END
GO


