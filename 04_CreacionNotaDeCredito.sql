USE Com2900G16;
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
-- Procedimiento para Generar Nota de Crédito
GO
CREATE PROCEDURE ventas.CrearNotaCredito
    @ID_Factura INT,
    @ID_Producto INT = NULL, -- Opcional, NULL para cancelar toda la factura
    @Motivo VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
	IF NOT EXISTS (SELECT 1 FROM ventas.Factura WHERE ID = @ID_Factura AND Estado = 'Pagada')
	BEGIN
			RAISERROR ('La nota de crédito solo puede generarse para facturas pagadas.', 16,1);
			RETURN
	END;

    IF @ID_Producto IS NULL
    BEGIN
        -- Cancelar factura completa
        UPDATE ventas.Factura
        SET Estado = 'Cancelada'
        WHERE ID = @ID_Factura;

        UPDATE ventas.DetalleFactura
        SET Estado = 1
        WHERE ID_Factura = @ID_Factura;
    END
    ELSE
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM ventas.DetalleFactura WHERE ID_Producto = @ID_Producto AND ID_Factura = @ID_Factura)
		BEGIN
			RAISERROR ('El producto no está facturado.', 16,1);
			RETURN
		END;

		-- Cancelar producto específico
        UPDATE ventas.DetalleFactura
        SET Estado = 1
        WHERE ID_Factura = @ID_Factura AND ID_Producto = @ID_Producto;

		UPDATE ventas.Factura
        SET Estado = 'Cancelada'
        WHERE ID = @ID_Factura;
    END

    -- Registrar la nota de crédito
    INSERT INTO ventas.NotaCredito (ID_Factura, ID_Cliente, ID_Producto, Motivo, Comprobante)
    SELECT 
        @ID_Factura, 
        v.ID_Cliente, 
        @ID_Producto, 
        @Motivo, 
		f.Comprobante
    FROM ventas.Factura f
	INNER JOIN ventas.Venta v ON f.ID_Venta = v.ID
    WHERE f.ID = @ID_Factura;
END;
GO

GO

GO
CREATE OR ALTER PROCEDURE ventas.CrearRolSupervisor
AS  
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Supervisor')
    BEGIN
        EXEC('CREATE ROLE Supervisor');
    END

    GRANT EXECUTE ON ventas.CrearNotaCredito TO Supervisor;
    GRANT SELECT ON schema::ventas TO Supervisor;
END;

GO
