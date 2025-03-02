--IMPORTACIONES

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

USE Com2900G16
GO
SET NOCOUNT ON
GO
-- === Insercion archivos Tienda ===

--< ARCHIVO SUCURSAL --> Informacion_complementaria.xlsx >

CREATE OR ALTER PROCEDURE tienda.ImportarSucursales
    @filePath NVARCHAR(255)
AS
BEGIN
    BEGIN TRY
        -- Configurar opciones avanzadas
        EXEC sp_configure 'show advanced options', 1;
        RECONFIGURE;
        EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
        RECONFIGURE;

        IF OBJECT_ID('tempdb..#tmpSucursal') IS NOT NULL
            DROP TABLE #tmpSucursal;

        CREATE TABLE #tmpSucursal (
            Ciudad varchar(50),
            Reemplazo varchar(50),
            Direccion varchar(100),
            Horario varchar(50),
            Telefono varchar(20)
        );

        -- Construir la consulta OPENROWSET para importar desde Excel
        DECLARE @sql NVARCHAR(MAX) =
        N'INSERT INTO #tmpSucursal (Ciudad, Reemplazo, Direccion, Horario, Telefono)
         SELECT * FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @FilePath + ''',
            ''SELECT * FROM [sucursal$]''
        )';

        EXEC sp_executesql @sql;

        INSERT INTO tienda.Sucursal (Direccion, Ciudad, Ciudad_anterior)
		(SELECT Direccion, Reemplazo, Ciudad FROM #tmpSucursal tmp WHERE NOT EXISTS  
		(SELECT 1 FROM tienda.Sucursal s WHERE tmp.Reemplazo = s.Ciudad collate Modern_Spanish_CI_AS AND tmp.Direccion = s.Direccion COLLATE Modern_Spanish_CI_AS)) 

    END TRY
    BEGIN CATCH
        RAISERROR( 'Error al importar el archivo Excel ' , 16, 1);
    end catch

		DROP TABLE IF EXISTS #tmpSucursal;

end
GO

--< ARCHIVO EMPLEADOS --> Informacion_complementaria.xlsx >

CREATE OR ALTER PROCEDURE tienda.ImportarEmpleados
    @filePath NVARCHAR(255)
AS
BEGIN
    BEGIN TRY

        IF OBJECT_ID('tempdb..#tmpEmpleado') IS NOT NULL
            DROP TABLE #tmpEmpleado;

        CREATE TABLE #tmpEmpleado (
			Legajo VARCHAR(6),
			Nombre VARCHAR(100),
			Apellido VARCHAR(100),
			DNI VARCHAR(8),
			dni_float float,
			Direccion VARCHAR(100),
			mail_personal VARCHAR(100),
			mail_empresa VARCHAR(100),
			CUIL VARCHAR(14),
			Cargo VARCHAR(50),
			Ciudad_Sucursal VARCHAR(50),
			Turno VARCHAR(25)
        );

        -- Construir la consulta OPENROWSET para importar desde Excel
        DECLARE @sql NVARCHAR(MAX) =
        N'INSERT INTO #tmpEmpleado (Legajo, Nombre, Apellido, dni_float, Direccion, mail_personal, mail_empresa, CUIL, Cargo, Ciudad_Sucursal, Turno)
         SELECT * FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @FilePath + ''',
            ''SELECT * FROM [Empleados$]''
        )';

        EXEC sp_executesql @sql;
		
		UPDATE #tmpEmpleado
		SET DNI = cast((convert(int, dni_float)) as varchar(8))

		INSERT INTO tienda.Empleado (Legajo, Nombre, Apellido, DNI, MailEmpresa, CUIL, Cargo, Turno, ID_Sucursal)
		(SELECT tmp.Legajo, tmp.Nombre, tmp.Apellido,
		DNI, REPLACE(REPLACE(REPLACE(REPLACE(tmp.mail_empresa, CHAR(9), ''), CHAR(10), ''), CHAR(13), ''), ' ', ''), CONCAT('23','-',tmp.DNI,'-','4'),
		tmp.Cargo, CASE TRIM(tmp.Turno) WHEN 'TM' THEN 'TM' WHEN 'TT' THEN 'TT' WHEN 'Jornada completa' THEN 'TC' END , 
		(SELECT ID FROM tienda.Sucursal WHERE Ciudad = Ciudad_Sucursal COLLATE Modern_Spanish_CI_AS)
		FROM #tmpEmpleado tmp
		WHERE tmp.Legajo IS NOT NULL AND NOT EXISTS 
		(SELECT 1 FROM tienda.Empleado e 
		WHERE tmp.Legajo = e.legajo COLLATE Modern_Spanish_CI_AS OR tmp.DNI = e.DNI COLLATE Modern_Spanish_CI_AS))
		
    END TRY
    BEGIN CATCH
        RAISERROR( 'Error al importar el archivo Excel' , 16, 1);
    end catch

		DROP TABLE IF EXISTS #tmpEmpleado;

