USE Com2900G16;
GO

-- Reporte mensual: Total facturado por días de la semana 
CREATE OR ALTER PROCEDURE informe.ReporteMensualPorDiaSemana
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        DATENAME(WEEKDAY, fac.FechaHora) AS DiaSemana,
        SUM(CASE WHEN dv.Estado != 1 THEN dv.Subtotal ELSE 0 END) AS TotalFacturado
    FROM ventas.Factura fac
    LEFT JOIN ventas.DetalleFactura dv ON fac.ID = dv.ID_Factura
    WHERE 
        YEAR(fac.FechaHora) = @Anio AND 
        MONTH(fac.FechaHora) = @Mes AND 
        fac.Estado = 'Pagada'
    GROUP BY DATENAME(WEEKDAY, fac.FechaHora)
    ORDER BY CASE 
                WHEN DATENAME(WEEKDAY, fac.FechaHora) = 'Monday' THEN 1
                WHEN DATENAME(WEEKDAY, fac.FechaHora) = 'Tuesday' THEN 2
                WHEN DATENAME(WEEKDAY, fac.FechaHora) = 'Wednesday' THEN 3
                WHEN DATENAME(WEEKDAY, fac.FechaHora) = 'Thursday' THEN 4
                WHEN DATENAME(WEEKDAY, fac.FechaHora) = 'Friday' THEN 5
                WHEN DATENAME(WEEKDAY, fac.FechaHora) = 'Saturday' THEN 6
                WHEN DATENAME(WEEKDAY, fac.FechaHora) = 'Sunday' THEN 7
             END

    FOR XML PATH('DiaSemana'), ROOT('ReporteMensual')
END;
GO

-- Reporte trimestral: Total facturado por turnos de trabajo por mes 
CREATE OR ALTER PROCEDURE informe.ReporteTrimestralPorTurno
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        (DATEPART(MONTH, fac.FechaHora) - 1) / 3 + 1 AS Trimestre, -- Cálculo del trimestre
        emp.Turno AS Turno,
        SUM(CASE WHEN dv.Estado != 1 THEN dv.Subtotal ELSE 0 END) AS TotalFacturado
    FROM ventas.Factura fac
    LEFT JOIN ventas.DetalleFactura dv ON fac.ID = dv.ID_Factura
    LEFT JOIN ventas.Venta v ON v.ID = fac.ID_Venta
    JOIN tienda.Empleado emp ON v.ID_Empleado = emp.ID
    WHERE 
        YEAR(fac.FechaHora) = @Anio
    GROUP BY (DATEPART(MONTH, fac.FechaHora) - 1) / 3 + 1, emp.Turno
    ORDER BY Trimestre, Turno
    FOR XML PATH('Turno'), ROOT('ReporteTrimestral')
END;
GO

-- Reporte por rango de fechas: Cantidad de productos vendidos 
CREATE OR ALTER PROCEDURE informe.ReportePorRangoFechasCantidadProductos
    @FechaInicio DATETIME,
    @FechaFin DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        prod.Nombre AS Producto,
        SUM(CASE WHEN df.Estado != 1 THEN df.Cantidad ELSE 0 END) AS CantidadVendida
    FROM ventas.DetalleFactura df
    JOIN ventas.Factura fac ON df.ID_Factura = fac.ID
    JOIN catalogo.Producto prod ON df.ID_Producto = prod.ID
    WHERE 
        fac.FechaHora BETWEEN @FechaInicio AND @FechaFin 
    GROUP BY prod.Nombre
    ORDER BY CantidadVendida DESC

    FOR XML PATH('Producto'), ROOT('ReporteRangoFechasCantidad')
END;
GO



-- Reporte por rango de fechas: Cantidad de productos vendidos por sucursal 
CREATE OR ALTER PROCEDURE informe.ReportePorRangoFechasSucursal
    @FechaInicio DATETIME,
    @FechaFin DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        suc.Direccion AS Sucursal,
        SUM(CASE WHEN df.Estado != 1 THEN df.Cantidad ELSE 0 END) AS CantidadVendida
    FROM ventas.DetalleFactura df
    JOIN ventas.Factura fac ON df.ID_Factura = fac.ID
    JOIN catalogo.Producto prod ON df.ID_Producto = prod.ID
    LEFT JOIN ventas.Venta v ON v.ID = fac.ID_Venta
    JOIN tienda.Sucursal suc ON v.ID_Sucursal = suc.ID
    WHERE 
        fac.FechaHora BETWEEN @FechaInicio AND @FechaFin 
    GROUP BY suc.Direccion
    ORDER BY CantidadVendida DESC

    FOR XML PATH('Producto'), ROOT('ReporteRangoFechasSucursal')
END;
GO


