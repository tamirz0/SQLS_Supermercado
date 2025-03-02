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

-- Procedimientos para la Tabla Sucursal
CREATE OR ALTER PROCEDURE tienda.AltaSucursal
    @Direccion VARCHAR(100),
    @Ciudad VARCHAR(50),
    @Ciudad_anterior VARCHAR(50) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM tienda.Sucursal WHERE Direccion = @Direccion)
	BEGIN
        RAISERROR ('Error: La dirección de la sucursal ya existe.', 16, 1);
		RETURN;
	END;

    INSERT INTO tienda.Sucursal (Direccion, Ciudad, Ciudad_anterior)
    VALUES (@Direccion, @Ciudad, @Ciudad_anterior);
END;
GO

CREATE OR ALTER PROCEDURE tienda.BajaSucursal
    @ID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tienda.Sucursal WHERE ID = @ID)
		BEGIN
			RAISERROR ('Error: Id incorrecto.', 16, 1);
			RETURN
		END

    DELETE FROM tienda.Sucursal WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE tienda.ModificarSucursal
    @ID INT,
    @Direccion VARCHAR(100),
    @Ciudad VARCHAR(50),
    @Ciudad_anterior VARCHAR(50) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM tienda.Sucursal WHERE Direccion = @Direccion AND ID <> @ID)
        BEGIN
			RAISERROR ('Error: La dirección de la sucursal ya existe.', 16, 1);
			RETURN
		END
    UPDATE tienda.Sucursal
    SET Direccion = @Direccion,
        Ciudad = @Ciudad,
        Ciudad_anterior = @Ciudad_anterior
    WHERE ID = @ID;
END;
GO

-- Procedimientos para la Tabla Empleado
CREATE OR ALTER PROCEDURE tienda.AltaEmpleado
    @Legajo CHAR(6),
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @DNI CHAR(8),
    @Mail_Empresa VARCHAR(100),
    @CUIL VARCHAR(13),
    @Cargo VARCHAR(20),
    @Turno CHAR(2),
    @ID_Sucursal INT,
    @Estado BIT = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM tienda.Empleado WHERE Legajo = @Legajo)
    BEGIN
		RAISERROR ('Error: El legajo del empleado ya existe.', 16, 1);
		RETURN
	END

    INSERT INTO tienda.Empleado (Legajo, Nombre, Apellido, DNI, MailEmpresa, CUIL, Cargo, Turno, ID_Sucursal, Estado)
    VALUES (@Legajo, @Nombre, @Apellido, @DNI, @Mail_Empresa, @CUIL, @Cargo, @Turno, @ID_Sucursal, @Estado);
END;
GO

CREATE OR ALTER PROCEDURE tienda.BajaEmpleado
    @ID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tienda.Empleado WHERE ID = @ID)
	BEGIN
        RAISERROR ('Error: Id incorrecto.', 16, 1);
		RETURN
	END

    DELETE FROM tienda.Empleado WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE tienda.ModificarEmpleado
    @ID INT,
    @Legajo CHAR(6),
    @Nombre VARCHAR(50),
    @Apellido VARCHAR(50),
    @DNI CHAR(8),
    @Mail_Empresa VARCHAR(100),
    @CUIL VARCHAR(13),
    @Cargo VARCHAR(20),
    @Turno CHAR(2),
    @ID_Sucursal INT,
    @Estado BIT = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM tienda.Empleado WHERE Legajo = @Legajo AND ID <> @ID)
    BEGIN
		RAISERROR ('Error: El legajo del empleado ya existe.', 16, 1);
		RETURN
	END

    IF NOT EXISTS (SELECT 1 FROM tienda.Empleado WHERE ID = @ID)
	BEGIN        
		RAISERROR ('Error: Id incorrecto.', 16, 1);
		RETURN
	END

    UPDATE tienda.Empleado
    SET Legajo = @Legajo,
        Nombre = @Nombre,
        Apellido = @Apellido,
        DNI = @DNI,
        MailEmpresa = @Mail_Empresa,
        CUIL = @CUIL,
        Cargo = @Cargo,
        Turno = @Turno,
        ID_Sucursal = @ID_Sucursal,
        Estado = @Estado
    WHERE ID = @ID;
