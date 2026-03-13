-- Creación de Base de Datos desde base postgres
CREATE DATABASE clinica_veterinaria;

-- Creación de SCHEMA conectado ya a la BASE de DATOS clinica_veterinaria
CREATE SCHEMA veterinaria;

-- Creación de Tablas

-- Tabla Dueños
CREATE TABLE veterinaria.duenos (
    id_dueno INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100),
    direccion VARCHAR(200),
    telefono VARCHAR(20)
);

-- Tabla Mascotas
CREATE TABLE veterinaria.mascotas (
    id_mascota INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100),
    tipo VARCHAR(50),
    fecha_nacimiento DATE,
    id_dueno INT,
    CONSTRAINT fk_duenos_id_dueno FOREIGN KEY (id_dueno) REFERENCES veterinaria.duenos(id_dueno)
);

-- Tabla Profesionales
CREATE TABLE veterinaria.profesionales (
    id_profesional INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100),
    especialidad VARCHAR(100)
);

-- Tabla Atenciones
CREATE TABLE veterinaria.atenciones (
    id_atencion INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_atencion DATE,
    descripcion TEXT,
    id_mascota INT,
    id_profesional INT,
    CONSTRAINT fk_mascotas_id_mascota FOREIGN KEY (id_mascota) REFERENCES veterinaria.mascotas(id_mascota),
    CONSTRAINT fk_profesionales_id_profesional FOREIGN KEY (id_profesional) REFERENCES veterinaria.profesionales(id_profesional)
);

-- Ingreso de datos a las tablas

-- Tabla Dueños
INSERT INTO veterinaria.duenos (nombre, direccion, telefono)
    VALUES 
    ('Juan Pérez', 'Calle Falsa 123', '555-1234'),
    ('Ana Gómez', 'Avenida Siempre Viva 456', '555-5678'),
    ('Carlos Ruiz', 'Calle 8 de Octubre 789', '555-8765');

-- Tabla Mascotas
INSERT INTO veterinaria.mascotas (nombre, tipo, fecha_nacimiento, id_dueno)
    VALUES 
    ('Rex', 'Perro', '2020-05-10', 1), 
    ('Luna', 'Gato', '2019-02-20', 2),
    ('Fido', 'Perro', '2021-03-15', 3);

-- Tabla Profesionales
INSERT INTO veterinaria.profesionales (nombre, especialidad)
    VALUES
    ('Dr. Martínez', 'Veterinario'),
    ('Dr. Pérez', 'Especialista en dermatología'),
    ('Dr. López', 'Cardiólogo veterinario');

-- Tabla Atenciones
INSERT INTO veterinaria.atenciones (fecha_atencion, descripcion, id_mascota, id_profesional)
    VALUES 
    ('2025-03-01', 'Chequeo general', 1,1),
    ('2025-03-05', 'Tratamiento dermatológico', 2,2),
    ('2025-03-07', 'Consulta cardiológica',3,3);

-- Consultas a la base de datos

-- 1. Obtener todos los dueños y sus mascotas
SELECT
d.nombre "Nombre Dueño", m.nombre "Nombre Mascota", m.tipo "Tipo"
FROM veterinaria.duenos d
JOIN veterinaria.mascotas m 
ON m.id_dueno = d.id_dueno;

-- 2. Obtener las atenciones realizadas a las mascotas con los detalles del profesional que atendió
SELECT
a.fecha_atencion "Fecha", a.descripcion " Atención", m.nombre "Nombre Mascota", m.tipo "Tipo", p.nombre "Profesional", p.especialidad "Especialidad"
FROM veterinaria.atenciones a
JOIN veterinaria.profesionales p 
ON a.id_profesional = p.id_profesional
JOIN veterinaria. mascotas m 
ON a.id_mascota = m.id_mascota;

-- 3. Contar la cantidad de atenciones por profesional
SELECT
p.nombre "Profesional", p.especialidad "Especialidad", COUNT(a.id_atencion) "Total Atenciones"
FROM veterinaria.atenciones a
LEFT JOIN veterinaria.profesionales p 
ON a.id_profesional = p.id_profesional
GROUP BY p.nombre, p.especialidad;

-- 4. Actualizar la dirección de un dueño (por ejemplo, cambiar la dirección de Juan Pérez)
UPDATE veterinaria.duenos
SET direccion = 'Avenida Verdadera 135'
WHERE nombre = 'Juan Pérez';

-- 5. Eliminar una atención (por ejemplo, atención con id 2)
DELETE FROM veterinaria.atenciones
WHERE id_atencion = 2;

-- 6. Realizar una transacción para agregar una nueva mascota, atención y actualización de información.

--Opción 1
BEGIN;
    -- Creamos la mascota y capturamos su ID en una "tabla temporal" llamada 'nueva_mascota' para poder ingresarla directametne en nueva atención
    WITH nueva_mascota AS (
        INSERT INTO veterinaria.mascotas (nombre, tipo, fecha_nacimiento, id_dueno)
        VALUES ('Katara', 'Perro', '2024-08-03', 1)
        RETURNING id_mascota
    )
    -- Usamos ese ID automáticamente para la atención
    INSERT INTO veterinaria.atenciones (fecha_atencion, descripcion, id_mascota, id_profesional)
    SELECT '2026-03-12', 'Consulta dermatología', id_mascota, 2 
    FROM nueva_mascota;
    -- Actualización teléfono dueño
    UPDATE veterinaria.duenos
    SET telefono = '555-0987'
    WHERE id_dueno = 1;
COMMIT;

-- Opción 2
-- Ocupando la estructura de DO $$
DO $$ 
DECLARE 
    v_id_mascota INT; -- Variable para guardar el ID generado
BEGIN
    -- 1. Insertar la nueva mascota y guardar su ID automático en la variable
    INSERT INTO veterinaria.mascotas (nombre, tipo, fecha_nacimiento, id_dueno)
    VALUES ('Leia', 'Perro', '2021-02-15', 3)
    RETURNING id_mascota INTO v_id_mascota;

    -- 2. Insertar la atención usando la variable v_id_mascota
    INSERT INTO veterinaria.atenciones (fecha_atencion, descripcion, id_mascota, id_profesional)
    VALUES ('2026-03-12', 'Control sano', v_id_mascota, 1);

    -- 3. Actualizar información (ejemplo: actualizar dirección)
    UPDATE veterinaria.duenos
    SET direccion = 'Calle 8 de Octubre 1979'
    WHERE id_dueno = 3;

    -- Mensaje de confirmación 
    RAISE NOTICE 'Proceso terminado correctamente: Ingreso nueva mascota, Atención realizada, Actualización de datos correcta';

EXCEPTION WHEN OTHERS THEN
    -- Si algo falla, se cancela todo automáticamente
    RAISE EXCEPTION 'Error, proceso cancelado: %', SQLERRM;
END $$;

