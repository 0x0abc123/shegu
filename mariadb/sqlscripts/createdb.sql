CREATE USER IF NOT EXISTS  'nc'@'localhost' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS  'nc'@'%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nc'@'localhost';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nc'@'%';
FLUSH PRIVILEGES;

CREATE USER IF NOT EXISTS  'rc'@'localhost' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS  'rc'@'%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS roundcubemail CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'rc'@'localhost';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'rc'@'%';
FLUSH PRIVILEGES;