-- Reporte mensual: Top 5 productos más vendidos por semana 
CREATE OR ALTER PROCEDURE informe.Top5ProductosMasVendidosPorSemana
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para calcular las semanas relativas al mes
    WITH ProductosPorSemana AS (
        SELECT 
            prod.Nombre AS Producto,
            DATEPART(WEEK, fac.FechaHora) - DATEPART(WEEK, DATEFROMPARTS(@Anio, @Mes, 1)) + 1 AS SemanaDelMes,
            SUM(CASE WHEN dv.Estado != 1 THEN dv.Cantidad ELSE 0 END) AS CantidadVendida
        FROM ventas.DetalleFactura dv
        JOIN ventas.Factura fac ON dv.ID_Factura = fac.ID
        JOIN catalogo.Producto prod ON dv.ID_Producto = prod.ID
        WHERE 
            YEAR(fac.FechaHora) = @Anio AND 
            MONTH(fac.FechaHora) = @Mes
        GROUP BY 
            prod.Nombre, 
            DATEPART(WEEK, fac.FechaHora) - DATEPART(WEEK, DATEFROMPARTS(@Anio, @Mes, 1)) + 1
    )
    SELECT 
        SemanaDelMes,
        Producto,
        CantidadVendida
    FROM (
        SELECT 
            SemanaDelMes,
            Producto,
            CantidadVendida,
            ROW_NUMBER() OVER (PARTITION BY SemanaDelMes ORDER BY CantidadVendida DESC) AS Rango
        FROM ProductosPorSemana
    ) AS Ranking
    WHERE Rango <= 5 -- Top 5 por semana
    ORDER BY SemanaDelMes, CantidadVendida DESC
	FOR XML PATH('Producto'), ROOT('ReporteTop5PorSemana')

END;
GO



-- Reporte mensual: Top 5 productos menos vendidos 
CREATE OR ALTER PROCEDURE informe.Top5ProductosMenosVendidosPorSemana
    @Mes INT,
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para calcular las semanas relativas al mes
    WITH ProductosPorSemana AS (
        SELECT 
            prod.Nombre AS Producto,
            DATEPART(WEEK, fac.FechaHora) - DATEPART(WEEK, DATEFROMPARTS(@Anio, @Mes, 1)) + 1 AS SemanaDelMes,
            SUM(CASE WHEN dv.Estado != 1 THEN dv.Cantidad ELSE 0 END) AS CantidadVendida
        FROM ventas.DetalleFactura dv
        JOIN ventas.Factura fac ON dv.ID_Factura = fac.ID
        JOIN catalogo.Producto prod ON dv.ID_Producto = prod.ID
        WHERE 
            YEAR(fac.FechaHora) = @Anio AND 
            MONTH(fac.FechaHora) = @Mes
        GROUP BY 
            prod.Nombre, 
            DATEPART(WEEK, fac.FechaHora) - DATEPART(WEEK, DATEFROMPARTS(@Anio, @Mes, 1)) + 1
    )
    SELECT 
        SemanaDelMes,
        Producto,
        CantidadVendida
    FROM (
        SELECT 
            SemanaDelMes,
            Producto,
            CantidadVendida,
            ROW_NUMBER() OVER (PARTITION BY SemanaDelMes ORDER BY CantidadVendida ASC) AS Rango
        FROM ProductosPorSemana
    ) AS Ranking
    WHERE Rango <= 5 -- Top 5 por semana
    ORDER BY SemanaDelMes, CantidadVendida ASC
	FOR XML PATH('Producto'), ROOT('ReporteTop5MenosPorSemana')
END;
GO


-- Reporte acumulado de ventas por fecha y sucursal 
CREATE OR ALTER PROCEDURE informe.TotalAcumuladoVentas
    @Fecha DATETIME,
    @SucursalID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Consulta para Detalle de Ventas con Total Acumulado en un solo XML
    SELECT 
        v.ID AS ID_Venta,
        v.Fecha AS FechaVenta,
        v.ID_Sucursal AS Sucursal,
        emp.Nombre + ' ' + emp.Apellido AS Empleado,
        c.Nombre AS Cliente,
        prod.Nombre AS Producto,
        dv.Cantidad AS CantidadVendida,
        dv.Precio_Unitario AS PrecioUnitario,
        dv.Subtotal AS Subtotal,
        (SELECT SUM(v.Total) 
         FROM ventas.Venta v 
         WHERE v.Fecha = @Fecha AND v.ID_Sucursal = @SucursalID) AS TotalAcumulado
    FROM ventas.Venta v
    JOIN ventas.DetalleVenta dv ON v.ID = dv.ID_Venta
    JOIN catalogo.Producto prod ON dv.ID_Producto = prod.ID
    JOIN tienda.Empleado emp ON v.ID_Empleado = emp.ID
    LEFT JOIN tienda.Cliente c ON v.ID_Cliente = c.ID
    WHERE 
        v.Fecha = @Fecha AND
        v.ID_Sucursal = @SucursalID
    FOR XML PATH('VentaDetalle'), ROOT('DetalleVentas');
END;
GO

