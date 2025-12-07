use smart_parking;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ========== 1. 用户表 users_list ==========
DROP TABLE IF EXISTS `users_list`;
CREATE TABLE `users_list` (
  `user_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '用户唯一标识',
  `username` VARCHAR(50) NOT NULL UNIQUE COMMENT '用户名（登录名）',
  `password_hash` VARCHAR(255) NOT NULL COMMENT '密码哈希值',
  `phone` VARCHAR(20) NOT NULL COMMENT '手机号',
  `email` VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
  `real_name` VARCHAR(50) DEFAULT NULL COMMENT '真实姓名',
  `register_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
  `last_login` DATETIME DEFAULT NULL COMMENT '最后登录时间',
  `status` TINYINT DEFAULT 1 COMMENT '账户状态（0-禁用，1-正常）',
  INDEX `idx_phone` (`phone`),
  INDEX `idx_email` (`email`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '用户信息表';

-- ========== 2. 管理员表 admins_list ==========
DROP TABLE IF EXISTS `admins_list`;
CREATE TABLE `admins_list` (
  `admin_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '管理员ID',
  `username` VARCHAR(50) NOT NULL UNIQUE COMMENT '登录名',
  `password_hash` VARCHAR(255) NOT NULL COMMENT '加密密码',
  `phone_number` VARCHAR(20) UNIQUE COMMENT '电话号码',
  `role` ENUM('system','lot_admin') DEFAULT 'lot_admin' COMMENT '角色类型',
  `lot_id` INT DEFAULT NULL COMMENT '若是停车场管理员，对应停车场ID',
  `status` TINYINT DEFAULT 1 COMMENT '状态（0-禁用，1-启用）',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  UNIQUE KEY `uniq_phone` (`phone_number`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '管理员表';

-- ========== 3. 停车场表 parking_lot ==========
DROP TABLE IF EXISTS `parking_lot`;
CREATE TABLE `parking_lot` (
  `lot_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '停车场唯一标识',
  `name` VARCHAR(100) NOT NULL COMMENT '停车场名称',
  `address` VARCHAR(255) NOT NULL COMMENT '详细地址',
  `total_levels` INT DEFAULT 1 COMMENT '总层数',
  `total_spaces` INT DEFAULT 0 COMMENT '总车位数',
  `hourly_rate` DECIMAL(8,2) DEFAULT 5.00 COMMENT '小时费率',
  `status` TINYINT DEFAULT 1 COMMENT '状态（0-关闭，1-开放）',
  `description` TEXT COMMENT '描述信息',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '停车场基本信息表';

-- ========== 4. 车位表 parking_space ==========
DROP TABLE IF EXISTS `parking_space`;
CREATE TABLE `parking_space` (
  `space_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '车位唯一标识',
  `lot_id` INT NOT NULL COMMENT '所属停车场ID',
  `level` INT DEFAULT 1 COMMENT '所在楼层',
  `space_number` VARCHAR(20) NOT NULL COMMENT '车位编号',
  `space_type` VARCHAR(20) DEFAULT '普通' COMMENT '车位类型',
  `is_occupied` TINYINT DEFAULT 0 COMMENT '是否被占用',
  `is_reserved` TINYINT DEFAULT 0 COMMENT '是否已被预订',
  `status` TINYINT DEFAULT 1 COMMENT '状态（0-禁用，1-可用）',
  `last_update` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后状态更新时间',
  INDEX `idx_lot_id` (`lot_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '车位表';

-- ========== 5. 车辆表 vehicle ==========
DROP TABLE IF EXISTS `vehicle`;
CREATE TABLE `vehicle` (
  `vehicle_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '车辆唯一标识',
  `user_id` INT NOT NULL COMMENT '关联用户ID',
  `license_plate` VARCHAR(20) NOT NULL UNIQUE COMMENT '车牌号',
  `brand` VARCHAR(50) DEFAULT NULL COMMENT '车辆品牌',
  `model` VARCHAR(50) DEFAULT NULL COMMENT '车型',
  `color` VARCHAR(20) DEFAULT NULL COMMENT '车辆颜色',
  `add_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '添加时间',
  INDEX `idx_user_id` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '车辆表';

-- ========== 6. 预约订单表 reservation_order ==========
DROP TABLE IF EXISTS `reservation_order`;
CREATE TABLE `reservation_order` (
  `order_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '订单唯一标识',
  `user_id` INT NOT NULL COMMENT '预订用户ID',
  `vehicle_id` INT NOT NULL COMMENT '预订车辆ID',
  `space_id` INT NOT NULL COMMENT '预订车位ID',
  `lot_id` INT NOT NULL COMMENT '所属停车场ID',
  `start_time` DATETIME NOT NULL COMMENT '预订开始时间',
  `end_time` DATETIME NOT NULL COMMENT '预订结束时间',
  `actual_end_time` DATETIME DEFAULT NULL COMMENT '实际离场时间',
  `duration_minutes` INT DEFAULT NULL COMMENT '预订时长（分钟）',
  `booking_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '预订下单时间',
  `status` TINYINT DEFAULT 1 COMMENT '订单状态（0-已取消，1-已预订，2-使用中，3-已完成）',
  `total_fee` DECIMAL(10,2) DEFAULT 0.00 COMMENT '应付总费用',
  `paid_fee` DECIMAL(10,2) DEFAULT 0.00 COMMENT '实付金额',
  `payment_status` TINYINT DEFAULT 0 COMMENT '支付状态（0-未支付，1-已支付）',
  `reservation_code` VARCHAR(50) NOT NULL UNIQUE COMMENT '预订编号',
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_space_id` (`space_id`),
  INDEX `idx_reservation_code` (`reservation_code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '预约订单表';

-- ========== 7. 支付记录表 payment_record ==========
DROP TABLE IF EXISTS `payment_record`;
CREATE TABLE `payment_record` (
  `payment_id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '支付流水号',
  `order_id` INT NOT NULL COMMENT '关联的订单ID',
  `user_id` INT NOT NULL COMMENT '用户ID',
  `amount` DECIMAL(10,2) NOT NULL COMMENT '支付金额',
  `method` ENUM('wechat','alipay','credit_card','wallet') NOT NULL COMMENT '支付方式',
  `transaction_no` VARCHAR(100) UNIQUE COMMENT '第三方支付平台交易号',
  `payment_status` TINYINT DEFAULT 0 COMMENT '支付状态（0-待支付，1-支付成功，2-失败，3-退款）',
  `pay_time` DATETIME DEFAULT NULL COMMENT '支付时间',
  `refund_time` DATETIME DEFAULT NULL COMMENT '退款时间',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  INDEX `idx_order_id` (`order_id`),
  INDEX `idx_user_id` (`user_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '支付记录表';

-- ========== 8. 停车记录表 parking_record ==========
DROP TABLE IF EXISTS `parking_record`;
CREATE TABLE `parking_record` (
  `record_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '停车记录唯一标识',
  `user_id` INT NOT NULL COMMENT '用户ID',
  `vehicle_id` INT NOT NULL COMMENT '车辆ID',
  `space_id` INT NOT NULL COMMENT '车位ID',
  `lot_id` INT NOT NULL COMMENT '停车场ID',
  `entry_time` DATETIME NOT NULL COMMENT '入场时间',
  `exit_time` DATETIME DEFAULT NULL COMMENT '出场时间',
  `duration_minutes` INT DEFAULT NULL COMMENT '停车时长（分钟）',
  `fee_calculated` DECIMAL(10,2) DEFAULT 0.00 COMMENT '计算停车费',
  `fee_paid` DECIMAL(10,2) DEFAULT 0.00 COMMENT '实际支付停车费',
  `payment_status` TINYINT DEFAULT 0 COMMENT '支付状态（0-未支付，1-已支付）',
  `is_violation` TINYINT DEFAULT 0 COMMENT '是否违规',
  `violation_reason` VARCHAR(255) DEFAULT NULL COMMENT '违规原因',
  `record_status` TINYINT DEFAULT 1 COMMENT '记录状态（1-在场，2-已出场）',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_vehicle_id` (`vehicle_id`),
  INDEX `idx_violation` (`is_violation`),
  INDEX `idx_record_status` (`record_status`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '停车记录表';

-- ========== 9. 违规记录表 violation_record ==========
DROP TABLE IF EXISTS `violation_record`;
CREATE TABLE `violation_record` (
  `violation_id` INT AUTO_INCREMENT PRIMARY KEY COMMENT '违规记录唯一标识',
  `record_id` INT NOT NULL COMMENT '关联停车记录ID',
  `user_id` INT NOT NULL COMMENT '用户ID',
  `vehicle_id` INT NOT NULL COMMENT '车辆ID',
  `violation_type` VARCHAR(50) NOT NULL COMMENT '违规类型',
  `violation_time` DATETIME NOT NULL COMMENT '违规发生时间',
  `description` TEXT COMMENT '违规描述',
  `fine_amount` DECIMAL(10,2) DEFAULT 0.00 COMMENT '罚款金额',
  `status` TINYINT DEFAULT 0 COMMENT '处理状态（0-未处理，1-已处理）',
  `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `process_time` DATETIME DEFAULT NULL COMMENT '处理时间',
  INDEX `idx_record_id` (`record_id`),
  INDEX `idx_user_id` (`user_id`),
  INDEX `idx_status` (`status`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = '违规记录表';

-- ========== ✅ 第二阶段：添加外键约束 ==========

-- admins_list → parking_lot
ALTER TABLE `admins_list`
  ADD CONSTRAINT `fk_admins_lot` FOREIGN KEY (`lot_id`)
  REFERENCES `parking_lot` (`lot_id`)
  ON UPDATE CASCADE ON DELETE SET NULL;

-- parking_space → parking_lot
ALTER TABLE `parking_space`
  ADD CONSTRAINT `fk_parking_space_lot` FOREIGN KEY (`lot_id`)
  REFERENCES `parking_lot` (`lot_id`)
  ON UPDATE CASCADE ON DELETE CASCADE;

-- vehicle → users_list
ALTER TABLE `vehicle`
  ADD CONSTRAINT `fk_vehicle_user` FOREIGN KEY (`user_id`)
  REFERENCES `users_list` (`user_id`)
  ON UPDATE CASCADE ON DELETE CASCADE;

-- reservation_order → users_list / vehicle / parking_space / parking_lot
ALTER TABLE `reservation_order`
  ADD CONSTRAINT `fk_reservation_user` FOREIGN KEY (`user_id`)
    REFERENCES `users_list` (`user_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_reservation_vehicle` FOREIGN KEY (`vehicle_id`)
    REFERENCES `vehicle` (`vehicle_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_reservation_space` FOREIGN KEY (`space_id`)
    REFERENCES `parking_space` (`space_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_reservation_lot` FOREIGN KEY (`lot_id`)
    REFERENCES `parking_lot` (`lot_id`)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- payment_record → reservation_order / users_list
ALTER TABLE `payment_record`
  ADD CONSTRAINT `fk_payment_order` FOREIGN KEY (`order_id`)
    REFERENCES `reservation_order` (`order_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_payment_user` FOREIGN KEY (`user_id`)
    REFERENCES `users_list` (`user_id`)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- parking_record → users_list / vehicle / parking_space / parking_lot
ALTER TABLE `parking_record`
  ADD CONSTRAINT `fk_record_user` FOREIGN KEY (`user_id`)
    REFERENCES `users_list` (`user_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_record_vehicle` FOREIGN KEY (`vehicle_id`)
    REFERENCES `vehicle` (`vehicle_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_record_space` FOREIGN KEY (`space_id`)
    REFERENCES `parking_space` (`space_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_record_lot` FOREIGN KEY (`lot_id`)
    REFERENCES `parking_lot` (`lot_id`)
    ON UPDATE CASCADE ON DELETE CASCADE;

-- violation_record → parking_record / users_list / vehicle
ALTER TABLE `violation_record`
  ADD CONSTRAINT `fk_violation_record` FOREIGN KEY (`record_id`)
    REFERENCES `parking_record` (`record_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_violation_user` FOREIGN KEY (`user_id`)
    REFERENCES `users_list` (`user_id`)
    ON UPDATE CASCADE ON DELETE CASCADE,
  ADD CONSTRAINT `fk_violation_vehicle` FOREIGN KEY (`vehicle_id`)
    REFERENCES `vehicle` (`vehicle_id`)
    ON UPDATE CASCADE ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;


-- 索引
-- 用户信息表索引
CREATE INDEX idx_users_login ON users_list(username, password_hash);
CREATE INDEX idx_users_phone ON users_list(phone);
CREATE INDEX idx_users_email ON users_list(email);

-- 车辆信息表索引
CREATE INDEX idx_vehicle_user_plate ON vehicle(user_id, license_plate);

-- 停车场信息表索引
CREATE INDEX idx_lot_status ON parking_lot(status, lot_id);

-- 车位信息表索引
CREATE INDEX idx_space_availability ON parking_space(lot_id, status, is_occupied, is_reserved);

-- 预订订单表索引
CREATE INDEX idx_reservation_user_status ON reservation_order(user_id, status, start_time);
CREATE INDEX idx_reservation_space_time ON reservation_order(space_id, start_time, end_time);
CREATE UNIQUE INDEX idx_reservation_code ON reservation_order(reservation_code);

-- 支付记录表索引
CREATE INDEX idx_payment_user_status ON payment_record(user_id, payment_status, create_time);
CREATE INDEX idx_payment_order ON payment_record(order_id);

-- 停车记录表索引
CREATE INDEX idx_park_user_status ON parking_record(user_id, record_status, entry_time);
CREATE INDEX idx_park_vehicle_exit ON parking_record(vehicle_id, exit_time);

-- 违规记录表索引
CREATE INDEX idx_violation_user_status ON violation_record(user_id, status, violation_time);
CREATE INDEX idx_violation_time ON violation_record(violation_time);




-- 用户视图：
-- 用户停车历史视图
CREATE VIEW user_parking_history AS
SELECT 
    pr.RecordID,
    u.Username,
    u.RealName,
    v.LicensePlate,
    pl.Name AS ParkingLot,
    ps.SpaceNumber,
    pr.EntryTime,
    pr.ExitTime,
    pr.DurationMinutes,
    pr.FeeCalculated,
    pr.FeePaid,
    pr.PaymentStatus
FROM parking_record pr
JOIN users_list u ON pr.UserID = u.UserID
JOIN vehicle v ON pr.VehicleID = v.VehicleID
JOIN parking_space ps ON pr.SpaceID = ps.SpaceID
JOIN parking_lot pl ON pr.LotID = pl.LotID;

-- 停车场实时车位视图
CREATE VIEW parking_lot_availability AS
SELECT 
    pl.LotID,
    pl.Name AS ParkingLot,
    pl.Address,
    pl.TotalSpaces,
    COUNT(ps.SpaceID) AS TotalSpaces,
    SUM(CASE WHEN ps.IsOccupied = 0 AND ps.IsReserved = 0 THEN 1 ELSE 0 END) AS AvailableSpaces,
    SUM(CASE WHEN ps.IsOccupied = 1 THEN 1 ELSE 0 END) AS OccupiedSpaces,
    SUM(CASE WHEN ps.IsReserved = 1 THEN 1 ELSE 0 END) AS ReservedSpaces
FROM parking_lot pl
LEFT JOIN parking_space ps ON pl.LotID = ps.LotID
GROUP BY pl.LotID, pl.Name, pl.Address, pl.TotalSpaces;

-- 违规记录视图
CREATE VIEW violation_records_view AS
SELECT 
    vr.ViolationID,
    u.Username,
    u.RealName,
    v.LicensePlate,
    vr.ViolationType,
    vr.ViolationTime,
    vr.Description,
    vr.FineAmount,
    vr.Status,
    pl.Name AS ParkingLot
FROM violation_record vr
JOIN users_list u ON vr.UserID = u.UserID
JOIN vehicle v ON vr.VehicleID = v.VehicleID
LEFT JOIN parking_record pr ON vr.RecordID = pr.RecordID
LEFT JOIN parking_lot pl ON pr.LotID = pl.LotID;

-- 停车场收入统计视图
CREATE VIEW parking_revenue_report AS
SELECT 
    pl.LotID,
    pl.Name AS ParkingLot,
    DATE_FORMAT(pr.EntryTime, '%Y-%m') AS Month,
    SUM(pr.FeePaid) AS ParkingRevenue,
    SUM(CASE WHEN vr.FineAmount IS NOT NULL THEN vr.FineAmount ELSE 0 END) AS FineRevenue,
    COUNT(DISTINCT pr.RecordID) AS ParkingCount,
    COUNT(DISTINCT vr.ViolationID) AS ViolationCount
FROM parking_lot pl
LEFT JOIN parking_record pr ON pl.LotID = pr.LotID
LEFT JOIN violation_record vr ON pr.RecordID = vr.RecordID
GROUP BY pl.LotID, pl.Name, DATE_FORMAT(pr.EntryTime, '%Y-%m');

-- 车位使用率视图
CREATE VIEW space_utilization_report AS
SELECT 
    ps.SpaceID,
    ps.SpaceNumber,
    pl.Name AS ParkingLot,
    COUNT(pr.RecordID) AS TotalUses,
    AVG(pr.DurationMinutes) AS AvgDuration,
    SUM(pr.DurationMinutes) AS TotalDuration,
    MAX(pr.EntryTime) AS LastUsed
FROM parking_space ps
JOIN parking_lot pl ON ps.LotID = pl.LotID
LEFT JOIN parking_record pr ON ps.SpaceID = pr.SpaceID
GROUP BY ps.SpaceID, ps.SpaceNumber, pl.Name;


-- 数据库用户创建及权限分配SQL语句
-- 创建应用程序用户（用于业务操作）
CREATE USER 'smart_parking_app'@'%' IDENTIFIED BY 'StrongPassword123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_parking_db.users_list TO 'smart_parking_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_parking_db.vehicle TO 'smart_parking_app'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_parking_db.parking_lot TO 'smart_parking_app'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_parking_db.parking_space TO 'smart_parking_app'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_parking_db.reservation_order TO 'smart_parking_app'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_parking_db.payment_record TO 'smart_parking_app'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_parking_db.parking_record TO 'smart_parking_app'@'%';
GRANT SELECT, INSERT, UPDATE ON smart_parking_db.violation_record TO 'smart_parking_app'@'%';
GRANT SELECT ON smart_parking_db.user_parking_history TO 'smart_parking_app'@'%';
GRANT SELECT ON smart_parking_db.parking_lot_availability TO 'smart_parking_app'@'%';

-- 创建报表用户（只读权限）
CREATE USER 'smart_parking_report'@'%' IDENTIFIED BY 'ReportPassword456!';
GRANT SELECT ON smart_parking_db.user_parking_history TO 'smart_parking_report'@'%';
GRANT SELECT ON smart_parking_db.parking_lot_availability TO 'smart_parking_report'@'%';
GRANT SELECT ON smart_parking_db.violation_records_view TO 'smart_parking_report'@'%';
GRANT SELECT ON smart_parking_db.parking_revenue_report TO 'smart_parking_report'@'%';
GRANT SELECT ON smart_parking_db.space_utilization_report TO 'smart_parking_report'@'%';

-- 创建管理员用户（有限管理权限）
CREATE USER 'smart_parking_admin'@'localhost' IDENTIFIED BY 'AdminPassword789!';
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_parking_db.admins_list TO 'smart_parking_admin'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_parking_db.parking_lot TO 'smart_parking_admin'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON smart_parking_db.parking_space TO 'smart_parking_admin'@'localhost';
GRANT SELECT ON smart_parking_db.* TO 'smart_parking_admin'@'localhost';

-- 刷新权限
FLUSH PRIVILEGES;
