USE Com2900G16;
GO
EXEC informe.LimpiarTodasLasTablas
-- Visualizar datos antes de insertar
SELECT * FROM tienda.Empleado;
GO

-- Agregar un nuevo empleado con el procedimiento almacenado AltaEmpleado
EXEC tienda.AltaSucursal 'Ejemplo 123', 'Ramos Mejia'
EXEC tienda.AltaEmpleado --SE EJECUTA CON EL ALTA EMPLEADO ORIGINAL, SIN ENCRIPTACION
    @Legajo = '112233', 
    @Nombre = 'Carlos', 
    @Apellido = 'López', 
    @DNI = '33445566', 
    @Mail_Empresa = 'carlos.lopez@empresa.com', 
    @CUIL = '20-33445566-8', 
    @Cargo = 'Gerente', 
    @Turno = 'N', 
    @ID_Sucursal = 1, 
    @Estado = 1;
GO

-- Ejecutar el procedimiento de encriptación
GO
EXEC tienda.EncriptarEmpleado;

-- Verificar que el nuevo empleado se haya insertado correctamente encriptado
SELECT * FROM tienda.Empleado;
GO

-- Verificar que el nuevo empleado se haya insertado correctamente desencriptado
OPEN SYMMETRIC KEY ClaveSimetricaEmpleado
DECRYPTION BY CERTIFICATE CertificadoEmpleado;
SELECT CONVERT(varchar, DECRYPTBYKEY(E.Apellido)) AS Apellido, CONVERT(varchar, DECRYPTBYKEY(E.Nombre)) AS Nombre,
CONVERT(varchar, CONVERT(varchar, DECRYPTBYKEY(E.DNI))) AS DNI,
CONVERT(varchar, DECRYPTBYKEY(E.CUIL)) AS CUIL
FROM tienda.Empleado E;
CLOSE SYMMETRIC KEY ClaveSimetricaEmpleado;


-- Intentar agregar un empleado con el mismo legajo para verificar el mensaje de error
EXEC tienda.AltaEmpleado 
    @Legajo = '112233',  -- Este legajo ya existe
    @Nombre = 'Ana', 
    @Apellido = 'Martínez', 
    @DNI = '44556677', 
    @Mail_Empresa = 'ana.martinez@empresa.com', 
    @CUIL = '27-44556677-9', 
    @Cargo = 'Soporte', 
    @Turno = 'M', 
    @ID_Sucursal = 1, 
    @Estado = 1;
GO


-- Modificar los datos del empleado con ID 1
EXEC tienda.ModificarEmpleado 
    @ID = 1, 
    @Legajo = '112233', 
    @Nombre = 'Juan Manuel', 
    @Apellido = 'Pérez González', 
    @DNI = '12345678', 
    @Mail_Empresa = 'juanmanuel.perez@empresa.com', 
    @CUIL = '20-12345678-3', 
    @Cargo = 'Analista Senior', 
    @Turno = 'N', 
    @ID_Sucursal = 1, 
    @Estado = 1;
GO

-- Verificar la actualización
SELECT * FROM tienda.Empleado;
GO

OPEN SYMMETRIC KEY ClaveSimetricaEmpleado
DECRYPTION BY CERTIFICATE CertificadoEmpleado;
SELECT CONVERT(varchar, DECRYPTBYKEY(E.Apellido)) AS Apellido, CONVERT(varchar, DECRYPTBYKEY(E.Nombre)) AS Nombre,
CONVERT(varchar, DECRYPTBYKEY(E.DNI)) AS DNI,
CONVERT(varchar, DECRYPTBYKEY(E.CUIL)) AS CUIL
FROM tienda.Empleado E;
CLOSE SYMMETRIC KEY ClaveSimetricaEmpleado;

-- Intentar modificar el empleado con ID 2 usando un legajo que ya existe
EXEC tienda.ModificarEmpleado 
    @ID = 2, 
    @Legajo = '112233', -- Este legajo ya existe en otro registro
    @Nombre = 'María Fernanda', 
    @Apellido = 'Gómez Alvarez', 
    @DNI = '87654321', 
    @Mail_Empresa = 'maria.fernanda@empresa.com', 
    @CUIL = '27-87654321-5', 
    @Cargo = 'Desarrollador Senior', 
    @Turno = 'T', 
    @ID_Sucursal = 2, 
    @Estado = 1;
GO