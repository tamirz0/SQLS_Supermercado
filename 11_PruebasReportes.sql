USE Com2900G16;
GO

-- Limpieza previa para evitar conflictos
EXEC informe.LimpiarTodasLasTablas;

-- Insertar datos en la tabla Sucursal
INSERT INTO tienda.Sucursal (Direccion, Ciudad) 
VALUES 
('Sucursal Centro', 'Ciudad A'),
('Sucursal Norte', 'Ciudad B'),
('Sucursal Sur', 'Ciudad C');
SELECT * FROM  tienda.Sucursal

-- Insertar datos en la tabla Empleado
INSERT INTO tienda.Empleado (Legajo, Nombre, Apellido, DNI, MailEmpresa, CUIL, Cargo, Turno, ID_Sucursal) 
VALUES 
('000001', 'Juan', 'Perez', '12345678', 'juan.perez@empresa.com', '20-12345678-9', 'Cajero', 'M', 1),
('000002', 'Ana', 'Garcia', '87654321', 'ana.garcia@empresa.com', '27-87654321-0', 'Supervisor', 'T', 2),
('000003', 'Luis', 'Lopez', '11223344', 'luis.lopez@empresa.com', '23-11223344-5', 'Gerente', 'N', 3);
SELECT * FROM  tienda.Empleado

-- Insertar datos en la tabla Cliente
INSERT INTO tienda.Cliente (Nombre, TipoCliente, Genero, CUIT)
VALUES 
('Maria Lopez', 'Normal', 'F', '20-98765432-1'),
('Carlos Diaz', 'Member', 'M', '20-87654321-2');
SELECT * FROM  tienda.Cliente

-- Insertar datos en la tabla CategoriaProducto
INSERT INTO catalogo.CategoriaProducto (LineaProducto, Categoria)
VALUES 
('Línea Blanca', 'Electrodomésticos'),
('Hogar', 'Muebles');
SELECT * FROM  catalogo.CategoriaProducto

-- Insertar datos en la tabla Producto
INSERT INTO catalogo.Producto (Nombre, ID_Categoria, PrecioUnitario, Fecha, IVA)
VALUES 
('Heladera', 1, 45000.00, '2024-01-01', 0.21),
('Microondas', 1, 15000.00, '2024-01-02', 0.21),
('Silla', 2, 1200.00, '2024-01-03', 0.21);
SELECT * FROM  catalogo.Producto


-- Insertar datos en la tabla MedioPago
INSERT INTO ventas.MedioPago (Descripcion_ESP, Descripcion_ENG)
VALUES 
('Efectivo', 'Cash'),
('Tarjeta de Crédito', 'Credit Card'),
('Tarjeta de Débito', 'Debit Card');
SELECT * FROM ventas.MedioPago

-- Insertar datos en la tabla Venta
INSERT INTO ventas.Venta (Fecha, ID_Cliente, Total, ID_Sucursal,ID_Empleado)
VALUES 
('2024-09-01', 1, 45000.00, 1,1),
('2024-11-02', 2, 33600.00, 2,2),
('2024-11-03', 1, 1200.00, 3,1);
SELECT * FROM ventas.Venta

-- Insertar datos en la tabla DetalleVenta
INSERT INTO ventas.DetalleVenta (ID_Venta, ID_Producto, Cantidad, Precio_Unitario, Subtotal)
VALUES 
(1, 1, 1, 45000.00, 45000.00),
(2, 2, 1, 15000.00, 30000.00),
(2, 3, 3, 1200.00, 3600.00),
(3, 3, 25, 1200.00, 30000.00);
SELECT * FROM ventas.DetalleVenta

-- Insertar datos en la tabla Factura
INSERT INTO ventas.Factura (Estado, FechaHora, Comprobante, PuntoDeVenta, SubTotal, IvaTotal, Total, ID_Venta)
VALUES 
('Pagada', '2024-09-01 10:00:00', 'A001', '00001', 45000.00, 9450.00, 54450.00, 1),
('Pagada', '2024-11-02 15:00:00', 'A002', '00002', 34600.00, 7266.00, 49650.00, 2),
('Pagada', '2024-11-03 18:00:00', 'A003', '00003', 30000.00, 6300.00, 36300.00, 3);
SELECT * FROM ventas.Factura

-- Insertar datos en la tabla DetalleFactura
INSERT INTO ventas.DetalleFactura (ID_Factura, ID_Producto, Cantidad, PrecioUnitario, IVA, Subtotal,Estado)
VALUES 
(1, 1, 1, 45000.00, 9450.00, 54450.00,0),
(2, 2, 1, 15000.00, 3150.00, 18150.00,0),
(2, 3, 3, 1200.00, 2520.00, 31500.00,0),
(3, 3, 25, 1200.00, 6300.00, 36000.00,0);
SELECT * FROM ventas.DetalleFactura

