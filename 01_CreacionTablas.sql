USE Com2900G16;
GO
/*


Se requiere que importe toda la información antes mencionada a la base de datos:
	ó Genere los objetos necesarios (store procedures, funciones, etc.) para importar los
	archivos antes mencionados. Tenga en cuenta que cada mes se recibirón archivos de
	novedades con la misma estructura, pero datos nuevos para agregar a cada maestro.
	ó Considere este comportamiento al generar el código. Debe admitir la importación de
	novedades periódicamente.
	ó Cada maestro debe importarse con un SP distinto. No se aceptarón scripts que
	realicen tareas por fuera de un SP.
	ó La estructura/esquema de las tablas a generar seró decisión suya. Puede que deba
	realizar procesos de transformación sobre los maestros recibidos para adaptarlos a la
	estructura requerida.
	ó Los archivos CSV/JSON no deben modificarse. En caso de que haya datos mal
	cargados, incompletos, erróneos, etc., deberó contemplarlo y realizar las correcciones
	en el fuente SQL. (Seróa una excepción si el archivo estó malformado y no es posible
	interpretarlo como JSON o CSV). 

*/

-- Creación de la tabla Sucursal
IF OBJECT_ID(N'tienda.Sucursal') IS NOT NULL
	DROP TABLE tienda.Sucursal;

CREATE TABLE tienda.Sucursal (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Direccion VARCHAR(100) NOT NULL UNIQUE,
    Ciudad VARCHAR(50) NOT NULL,
	Ciudad_anterior VARCHAR(50)
);

-- Creación de la tabla Empleado
IF OBJECT_ID(N'tienda.Empleado') IS NOT NULL
	DROP TABLE tienda.Empleado;

