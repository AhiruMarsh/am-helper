-- データベース作成: `local_dynmap`
CREATE DATABASE IF NOT EXISTS `local_dynmap` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `local_dynmap`;

-- 上記のデータベースを`mc`ユーザーが操作できるように
GRANT all ON local_dynmap.* TO 'mc';