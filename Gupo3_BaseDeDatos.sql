
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ControlAccesoFisico')
BEGIN
    CREATE DATABASE ControlAccesoFisico;
END
GO

USE ControlAccesoFisico;
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Empleados')
BEGIN
    CREATE TABLE Empleados (
        IdEmpleado INT PRIMARY KEY IDENTITY(1,1),
        NumeroTarjeta VARCHAR(50) UNIQUE NOT NULL,
        Nombre VARCHAR(100) NOT NULL,
        Apellido VARCHAR(100) NOT NULL,
        Email VARCHAR(150) UNIQUE NOT NULL,
        Telefono VARCHAR(20),
        Departamento VARCHAR(100),
        Cargo VARCHAR(100),
        FechaIngreso DATE NOT NULL,
        Estado VARCHAR(20) CHECK (Estado IN ('Activo', 'Inactivo', 'Suspendido')) DEFAULT 'Activo',
        FotoUrl VARCHAR(255),
        FechaCreacion DATETIME DEFAULT GETDATE(),
        FechaModificacion DATETIME DEFAULT GETDATE()
    );
    
    CREATE INDEX IX_Empleados_Tarjeta ON Empleados(NumeroTarjeta);
    CREATE INDEX IX_Empleados_Estado ON Empleados(Estado);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Zonas')
BEGIN
    CREATE TABLE Zonas (
        IdZona INT PRIMARY KEY IDENTITY(1,1),
        NombreZona VARCHAR(100) NOT NULL,
        Descripcion VARCHAR(500),
        NivelSeguridad VARCHAR(20) CHECK (NivelSeguridad IN ('Bajo', 'Medio', 'Alto', 'Critico')) DEFAULT 'Medio',
        Edificio VARCHAR(50),
        Piso VARCHAR(20),
        Estado VARCHAR(20) CHECK (Estado IN ('Activa', 'Mantenimiento', 'Deshabilitada')) DEFAULT 'Activa',
        FechaCreacion DATETIME DEFAULT GETDATE()
    );
    
    CREATE INDEX IX_Zonas_Nivel ON Zonas(NivelSeguridad);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DispositivosAcceso')
BEGIN
    CREATE TABLE DispositivosAcceso (
        IdDispositivo INT PRIMARY KEY IDENTITY(1,1),
        IdZona INT NOT NULL,
        CodigoDispositivo VARCHAR(50) UNIQUE NOT NULL,
        TipoDispositivo VARCHAR(30) CHECK (TipoDispositivo IN ('LectorTarjeta', 'SensorMovimiento', 'CerraduraElectronica', 'Camara')) NOT NULL,
        Ubicacion VARCHAR(150),
        Modelo VARCHAR(100),
        DireccionIP VARCHAR(45),
        Estado VARCHAR(20) CHECK (Estado IN ('Operativo', 'Mantenimiento', 'FueraServicio')) DEFAULT 'Operativo',
        UltimaComunicacion DATETIME,
        FechaCreacion DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Dispositivos_Zona FOREIGN KEY (IdZona) REFERENCES Zonas(IdZona) ON DELETE CASCADE
    );
    
    CREATE INDEX IX_Dispositivos_Zona ON DispositivosAcceso(IdZona);
    CREATE INDEX IX_Dispositivos_Tipo ON DispositivosAcceso(TipoDispositivo);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PermisosAcceso')
BEGIN
    CREATE TABLE PermisosAcceso (
        IdPermiso INT PRIMARY KEY IDENTITY(1,1),
        IdEmpleado INT NOT NULL,
        IdZona INT NOT NULL,
        FechaInicio DATE NOT NULL,
        FechaFin DATE,
        HorarioInicio TIME DEFAULT '00:00:00',
        HorarioFin TIME DEFAULT '23:59:59',
        DiasSemana VARCHAR(100) DEFAULT 'Lunes,Martes,Miercoles,Jueves,Viernes',
        Estado VARCHAR(20) CHECK (Estado IN ('Activo', 'Suspendido', 'Expirado')) DEFAULT 'Activo',
        AutorizadorId INT,
        Motivo VARCHAR(500),
        FechaCreacion DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_Permisos_Empleado FOREIGN KEY (IdEmpleado) REFERENCES Empleados(IdEmpleado) ON DELETE CASCADE,
        CONSTRAINT FK_Permisos_Zona FOREIGN KEY (IdZona) REFERENCES Zonas(IdZona) ON DELETE CASCADE,
        CONSTRAINT FK_Permisos_Autorizador FOREIGN KEY (AutorizadorId) REFERENCES Empleados(IdEmpleado),
        CONSTRAINT UQ_Permiso_Empleado_Zona UNIQUE (IdEmpleado, IdZona)
    );
    
    CREATE INDEX IX_Permisos_Empleado ON PermisosAcceso(IdEmpleado);
    CREATE INDEX IX_Permisos_Zona ON PermisosAcceso(IdZona);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RegistrosAcceso')
