-- ============================================================
-- SCRIPT DE CREACIÓN: MUNICIPALIDAD DE VIALE (INSTITUCIÓN OFICIAL)
-- Válido para Staging y Producción
-- ============================================================

USE `railway`;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;

-- 1. Insertar o actualizar el usuario de la institución
INSERT INTO usuarios (email, password, tipo_usuario, activo, email_verified, id_ciudad)
VALUES ('muni.viale@reportarg.com', '$2b$10$FMpCbKh37kGBDwl.W3rL7Of.IHTGizwSCLyFIXA8OmwQ7FgP91tJC', 'institucion', 1, 1, 1)
ON DUPLICATE KEY UPDATE 
  password = VALUES(password),
  tipo_usuario = 'institucion',
  activo = 1,
  email_verified = 1,
  id_ciudad = 1;

-- 2. Asegurar que otras instituciones de la ciudad 1 no queden como principales
UPDATE instituciones SET es_principal = 0 WHERE id_ciudad = 1;

-- 3. Insertar o actualizar el perfil de la Municipalidad de Viale como Institución Principal
INSERT INTO instituciones (id_usuario, nombre, tipo, telefono, provincia, ciudad, zona, direccion, foto_perfil, verificada, status, id_ciudad, es_principal)
SELECT id_usuario, 'Municipalidad de Viale', 'municipio', '0343-4920011', 'Entre Ríos', 'Viale', 'Centro', '9 de Julio 845', 'https://res.cloudinary.com/dbozxsigi/image/upload/v1788893358/reportarg/usuarios/pydjlrz8wluzdxkvtt7x.jpg', 1, 'approved', 1, 1
FROM usuarios WHERE email = 'muni.viale@reportarg.com'
ON DUPLICATE KEY UPDATE 
  nombre = 'Municipalidad de Viale',
  tipo = 'municipio',
  telefono = '0343-4920011',
  provincia = 'Entre Ríos',
  ciudad = 'Viale',
  zona = 'Centro',
  direccion = '9 de Julio 845',
  foto_perfil = 'https://res.cloudinary.com/dbozxsigi/image/upload/v1788893358/reportarg/usuarios/pydjlrz8wluzdxkvtt7x.jpg',
  verificada = 1,
  status = 'approved',
  id_ciudad = 1,
  es_principal = 1;

-- 4. Asignar todas las categorías de la plataforma a la Municipalidad de Viale
INSERT IGNORE INTO institucion_categorias (id_institucion, id_categoria)
SELECT i.id_institucion, c.id_categoria
FROM instituciones i
CROSS JOIN categorias c
WHERE i.id_usuario = (SELECT id_usuario FROM usuarios WHERE email = 'muni.viale@reportarg.com');

SET SQL_SAFE_UPDATES = 1;
SET FOREIGN_KEY_CHECKS = 1;