end
GO

-- ==== INSERCION ARCHIVOS CATALOGO ==== 

--< ARCHIVO LINEA PRODUCTO --> Informacion_complementaria.xlsx >

CREATE OR ALTER PROCEDURE [catalogo].[ImportarCategoriaProducto]
	@FilePath NVARCHAR(255)
AS
BEGIN
	

	BEGIN TRY 
		IF OBJECT_ID('tempdb..#tmp_CategoriaProducto') IS NOT NULL
            DROP TABLE #tmp_CategoriaProducto;

		CREATE TABLE #tmp_CategoriaProducto (
			LineaProducto VARCHAR(40),
			Producto VARCHAR(100)
		);

		DECLARE @sql NVARCHAR(MAX);
		SET @sql = N'
			INSERT INTO #tmp_CategoriaProducto (LineaProducto, Producto)
			SELECT * FROM OPENROWSET(
				''Microsoft.ACE.OLEDB.12.0'',
				''Excel 12.0;HDR=YES;Database=' + @FilePath + ''',
				''SELECT * FROM [Clasificacion productos$]''
			)';

		EXEC sp_executesql @sql;

		INSERT INTO catalogo.CategoriaProducto (LineaProducto, Categoria)
		(
			SELECT tmp.LineaProducto, tmp.Producto
				FROM #tmp_CategoriaProducto tmp
				WHERE NOT EXISTS
				(
					SELECT 1
						FROM catalogo.CategoriaProducto c
						WHERE tmp.Producto = c.Categoria 
						COLLATE Modern_Spanish_CI_AS
				)
		)

	END TRY
	BEGIN CATCH
		RAISERROR( 'Error al importar los datos ', 16, 1);
	END CATCH;
	
	IF OBJECT_ID('tempdb..#tmp_CategoriaProducto') IS NOT NULL
        DROP TABLE #tmp_CategoriaProducto;

END;
GO
--FUENTE: https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-data-from-excel-to-sql?view=sql-server-ver16 

-- AUXILIAR === CREACION FUNCION NORMALIZAR STRINGS (utf-8 --> ascii)

IF OBJECT_ID(N'catalogo.utf8_ascii') IS NOT NULL
	DROP TABLE catalogo.utf8_ascii;
	GO

CREATE TABLE catalogo.utf8_ascii(
		id int identity(1,1),
		utf8 NCHAR(2),
		ascii char(1)
);

INSERT INTO catalogo.utf8_ascii
	VALUES 
	('Ã¡', 'á'),
	('Ã‰', 'É'),
	('Ã©', 'é'),
	(CONCAT('Ã', NCHAR(173)), 'í'), --CARACTER INVISIBLE
	('Ã“', 'Ó'),
	(CONCAT('Ã', NCHAR(179)), 'ó'),
	('Ãš', 'Ú'),
	('Ãº', 'ú'),
	('Ã‘', 'Ñ'),
	('Ã±', 'ñ'),
	('Ãœ', 'Ü'),
	('Ã¼', 'ü'),
	('ÃŒ', 'Í'),
	('Âº', 'º'),
	(CONCAT('Ã', NCHAR(129)), 'Á') --CARACTER INVISIBLE


IF OBJECT_ID(N'catalogo.fnNormalizar', N'FN') IS NOT NULL
	DROP FUNCTION catalogo.fnNormalizar;
GO