BEGIN
    CREATE TABLE RegistrosAcceso (
        IdRegistro BIGINT PRIMARY KEY IDENTITY(1,1),
        IdEmpleado INT,
        IdZona INT NOT NULL,
        IdDispositivo INT NOT NULL,
        NumeroTarjeta VARCHAR(50),
        TipoEvento VARCHAR(30) CHECK (TipoEvento IN ('Entrada', 'Salida', 'IntentoDenegado', 'Emergencia')) NOT NULL,
        Resultado VARCHAR(20) CHECK (Resultado IN ('Exitoso', 'Denegado', 'Error')) NOT NULL,
        MotivoDenegacion VARCHAR(255),
        FechaHora DATETIME DEFAULT GETDATE(),
        DatosSensor VARCHAR(MAX), -- JSON con datos adicionales del sensor
        CONSTRAINT FK_Registros_Empleado FOREIGN KEY (IdEmpleado) REFERENCES Empleados(IdEmpleado) ON DELETE SET NULL,
        CONSTRAINT FK_Registros_Zona FOREIGN KEY (IdZona) REFERENCES Zonas(IdZona),
        CONSTRAINT FK_Registros_Dispositivo FOREIGN KEY (IdDispositivo) REFERENCES DispositivosAcceso(IdDispositivo)
    );
    
    CREATE INDEX IX_Registros_Fecha ON RegistrosAcceso(FechaHora);
    CREATE INDEX IX_Registros_Empleado ON RegistrosAcceso(IdEmpleado);
    CREATE INDEX IX_Registros_Resultado ON RegistrosAcceso(Resultado);
    CREATE INDEX IX_Registros_Tipo ON RegistrosAcceso(TipoEvento);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EventosSeguridad')
BEGIN
    CREATE TABLE EventosSeguridad (
        IdEvento BIGINT PRIMARY KEY IDENTITY(1,1),
        TipoEvento VARCHAR(30) CHECK (TipoEvento IN ('Alerta', 'Emergencia', 'Mantenimiento', 'FalloSistema')) NOT NULL,
        IdZona INT,
        IdDispositivo INT,
        Descripcion VARCHAR(MAX) NOT NULL,
        NivelGravedad VARCHAR(20) CHECK (NivelGravedad IN ('Info', 'Advertencia', 'Critico')) DEFAULT 'Info',
        Estado VARCHAR(20) CHECK (Estado IN ('Pendiente', 'EnProceso', 'Resuelto')) DEFAULT 'Pendiente',
        FechaHora DATETIME DEFAULT GETDATE(),
        ResueltoPor INT,
        FechaResolucion DATETIME,
        NotasResolucion VARCHAR(MAX),
        CONSTRAINT FK_Eventos_Zona FOREIGN KEY (IdZona) REFERENCES Zonas(IdZona) ON DELETE SET NULL,
        CONSTRAINT FK_Eventos_Dispositivo FOREIGN KEY (IdDispositivo) REFERENCES DispositivosAcceso(IdDispositivo) ON DELETE SET NULL,
        CONSTRAINT FK_Eventos_Resolutor FOREIGN KEY (ResueltoPor) REFERENCES Empleados(IdEmpleado)
    );
    
    CREATE INDEX IX_Eventos_Tipo ON EventosSeguridad(TipoEvento);
    CREATE INDEX IX_Eventos_Estado ON EventosSeguridad(Estado);
    CREATE INDEX IX_Eventos_Fecha ON EventosSeguridad(FechaHora);
END
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_RegistrarAcceso')
    DROP PROCEDURE sp_RegistrarAcceso;
