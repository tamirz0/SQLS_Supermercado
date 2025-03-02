USE Com2900G16;
-- 1. Creación de datos de prueba para las tablas necesarias
EXEC informe.LimpiarTodasLasTablas;
EXEC tienda.AltaSucursal @Direccion = 'Calle Principal 456', @Ciudad = 'Ciudad Ejemplo', @Ciudad_anterior = NULL;
EXEC tienda.AltaEmpleado @Legajo = '000002', @Nombre = 'Ana', @Apellido = 'Lopez', @DNI = '87654321',
    @Mail_Empresa = 'ana.lopez@empresa.com', @CUIL = '27-87654321-9', @Cargo = 'Vendedor', @Turno = 'TT', @ID_Sucursal = 1, @Estado = 1;
EXEC tienda.AltaCliente @Nombre = 'Laura Garcia', @TipoCliente = 'Member', @Genero = 'F', @Estado = 1, @CUIT = '20-41141444-1';
EXEC catalogo.AltaCategoriaProducto @LineaProducto = 'Línea Jardín', @Categoria = 'Muebles de Jardín';

Declare @date date
set @date = getdate()
EXEC catalogo.AltaProducto 
    @Nombre = 'Lavadora', 
    @ID_Categoria = 1, 
    @PrecioUnitario = 2000.00, 
    @PrecioReferencia = 2000.00, 
    @UnidadReferencia = 'Unidad', 
    @Fecha = @date,
	@IVA = 0.21;

Declare @date date
set @date = getdate()
EXEC catalogo.AltaProducto 
    @Nombre = 'Silla', 
    @ID_Categoria = 1, 
    @PrecioUnitario = 2000.00, 
    @PrecioReferencia = 2000.00, 
    @UnidadReferencia = 'Unidad', 
    @Fecha = @date,
	@IVA = 0.21;

EXEC ventas.AltaMedioPago 
    @Descripcion_ESP = 'Tarjeta de Crédito', 
    @Descripcion_ENG = 'Credit Card';
EXEC ventas.AltaVenta @ID_Cliente = 1, @ID_Sucursal = 1, @ID_Empleado = 1
EXEC ventas.AltaDetalleVenta @ID_Venta=1, @ID_Producto= 1, @Cantidad=2
EXEC ventas.AltaDetalleVenta @ID_Venta=1, @ID_Producto= 2, @Cantidad=5
EXEC ventas.AltaFactura @ID_Venta = 1 , @PuntoDeVenta = 0001,@Comprobante = '00000001'
EXEC ventas.AltaDetalleFactura @ID_Venta = 1, @ID_Factura = 1
EXEC ventas.AltaPago @ID_Factura = 1, @ID_MedioPago = 1, @Monto = 16940.00

-- 2. Creación de los usuarios y asignación de roles
EXEC ventas.CrearRolSupervisor

CREATE USER SupervisorUser WITHOUT LOGIN;
EXEC sp_addrolemember 'Supervisor', 'SupervisorUser';

-- Crear usuario sin permisos para crear notas de crédito
CREATE USER EmpleadoUser WITHOUT LOGIN;

-- 3. Pruebas de ejecución del procedimiento ventas.CrearNotaCredito

-- Asignación de contexto a SupervisorUser y ejecución del procedimiento
EXECUTE AS USER = 'SupervisorUser';

PRINT 'Intentando crear nota de crédito como Supervisor:';
EXEC ventas.CrearNotaCredito 
    @ID_Factura = 1, 
    @ID_Producto = 1, 
    @Motivo = 'Devolución de producto defectuoso'

EXEC ventas.CrearNotaCredito 
    @ID_Factura = 1, 
    @Motivo = 'Devolución de producto defectuoso'

SELECT * FROM ventas.Factura 
REVERT;

-- Intento de ejecución del procedimiento como usuario sin permisos (EmpleadoUser)
EXECUTE AS USER = 'EmpleadoUser';

PRINT 'Intentando crear nota de crédito como Empleado sin permisos:';
EXEC ventas.CrearNotaCredito 
    @ID_Factura = 1, 
    @ID_Producto = 1, 
    @Motivo = 'Devolución de producto defectuoso'
REVERT;

EXECUTE AS USER = 'SupervisorUser';

SELECT * FROM ventas.NotaCredito