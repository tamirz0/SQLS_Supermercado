/*


Se requiere que importe toda la información antes mencionada a la base de datos:
	• Genere los objetos necesarios (store procedures, funciones, etc.) para importar los
	archivos antes mencionados. Tenga en cuenta que cada mes se recibirán archivos de
	novedades con la misma estructura, pero datos nuevos para agregar a cada maestro.
	• Considere este comportamiento al generar el código. Debe admitir la importación de
	novedades periódicamente.
	• Cada maestro debe importarse con un SP distinto. No se aceptarán scripts que
	realicen tareas por fuera de un SP.
	• La estructura/esquema de las tablas a generar será decisión suya. Puede que deba
	realizar procesos de transformación sobre los maestros recibidos para adaptarlos a la
	estructura requerida.
	• Los archivos CSV/JSON no deben modificarse. En caso de que haya datos mal
	cargados, incompletos, erróneos, etc., deberá contemplarlo y realizar las correcciones
	en el fuente SQL. (Sería una excepción si el archivo está malformado y no es posible
	interpretarlo como JSON o CSV). 

*/
USE Com2900G16;
GO

CREATE OR ALTER PROCEDURE tienda.EncriptarEmpleado
AS
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
        CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password123!';

    IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertificadoEmpleado')
    BEGIN
        CREATE CERTIFICATE CertificadoEmpleado
        WITH SUBJECT = 'Certificado para cifrado de la tabla Empleado';
    END;

    IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'ClaveSimetricaEmpleado')
    BEGIN
        CREATE SYMMETRIC KEY ClaveSimetricaEmpleado
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE CertificadoEmpleado;
    END;

	CREATE TABLE #tmp_empleados 
	(
		Legajo CHAR(6),
		Nombre VARCHAR(50),
		Apellido VARCHAR(50),
		DNI CHAR(8), 
		CUIL CHAR(13),
	)

    OPEN SYMMETRIC KEY ClaveSimetricaEmpleado
    DECRYPTION BY CERTIFICATE CertificadoEmpleado;

	INSERT INTO #tmp_empleados 
	SELECT e.Legajo, e.Nombre, e.Apellido, e.DNI, e.CUIL FROM tienda.Empleado e

	ALTER TABLE tienda.Empleado
	DROP CONSTRAINT CHK_DNI,CHK_CUIL;
	ALTER TABLE tienda.Empleado
	DROP COLUMN Nombre, Apellido, DNI,CUIL;

	ALTER TABLE tienda.Empleado
	ADD 
    Nombre VARBINARY(255) NULL,
    Apellido VARBINARY(255) NULL,
    DNI VARBINARY(255) NULL,
	CUIL VARBINARY(255) NULL

	UPDATE tienda.Empleado
	SET 
		Nombre = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'),CAST((SELECT tmp.Nombre FROM #tmp_empleados tmp where tmp.Legajo = Legajo) AS varbinary(255))),
		Apellido = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'),CAST((SELECT tmp.Apellido FROM #tmp_empleados tmp where tmp.Legajo = Legajo) AS varbinary(255))),
		DNI = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'),CAST((SELECT tmp.DNI FROM #tmp_empleados tmp where tmp.Legajo = Legajo) AS varbinary(255))),
		CUIL = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'),CAST((SELECT tmp.CUIL FROM #tmp_empleados tmp where tmp.Legajo = Legajo) AS varbinary(255)))
	
	CLOSE SYMMETRIC KEY ClaveSimetricaEmpleado;
	
END;
GO

CREATE OR ALTER PROCEDURE tienda.AltaEmpleado
    @Legajo VARCHAR(7),
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @DNI VARCHAR(8),
    @Mail_Empresa VARCHAR(100),
    @CUIL VARCHAR(13),
    @Cargo VARCHAR(50),
    @Turno VARCHAR(25),
    @ID_Sucursal INT,
    @Estado BIT = 1
AS
BEGIN
    OPEN SYMMETRIC KEY ClaveSimetricaEmpleado
    DECRYPTION BY CERTIFICATE CertificadoEmpleado;

    IF EXISTS (SELECT 1 FROM tienda.Empleado WHERE Legajo = @Legajo)
    BEGIN
        PRINT ('Error: El legajo del empleado ya existe.');
        CLOSE SYMMETRIC KEY ClaveSimetricaEmpleado;
        RETURN;
    END

    INSERT INTO tienda.Empleado (Legajo, Nombre, Apellido, DNI, MailEmpresa, CUIL, Cargo, Turno, ID_Sucursal, Estado)
    VALUES (
        @Legajo,
        ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), CAST(@Nombre AS VARBINARY(255))),
        ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), CAST(@Apellido AS VARBINARY(255))),
        ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), CAST(@DNI AS VARBINARY(255))),
        @Mail_Empresa,
        ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), CAST(@CUIL AS VARBINARY(255))),
        @Cargo,
        @Turno,
        @ID_Sucursal,
        @Estado
    );

    CLOSE SYMMETRIC KEY ClaveSimetricaEmpleado;
END;
GO

CREATE OR ALTER PROCEDURE tienda.ModificarEmpleado
    @ID INT,
    @Legajo VARCHAR(7),
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @DNI VARCHAR(8),
    @Mail_Empresa VARCHAR(100),
    @CUIL VARCHAR(13),
    @Cargo VARCHAR(50),
    @Turno VARCHAR(25),
    @ID_Sucursal INT,
    @Estado BIT = 1
AS
BEGIN
    OPEN SYMMETRIC KEY ClaveSimetricaEmpleado
    DECRYPTION BY CERTIFICATE CertificadoEmpleado;

    IF EXISTS (SELECT 1 FROM tienda.Empleado WHERE Legajo = @Legajo AND ID <> @ID)
    BEGIN
        PRINT ('Error: El legajo del empleado ya existe.');
        CLOSE SYMMETRIC KEY ClaveSimetricaEmpleado;
        RETURN;
    END

    UPDATE tienda.Empleado
    SET Legajo = @Legajo,
        Nombre = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), @Nombre),
        Apellido = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), @Apellido),
        DNI = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), @DNI),
        MailEmpresa =  @Mail_Empresa,
        CUIL = ENCRYPTBYKEY(KEY_GUID('ClaveSimetricaEmpleado'), @CUIL),
        Cargo = @Cargo,
        Turno = @Turno,
        ID_Sucursal = @ID_Sucursal,
        Estado = @Estado
    WHERE ID = @ID;

    CLOSE SYMMETRIC KEY ClaveSimetricaEmpleado;
END;
GO