GO

CREATE PROCEDURE sp_RegistrarAcceso
    @NumeroTarjeta VARCHAR(50),
    @IdZona INT,
    @IdDispositivo INT,
    @TipoEvento VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdEmpleado INT;
    DECLARE @TienePermiso BIT = 0;
    DECLARE @Resultado VARCHAR(20);
    DECLARE @Motivo VARCHAR(255);
    DECLARE @DiaActual VARCHAR(20);
    
    SET @DiaActual = CASE DATEPART(WEEKDAY, GETDATE())
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miercoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sabado'
    END;
    
    BEGIN TRY    
        SELECT @IdEmpleado = IdEmpleado
        FROM Empleados
        WHERE NumeroTarjeta = @NumeroTarjeta AND Estado = 'Activo';
        
        IF @IdEmpleado IS NOT NULL
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM PermisosAcceso
                WHERE IdEmpleado = @IdEmpleado
                    AND IdZona = @IdZona
                    AND Estado = 'Activo'
                    AND (FechaFin IS NULL OR FechaFin >= CAST(GETDATE() AS DATE))
                    AND CAST(GETDATE() AS TIME) BETWEEN HorarioInicio AND HorarioFin
                    AND DiasSemana LIKE '%' + @DiaActual + '%'
            )
            BEGIN
                SET @TienePermiso = 1;
                SET @Resultado = 'Exitoso';
                SET @Motivo = NULL;
            END
            ELSE
            BEGIN
                SET @Resultado = 'Denegado';
                SET @Motivo = 'Sin permisos para esta zona o fuera de horario';
            END
        END
        ELSE
        BEGIN
            SET @Resultado = 'Denegado';
            SET @Motivo = 'Tarjeta no válida o empleado inactivo';
        END
     
        INSERT INTO RegistrosAcceso (
            IdEmpleado, IdZona, IdDispositivo, NumeroTarjeta,
            TipoEvento, Resultado, MotivoDenegacion, FechaHora
        ) VALUES (
            @IdEmpleado, @IdZona, @IdDispositivo, @NumeroTarjeta,
            @TipoEvento, @Resultado, @Motivo, GETDATE()
        );
        
        IF @Resultado = 'Denegado'
        BEGIN
            INSERT INTO EventosSeguridad (TipoEvento, IdZona, IdDispositivo, Descripcion, NivelGravedad)
            VALUES ('Alerta', @IdZona, @IdDispositivo, 
                    'Acceso denegado - ' + ISNULL(@Motivo, 'Desconocido'), 'Advertencia');
        END
        
        -- Retornar resultado
        SELECT @Resultado AS Resultado, @Motivo AS Motivo, @IdEmpleado AS IdEmpleado;
        
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Motivo, NULL AS IdEmpleado;
    END CATCH
END
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_AccesosRecientes')
    DROP VIEW vw_AccesosRecientes;
GO

CREATE VIEW vw_AccesosRecientes AS
SELECT TOP 100
    r.IdRegistro,
    e.Nombre,
    e.Apellido,
    e.NumeroTarjeta,
    z.NombreZona,
    d.CodigoDispositivo,
    r.TipoEvento,
    r.Resultado,
    r.FechaHora,
    r.MotivoDenegacion
FROM RegistrosAcceso r
LEFT JOIN Empleados e ON r.IdEmpleado = e.IdEmpleado
INNER JOIN Zonas z ON r.IdZona = z.IdZona
INNER JOIN DispositivosAcceso d ON r.IdDispositivo = d.IdDispositivo
ORDER BY r.FechaHora DESC;
GO


IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_PermisosActivos')
    DROP VIEW vw_PermisosActivos;
GO

CREATE VIEW vw_PermisosActivos AS
SELECT 
    e.IdEmpleado,
    e.Nombre,
    e.Apellido,
    e.NumeroTarjeta,
    e.Departamento,
    z.NombreZona,
    z.NivelSeguridad,
    p.FechaInicio,
    p.FechaFin,
    p.HorarioInicio,
    p.HorarioFin,
    p.DiasSemana