CREATE OR ALTER FUNCTION catalogo.fnNormalizar (@string VARCHAR(100))
RETURNS VARCHAR(100)
AS
BEGIN
	DECLARE @indice int,
			@total int,
			@utf_8 nchar(2),
			@ascii char(1)

	SET @indice = (SELECT MIN(id) FROM catalogo.utf8_ascii);
	SET @total = (SELECT MAX(id) FROM catalogo.utf8_ascii);

	IF NOT EXISTS (SELECT 1 WHERE @string LIKE '%Ã%' OR @string LIKE '%å%' OR @string LIKE '%Â%')
		RETURN @string;
	
	WHILE @indice <= @total
	BEGIN
		SET @utf_8 = (SELECT TOP(1) utf8 FROM catalogo.utf8_ascii WHERE id = @indice);
		SET @ascii = (SELECT TOP(1) ascii FROM catalogo.utf8_ascii WHERE id = @indice);

		SET @string = REPLACE(@string, @utf_8, @ascii) COLLATE Latin1_General_CI_AS;
		SET @indice = @indice + 1;
	END;
	SET @string = REPLACE(@string, 'å˜','ñ') COLLATE Latin1_General_CI_AS; --caso especial
	SET @string = REPLACE(@string, 'Ãƒº', 'ú') 
	RETURN @string;
END
GO

--< ARCHIVO CATALOGO -->  catalogo.csv >

CREATE OR ALTER PROCEDURE [catalogo].[importarCatalogoCsv]
    @FilePath NVARCHAR(255) 