CREATE TABLE tienda.Empleado (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Legajo CHAR(6) UNIQUE,
    Nombre VARCHAR(50) NOT NULL,
    Apellido VARCHAR(50),
    DNI CHAR(8), 
    MailEmpresa VARCHAR(100),
    CUIL CHAR(13),
    Cargo VARCHAR(20),
    Turno CHAR(2),
    ID_Sucursal INT NOT NULL,
    Estado BIT DEFAULT 1,
    FOREIGN KEY (ID_Sucursal) REFERENCES tienda.Sucursal(ID) ON DELETE NO ACTION,
    CHECK (Legajo LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'), 
    CONSTRAINT CHK_DNI CHECK (DNI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'), 
    CHECK (MailEmpresa LIKE '%_@__%.__%'), 
    CONSTRAINT CHK_CUIL CHECK (CUIL LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'), 
    CHECK (Estado IN (0, 1)) 
);

-- Creación de la tabl Cliente
IF OBJECT_ID(N'tienda.Cliente') IS NOT NULL
	DROP TABLE tienda.Cliente;

CREATE TABLE tienda.Cliente (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    TipoCliente VARCHAR(6) NOT NULL,
    Genero CHAR(1) NOT NULL, --Cambió
    Estado BIT DEFAULT 1,
	CUIT CHAR(13),
	CHECK (TipoCliente IN ('Member', 'Normal')),
	CHECK (Genero IN ('F', 'M'))
);

-- Creación de la tabla Linea Producto
IF OBJECT_ID(N'catalogo.CategoriaProducto') IS NOT NULL
	DROP TABLE catalogo.CategoriaProducto;

CREATE TABLE catalogo.CategoriaProducto (
    ID INT IDENTITY(1,1) PRIMARY KEY,
	LineaProducto VARCHAR(40),
	Categoria VARCHAR(100) NOT NULL UNIQUE
);

-- Creación de la tabla Producto
IF OBJECT_ID(N'catalogo.Producto') IS NOT NULL
	DROP TABLE catalogo.Producto;

CREATE TABLE catalogo.Producto (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    ID_Categoria INT,
    PrecioUnitario DECIMAL(10, 2) NOT NULL,
	PrecioReferencia DECIMAL(10,2),
	UnidadReferencia VARCHAR(25),
    Fecha DATETIME NOT NULL,
	IVA DECIMAL(10, 2) DEFAULT 0.21,
	FOREIGN KEY (ID_Categoria) REFERENCES catalogo.CategoriaProducto (ID) ON DELETE NO ACTION
);

-- Creación de la tabla MedioPago
IF OBJECT_ID(N'ventas.MedioPago') IS NOT NULL
	DROP TABLE ventas.MedioPago;

CREATE TABLE ventas.MedioPago (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion_ESP VARCHAR(50) NOT NULL UNIQUE,
	Descripcion_ENG VARCHAR(50) NOT NULL UNIQUE
);

IF OBJECT_ID(N'ventas.Venta') IS NOT NULL
    DROP TABLE ventas.Venta;

CREATE TABLE ventas.Venta (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Fecha DATETIME NOT NULL DEFAULT GETDATE(),
    ID_Cliente INT NULL, 
    Total DECIMAL(18,2) NOT NULL,
	id_factura_importado VARCHAR(30),
	ID_SUCURSAL INT NOT NULL,
	ID_Empleado INT NOT NULL,
	FOREIGN KEY (ID_Cliente) REFERENCES tienda.Cliente(ID) ON DELETE NO ACTION,
	FOREIGN KEY (ID_Sucursal) REFERENCES tienda.Sucursal(ID) ON DELETE NO ACTION,
	FOREIGN KEY (ID_Empleado) REFERENCES tienda.Empleado(ID) ON DELETE NO ACTION,
);

IF OBJECT_ID(N'ventas.DetalleVenta') IS NOT NULL
    DROP TABLE ventas.DetalleVenta

CREATE TABLE ventas.DetalleVenta (
    ID INT PRIMARY KEY IDENTITY(1,1),
    ID_Venta INT NOT NULL,
    ID_Producto INT NOT NULL, 
    Cantidad INT NOT NULL,
    Precio_Unitario DECIMAL(18,2) NOT NULL,
    Subtotal  DECIMAL(18,2) NOT NULL,
    FOREIGN KEY (ID_Venta) REFERENCES ventas.Venta(ID)
);

-- Creación de la tabla Factura
IF OBJECT_ID(N'ventas.Factura') IS NOT NULL
	DROP TABLE ventas.Factura;

CREATE TABLE ventas.Factura (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Estado VARCHAR(11),
	FechaHora DATETIME NOT NULL,
	Comprobante VARCHAR(10) NOT NULL,
	PuntoDeVenta CHAR(5) NOT NULL,
	SubTotal DECIMAL(10, 2) NOT NULL,
	IvaTotal DECIMAL(10, 2) NOT NULL,
	Total DECIMAL(10, 2) NOT NULL,
	ID_Venta INT NOT NULL,
	CHECK (Estado IN ('Pagada', 'No pagada','Cancelada')),
	FOREIGN KEY (ID_Venta) REFERENCES ventas.Venta(ID)
);

-- Creación de la tabla DetalleFactura
IF OBJECT_ID(N'ventas.DetalleFactura') IS NOT NULL
	DROP TABLE ventas.DetalleFactura;

CREATE TABLE ventas.DetalleFactura (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ID_Factura INT NOT NULL,
    ID_Producto INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10, 2) NOT NULL,
	IVA DECIMAL(18,2) NOT NULL,
    Subtotal  DECIMAL(10,2) ,
	Estado BIT NOT NULL DEFAULT 0, --Si es 1 se volvio el detalle con nota de credito 
    FOREIGN KEY (ID_Factura) REFERENCES ventas.Factura(ID) ON DELETE CASCADE,
    FOREIGN KEY (ID_Producto) REFERENCES catalogo.Producto(ID) ON DELETE NO ACTION
);

IF OBJECT_ID(N'ventas.Pago') IS NOT NULL
    DROP TABLE ventas.Pago

CREATE TABLE ventas.Pago (
    ID INT PRIMARY KEY IDENTITY(1,1),
    ID_Factura INT NOT NULL, 
	ID_MedioPago INT NOT NULL,
	Monto DECIMAL(18,2) NOT NULL, 
    Fecha_Pago DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (ID_Factura) REFERENCES ventas.Factura(ID),
	FOREIGN KEY (ID_MedioPago) REFERENCES ventas.MedioPago(ID)
);


-- Creación de la tabla NotaCredito
IF OBJECT_ID(N'ventas.NotaCredito') IS NOT NULL
    DROP TABLE ventas.NotaCredito;

CREATE TABLE ventas.NotaCredito (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ID_Factura INT NOT NULL,
	ID_Cliente INT NOT NULL, 
	ID_Producto INT NULL,
    FechaEmision DATETIME DEFAULT GETDATE(),
    Motivo VARCHAR(255), --Cambió
	Comprobante VARCHAR(10) NOT NULL,
    FOREIGN KEY (ID_Factura) REFERENCES ventas.Factura(ID) ON DELETE NO ACTION,
	FOREIGN KEY (ID_Cliente) REFERENCES tienda.Cliente(ID) ON DELETE NO ACTION,
	FOREIGN KEY (ID_Producto) REFERENCES catalogo.Producto(ID) ON DELETE NO ACTION
);