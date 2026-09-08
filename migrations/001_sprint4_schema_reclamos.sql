-- ============================================================
-- SCRIPT DE MIGRACIÓN SPRINT 4: RECLAMOS Y MULTI-TENANCY (ReportARG)
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- 1. TABLA CIUDADES
CREATE TABLE IF NOT EXISTS ciudades (
  id_ciudad INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  provincia VARCHAR(100) NOT NULL,
  activa TINYINT(1) NOT NULL DEFAULT 1,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed inicial de ciudad
INSERT INTO ciudades (id_ciudad, nombre, provincia, activa)
VALUES (1, 'Viale', 'Entre Ríos', 1)
ON DUPLICATE KEY UPDATE id_ciudad=id_ciudad;

-- 2. TABLA INSTITUCION_CATEGORIAS
CREATE TABLE IF NOT EXISTS institucion_categorias (
  id_institucion INT NOT NULL,
  id_categoria INT NOT NULL,
  PRIMARY KEY (id_institucion, id_categoria),
  KEY idx_inst_cat_cat (id_categoria),
  CONSTRAINT fk_inst_cat_inst FOREIGN KEY (id_institucion) REFERENCES instituciones (id_institucion) ON DELETE CASCADE,
  CONSTRAINT fk_inst_cat_cat FOREIGN KEY (id_categoria) REFERENCES categorias (id_categoria) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. TABLA RECLAMOS_AFECTADOS ("A mí también me pasa")
CREATE TABLE IF NOT EXISTS reclamos_afectados (
  id_reclamo INT NOT NULL,
  id_usuario INT NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_reclamo, id_usuario),
  CONSTRAINT fk_afectados_reclamo FOREIGN KEY (id_reclamo) REFERENCES reclamos (id_reclamo) ON DELETE CASCADE,
  CONSTRAINT fk_afectados_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. TABLA RECLAMOS_ACTUALIZACIONES
CREATE TABLE IF NOT EXISTS reclamos_actualizaciones (
  id_actualizacion INT AUTO_INCREMENT PRIMARY KEY,
  id_reclamo INT NOT NULL,
  id_usuario INT NOT NULL,
  tipo_autor ENUM('ciudadano', 'institucion', 'admin') NOT NULL,
  texto TEXT NOT NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_act_reclamo FOREIGN KEY (id_reclamo) REFERENCES reclamos (id_reclamo) ON DELETE CASCADE,
  CONSTRAINT fk_act_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. TABLA RECLAMOS_HISTORIAL (Auditoría Inmutable)
CREATE TABLE IF NOT EXISTS reclamos_historial (
  id_historial INT AUTO_INCREMENT PRIMARY KEY,
  id_reclamo INT NOT NULL,
  id_usuario INT NOT NULL,
  tipo_evento ENUM('CREACION', 'EDICION', 'CAMBIO_ESTADO', 'CANCELACION', 'RESOLUCION', 'REAPERTURA', 'REASIGNACION') NOT NULL,
  detalle TEXT NULL,
  estado_anterior VARCHAR(50) NULL,
  estado_nuevo VARCHAR(50) NULL,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_hist_reclamo FOREIGN KEY (id_reclamo) REFERENCES reclamos (id_reclamo) ON DELETE CASCADE,
  CONSTRAINT fk_hist_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. AJUSTES EN TABLA USUARIOS
ALTER TABLE usuarios ADD COLUMN id_ciudad INT NULL DEFAULT 1;

-- 7. AJUSTES EN TABLA INSTITUCIONES
ALTER TABLE instituciones ADD COLUMN id_ciudad INT NULL DEFAULT 1;
ALTER TABLE instituciones ADD COLUMN es_principal TINYINT(1) NOT NULL DEFAULT 0;

-- 8. AJUSTES EN TABLA RECLAMOS
ALTER TABLE reclamos ADD COLUMN visibilidad ENUM('publico', 'privado') NOT NULL DEFAULT 'publico';
ALTER TABLE reclamos ADD COLUMN editado TINYINT(1) NOT NULL DEFAULT 0;
ALTER TABLE reclamos ADD COLUMN id_ciudad INT NULL DEFAULT 1;
ALTER TABLE reclamos ADD COLUMN id_institucion INT NULL;
ALTER TABLE reclamos ADD COLUMN motivo_cancelacion TEXT NULL;
ALTER TABLE reclamos ADD COLUMN cancelado_por_tipo ENUM('ciudadano', 'institucion') NULL;
ALTER TABLE reclamos ADD COLUMN mensaje_resolucion TEXT NULL;
ALTER TABLE reclamos ADD COLUMN fecha_resolucion DATETIME NULL;
ALTER TABLE reclamos ADD COLUMN fecha_ultimo_cambio_estado DATETIME NULL;

-- 9. REFACTOR DE ESTADOS EN RECLAMOS (Pendiente, En revisión, En proceso, Resuelto, Cancelado)
-- A. Pasamos temporalmente a VARCHAR para evitar errores de truncado de datos en filas existentes
ALTER TABLE reclamos MODIFY COLUMN estado VARCHAR(50) NOT NULL DEFAULT 'Pendiente';

-- B. Mapeamos los valores antiguos a los nuevos nombres de estados del Sprint 4
SET SQL_SAFE_UPDATES = 0;
UPDATE reclamos SET estado = 'Pendiente' WHERE estado IN ('recibido', 'recibidos', 'pendiente');
UPDATE reclamos SET estado = 'En proceso' WHERE estado IN ('en_proceso', 'en proceso');
UPDATE reclamos SET estado = 'Resuelto' WHERE estado IN ('resuelto');
UPDATE reclamos SET estado = 'Cancelado' WHERE estado IN ('rechazado', 'cancelado');
SET SQL_SAFE_UPDATES = 1;

-- C. Aplicamos el nuevo tipo ENUM refinado
ALTER TABLE reclamos MODIFY COLUMN estado ENUM('Pendiente', 'En revisión', 'En proceso', 'Resuelto', 'Cancelado') NOT NULL DEFAULT 'Pendiente';

SET FOREIGN_KEY_CHECKS = 1;