END;
GO

-- Procedimientos para la Tabla Cliente
CREATE OR ALTER PROCEDURE tienda.AltaCliente
    @Nombre VARCHAR(100),
    @TipoCliente VARCHAR(6),
    @Genero CHAR(1),
    @Estado BIT = 1,
	@CUIT CHAR(13)
AS
BEGIN
    IF @TipoCliente NOT IN ('Member', 'Normal')
	BEGIN        
		RAISERROR ('Error: Tipo de cliente inválido.', 16, 1);
		RETURN
	END

    IF @Genero NOT IN ('F', 'M')
	BEGIN        
		RAISERROR ('Error: Género inválido.', 16, 1);
		RETURN
	END
    IF EXISTS (SELECT 1 FROM tienda.Cliente WHERE CUIT = @CUIT AND @CUIT IS NOT NULL)
	BEGIN        
		RAISERROR ('Error: CUIT ya utilizado.', 16, 1);
		RETURN
	END
    INSERT INTO tienda.Cliente (Nombre, TipoCliente, Genero, Estado,CUIT)
    VALUES (@Nombre, @TipoCliente, @Genero, @Estado,@CUIT);
END;
GO

CREATE OR ALTER PROCEDURE tienda.BajaCliente
    @ID INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM tienda.Cliente WHERE @ID = ID)
	BEGIN
		RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    DELETE FROM tienda.Cliente WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE tienda.ModificarCliente
    @ID INT,
    @Nombre VARCHAR(100),
    @TipoCliente VARCHAR(6),
    @Genero CHAR(1),
    @Estado BIT = 1
AS
BEGIN
    IF @TipoCliente NOT IN ('Member', 'Normal')
	BEGIN
        RAISERROR ('Error: Tipo de cliente inválido.', 16, 1);
		RETURN
	END
    IF @Genero NOT IN ('F', 'M')
	BEGIN
        RAISERROR ('Error: Género inválido.', 16, 1);
		RETURN
	END
	IF NOT EXISTS (SELECT 1 FROM tienda.Cliente WHERE @ID = ID)
	BEGIN
        RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    UPDATE tienda.Cliente
    SET Nombre = @Nombre,
        TipoCliente = @TipoCliente,
        Genero = @Genero,
        Estado = @Estado
    WHERE ID = @ID;
END;
GO

-- Procedimientos para la Tabla CategoriaProducto
CREATE OR ALTER PROCEDURE catalogo.AltaCategoriaProducto
    @LineaProducto VARCHAR(40),
    @Categoria VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM catalogo.CategoriaProducto WHERE Categoria = @Categoria)
	BEGIN
        RAISERROR ('Error: La categoría ya existe.', 16, 1);
		RETURN
	END
    INSERT INTO catalogo.CategoriaProducto (LineaProducto, Categoria)
    VALUES (@LineaProducto, @Categoria);
END;
GO

CREATE OR ALTER PROCEDURE catalogo.BajaCategoriaProducto
    @ID INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM catalogo.CategoriaProducto WHERE @ID = ID)
	BEGIN
        RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    DELETE FROM catalogo.CategoriaProducto WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE catalogo.ModificarCategoriaProducto
    @ID INT,
    @LineaProducto VARCHAR(40),
    @Categoria VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM catalogo.CategoriaProducto WHERE Categoria = @Categoria AND ID <> @ID)
	BEGIN
        RAISERROR ('Error: La categoría ya existe.', 16, 1);
		RETURN
	END
	IF NOT EXISTS (SELECT 1 FROM catalogo.CategoriaProducto WHERE @ID = ID)
	BEGIN
        RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    UPDATE catalogo.CategoriaProducto
    SET LineaProducto = @LineaProducto,
        Categoria = @Categoria
    WHERE ID = @ID;
END;
GO