AS
BEGIN
    BEGIN TRY
        -- Crear la tabla temporal para almacenar los datos del archivo CSV
        CREATE TABLE #staging_catalogo_producto (
            id INT,
            category VARCHAR(100),
            name VARCHAR(100),
            price DECIMAL(10, 2),
            reference_price DECIMAL(10, 2),
            reference_unit VARCHAR(20),
            date DATETIME
        );

        -- Construir la instrucción BULK INSERT con SQL dinámico
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #staging_catalogo_producto 
            FROM ''' + @FilePath + '''
            WITH (
				FORMAT = ''CSV'', 
                FIELDTERMINATOR = '','',  -- Delimitador de campo
                ROWTERMINATOR = ''0x0a'',         -- Delimitador de fila
                FIRSTROW = 1,             -- Ignorar la primera fila de encabezado
                CODEPAGE = ''65001''              -- UTF-8
            );
        ';

        -- Ejecutar la instrucción BULK INSERT usando SQL dinámico
        EXEC sp_executesql @sql;

        -- Seleccionar los datos de la tabla temporal para verificación
        --SELECT * FROM #staging_catalogo_producto;

		WITH cte_Duplicados
		AS
		(
		SELECT tmp.id, ROW_NUMBER() OVER (PARTITION BY tmp.name, tmp.reference_price, tmp.reference_unit, tmp.price, tmp.date ORDER BY tmp.date) as Aparicion
			FROM #staging_catalogo_producto tmp
		)

		/*
		SELECT *
			FROM cte_Duplicados
			WHERE Aparicion > 1
		*/
		DELETE FROM cte_Duplicados
		WHERE Aparicion > 1
		
		UPDATE #staging_catalogo_producto
		SET name = catalogo.fnNormalizar(name)
		WHERE name LIKE '%Ã%' OR name LIKE '%å%' OR name LIKE '%Â%'

		INSERT INTO catalogo.Producto (Nombre, ID_Categoria, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
		(
			SELECT tmp.name,
				   (SELECT c.ID FROM catalogo.CategoriaProducto c WHERE c.Categoria = tmp.category COLLATE Modern_Spanish_CI_AS),
				   tmp.price,
				   tmp.reference_price,
				   tmp.reference_unit,
				   tmp.date
				FROM #staging_catalogo_producto tmp
				WHERE NOT EXISTS
				(
					SELECT 1
						FROM catalogo.Producto p 
						WHERE p.Nombre = tmp.name COLLATE Modern_Spanish_CI_AS
						AND p.PrecioUnitario = tmp.price
						AND p.PrecioReferencia = tmp.reference_price 
						AND p.UnidadReferencia = tmp.reference_unit COLLATE Modern_Spanish_CI_AS
						AND p.Fecha = tmp.date
				)
		)
		

    END TRY
    BEGIN CATCH
        RAISERROR( 'Error al importar los datos ' , 16, 1);
    END CATCH;

    DROP TABLE IF EXISTS #staging_catalogo_producto;
END;
GO

--< ARCHIVO PRODUCTOS IMPORTADOS --> Productos_importados.xlsx >

CREATE OR ALTER PROCEDURE catalogo.ImportarDesdeExcel
    @FilePath NVARCHAR(255) -- Ruta completa del archivo Excel
AS
BEGIN
    BEGIN TRY


        -- Crear tabla temporal para importar los datos
        IF OBJECT_ID('tempdb..#ProductosTemp') IS NOT NULL
            DROP TABLE #ProductosTemp;

        CREATE TABLE #ProductosTemp (
            IdProducto  VARCHAR(20) NULL,
            NombreProducto VARCHAR(100) NULL,
            Proveedor VARCHAR(100) NULL,
			Categoría VARCHAR(100) NULL,
			CantidadPorUnidad VARCHAR(100) NULL,
			PrecioUnidad VARCHAR(100) NULL,
        );

        -- Construir la consulta OPENROWSET para importar desde Excel
        DECLARE @sql NVARCHAR(MAX) = 
        'INSERT INTO #ProductosTemp (IdProducto, NombreProducto, Proveedor, Categoría, CantidadPorUnidad, PrecioUnidad)
         SELECT * FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @FilePath + ''',
            ''SELECT * FROM [Listado de Productos$]''
        )';

        -- Ejecutar la consulta para cargar los datos
        EXEC sp_executesql @sql;

        -- Verificar la carga
        UPDATE #ProductosTemp
		SET Categoría = CONCAT('importado_',Categoría)

		INSERT INTO catalogo.CategoriaProducto (LineaProducto, Categoria)
		(
			SELECT DISTINCT 'Importado', tmp.Categoría
				FROM #ProductosTemp tmp
				WHERE NOT EXISTS
				(
					SELECT 1
						FROM catalogo.CategoriaProducto c
						WHERE c.Categoria = tmp.Categoría COLLATE Modern_Spanish_CI_AS
				)
		)

		INSERT INTO catalogo.Producto (Nombre, ID_Categoria, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
		(
			SELECT tmp.NombreProducto,
				   (SELECT c.ID FROM catalogo.CategoriaProducto c WHERE c.Categoria = tmp.Categoría COLLATE Modern_Spanish_CI_AS),
				   tmp.PrecioUnidad,
				   tmp.PrecioUnidad,
				   tmp.CantidadPorUnidad,
				   GETDATE()
				FROM #ProductosTemp tmp
				WHERE NOT EXISTS
				(
					SELECT 1
						FROM catalogo.Producto p 
						WHERE p.Nombre = tmp.NombreProducto COLLATE Modern_Spanish_CI_AS
						AND p.PrecioUnitario = tmp.PrecioUnidad
						AND p.PrecioReferencia = tmp.PrecioUnidad 
						AND p.UnidadReferencia = tmp.CantidadPorUnidad COLLATE Modern_Spanish_CI_AS
				) 
		)


    END TRY
    BEGIN CATCH
        RAISERROR( 'Error al importar el archivo Excel ', 16, 1);
    END CATCH;
END;
GO

-- AUXILIAR ==== FUNCION OBTENER VALOR DOLAR MEDIANTE UNA API

CREATE OR ALTER FUNCTION [catalogo].[ConversionDolarPeso] ()
RETURNS INT
BEGIN
DECLARE @URL NVARCHAR(MAX) = 'https://dolarapi.com/v1/dolares/oficial';
Declare @Object as Int;
Declare @ResponseText as Varchar(8000);
Declare @valor as int;

Exec sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
Exec sp_OAMethod @Object, 'open', NULL, 'get',
       @URL,
       'False'
Exec sp_OAMethod @Object, 'send'
Exec sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT
IF((Select @ResponseText) <> '')
BEGIN
     DECLARE @json NVARCHAR(MAX) = (Select @ResponseText)
		SET @valor = 
			CAST(ROUND(CAST(
				(SELECT venta
				 FROM OPENJSON(@json)
				 WITH (
					moneda VARCHAR(10) '$.moneda',
					casa VARCHAR(10) '$.casa',
					nombre VARCHAR(10) '$.nombre',
					compra VARCHAR(10) '$.compra',
					venta VARCHAR(10) '$.venta',
					fechaActualizacion NVARCHAR(20) '$.fechaActualizacion'
				 )
				) AS FLOAT), 0) AS INT);
END
ELSE
	 SET @valor = 1000;
Exec sp_OADestroy @Object
RETURN @valor
END
GO

--< ARCHIVO ACCESORIOS ELECTRONICOS --> Electronic accessories.xlsx >
-- SE INSERTA EL VALOR EN PESOS AL MOMENTO DE REALIZAR LA INSERCION
-- MEDIANTE UNA API QUE OBTIENE EL VALOR DEL DOLAR, EL PRECIO EN USD
-- SE GUARDA EN PRECIO DE REFERENCIA Y LA UNIDAD DE REFERENCIA ES USD

CREATE OR ALTER PROCEDURE catalogo.ImportarDesdeExcelElectronicos
    @FilePath NVARCHAR(255) -- Ruta completa del archivo Excel
AS
BEGIN
	DECLARE @valorDolar as INT;
	SET @valorDolar = catalogo.ConversionDolarPeso()
	IF (@valorDolar = 0)
		RAISERROR( 'Error al obtener el valor del dolar en pesos', 16, 1)

    BEGIN TRY
        -- Configurar opciones avanzadas
        EXEC sp_configure 'show advanced options', 1;
        RECONFIGURE;
        EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
        RECONFIGURE;

        -- Crear tabla temporal para importar los datos
        IF OBJECT_ID('tempdb..#ProductosTemp') IS NOT NULL
            DROP TABLE #ProductosTemp;

        CREATE TABLE #ProductosTemp (
            Product VARCHAR(100) NULL,
            PrecioUnitarioenDolares VARCHAR(10) NULL
        );

        -- Construir la consulta OPENROWSET para importar desde Excel
        DECLARE @sql NVARCHAR(MAX) = 
        'INSERT INTO #ProductosTemp (Product, PrecioUnitarioenDolares)
         SELECT * FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @FilePath + ''',
            ''SELECT * FROM [Sheet1$]''
        )';

        -- Ejecutar la consulta para cargar los datos
        EXEC sp_executesql @sql;

        -- Verificar la carga
        --SELECT * FROM #ProductosTemp;

		-- Obtener valor del dolar
		IF NOT EXISTS (SELECT 1 FROM catalogo.CategoriaProducto WHERE Categoria = 'Electronico' AND LineaProducto = 'Accesorio')
		BEGIN
			INSERT INTO catalogo.CategoriaProducto (LineaProducto, Categoria)
			VALUES ('Accesorio', 'Electronico')
		END
		
		INSERT INTO catalogo.Producto (Nombre, ID_Categoria, PrecioUnitario, PrecioReferencia, UnidadReferencia, Fecha)
		(
			SELECT tmp.Product,
				   (SELECT c.ID FROM catalogo.CategoriaProducto c WHERE c.Categoria = 'Electronico'),
				   CAST(tmp.PrecioUnitarioenDolares as DECIMAL(10,2)) * @valorDolar,
				   CAST(tmp.PrecioUnitarioenDolares as DECIMAL(10,2)),
				   'USD',
				   GETDATE()
				FROM #ProductosTemp tmp
				WHERE NOT EXISTS 
					(
						SELECT 1
							FROM catalogo.Producto p
							WHERE p.Nombre = tmp.Product COLLATE Modern_Spanish_CI_AS AND p.PrecioReferencia = CAST(tmp.PrecioUnitarioenDolares as DECIMAL(10,2))
					)
		)

    END TRY
    BEGIN CATCH
        RAISERROR( 'Error al importar el archivo Excel ', 16, 1);
    END CATCH;