FROM Empleados e
INNER JOIN PermisosAcceso p ON e.IdEmpleado = p.IdEmpleado
INNER JOIN Zonas z ON p.IdZona = z.IdZona
WHERE e.Estado = 'Activo' 
    AND p.Estado = 'Activo'
    AND (p.FechaFin IS NULL OR p.FechaFin >= CAST(GETDATE() AS DATE));
GO



IF NOT EXISTS (SELECT * FROM Zonas)
BEGIN
    INSERT INTO Zonas (NombreZona, Descripcion, NivelSeguridad, Edificio, Piso) VALUES
    ('Recepción', 'Área de recepción principal', 'Bajo', 'Edificio A', '1'),
    ('Oficinas Generales', 'Área de trabajo general', 'Medio', 'Edificio A', '2-5'),
    ('Sala de Servidores', 'Data center principal', 'Critico', 'Edificio B', 'Sótano'),
    ('Laboratorio', 'Laboratorio de desarrollo', 'Alto', 'Edificio B', '3'),
    ('Estacionamiento', 'Área de parqueo', 'Bajo', 'Exterior', 'P1');
    
    PRINT 'Zonas insertadas correctamente';
END
GO

IF NOT EXISTS (SELECT * FROM Empleados)
BEGIN
    INSERT INTO Empleados (NumeroTarjeta, Nombre, Apellido, Email, Departamento, Cargo, FechaIngreso) VALUES
    ('EMP001', 'Ana', 'Martínez', 'ana.martinez@empresa.com', 'Recepción', 'Recepcionista', '2024-01-15'),
    ('EMP002', 'Carlos', 'López', 'carlos.lopez@empresa.com', 'IT', 'Administrador de Sistemas', '2023-06-10'),
    ('EMP003', 'María', 'García', 'maria.garcia@empresa.com', 'Desarrollo', 'Desarrolladora Senior', '2023-03-20'),
    ('EMP004', 'Juan', 'Pérez', 'juan.perez@empresa.com', 'Seguridad', 'Supervisor de Seguridad', '2022-09-01');
    
    PRINT 'Empleados insertados correctamente';
END
GO

IF NOT EXISTS (SELECT * FROM DispositivosAcceso)
BEGIN
    INSERT INTO DispositivosAcceso (IdZona, CodigoDispositivo, TipoDispositivo, Ubicacion, Estado) VALUES
    (1, 'LECT-REC-001', 'LectorTarjeta', 'Puerta principal recepción', 'Operativo'),
    (2, 'LECT-OF-001', 'LectorTarjeta', 'Acceso oficinas piso 2', 'Operativo'),
    (3, 'LECT-SRV-001', 'LectorTarjeta', 'Puerta sala de servidores', 'Operativo'),
    (3, 'SENS-SRV-001', 'SensorMovimiento', 'Interior sala servidores', 'Operativo'),
    (4, 'LECT-LAB-001', 'LectorTarjeta', 'Entrada laboratorio', 'Operativo');
    
    PRINT 'Dispositivos insertados correctamente';
END
GO

IF NOT EXISTS (SELECT * FROM PermisosAcceso)
BEGIN
    INSERT INTO PermisosAcceso (IdEmpleado, IdZona, FechaInicio, AutorizadorId, Estado) VALUES
    (1, 1, '2024-01-15', 4, 'Activo'), -- Ana puede acceder a recepción
    (2, 1, '2023-06-10', 4, 'Activo'), -- Carlos puede acceder a recepción
    (2, 3, '2023-06-10', 4, 'Activo'), -- Carlos puede acceder a sala de servidores
    (3, 1, '2023-03-20', 4, 'Activo'), -- María puede acceder a recepción
    (3, 2, '2023-03-20', 4, 'Activo'), -- María puede acceder a oficinas
    (3, 4, '2023-03-20', 4, 'Activo'), -- María puede acceder al laboratorio
    (4, 1, '2022-09-01', 4, 'Activo'), -- Juan (Supervisor) acceso a recepción
    (4, 2, '2022-09-01', 4, 'Activo'), -- Juan acceso a oficinas
    (4, 3, '2022-09-01', 4, 'Activo'); -- Juan acceso a sala de servidores
    
    PRINT 'Permisos insertados correctamente';
END
GO

PRINT '==========================================';
PRINT 'Base de datos creada exitosamente!';
PRINT 'Base de datos: ControlAccesoFisico';
PRINT '==========================================';
GO