-- Procedimientos para la Tabla Producto
CREATE OR ALTER PROCEDURE catalogo.AltaProducto
    @Nombre VARCHAR(100),
    @ID_Categoria INT,
    @PrecioUnitario DECIMAL(10, 2),
    @PrecioReferencia DECIMAL(10, 2),
    @UnidadReferencia VARCHAR(25),
    @Fecha DATETIME,
	@IVA DECIMAL(10, 2)
AS
BEGIN
    IF @PrecioUnitario <= 0
	BEGIN
        RAISERROR ('Error: Precio unitario debe ser mayor a cero.', 16, 1);
		RETURN
	END
    INSERT INTO catalogo.Producto (Nombre, ID_Categoria, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha,IVA)
    VALUES (@Nombre, @ID_Categoria, @PrecioUnitario, @PrecioReferencia, @UnidadReferencia, @Fecha, @IVA);
END;
GO

CREATE OR ALTER PROCEDURE catalogo.BajaProducto
    @ID INT
AS
BEGIN

	IF NOT EXISTS (SELECT 1 FROM catalogo.Producto WHERE @ID = ID)
	BEGIN
        RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    DELETE FROM catalogo.Producto WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE catalogo.ModificarProducto
    @ID INT,
    @Nombre VARCHAR(100),
    @ID_Categoria INT,
    @PrecioUnitario DECIMAL(10, 2),
    @PrecioReferencia DECIMAL(10, 2),
    @UnidadReferencia VARCHAR(25),
    @Fecha DATETIME,
	@IVA DECIMAL(10, 2)
AS
BEGIN
    IF @PrecioUnitario <= 0
	BEGIN
        RAISERROR ('Error: Precio unitario debe ser mayor a cero.', 16, 1);
		RETURN
	END
	IF NOT EXISTS (SELECT 1 FROM catalogo.Producto WHERE @ID = ID)
	BEGIN
        RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    UPDATE catalogo.Producto
    SET Nombre = @Nombre,
        ID_Categoria = @ID_Categoria,
        PrecioUnitario = @PrecioUnitario,
        PrecioReferencia = @PrecioReferencia,
        UnidadReferencia = @UnidadReferencia,
        Fecha = @Fecha
    WHERE ID = @ID;
END;
GO

-- Procedimientos para la Tabla MedioPago
CREATE OR ALTER PROCEDURE ventas.AltaMedioPago
    @Descripcion_ESP VARCHAR(50),
    @Descripcion_ENG VARCHAR(50)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM ventas.MedioPago WHERE Descripcion_ESP = @Descripcion_ESP OR Descripcion_ENG = @Descripcion_ENG)
	BEGIN
        RAISERROR ('Error: El medio de pago ya existe.', 16, 1);
		RETURN
	END
    INSERT INTO ventas.MedioPago (Descripcion_ESP, Descripcion_ENG)
    VALUES (@Descripcion_ESP, @Descripcion_ENG);
END;
GO

CREATE OR ALTER PROCEDURE ventas.BajaMedioPago
    @ID INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM ventas.MedioPago WHERE @ID = ID)
	BEGIN
        RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    DELETE FROM ventas.MedioPago WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE ventas.ModificarMedioPago
    @ID INT,
    @Descripcion_ESP VARCHAR(50),
    @Descripcion_ENG VARCHAR(50)
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM ventas.MedioPago WHERE @ID = ID)
		BEGIN
        RAISERROR ('Error: ID incorrecto.', 16, 1);
		RETURN
	END
    IF EXISTS (SELECT 1 FROM ventas.MedioPago WHERE (Descripcion_ESP = @Descripcion_ESP OR Descripcion_ENG = @Descripcion_ENG) AND ID <> @ID)
		BEGIN
        RAISERROR ('Error: El medio de pago ya existe.', 16, 1);
		RETURN
	END

    UPDATE ventas.MedioPago
    SET Descripcion_ESP = @Descripcion_ESP,
        Descripcion_ENG = @Descripcion_ENG
    WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE ventas.AltaFactura
    @ID_Venta INT,
    @PuntoDeVenta CHAR(5),
	@Comprobante VARCHAR(10)
