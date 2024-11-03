CREATE TABLE IF NOT EXISTS `neon_pizzajob` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `total_deliveries` INT DEFAULT 0
);