-- Insertar datos en la tabla Pago
INSERT INTO ventas.Pago (ID_Factura, ID_MedioPago, Monto)
VALUES 
(1, 1, 54450.00),
(2, 2, 41866.00),
(3, 2, 36300.00);

--- 1. Llamado para obtener el reporte mensual de total facturado por días de la semana
EXEC informe.ReporteMensualPorDiaSemana @Mes = 11, @Anio = 2024;
-- Esperado: 
/*<ReporteMensual>
  <DiaSemana>
    <DiaSemana>Saturday</DiaSemana>
    <TotalFacturado>49650.00</TotalFacturado>
  </DiaSemana>
  <DiaSemana>
    <DiaSemana>Sunday</DiaSemana>
    <TotalFacturado>36000.00</TotalFacturado>
  </DiaSemana>
</ReporteMensual>*/

-- 2. Llamado para obtener el reporte trimestral de total facturado por turnos de trabajo por mes
EXEC informe.ReporteTrimestralPorTurno @Anio = 2024;
-- Esperado:
/*<ReporteTrimestral>
  <Turno>
    <Trimestre>3</Trimestre>
    <Turno>M </Turno>
    <TotalFacturado>54450.00</TotalFacturado>
  </Turno>
  <Turno>
    <Trimestre>4</Trimestre>
    <Turno>M </Turno>
    <TotalFacturado>36000.00</TotalFacturado>
  </Turno>
  <Turno>
    <Trimestre>4</Trimestre>
    <Turno>T </Turno>
    <TotalFacturado>49650.00</TotalFacturado>
  </Turno>
</ReporteTrimestral>*/

-- 3. Llamado para obtener la cantidad de productos vendidos en un rango de fechas
DECLARE @FechaInicio DATETIME, @FechaFin DATETIME;
SET @FechaInicio = CONVERT(DATETIME, '01/10/2024', 103);
SET @FechaFin = CONVERT(DATETIME, '30/11/2024', 103);

EXEC informe.ReportePorRangoFechasCantidadProductos 
    @FechaInicio = @FechaInicio, 
    @FechaFin = @FechaFin;
-- Esperado:
/*<ReporteRangoFechasCantidad>
  <Producto>
    <Producto>Silla</Producto>
    <CantidadVendida>28</CantidadVendida>
  </Producto>
  <Producto>
    <Producto>Microondas</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
</ReporteRangoFechasCantidad>*/

-- 4. Llamado para obtener la cantidad de productos vendidos por sucursal en un rango de fechas
DECLARE @FechaInicio DATETIME, @FechaFin DATETIME;
SET @FechaInicio = CONVERT(DATETIME, '01/01/2024', 103);
SET @FechaFin = CONVERT(DATETIME, '30/11/2024', 103);

EXEC informe.ReportePorRangoFechasSucursal 
    @FechaInicio = @FechaInicio, 
    @FechaFin = @FechaFin;
-- Esperado:
/*<ReporteRangoFechasSucursal>
  <Producto>
    <Sucursal>Sucursal Sur</Sucursal>
    <CantidadVendida>25</CantidadVendida>
  </Producto>
  <Producto>
    <Sucursal>Sucursal Norte</Sucursal>
    <CantidadVendida>4</CantidadVendida>
  </Producto>
  <Producto>
    <Sucursal>Sucursal Centro</Sucursal>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
</ReporteRangoFechasSucursal>*/

-- 5. Llamado para obtener el top 5 de productos más vendidos en un mes
-- Nuevos productos
INSERT INTO catalogo.Producto (Nombre, ID_Categoria, PrecioUnitario, Fecha, IVA)
VALUES 
('Lavarropas', 1, 60000.00, '2024-01-05', 0.21),
('Televisor', 1, 120000.00, '2024-01-06', 0.21),
('Mesa', 2, 4500.00, '2024-01-07', 0.21),
('Sillón', 2, 18000.00, '2024-01-08', 0.21),
('Aire Acondicionado', 1, 85000.00, '2024-01-09', 0.21);

-- Nuevas ventas
INSERT INTO ventas.Venta (Fecha, ID_Cliente, Total, ID_Sucursal, ID_Empleado)
VALUES 
('2024-11-10', 1, 120000.00, 1, 2),
('2024-11-12', 2, 18000.00, 3, 3),
('2024-11-13', 1, 94500.00, 2, 1),
('2024-11-15', 2, 4500.00, 1, 1),
('2024-11-18', 1, 60000.00, 3, 2);

-- Nuevos detalles de ventas
INSERT INTO ventas.DetalleVenta (ID_Venta, ID_Producto, Cantidad, Precio_Unitario, Subtotal)
VALUES 
(4, 5, 1, 120000.00, 120000.00), -- Televisor
(5, 6, 1, 18000.00, 18000.00),   -- Sillón
(6, 7, 3, 1500.00, 4500.00),     -- Mesa
(7, 1, 1, 60000.00, 60000.00),   -- Lavarropas
(8, 5, 1, 85000.00, 85000.00);   -- Aire Acondicionado