AS
BEGIN
    DECLARE @ID_Factura INT;
	DECLARE @UltimoComprobante INT;

	IF NOT EXISTS (SELECT 1 FROM ventas.Venta WHERE ID = @ID_Venta)
	BEGIN
        RAISERROR ('Venta no encontrada.', 16, 1);
		RETURN
	END
	SELECT @UltimoComprobante = MAX(ID)
		FROM ventas.Factura;

	DECLARE @subTotal DECIMAL(10,2) = (SELECT v.Total FROM ventas.Venta v WHERE ID = @ID_Venta)

    INSERT INTO ventas.Factura (Estado, FechaHora, Comprobante, PuntoDeVenta, SubTotal, IvaTotal, Total,ID_Venta)
    VALUES ('No pagada', GETDATE(), @Comprobante, @PuntoDeVenta, @subTotal, @subTotal * 0.21, @subTotal + @subTotal * 0.21,@ID_Venta);
END;
GO

CREATE OR ALTER PROCEDURE ventas.BajaFactura
    @ID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID)
	BEGIN
        RAISERROR ('Factura no encontrada.', 16, 1);
		RETURN
	END
    IF EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID AND Estado = 'Pagada')
	BEGIN
        RAISERROR ('No se puede eliminar una factura pagada.', 16, 1);
		RETURN
	END

	UPDATE ventas.Factura
		SET Estado = 'Cancelada'
		WHERE ID = @ID;
END;

GO
CREATE OR ALTER PROCEDURE ventas.ModificarFactura
    @ID INT,
    @Estado VARCHAR(10)
AS
BEGIN
    IF @Estado NOT IN ('Pagada', 'No pagada','Cancelada')
	BEGIN
        RAISERROR ('Estado de factura no válido. Debe ser "Pagada", "No pagada" o "Cancelada".', 16, 1);
		RETURN
	END
    IF NOT EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID)
	BEGIN
        RAISERROR ('Factura no encontrada.', 16, 1);
		RETURN
	END
    UPDATE ventas.Factura
		SET Estado = @Estado
    WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE ventas.AltaDetalleFactura
    @ID_Venta INT,
    @ID_Factura INT
AS
BEGIN
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID_Factura)
	BEGIN
        RAISERROR ('Factura no encontrada.', 16, 1);
		RETURN
	END
    IF NOT EXISTS (SELECT 1 FROM ventas.Venta WHERE ID = @ID_Venta)
	BEGIN
        RAISERROR ('Venta no encontrada.', 16, 1);
		RETURN
	END
    IF NOT EXISTS (SELECT 1 FROM ventas.Factura WHERE ID_Venta = @ID_Venta AND ID = @ID_Factura)
	BEGIN
        RAISERROR ('Factura no coincide con venta.', 16, 1);
		RETURN
	END
    INSERT INTO ventas.DetalleFactura (ID_Factura, ID_Producto, Cantidad, PrecioUnitario, IVA, Subtotal)
    SELECT 
        @ID_Factura AS ID_Factura,
        DV.ID_Producto,
        DV.Cantidad,
        P.PrecioUnitario,
        (DV.Subtotal * P.IVA) AS IVA,
        (DV.Subtotal + (DV.Subtotal * P.IVA)) AS Subtotal
    FROM 
        ventas.DetalleVenta DV
    INNER JOIN 
        catalogo.Producto P ON DV.ID_Producto = P.ID
    WHERE 
        DV.ID_Venta = @ID_Venta;

    -- Cálculo de totales
    DECLARE @IVATotal DECIMAL(18, 2);
    SELECT @IVATotal = SUM(IVA)
    FROM ventas.DetalleFactura
    WHERE ID_Factura = @ID_Factura;

    DECLARE @Subtotal DECIMAL(18, 2);
    SELECT @Subtotal = SUM(Subtotal) 
    FROM ventas.DetalleVenta
    WHERE ID_Venta = @ID_Venta;

    -- Actualización de la factura
    UPDATE ventas.Factura
    SET 
        IvaTotal = @IVATotal,
        SubTotal = @Subtotal,
        Total = @IVATotal + @Subtotal
    WHERE ID = @ID_Factura;
