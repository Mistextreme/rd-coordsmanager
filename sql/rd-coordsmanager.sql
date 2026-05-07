-- ============================================================
--  rd-coordsmanager | SQL Install
--  RoxDev Development Store
--  NOTE: The resource auto-creates this table on first start.
--        This file is provided as a manual install reference.
-- ============================================================

CREATE TABLE IF NOT EXISTS `rd_coords` (
    `id`         INT          NOT NULL AUTO_INCREMENT,
    `discord_id` VARCHAR(100) NOT NULL,
    `name`       VARCHAR(60)  NOT NULL DEFAULT 'Unnamed',
    `x`          FLOAT        NOT NULL DEFAULT 0,
    `y`          FLOAT        NOT NULL DEFAULT 0,
    `z`          FLOAT        NOT NULL DEFAULT 0,
    `heading`    FLOAT        NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_discord` (`discord_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