-- Nuevas facturas
INSERT INTO ventas.Factura (Estado, FechaHora, Comprobante, PuntoDeVenta, SubTotal, IvaTotal, Total, ID_Venta)
VALUES 
('Pagada', '2024-11-10 09:30:00', 'A004', '00004', 120000.00, 25200.00, 145200.00, 4),
('Pagada', '2024-11-12 14:45:00', 'A005', '00005', 18000.00, 3780.00, 21780.00, 5),
('Pagada', '2024-11-13 16:20:00', 'A006', '00006', 94500.00, 19845.00, 114345.00, 6),
('Pagada', '2024-11-15 10:10:00', 'A007', '00007', 4500.00, 945.00, 5445.00, 7),
('Pagada', '2024-11-18 11:50:00', 'A008', '00008', 60000.00, 12600.00, 72600.00, 8);

-- Nuevos detalles de facturas
INSERT INTO ventas.DetalleFactura (ID_Factura, ID_Producto, Cantidad, PrecioUnitario, IVA, Subtotal, Estado)
VALUES 
(4, 5, 1, 120000.00, 25200.00, 145200.00, 0),
(5, 6, 1, 18000.00, 3780.00, 21780.00, 0),
(6, 7, 3, 1500.00, 945.00, 5445.00, 0),
(7, 1, 1, 60000.00, 12600.00, 72600.00, 0),
(8, 5, 1, 85000.00, 17850.00, 102850.00, 0);

-- Nuevos pagos
INSERT INTO ventas.Pago (ID_Factura, ID_MedioPago, Monto)
VALUES 
(4, 2, 145200.00),
(5, 1, 21780.00),
(6, 3, 114345.00),
(7, 2, 5445.00),
(8, 1, 72600.00);

EXEC informe.Top5ProductosMasVendidosPorSemana @Mes = 11, @Anio = 2024;
-- Esperado:
/*<ReporteTop5PorSemana>
  <Producto>
    <SemanaDelMes>1</SemanaDelMes>
    <Producto>Silla</Producto>
    <CantidadVendida>3</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>1</SemanaDelMes>
    <Producto>Microondas</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>2</SemanaDelMes>
    <Producto>Silla</Producto>
    <CantidadVendida>25</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Sillón</Producto>
    <CantidadVendida>3</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Televisor</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Heladera</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Mesa</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>4</SemanaDelMes>
    <Producto>Televisor</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
</ReporteTop5PorSemana>
*/
-- 6. Llamado para obtener el top 5 de productos menos vendidos en un mes
EXEC informe.Top5ProductosMenosVendidosPorSemana @Mes = 11, @Anio = 2024;
-- Esperado:
/*<ReporteTop5MenosPorSemana>
  <Producto>
    <SemanaDelMes>1</SemanaDelMes>
    <Producto>Microondas</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>1</SemanaDelMes>
    <Producto>Silla</Producto>
    <CantidadVendida>3</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>2</SemanaDelMes>
    <Producto>Silla</Producto>
    <CantidadVendida>25</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Heladera</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Mesa</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Televisor</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>3</SemanaDelMes>
    <Producto>Sillón</Producto>
    <CantidadVendida>3</CantidadVendida>
  </Producto>
  <Producto>
    <SemanaDelMes>4</SemanaDelMes>
    <Producto>Televisor</Producto>
    <CantidadVendida>1</CantidadVendida>
  </Producto>
</ReporteTop5MenosPorSemana>*/

-- 7. Llamado para obtener el total acumulado de ventas para una fecha y sucursal
EXEC informe.TotalAcumuladoVentas @Fecha = '2024-11-02', @SucursalID = 2;
-- Esperado:
/*<DetalleVentas>
  <VentaDetalle>
    <ID_Venta>2</ID_Venta>
    <FechaVenta>2024-11-02T00:00:00</FechaVenta>
    <Sucursal>2</Sucursal>
    <Empleado>Ana Garcia</Empleado>
    <Cliente>Carlos Diaz</Cliente>
    <Producto>Microondas</Producto>
    <CantidadVendida>1</CantidadVendida>
    <PrecioUnitario>15000.00</PrecioUnitario>
    <Subtotal>30000.00</Subtotal>
    <TotalAcumulado>33600.00</TotalAcumulado>
  </VentaDetalle>
  <VentaDetalle>
    <ID_Venta>2</ID_Venta>
    <FechaVenta>2024-11-02T00:00:00</FechaVenta>
    <Sucursal>2</Sucursal>
    <Empleado>Ana Garcia</Empleado>
    <Cliente>Carlos Diaz</Cliente>
    <Producto>Silla</Producto>
    <CantidadVendida>3</CantidadVendida>
    <PrecioUnitario>1200.00</PrecioUnitario>
    <Subtotal>3600.00</Subtotal>
    <TotalAcumulado>33600.00</TotalAcumulado>
  </VentaDetalle>
</DetalleVentas>*/