END;


GO


CREATE OR ALTER PROCEDURE ventas.ModificarDetalleFactura
    @ID INT,
    @ID_Factura INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID_Factura)
	BEGIN
        RAISERROR ('Factura no encontrada.', 16, 1);
		RETURN
	END
    UPDATE ventas.DetalleFactura
    SET ID_Factura = @ID_Factura
    WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE ventas.AltaVenta
    @ID_Cliente INT,
	@ID_Sucursal INT,
	@ID_Empleado INT
AS
BEGIN
    DECLARE @ID_Venta INT;

    INSERT INTO ventas.Venta (ID_Cliente, Total,ID_Sucursal,ID_Empleado)
    VALUES (@ID_Cliente, 0, @ID_Sucursal,@ID_Empleado);
END;
GO

CREATE OR ALTER PROCEDURE ventas.BajaVenta
    @ID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ventas.Venta WHERE ID = @ID)
	BEGIN
        RAISERROR ('Venta no encontrada.', 16, 1);
		RETURN
	END
    DELETE FROM ventas.Venta WHERE ID = @ID;
END;
GO



CREATE OR ALTER PROCEDURE ventas.ModificarVenta
    @ID INT,
    @ID_Cliente INT,
    @id_factura_importado VARCHAR(30),
	@ID_Empleado INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tienda.Cliente WHERE ID = @ID_Cliente)
	BEGIN
        RAISERROR ('Cliente no encontrado.', 16, 1);
		RETURN
	END
    IF NOT EXISTS (SELECT 1 FROM ventas.Venta WHERE ID = @ID)
	BEGIN
        RAISERROR ('Venta no encontrada.', 16, 1);
		RETURN
	END
    UPDATE ventas.Venta
    SET ID_Cliente = @ID_Cliente,
        ID_Empleado = @ID_Empleado,
        id_factura_importado = @id_factura_importado
    WHERE ID = @ID;
END;
GO


CREATE OR ALTER PROCEDURE ventas.AltaDetalleVenta
    @ID_Venta INT,
    @ID_Producto INT,
    @Cantidad INT
AS
BEGIN
    DECLARE @PrecioUnitario DECIMAL(18, 2);
    DECLARE @Subtotal DECIMAL(18, 2);

	IF NOT EXISTS (SELECT 1 FROM ventas.Venta WHERE ID = @ID_Venta)
	BEGIN
        RAISERROR ('Venta no encontrada.', 16, 1);
		RETURN
	END

	IF EXISTS (SELECT 1 FROM ventas.DetalleVenta WHERE ID_Producto = @ID_Producto AND ID_Venta = @ID_Venta)
	BEGIN
        RAISERROR ('Modifique detalle ya existente.', 16, 1);
		RETURN
	END

    SELECT @PrecioUnitario = PrecioUnitario
    FROM catalogo.Producto
    WHERE ID = @ID_Producto;

    IF @PrecioUnitario IS NULL
    BEGIN
        RAISERROR ('El producto especificado no existe o no tiene un precio definido.', 16, 1);
 		RETURN
	END

    INSERT INTO ventas.DetalleVenta (ID_Venta, ID_Producto, Cantidad, Precio_Unitario,Subtotal)
    VALUES (@ID_Venta, @ID_Producto, @Cantidad, @PrecioUnitario, @Cantidad *  @PrecioUnitario);

    SET @Subtotal = @Cantidad * @PrecioUnitario;

    UPDATE ventas.Venta
    SET Total = Total + @Subtotal
    WHERE ID = @ID_Venta;
END;

GO
CREATE OR ALTER PROCEDURE ventas.BajaDetalleVenta
    @ID INT