END;
GO

-- ==== INSERCION VENTAS ====

--< ARCHIVO MEDIOS DE PAGO --> Informacion_complementaria.xlsx >

CREATE OR ALTER PROCEDURE ventas.ImportarMediosDePago
    @filePath NVARCHAR(255)
AS
BEGIN
    BEGIN TRY
        -- Configurar opciones avanzadas
        EXEC sp_configure 'show advanced options', 1;
        RECONFIGURE;
        EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
        RECONFIGURE;

        IF OBJECT_ID('tempdb..#tmpMedioDePago') IS NOT NULL
            DROP TABLE #tmpMedioDePago;

        CREATE TABLE #tmpMedioDePago (
			AUX CHAR(1),
			ENG VARCHAR(50),
			ESP VARCHAR(50)
        );

        -- Construir la consulta OPENROWSET para importar desde Excel
        DECLARE @sql NVARCHAR(MAX) =
        N'INSERT INTO #tmpMedioDePago (AUX, ENG, ESP)
         SELECT * FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @FilePath + ''',
            ''SELECT * FROM [medios de pago$]''
        )';

        EXEC sp_executesql @sql;
		
		--SELECT * FROM #tmpMedioDePago;
		
		INSERT INTO ventas.MedioPago (Descripcion_ESP, Descripcion_ENG)
		(
			SELECT tmp.ESP, tmp.ENG
				FROM #tmpMedioDePago tmp
				WHERE NOT EXISTS 
				( 
				SELECT 1 
					FROM ventas.MedioPago m
					WHERE tmp.ESP = m.Descripcion_ESP COLLATE Modern_Spanish_CI_AS OR tmp.ENG = m.Descripcion_ENG COLLATE Modern_Spanish_CI_AS
				)
		)
		
    END TRY
    BEGIN CATCH
        RAISERROR( 'Error al importar el archivo Excel ', 16, 1);
    end catch

		DROP TABLE IF EXISTS #tmpMedioDePago;

end
GO

--< ARCHIVO VENTAS --> Ventas_registradas.csv >

CREATE OR ALTER PROCEDURE [ventas].[importarVentasCsv]
    @FilePath NVARCHAR(255) 
AS
BEGIN
    BEGIN TRY
        -- Crear la tabla temporal para almacenar los datos del archivo CSV
        CREATE TABLE #tmp_ventas (
			ID_FACTURA VARCHAR(50),
			Tipo_De_Factura CHAR(1),
			Ciudad VARCHAR(50),
			Tipo_De_Cliente VARCHAR(30),
			Genero VARCHAR(50),
			Producto VARCHAR(200),
			Precio_Unitario DECIMAL(10,2),
			Cantidad int,
			Fecha VARCHAR(20),
			Hora VARCHAR(20),
			Medio_De_Pago VARCHAR(30),
			Legajo_Empleado VARCHAR(50),
			Identificador_Pago VARCHAR(100)
        );

        -- Construir la instrucción BULK INSERT con SQL dinámico
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
            BULK INSERT #tmp_ventas 
            FROM ''' + @FilePath + '''
            WITH (
				FORMAT = ''CSV'', 
                FIELDTERMINATOR = '';'',  -- Delimitador de campo
                ROWTERMINATOR = ''0x0a'',         -- Delimitador de fila
                FIRSTROW = 2,             -- Ignorar la primera fila de encabezado
                CODEPAGE = ''65001''              -- UTF-8
            );
        ';
        -- Ejecutar la instrucción BULK INSERT usando SQL dinámico
        EXEC sp_executesql @sql;


		--tratamiento fecha
		UPDATE #tmp_ventas
		SET Fecha = Fecha + ' ' + Hora

		UPDATE #tmp_ventas
		SET Producto = catalogo.fnNormalizar(Producto)

		IF NOT EXISTS (SELECT 1 FROM tienda.Cliente WHERE Nombre = 'AuxiliarImportaciones')
			INSERT INTO tienda.Cliente (Nombre, TipoCliente, Genero, Estado) VALUES ('AuxiliarImportaciones', 'Member', 'M', 1);	
		
		INSERT INTO ventas.Venta(Fecha, ID_Cliente, Total, id_factura_importado, ID_SUCURSAL, ID_Empleado)
		(
		SELECT CONVERT(DATE, tmp.Fecha, 101),
				(SELECT TOP(1) c.ID FROM tienda.Cliente c),
				tmp.Cantidad * tmp.Precio_Unitario,
				tmp.ID_FACTURA,
				(SELECT s.ID FROM tienda.Sucursal s WHERE s.Ciudad_anterior = tmp.Ciudad),
				(SELECT e.ID FROM tienda.Empleado e WHERE e.Legajo = tmp.Legajo_Empleado)
			FROM #tmp_ventas tmp
			WHERE NOT EXISTS 
			(
				SELECT 1
					FROM ventas.Venta v
					WHERE v.id_factura_importado = tmp.ID_FACTURA
			)
		)
		
		INSERT INTO ventas.DetalleVenta(ID_Venta, ID_Producto, Cantidad, Precio_Unitario, Subtotal)
		(
		SELECT 
			(SELECT v.ID FROM ventas.Venta v WHERE v.id_factura_importado = tmp.ID_FACTURA),
			(SELECT p.ID FROM catalogo.Producto p WHERE p.Nombre = tmp.Producto AND p.PrecioUnitario = tmp.Precio_Unitario),
			tmp.Cantidad,
			tmp.Precio_Unitario,
			tmp.Cantidad * tmp.Precio_Unitario
			FROM #tmp_ventas tmp
			WHERE NOT EXISTS 
			(
				SELECT 1
					FROM ventas.DetalleVenta d
					WHERE d.ID_Venta = (SELECT v.ID FROM ventas.Venta v WHERE v.id_factura_importado = tmp.ID_FACTURA)

			)
			AND EXISTS
			(
				SELECT 1
					FROM ventas.Venta v
					WHERE v.id_factura_importado = tmp.ID_FACTURA
			)
			AND EXISTS
			(
				SELECT 1
					FROM catalogo.Producto p
					WHERE p.Nombre = tmp.Producto AND p.PrecioUnitario = tmp.Precio_Unitario
			)
		)

		
		INSERT INTO ventas.Factura(Estado, FechaHora, Comprobante, PuntoDeVenta, SubTotal, IvaTotal, Total, ID_Venta)
		(
		SELECT 'Pagada',
				v.Fecha,
				'--',
				'00000',
				v.Total,
				v.Total * 0.21,
				v.Total + v.Total * 0.21,
				v.ID
			FROM ventas.Venta v JOIN #tmp_ventas tmp ON v.id_factura_importado = tmp.ID_FACTURA
			WHERE NOT EXISTS
			(
				SELECT 1
					FROM ventas.Factura f
					WHERE f.ID_Venta = v.ID
			)
		)

		INSERT INTO ventas.DetalleFactura(ID_Factura, ID_Producto, Cantidad, PrecioUnitario, IVA, Subtotal)
		(
		SELECT f.ID,
				dv.ID_Producto,
				dv.Cantidad,
				dv.Precio_Unitario,
				dv.Cantidad * dv.Precio_Unitario * 0.21,
				dv.Cantidad * dv.Precio_Unitario + dv.Cantidad * dv.Precio_Unitario * 0.21
			FROM #tmp_ventas tmp 
			JOIN ventas.Venta v ON v.id_factura_importado = tmp.ID_FACTURA
			JOIN ventas.Factura f ON f.ID_Venta = v.ID
			JOIN ventas.DetalleVenta dv ON dv.ID_Venta = v.ID
			WHERE NOT EXISTS
			(
				SELECT 1
					FROM ventas.DetalleFactura df
					WHERE df.ID_Factura = f.ID
			)
		)

		INSERT INTO ventas.Pago(ID_Factura, ID_MedioPago, Monto, Fecha_Pago)
		(
		SELECT f.ID,
			(SELECT mp.ID FROM ventas.MedioPago mp WHERE mp.Descripcion_ENG = tmp.Medio_De_Pago),
			f.Total,
			f.FechaHora
			FROM ventas.Factura f 
			JOIN ventas.Venta v ON f.ID_Venta = v.ID
			JOIN #tmp_ventas tmp ON v.id_factura_importado = tmp.ID_FACTURA
			WHERE NOT EXISTS
			(
				SELECT 1
					FROM ventas.Pago p
					WHERE p.ID_Factura = f.ID
			)
		)
		
    END TRY
    BEGIN CATCH
        -- Capturar errores
        RAISERROR( 'Error al importar los datos ' , 16, 1);
		
    END CATCH;

    -- Eliminar la tabla temporal al final del procedimiento
    DROP TABLE IF EXISTS #tmp_ventas;
END;
GO

SET NOCOUNT OFF