AS
BEGIN
    DECLARE @ID_Venta INT;
	DECLARE @Subtotal DECIMAL(18, 2);

    IF NOT EXISTS (SELECT 1 FROM ventas.DetalleVenta WHERE ID = @ID)
	BEGIN
        RAISERROR ('Detalle de venta no encontrado.', 16, 1);
		RETURN
	END
	SELECT @ID_Venta = ID_VENTA
    FROM ventas.DetalleVenta
    WHERE ID = @ID_Venta;

	SELECT @Subtotal = Total
    FROM ventas.Venta
    WHERE ID = @ID_Venta;

	UPDATE ventas.Venta
		SET Total = Total - @Subtotal
		WHERE ID = @ID_Venta;

    DELETE FROM ventas.DetalleVenta WHERE ID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE ventas.ModificarDetalleVenta
    @ID INT,
    @ID_Producto INT,
    @Cantidad INT
AS
BEGIN
    DECLARE @PrecioUnitario DECIMAL(18, 2);
	DECLARE @ID_Venta INT;
	DECLARE @SubTotal DECIMAL(18, 2);

    IF NOT EXISTS (SELECT 1 FROM ventas.Venta WHERE ID = @ID_Venta)
	BEGIN
        RAISERROR ('Venta no encontrada.', 16, 1);
		RETURN
	END
    IF NOT EXISTS (SELECT 1 FROM catalogo.Producto WHERE ID = @ID_Producto)
	BEGIN
        RAISERROR ('Producto no encontrado.', 16, 1);
		RETURN
	END
    IF NOT EXISTS (SELECT 1 FROM ventas.DetalleVenta WHERE ID = @ID)
	BEGIN
        RAISERROR ('Detalle de venta no encontrado.', 16, 1);
		RETURN
	END
	SELECT @PrecioUnitario = PrecioUnitario
		FROM catalogo.Producto
		WHERE ID = @ID_Producto;

	SELECT @ID_Venta = ID_Venta
		FROM ventas.DetalleVenta
		WHERE ID = @ID;

	SELECT @Subtotal = Total
		FROM ventas.Venta
		WHERE ID = @ID_Venta;

	UPDATE ventas.Venta 
	SET Total = Total - @Subtotal
	WHERE ID = @ID_Venta;

    UPDATE ventas.DetalleVenta
    SET ID_Producto = @ID_Producto,
        Cantidad = @Cantidad,
        Precio_Unitario = @PrecioUnitario,
		SubTotal = @Cantidad * @PrecioUnitario
	WHERE ID = @ID;
	
	SELECT @Subtotal = Total
		FROM ventas.Venta
		WHERE ID = @ID_Venta;

	UPDATE ventas.Venta 
		SET Total = Total + @Subtotal
		WHERE ID = @ID_Venta;
END;
GO

CREATE OR ALTER PROCEDURE ventas.AltaPago
    @ID_Factura INT,
    @ID_MedioPago INT,
    @Monto DECIMAL(18, 2)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID_Factura)
	BEGIN
        RAISERROR ('Factura no encontrada.', 16, 1);
		RETURN
	END
    IF EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID_Factura AND ESTADO = 'Pagada')
	BEGIN
        RAISERROR ('Factura ya pagada.', 16, 1);
		RETURN
	END
    DECLARE @MontoFactura DECIMAL(18, 2);
	SET @MontoFactura = (SELECT Total FROM ventas.Factura WHERE ID = @ID_Factura);

	IF (@Monto < @MontoFactura)
	BEGIN
        RAISERROR ('Monto insuficiente.', 16, 1);
		RETURN
	END
	IF (@Monto > @MontoFactura)
	BEGIN
        RAISERROR ('Monto incorrecto.', 16, 1);
		RETURN
	END
	IF NOT EXISTS (SELECT 1 FROM ventas.MedioPago WHERE ID = @ID_MedioPago)
	BEGIN
        RAISERROR ('Medio de pago no encontrado.', 16, 1);
		RETURN
	END
    INSERT INTO ventas.Pago (ID_Factura, ID_MedioPago, Monto, Fecha_Pago)
    VALUES (@ID_Factura, @ID_MedioPago, @Monto, GETDATE());

    UPDATE ventas.Factura
    SET Estado = 'Pagada'
    WHERE ID = @ID_Factura;

    DECLARE @ID_Venta INT;
    SET @ID_Venta = (SELECT ID FROM ventas.Factura WHERE ID = @ID_Factura);

END;
GO

CREATE OR ALTER PROCEDURE informe.LimpiarTodasLasTablas
AS
BEGIN
    SET NOCOUNT ON;

    -- Deshabilitar restricciones de clave foránea
    ALTER TABLE ventas.DetalleFactura NOCHECK CONSTRAINT ALL;
    ALTER TABLE ventas.Factura NOCHECK CONSTRAINT ALL;
    ALTER TABLE ventas.MedioPago NOCHECK CONSTRAINT ALL;
    ALTER TABLE ventas.Venta NOCHECK CONSTRAINT ALL;
    ALTER TABLE ventas.DetalleVenta NOCHECK CONSTRAINT ALL;
    ALTER TABLE ventas.Pago NOCHECK CONSTRAINT ALL;
    ALTER TABLE tienda.Empleado NOCHECK CONSTRAINT ALL;
    ALTER TABLE tienda.Cliente NOCHECK CONSTRAINT ALL;
    ALTER TABLE tienda.Sucursal NOCHECK CONSTRAINT ALL;
    ALTER TABLE catalogo.Producto NOCHECK CONSTRAINT ALL;
    ALTER TABLE catalogo.CategoriaProducto NOCHECK CONSTRAINT ALL;
    ALTER TABLE ventas.NotaCredito NOCHECK CONSTRAINT ALL;

    -- Borrar datos de todas las tablas
    DELETE FROM ventas.DetalleFactura;
    DELETE FROM ventas.Factura;
    DELETE FROM ventas.MedioPago;
    DELETE FROM ventas.Venta;
    DELETE FROM ventas.DetalleVenta;
    DELETE FROM ventas.Pago;
    DELETE FROM tienda.Empleado;
    DELETE FROM tienda.Cliente;
    DELETE FROM tienda.Sucursal;
    DELETE FROM catalogo.Producto;
    DELETE FROM catalogo.CategoriaProducto;
    DELETE FROM ventas.NotaCredito;

    -- Reiniciar los contadores IDENTITY a 1
    DBCC CHECKIDENT ('ventas.DetalleFactura', RESEED, 0);
    DBCC CHECKIDENT ('ventas.Factura', RESEED, 0);
    DBCC CHECKIDENT ('ventas.MedioPago', RESEED, 0);
    DBCC CHECKIDENT ('ventas.Venta', RESEED, 0);
    DBCC CHECKIDENT ('ventas.DetalleVenta', RESEED, 0);
    DBCC CHECKIDENT ('ventas.Pago', RESEED, 0);
    DBCC CHECKIDENT ('tienda.Empleado', RESEED, 0);
    DBCC CHECKIDENT ('tienda.Cliente', RESEED, 0);
    DBCC CHECKIDENT ('tienda.Sucursal', RESEED, 0);
    DBCC CHECKIDENT ('catalogo.Producto', RESEED, 0);
    DBCC CHECKIDENT ('catalogo.CategoriaProducto', RESEED, 0);
    DBCC CHECKIDENT ('ventas.NotaCredito', RESEED, 0);

    -- Habilitar restricciones de clave foránea
    ALTER TABLE ventas.DetalleFactura WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE ventas.Factura WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE ventas.MedioPago WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE ventas.Venta WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE ventas.DetalleVenta WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE ventas.Pago WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE tienda.Empleado WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE tienda.Cliente WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE tienda.Sucursal WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE catalogo.Producto WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE catalogo.CategoriaProducto WITH CHECK CHECK CONSTRAINT ALL;
    ALTER TABLE ventas.NotaCredito WITH CHECK CHECK CONSTRAINT ALL;

    PRINT ('Todas las tablas han sido vaciadas y los contadores IDENTITY han sido reiniciados a 1.');
END;
GO


