-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 08, 2026 at 08:19 AM
-- Updated:         Mar 10, 2026 (includes all migrations through migrate-guest-id-type)
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET FOREIGN_KEY_CHECKS = 0;
SET time_zone = "+00:00";

-- ============================================================
-- DROP ALL VIEWS & TABLES for clean idempotent re-import
-- ============================================================
DROP VIEW IF EXISTS `inspection_summary`;
DROP VIEW IF EXISTS `room_inspection_checklist`;
DROP VIEW IF EXISTS `v_room_asset_summary`;
DROP VIEW IF EXISTS `v_room_asset_inventory`;
DROP VIEW IF EXISTS `payment_summary`;
DROP VIEW IF EXISTS `booking_details_enhanced`;
DROP VIEW IF EXISTS `service_order_details`;
DROP VIEW IF EXISTS `booking_details`;

DROP TABLE IF EXISTS `asset_charges`;
DROP TABLE IF EXISTS `inspection_items`;
DROP TABLE IF EXISTS `room_inspections`;
DROP TABLE IF EXISTS `room_asset_history`;
DROP TABLE IF EXISTS `room_asset_instances`;
DROP TABLE IF EXISTS `room_assets`;
DROP TABLE IF EXISTS `asset_categories`;
DROP TABLE IF EXISTS `income_records`;
DROP TABLE IF EXISTS `expense_records`;
DROP TABLE IF EXISTS `staff_salaries`;
DROP TABLE IF EXISTS `hotel_policies`;
DROP TABLE IF EXISTS `financial_management`;
DROP TABLE IF EXISTS `refunds`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `billing_settings`;
DROP TABLE IF EXISTS `invoice_items`;
DROP TABLE IF EXISTS `invoices`;
DROP TABLE IF EXISTS `service_order_details`;
DROP TABLE IF EXISTS `service_orders`;
DROP TABLE IF EXISTS `services`;
DROP TABLE IF EXISTS `room_cleaning_status`;
DROP TABLE IF EXISTS `maintenance_logs`;
DROP TABLE IF EXISTS `rooms`;
DROP TABLE IF EXISTS `inventory_transactions`;
DROP TABLE IF EXISTS `inventory_stocks`;
DROP TABLE IF EXISTS `inventory_items`;
DROP TABLE IF EXISTS `inventory_categories`;
DROP TABLE IF EXISTS `housekeeping_staff`;
DROP TABLE IF EXISTS `notifications`;
DROP TABLE IF EXISTS `guest_sessions`;
DROP TABLE IF EXISTS `hotel_users`;
DROP TABLE IF EXISTS `guests`;
DROP TABLE IF EXISTS `cleaning_tasks`;
DROP TABLE IF EXISTS `booking_details`;
DROP TABLE IF EXISTS `bookings`;
-- ============================================================


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hotel_management_db`
--

DELIMITER $$
--
-- Functions
--
DROP FUNCTION IF EXISTS `check_room_availability_enhanced`$$
CREATE FUNCTION `check_room_availability_enhanced` (`p_room_id` INT, `p_start_date` DATE, `p_end_date` DATE) RETURNS LONGTEXT CHARSET utf8mb4 COLLATE utf8mb4_bin READS SQL DATA BEGIN
    DECLARE v_conflict_count          INT DEFAULT 0;
    DECLARE v_early_checkout_available BOOLEAN DEFAULT FALSE;
    DECLARE v_result JSON;

    SELECT COUNT(*) INTO v_conflict_count
    FROM bookings
    WHERE room_id = p_room_id
      AND booking_status IN ('Confirmed','CheckedIn')
      AND ((check_in <= p_start_date AND check_out > p_start_date)
        OR (check_in < p_end_date   AND check_out >= p_end_date)
        OR (check_in >= p_start_date AND check_out <= p_end_date))
      AND (actual_checkout_time IS NULL OR actual_checkout_time >= p_start_date);

    SELECT COUNT(*) > 0 INTO v_early_checkout_available
    FROM bookings
    WHERE room_id = p_room_id
      AND is_early_checkout = TRUE
      AND actual_checkout_time IS NOT NULL
      AND actual_checkout_time <= p_start_date
      AND check_out > p_start_date;

    SET v_result = JSON_OBJECT(
        'available', CASE
            WHEN v_conflict_count = 0 THEN TRUE
            WHEN v_early_checkout_available THEN TRUE
            ELSE FALSE
        END,
        'conflicts',                v_conflict_count,
        'early_checkout_available', v_early_checkout_available
    );
    RETURN v_result;
END$$

DROP FUNCTION IF EXISTS `GetCheckoutType`$$
CREATE FUNCTION `GetCheckoutType` (`checkout_date` DATE, `checkout_time_val` TIME) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC READS SQL DATA BEGIN
    IF checkout_time_val < '12:00:00' THEN
        RETURN 'Early';
    ELSEIF checkout_time_val > '18:00:00' THEN
        RETURN 'Late';
    ELSE
        RETURN 'Standard';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `bookings`
--

CREATE TABLE `bookings` (
  `booking_id` int(11) NOT NULL,
  `guest_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `check_in` date NOT NULL,
  `check_out` date NOT NULL,
  `number_of_guests` int(11) NOT NULL DEFAULT 1,
  `number_of_nights` int(11) GENERATED ALWAYS AS (to_days(`check_out`) - to_days(`check_in`)) STORED,
  `room_price` decimal(10,2) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `discount_type` enum('None','Percentage','Fixed') DEFAULT 'None',
  `discount_value` decimal(10,2) DEFAULT 0.00,
  `discount_reason` varchar(100) DEFAULT NULL,
  `advance_payment` decimal(10,2) DEFAULT 0.00,
  `payment_status` enum('Pending','Partial','Paid') DEFAULT 'Pending',
  `payment_method` enum('Cash','Card','Debit Card','UPI','Online') DEFAULT 'Cash',
  `booking_source` enum('Walk-in','Phone','Online','OTA','Corporate','Other') DEFAULT 'Walk-in',
  `booking_status` enum('Confirmed','CheckedIn','CheckedOut','Cancelled','NoShow') DEFAULT 'Confirmed',
  `special_requests` text DEFAULT NULL,
  `actual_checkin_time` datetime DEFAULT NULL,
  `actual_checkout_time` datetime DEFAULT NULL COMMENT 'Actual time guest checked out',
  `checkout_type` enum('Early','Standard','Late') DEFAULT 'Standard' COMMENT 'Type of checkout',
  `is_early_checkout` tinyint(1) DEFAULT 0 COMMENT 'Flag for early checkout',
  `late_checkout_fee` decimal(10,2) DEFAULT 0.00 COMMENT 'Late checkout fee if applicable',
  `early_checkout_reason` varchar(255) DEFAULT NULL,
  `is_extension` tinyint(1) DEFAULT 0,
  `parent_booking_id` int(11) DEFAULT NULL,
  `booking_group_id` varchar(50) DEFAULT NULL,
  `cancellation_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `booking_details`
-- (See below for the actual view)
--
CREATE TABLE `booking_details` (
`booking_id` int(11)
,`check_in` date
,`check_out` date
,`total_amount` decimal(10,2)
,`payment_status` enum('Pending','Partial','Paid')
,`booking_status` enum('Confirmed','CheckedIn','CheckedOut','Cancelled')
,`created_at` timestamp
,`guest_name` varchar(100)
,`guest_phone` varchar(15)
,`guest_email` varchar(100)
,`room_number` varchar(10)
,`room_type` enum('Single','Double','Suite','Deluxe')
,`room_price` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `cleaning_tasks`
--

CREATE TABLE `cleaning_tasks` (
  `task_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `staff_id` int(11) DEFAULT NULL,
  `task_type` enum('Deep Clean','Regular Clean','Quick Clean','Turnover','Spot Clean') DEFAULT 'Regular Clean',
  `status` enum('Not Started','In Progress','Completed','Cancelled','Pending Approval') DEFAULT 'Not Started',
  `priority` enum('Low','Medium','High','Urgent') DEFAULT 'Medium',
  `scheduled_date` date NOT NULL,
  `scheduled_time` time DEFAULT NULL,
  `start_time` datetime DEFAULT NULL,
  `completion_time` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `checklist_items` varchar(500) DEFAULT NULL,
  `assigned_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `cleaning_tasks`
--

INSERT INTO `cleaning_tasks` (`task_id`, `room_id`, `staff_id`, `task_type`, `status`, `priority`, `scheduled_date`, `scheduled_time`, `start_time`, `completion_time`, `notes`, `checklist_items`, `assigned_by`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'Turnover', 'Completed', 'High', '2026-03-08', '09:00:00', NULL, NULL, 'Guest checkout - full deep clean', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(2, 2, 3, 'Regular Clean', 'In Progress', 'Medium', '2026-03-08', '10:00:00', NULL, NULL, 'Standard daily cleaning', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, 3, 4, 'Quick Clean', 'Not Started', 'Low', '2026-03-08', '11:00:00', NULL, NULL, 'Tidy up and restock amenities', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(4, 4, 5, 'Spot Clean', 'Pending Approval', 'High', '2026-03-08', '14:00:00', NULL, NULL, 'Carpet stain removal in corridor', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(5, 5, 2, 'Regular Clean', 'Not Started', 'Medium', '2026-03-09', '09:00:00', NULL, NULL, 'Standard cleaning', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(6, 6, 3, 'Deep Clean', 'Not Started', 'High', '2026-03-09', '10:00:00', NULL, NULL, 'Full deep clean - maintenance done', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(7, 7, 4, 'Regular Clean', 'Cancelled', 'Low', '2026-03-08', '15:00:00', NULL, NULL, 'Room not available', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `guests`
--

CREATE TABLE `guests` (
  `guest_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `id_proof` varchar(50) NOT NULL,
  `id_type` enum('NID','Passport','Driving License','Other') NOT NULL DEFAULT 'NID',
  `address` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hotel_users`
--

CREATE TABLE `hotel_users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `role` enum('Admin','Manager','Staff') NOT NULL DEFAULT 'Staff',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_login_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `guest_sessions`
--

CREATE TABLE `guest_sessions` (
  `session_id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `guest_id` int(11) NOT NULL,
  `access_token` varchar(256) NOT NULL,
  `token_pin` varchar(6) NOT NULL,
  `is_active` tinyint(4) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,
  `checked_out_at` timestamp NULL DEFAULT NULL,
  `last_accessed` timestamp NULL DEFAULT NULL,
  `access_count` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL COMMENT 'check_in, check_out, booking, payment, overdue, maintenance, housekeeping, system, no_show, unpaid_checkout, cleaning_needed',
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `reference_type` varchar(50) DEFAULT NULL COMMENT 'booking, guest, room, payment, invoice',
  `reference_id` int(11) DEFAULT NULL,
  `priority` enum('low','normal','high','urgent') DEFAULT 'normal',
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `read_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `housekeeping_staff`
--

CREATE TABLE `housekeeping_staff` (
  `staff_id` int(11) NOT NULL,
  `staff_name` varchar(100) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `role` enum('Housekeeper','Supervisor','Manager') DEFAULT 'Housekeeper',
  `shift` enum('Morning','Afternoon','Night') DEFAULT 'Morning',
  `status` enum('Active','Inactive','On Leave') DEFAULT 'Active',
  `assigned_floors` varchar(50) DEFAULT NULL,
  `hire_date` date DEFAULT NULL,
  `monthly_salary` decimal(10,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `housekeeping_staff`
--

INSERT INTO `housekeeping_staff` (`staff_id`, `staff_name`, `phone`, `email`, `role`, `shift`, `status`, `assigned_floors`, `hire_date`, `created_at`, `updated_at`) VALUES
(1, 'Priya Sharma', '9876543220', 'priya@hotel.com', 'Supervisor', 'Morning', 'Active', '1,2,3', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(2, 'Rajesh Kumar', '9876543221', 'rajesh@hotel.com', 'Housekeeper', 'Morning', 'Active', '1,2', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, 'Anita Singh', '9876543222', 'anita@hotel.com', 'Housekeeper', 'Morning', 'Active', '2,3', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(4, 'Vikram Patel', '9876543223', 'vikram@hotel.com', 'Housekeeper', 'Afternoon', 'Active', '3,4', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(5, 'Neha Gupta', '9876543224', 'neha@hotel.com', 'Housekeeper', 'Afternoon', 'Active', '1,4', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(6, 'Suresh Verma', '9876543225', 'suresh@hotel.com', 'Manager', 'Morning', 'Active', '1,2,3,4', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(7, 'Deepa Nair', '9876543226', 'deepa@hotel.com', 'Housekeeper', 'Night', 'On Leave', '2,3', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(8, 'Arjun Singh', '9876543227', 'arjun@hotel.com', 'Housekeeper', 'Night', 'Active', '1,3,4', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_categories`
--

CREATE TABLE `inventory_categories` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory_categories`
--

INSERT INTO `inventory_categories` (`category_id`, `category_name`, `description`, `created_at`) VALUES
(1, 'Linens & Bedding', 'Towels, bed sheets, pillow covers, blankets', '2026-03-08 06:24:40'),
(2, 'Toiletries', 'Soaps, shampoos, conditioners, toothbrushes', '2026-03-08 06:24:40'),
(3, 'Cleaning Supplies', 'Detergents, disinfectants, brooms, mops', '2026-03-08 06:24:40'),
(4, 'Kitchen Supplies', 'Utensils, plates, glasses, cutlery', '2026-03-08 06:24:40'),
(5, 'Laundry Supplies', 'Detergent, fabric softeners, stain removers', '2026-03-08 06:24:40'),
(6, 'Stationery', 'Notepads, pens, folders, envelopes', '2026-03-08 06:24:40'),
(7, 'Maintenance & Tools', 'Tools, spare parts, bulbs, batteries', '2026-03-08 06:24:40'),
(8, 'Beverages & Snacks', 'Coffee, tea, sugar, biscuits, chocolates', '2026-03-08 06:24:40');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_items`
--

CREATE TABLE `inventory_items` (
  `item_id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `category_id` int(11) NOT NULL,
  `unit` enum('Pieces','Kg','Liters','Boxes','Sets','Rolls','Bottles') NOT NULL,
  `unit_cost` decimal(10,2) NOT NULL,
  `description` text DEFAULT NULL,
  `supplier_name` varchar(100) DEFAULT NULL,
  `supplier_phone` varchar(15) DEFAULT NULL,
  `status` enum('Active','Inactive') DEFAULT 'Active',
  `is_checkin_item` tinyint(1) NOT NULL DEFAULT 0,
  `checkin_qty_per_guest` int(11) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory_items`
--

INSERT INTO `inventory_items` (`item_id`, `item_name`, `category_id`, `unit`, `unit_cost`, `description`, `supplier_name`, `supplier_phone`, `status`, `created_at`, `updated_at`) VALUES
(1, 'Bath Towel', 1, 'Pieces', 150.00, 'Premium cotton bath towel (white)', 'Linen World', '9876543210', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(2, 'Bed Sheet', 1, 'Pieces', 250.00, 'Cotton bed sheet set (queen size)', 'Linen World', '9876543210', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(3, 'Pillow Cover', 1, 'Pieces', 80.00, 'Cotton pillow cover', 'Linen World', '9876543210', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(4, 'Blanket', 1, 'Pieces', 300.00, 'Warm blanket (double size)', 'Linen World', '9876543210', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(5, 'Soap Bar', 2, 'Pieces', 20.00, 'Guest soap bar', 'Hygiene Plus', '9876543211', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(6, 'Shampoo Bottle', 2, 'Bottles', 150.00, 'Premium shampoo (250ml)', 'Hygiene Plus', '9876543211', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(7, 'Conditioner Bottle', 2, 'Bottles', 150.00, 'Conditioner (250ml)', 'Hygiene Plus', '9876543211', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(8, 'Toothbrush', 2, 'Pieces', 15.00, 'Disposable toothbrush', 'Hygiene Plus', '9876543211', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(9, 'Floor Cleaner', 3, 'Liters', 200.00, 'Multi-purpose floor cleaner (5L)', 'Clean Care', '9876543212', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(10, 'Disinfectant Spray', 3, 'Bottles', 180.00, 'Room disinfectant spray (500ml)', 'Clean Care', '9876543212', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(11, 'Dish Soap', 3, 'Liters', 100.00, 'Liquid dish soap (1L)', 'Clean Care', '9876543212', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(12, 'Paper Plates', 4, 'Sets', 50.00, 'Disposable paper plates (50pcs)', 'Kitchen Plus', '9876543213', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(13, 'Glass Cups', 4, 'Sets', 300.00, 'Glass cups set (6pcs)', 'Kitchen Plus', '9876543213', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(14, 'Stainless Steel Cutlery', 4, 'Sets', 400.00, 'Cutlery set (6 place)', 'Kitchen Plus', '9876543213', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(15, 'Laundry Detergent', 5, 'Kg', 250.00, 'Laundry detergent powder (1kg)', 'Wash World', '9876543214', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(16, 'Fabric Softener', 5, 'Liters', 200.00, 'Fabric softener (1L)', 'Wash World', '9876543214', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(17, 'Stain Remover', 5, 'Bottles', 180.00, 'Stain remover spray (500ml)', 'Wash World', '9876543214', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(18, 'Office Notepad', 6, 'Pieces', 30.00, 'Spiral notepads', 'Paper Co', '9876543215', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(19, 'Ballpoint Pen', 6, 'Boxes', 150.00, 'Ballpoint pens box (50pcs)', 'Paper Co', '9876543215', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(20, 'Folder', 6, 'Pieces', 20.00, 'Plastic folder', 'Paper Co', '9876543215', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(21, 'Light Bulb', 7, 'Pieces', 80.00, 'LED bulb 10W', 'Electricals', '9876543216', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(22, 'Battery', 7, 'Boxes', 400.00, 'AA batteries (12 pack)', 'Electricals', '9876543216', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(23, 'Coffee Powder', 8, 'Kg', 500.00, 'Premium instant coffee (250g)', 'Beverages Co', '9876543217', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(24, 'Tea Bags', 8, 'Boxes', 300.00, 'Tea bags box (100pcs)', 'Beverages Co', '9876543217', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(25, 'Sugar', 8, 'Kg', 60.00, 'White sugar (1kg)', 'Beverages Co', '9876543217', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(26, 'Biscuits', 8, 'Boxes', 200.00, 'Assorted biscuits box', 'Beverages Co', '9876543217', 'Active', '2026-03-08 06:24:40', '2026-03-08 06:24:40');

-- Mark Soap, Shampoo, Conditioner, Toothbrush as auto-deduct check-in items
UPDATE `inventory_items` SET `is_checkin_item` = 1, `checkin_qty_per_guest` = 1
WHERE `item_id` IN (5, 6, 7, 8);

-- --------------------------------------------------------

--
-- Table structure for table `inventory_stocks`
--

CREATE TABLE `inventory_stocks` (
  `stock_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `current_quantity` int(11) DEFAULT 0,
  `minimum_quantity` int(11) DEFAULT 10,
  `maximum_quantity` int(11) DEFAULT 100,
  `reorder_quantity` int(11) DEFAULT 50,
  `total_value` decimal(12,2) DEFAULT 0.00,
  `last_restocked` timestamp NULL DEFAULT NULL,
  `last_consumed_date` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory_stocks`
--

INSERT INTO `inventory_stocks` (`stock_id`, `item_id`, `current_quantity`, `minimum_quantity`, `maximum_quantity`, `reorder_quantity`, `total_value`, `last_restocked`, `last_consumed_date`, `created_at`, `updated_at`) VALUES
(1, 1, 50, 10, 100, 50, 7500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(2, 2, 50, 10, 100, 50, 12500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(3, 3, 50, 10, 100, 50, 4000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(4, 4, 50, 10, 100, 50, 15000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(5, 5, 50, 10, 100, 50, 1000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(6, 6, 50, 10, 100, 50, 7500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(7, 7, 50, 10, 100, 50, 7500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(8, 8, 50, 10, 100, 50, 750.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(9, 9, 50, 10, 100, 50, 10000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(10, 10, 50, 10, 100, 50, 9000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(11, 11, 50, 10, 100, 50, 5000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(12, 12, 50, 10, 100, 50, 2500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(13, 13, 50, 10, 100, 50, 15000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(14, 14, 50, 10, 100, 50, 20000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(15, 15, 50, 10, 100, 50, 12500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(16, 16, 50, 10, 100, 50, 10000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(17, 17, 50, 10, 100, 50, 9000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(18, 18, 50, 10, 100, 50, 1500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(19, 19, 50, 10, 100, 50, 7500.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(20, 20, 50, 10, 100, 50, 1000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(21, 21, 50, 10, 100, 50, 4000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(22, 22, 50, 10, 100, 50, 20000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(23, 23, 50, 10, 100, 50, 25000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(24, 24, 50, 10, 100, 50, 15000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(25, 25, 50, 10, 100, 50, 3000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(26, 26, 50, 10, 100, 50, 10000.00, NULL, NULL, '2026-03-08 06:24:40', '2026-03-08 06:24:40');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_transactions`
--

CREATE TABLE `inventory_transactions` (
  `transaction_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `transaction_type` enum('Restock','Consume','Adjustment','Damage','Expiry') NOT NULL,
  `quantity_change` int(11) NOT NULL,
  `previous_quantity` int(11) NOT NULL,
  `new_quantity` int(11) NOT NULL,
  `notes` text DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `booked_against` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `maintenance_logs`
--

CREATE TABLE `maintenance_logs` (
  `log_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `maintenance_type` enum('Plumbing','Electrical','HVAC','Furniture','Appliance','Paint','Flooring','Other') NOT NULL,
  `issue_description` text NOT NULL,
  `severity` enum('Low','Medium','High','Critical') DEFAULT 'Medium',
  `status` enum('Reported','Assigned','In Progress','Completed','On Hold') DEFAULT 'Reported',
  `assigned_to` varchar(100) DEFAULT NULL,
  `reported_by` varchar(100) DEFAULT NULL,
  `reported_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_date` datetime DEFAULT NULL,
  `cost_estimate` decimal(10,2) DEFAULT NULL,
  `actual_cost` decimal(10,2) DEFAULT NULL,
  `parts_required` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `maintenance_logs`
--

INSERT INTO `maintenance_logs` (`log_id`, `room_id`, `maintenance_type`, `issue_description`, `severity`, `status`, `assigned_to`, `reported_by`, `reported_date`, `completed_date`, `cost_estimate`, `actual_cost`, `parts_required`, `notes`, `created_at`, `updated_at`) VALUES
(1, 2, 'Plumbing', 'Bathroom sink drains slowly', 'Medium', 'Assigned', 'Ali Hassan', 'Housekeeping Staff', '2026-03-08 06:24:41', NULL, 800.00, NULL, NULL, 'Needs pipe cleaning', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(2, 4, 'Electrical', 'Bedside lamp flickering', 'High', 'In Progress', 'Imran Khan', 'Guest Complaint', '2026-03-08 06:24:41', NULL, 500.00, NULL, NULL, 'Likely loose connection', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, 3, 'HVAC', 'AC not cooling properly', 'Critical', 'Reported', 'Arun', 'Housekeeping Staff', '2026-03-08 06:24:41', NULL, 3500.00, NULL, NULL, 'Compressor may need repair', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(4, 5, 'Furniture', 'Chair has broken leg', 'Low', 'Completed', 'Lokesh', 'Inspection', '2026-03-08 06:24:41', NULL, 400.00, NULL, NULL, 'Repaired successfully', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(5, 6, 'Appliance', 'Microwave not heating', 'Medium', 'In Progress', 'Pravesh', 'Guest Request', '2026-03-08 06:24:41', NULL, 1200.00, NULL, NULL, 'Needs service check', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(6, 7, 'Paint', 'Wall has water stain marks', 'Low', 'On Hold', 'Suresh', 'Inspection', '2026-03-08 06:24:41', NULL, 600.00, NULL, NULL, 'Waiting for rainy season to end', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(7, 1, 'Flooring', 'Carpet has burn mark', 'Medium', 'Assigned', 'Mohan', 'Housekeeping Staff', '2026-03-08 06:24:41', NULL, 2500.00, NULL, NULL, 'Spot replacement needed', '2026-03-08 06:24:41', '2026-03-08 06:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `rooms`
--

CREATE TABLE `rooms` (
  `room_id` int(11) NOT NULL,
  `room_number` varchar(10) NOT NULL,
  `room_type` enum('Single','Double','Suite','Deluxe') NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `bed_count` int(11) NOT NULL DEFAULT 1,
  `max_guests` int(11) NOT NULL DEFAULT 2,
  `status` enum('Available','Booked','Maintenance') DEFAULT 'Available',
  `description` text DEFAULT NULL,
  `amenities` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `rooms`
--

INSERT INTO `rooms` (`room_id`, `room_number`, `room_type`, `price`, `bed_count`, `max_guests`, `status`, `description`, `amenities`, `created_at`, `updated_at`) VALUES
(1, '101', 'Single', 1500.00, 1, 2, 'Available', 'Cozy single room with garden view', 'WiFi, TV, AC', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(2, '102', 'Single', 1500.00, 1, 2, 'Available', 'Single room with city view', 'WiFi, TV, AC', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, '201', 'Double', 2500.00, 1, 2, 'Available', 'Spacious double room', 'WiFi, TV, AC, Mini-bar', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(4, '202', 'Double', 2500.00, 1, 2, 'Available', 'Double room with balcony', 'WiFi, TV, AC, Mini-bar', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(5, '301', 'Suite', 5000.00, 1, 2, 'Available', 'Luxury suite with separate living area', 'WiFi, TV, AC, Mini-bar, Jacuzzi', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(6, '302', 'Suite', 5000.00, 1, 2, 'Maintenance', 'Premium suite under renovation', 'WiFi, TV, AC, Mini-bar, Jacuzzi', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(7, '401', 'Deluxe', 7500.00, 1, 2, 'Available', 'Deluxe room with premium amenities', 'WiFi, TV, AC, Mini-bar, Jacuzzi, Kitchen', '2026-03-08 06:24:41', '2026-03-08 06:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `room_cleaning_status`
--

CREATE TABLE `room_cleaning_status` (
  `status_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `cleaning_status` enum('Clean','Dirty','In Progress','Inspection','Out of Service') DEFAULT 'Clean',
  `last_cleaned_by` int(11) DEFAULT NULL,
  `last_cleaned_date` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `room_cleaning_status`
--

INSERT INTO `room_cleaning_status` (`status_id`, `room_id`, `cleaning_status`, `last_cleaned_by`, `last_cleaned_date`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 'Clean', NULL, '2026-03-08 12:24:41', 'Initial setup', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(2, 2, 'Clean', NULL, '2026-03-08 12:24:41', 'Initial setup', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, 3, 'Clean', NULL, '2026-03-08 12:24:41', 'Initial setup', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(4, 4, 'Clean', NULL, '2026-03-08 12:24:41', 'Initial setup', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(5, 5, 'Clean', NULL, '2026-03-08 12:24:41', 'Initial setup', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(6, 6, 'Clean', NULL, '2026-03-08 12:24:41', 'Initial setup', '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(7, 7, 'Clean', NULL, '2026-03-08 12:24:41', 'Initial setup', '2026-03-08 06:24:41', '2026-03-08 06:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `service_id` int(11) NOT NULL,
  `service_name` varchar(100) NOT NULL,
  `category` enum('Food','Beverage','Laundry','Spa','Transport','Housekeeping','Other') NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `availability` enum('Available','Unavailable') DEFAULT 'Available',
  `image_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`service_id`, `service_name`, `category`, `description`, `price`, `availability`, `image_url`, `created_at`, `updated_at`) VALUES
(1, 'Breakfast Buffet', 'Food', 'Continental breakfast with variety of options', 500.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(2, 'Chicken Curry with Rice', 'Food', 'Traditional chicken curry served with basmati rice', 350.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, 'Vegetable Biryani', 'Food', 'Aromatic vegetable biryani with raita', 300.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(4, 'Club Sandwich', 'Food', 'Classic club sandwich with fries', 250.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(5, 'Margherita Pizza', 'Food', 'Fresh mozzarella and basil pizza', 400.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(6, 'Caesar Salad', 'Food', 'Crispy romaine lettuce with Caesar dressing', 200.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(7, 'Fresh Juice', 'Beverage', 'Freshly squeezed orange or apple juice', 120.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(8, 'Coffee', 'Beverage', 'Hot coffee (espresso, cappuccino, latte)', 100.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(9, 'Tea', 'Beverage', 'Selection of premium teas', 80.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(10, 'Soft Drinks', 'Beverage', 'Assorted soft drinks', 60.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(11, 'Mineral Water', 'Beverage', 'Premium mineral water', 40.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(12, 'Laundry Service', 'Laundry', 'Wash and iron per kg', 150.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(13, 'Express Laundry', 'Laundry', 'Same day laundry service per kg', 250.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(14, 'Dry Cleaning', 'Laundry', 'Professional dry cleaning per item', 200.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(15, 'Full Body Massage', 'Spa', '60-minute relaxing full body massage', 2000.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(16, 'Facial Treatment', 'Spa', 'Rejuvenating facial treatment', 1500.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(17, 'Aromatherapy', 'Spa', '45-minute aromatherapy session', 1200.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(18, 'Airport Pickup', 'Transport', 'One-way airport transfer', 800.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(19, 'City Tour', 'Transport', 'Half-day city sightseeing tour', 2500.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(20, 'Car Rental', 'Transport', 'Car rental per day with driver', 3000.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(21, 'Extra Towels', 'Housekeeping', 'Additional towel set', 100.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(22, 'Extra Bedding', 'Housekeeping', 'Extra blankets and pillows', 150.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(23, 'Room Cleaning', 'Housekeeping', 'Additional room cleaning service', 200.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(24, 'Newspaper', 'Other', 'Daily newspaper delivery', 30.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(25, 'Iron & Board', 'Other', 'Iron and ironing board rental', 50.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(26, 'Baby Cot', 'Other', 'Baby cot rental per day', 200.00, 'Available', NULL, '2026-03-08 06:24:41', '2026-03-08 06:24:41');

-- --------------------------------------------------------

--
-- Table structure for table `service_orders`
--

CREATE TABLE `service_orders` (
  `order_id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `service_id` int(11) NOT NULL,
  `quantity` int(11) DEFAULT 1,
  `unit_price` decimal(10,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `order_status` enum('Pending','InProgress','Completed','Invoiced','Cancelled') DEFAULT 'Pending',
  `special_instructions` text DEFAULT NULL,
  `ordered_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `service_order_details`
-- (See below for the actual view)
--
CREATE TABLE `service_order_details` (
`order_id` int(11)
,`quantity` int(11)
,`unit_price` decimal(10,2)
,`total_price` decimal(10,2)
,`order_status` enum('Pending','InProgress','Completed','Cancelled')
,`special_instructions` text
,`ordered_at` timestamp
,`completed_at` timestamp
,`service_name` varchar(100)
,`category` enum('Food','Beverage','Laundry','Spa','Transport','Housekeeping','Other')
,`booking_id` int(11)
,`guest_name` varchar(100)
,`guest_phone` varchar(15)
,`room_number` varchar(10)
);

-- --------------------------------------------------------

--
-- Structure for view `booking_details`
--
DROP TABLE IF EXISTS `booking_details`;

CREATE OR REPLACE VIEW `booking_details` AS
SELECT
  `b`.`booking_id`            AS `booking_id`,
  `b`.`guest_id`              AS `guest_id`,
  `b`.`room_id`               AS `room_id`,
  `b`.`check_in`              AS `check_in`,
  `b`.`check_out`             AS `check_out`,
  `b`.`number_of_guests`      AS `number_of_guests`,
  `b`.`number_of_nights`      AS `number_of_nights`,
  `b`.`room_price`            AS `room_price`,
  `b`.`total_amount`          AS `total_amount`,
  `b`.`advance_payment`       AS `advance_payment`,
  `b`.`payment_status`        AS `payment_status`,
  `b`.`payment_method`        AS `payment_method`,
  `b`.`discount_type`         AS `discount_type`,
  `b`.`discount_value`        AS `discount_value`,
  `b`.`discount_reason`       AS `discount_reason`,
  `b`.`booking_source`        AS `booking_source`,
  `b`.`booking_status`        AS `booking_status`,
  `b`.`special_requests`      AS `special_requests`,
  `b`.`cancellation_reason`   AS `cancellation_reason`,
  `b`.`actual_checkin_time`   AS `actual_checkin_time`,
  `b`.`actual_checkout_time`  AS `actual_checkout_time`,
  `b`.`checkout_type`         AS `checkout_type`,
  `b`.`is_early_checkout`     AS `is_early_checkout`,
  `b`.`late_checkout_fee`     AS `late_checkout_fee`,
  `b`.`early_checkout_reason` AS `early_checkout_reason`,
  `b`.`is_extension`          AS `is_extension`,
  `b`.`parent_booking_id`     AS `parent_booking_id`,
  `b`.`booking_group_id`      AS `booking_group_id`,
  `b`.`created_at`            AS `created_at`,
  `b`.`updated_at`            AS `updated_at`,
  `g`.`name`                  AS `guest_name`,
  `g`.`phone`                 AS `guest_phone`,
  `g`.`email`                 AS `guest_email`,
  `r`.`room_number`           AS `room_number`,
  `r`.`room_type`             AS `room_type`,
  `r`.`price`                 AS `current_room_price`
FROM ((`bookings` `b`
  JOIN `guests` `g` ON (`b`.`guest_id` = `g`.`guest_id`))
  JOIN `rooms` `r`  ON (`b`.`room_id`  = `r`.`room_id`));

-- --------------------------------------------------------

--
-- Structure for view `booking_details_enhanced`
-- (Full booking view including cancellation_reason — used by Booking.getAll() and Booking.getById())
--
DROP TABLE IF EXISTS `booking_details_enhanced`;

CREATE OR REPLACE VIEW `booking_details_enhanced` AS
SELECT
  `b`.`booking_id`            AS `booking_id`,
  `b`.`guest_id`              AS `guest_id`,
  `b`.`room_id`               AS `room_id`,
  `b`.`check_in`              AS `check_in`,
  `b`.`check_out`             AS `check_out`,
  `b`.`number_of_guests`      AS `number_of_guests`,
  `b`.`number_of_nights`      AS `number_of_nights`,
  `b`.`room_price`            AS `room_price`,
  `b`.`total_amount`          AS `total_amount`,
  `b`.`advance_payment`       AS `advance_payment`,
  `b`.`payment_status`        AS `payment_status`,
  `b`.`payment_method`        AS `payment_method`,
  `b`.`discount_type`         AS `discount_type`,
  `b`.`discount_value`        AS `discount_value`,
  `b`.`discount_reason`       AS `discount_reason`,
  `b`.`booking_source`        AS `booking_source`,
  `b`.`booking_status`        AS `booking_status`,
  `b`.`special_requests`      AS `special_requests`,
  `b`.`cancellation_reason`   AS `cancellation_reason`,
  `b`.`actual_checkin_time`   AS `actual_checkin_time`,
  `b`.`actual_checkout_time`  AS `actual_checkout_time`,
  `b`.`checkout_type`         AS `checkout_type`,
  `b`.`is_early_checkout`     AS `is_early_checkout`,
  `b`.`late_checkout_fee`     AS `late_checkout_fee`,
  `b`.`early_checkout_reason` AS `early_checkout_reason`,
  `b`.`is_extension`          AS `is_extension`,
  `b`.`parent_booking_id`     AS `parent_booking_id`,
  `b`.`booking_group_id`      AS `booking_group_id`,
  `b`.`created_at`            AS `created_at`,
  `b`.`updated_at`            AS `updated_at`,
  `g`.`name`                  AS `guest_name`,
  `g`.`phone`                 AS `guest_phone`,
  `g`.`email`                 AS `guest_email`,
  `r`.`room_number`           AS `room_number`,
  `r`.`room_type`             AS `room_type`,
  `r`.`price`                 AS `current_room_price`
FROM ((`bookings` `b`
  JOIN `guests` `g` ON (`b`.`guest_id` = `g`.`guest_id`))
  JOIN `rooms` `r`  ON (`b`.`room_id`  = `r`.`room_id`));

-- --------------------------------------------------------

--
-- Structure for view `service_order_details`
--
DROP TABLE IF EXISTS `service_order_details`;

CREATE OR REPLACE VIEW `service_order_details`  AS SELECT `so`.`order_id` AS `order_id`, `so`.`quantity` AS `quantity`, `so`.`unit_price` AS `unit_price`, `so`.`total_price` AS `total_price`, `so`.`order_status` AS `order_status`, `so`.`special_instructions` AS `special_instructions`, `so`.`ordered_at` AS `ordered_at`, `so`.`completed_at` AS `completed_at`, `s`.`service_name` AS `service_name`, `s`.`category` AS `category`, `b`.`booking_id` AS `booking_id`, `g`.`name` AS `guest_name`, `g`.`phone` AS `guest_phone`, `r`.`room_number` AS `room_number` FROM ((((`service_orders` `so` join `services` `s` on(`so`.`service_id` = `s`.`service_id`)) join `bookings` `b` on(`so`.`booking_id` = `b`.`booking_id`)) join `guests` `g` on(`b`.`guest_id` = `g`.`guest_id`)) join `rooms` `r` on(`b`.`room_id` = `r`.`room_id`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `bookings`
--
ALTER TABLE `bookings`
  ADD PRIMARY KEY (`booking_id`),
  ADD KEY `room_id` (`room_id`),
  ADD KEY `idx_status` (`booking_status`),
  ADD KEY `idx_check_in` (`check_in`),
  ADD KEY `idx_check_out` (`check_out`),
  ADD KEY `idx_guest` (`guest_id`);

--
-- Indexes for table `cleaning_tasks`
--
ALTER TABLE `cleaning_tasks`
  ADD PRIMARY KEY (`task_id`),
  ADD KEY `assigned_by` (`assigned_by`),
  ADD KEY `idx_room` (`room_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_date` (`scheduled_date`),
  ADD KEY `idx_staff` (`staff_id`);

--
-- Indexes for table `guests`
--
ALTER TABLE `guests`
  ADD PRIMARY KEY (`guest_id`);

--
-- Indexes for table `hotel_users`
--
ALTER TABLE `hotel_users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_hotel_users_username` (`username`),
  ADD KEY `idx_hotel_users_role` (`role`),
  ADD KEY `idx_hotel_users_active` (`is_active`);

--
-- Indexes for table `guest_sessions`
--
ALTER TABLE `guest_sessions`
  ADD PRIMARY KEY (`session_id`),
  ADD UNIQUE KEY `booking_id` (`booking_id`),
  ADD UNIQUE KEY `access_token` (`access_token`),
  ADD KEY `guest_id` (`guest_id`),
  ADD KEY `idx_token` (`access_token`),
  ADD KEY `idx_pin` (`token_pin`),
  ADD KEY `idx_booking` (`booking_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_is_read` (`is_read`),
  ADD KEY `idx_type` (`type`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_priority` (`priority`);

--
-- Indexes for table `housekeeping_staff`
--
ALTER TABLE `housekeeping_staff`
  ADD PRIMARY KEY (`staff_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_role` (`role`);

--
-- Indexes for table `inventory_categories`
--
ALTER TABLE `inventory_categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `category_name` (`category_name`);

--
-- Indexes for table `inventory_items`
--
ALTER TABLE `inventory_items`
  ADD PRIMARY KEY (`item_id`),
  ADD KEY `idx_category` (`category_id`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `inventory_stocks`
--
ALTER TABLE `inventory_stocks`
  ADD PRIMARY KEY (`stock_id`),
  ADD UNIQUE KEY `item_id` (`item_id`),
  ADD KEY `idx_low_stock` (`current_quantity`),
  ADD KEY `idx_last_restocked` (`last_restocked`);

--
-- Indexes for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `booked_against` (`booked_against`),
  ADD KEY `idx_item` (`item_id`),
  ADD KEY `idx_type` (`transaction_type`),
  ADD KEY `idx_date` (`created_at`);

--
-- Indexes for table `maintenance_logs`
--
ALTER TABLE `maintenance_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_room` (`room_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_type` (`maintenance_type`),
  ADD KEY `idx_severity` (`severity`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`room_id`),
  ADD UNIQUE KEY `room_number` (`room_number`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_room_type` (`room_type`);

--
-- Indexes for table `room_cleaning_status`
--
ALTER TABLE `room_cleaning_status`
  ADD PRIMARY KEY (`status_id`),
  ADD UNIQUE KEY `room_id` (`room_id`),
  ADD KEY `idx_room` (`room_id`),
  ADD KEY `idx_status` (`cleaning_status`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`service_id`);

--
-- Indexes for table `service_orders`
--
ALTER TABLE `service_orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `service_id` (`service_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `booking_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cleaning_tasks`
--
ALTER TABLE `cleaning_tasks`
  MODIFY `task_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `guests`
--
ALTER TABLE `guests`
  MODIFY `guest_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `hotel_users`
--
ALTER TABLE `hotel_users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guest_sessions`
--
ALTER TABLE `guest_sessions`
  MODIFY `session_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `housekeeping_staff`
--
ALTER TABLE `housekeeping_staff`
  MODIFY `staff_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `inventory_categories`
--
ALTER TABLE `inventory_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `inventory_items`
--
ALTER TABLE `inventory_items`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `inventory_stocks`
--
ALTER TABLE `inventory_stocks`
  MODIFY `stock_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `maintenance_logs`
--
ALTER TABLE `maintenance_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `room_cleaning_status`
--
ALTER TABLE `room_cleaning_status`
  MODIFY `status_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `service_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT for table `service_orders`
--
ALTER TABLE `service_orders`
  MODIFY `order_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookings`
--
ALTER TABLE `bookings`
  ADD CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;

--
-- Constraints for table `cleaning_tasks`
--
ALTER TABLE `cleaning_tasks`
  ADD CONSTRAINT `cleaning_tasks_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cleaning_tasks_ibfk_2` FOREIGN KEY (`staff_id`) REFERENCES `housekeeping_staff` (`staff_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `cleaning_tasks_ibfk_3` FOREIGN KEY (`assigned_by`) REFERENCES `housekeeping_staff` (`staff_id`) ON DELETE SET NULL;

--
-- Constraints for table `guest_sessions`
--
ALTER TABLE `guest_sessions`
  ADD CONSTRAINT `guest_sessions_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guest_sessions_ibfk_2` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE;

--
-- Constraints for table `inventory_items`
--
ALTER TABLE `inventory_items`
  ADD CONSTRAINT `inventory_items_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `inventory_categories` (`category_id`) ON DELETE CASCADE;

--
-- Constraints for table `inventory_stocks`
--
ALTER TABLE `inventory_stocks`
  ADD CONSTRAINT `inventory_stocks_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`item_id`) ON DELETE CASCADE;

--
-- Constraints for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  ADD CONSTRAINT `inventory_transactions_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`item_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inventory_transactions_ibfk_2` FOREIGN KEY (`booked_against`) REFERENCES `bookings` (`booking_id`) ON DELETE SET NULL;

--
-- Constraints for table `maintenance_logs`
--
ALTER TABLE `maintenance_logs`
  ADD CONSTRAINT `maintenance_logs_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;

--
-- Constraints for table `room_cleaning_status`
--
ALTER TABLE `room_cleaning_status`
  ADD CONSTRAINT `room_cleaning_status_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;

--
-- Table structure for table `invoices`
--
CREATE TABLE `invoices` (
  `invoice_id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL,
  `invoice_number` varchar(50) NOT NULL,
  `guest_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `tax_amount` decimal(10,2) DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL,
  `amount_paid` decimal(10,2) DEFAULT 0.00,
  `amount_due` decimal(10,2) DEFAULT 0.00,
  `invoice_date` date NOT NULL,
  `due_date` date DEFAULT NULL,
  `payment_status` enum('Pending','Partial','Paid','Overdue','Cancelled') DEFAULT 'Pending',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`invoice_id`),
  UNIQUE KEY `invoice_number` (`invoice_number`),
  KEY `idx_booking_id` (`booking_id`),
  KEY `idx_guest_id` (`guest_id`),
  KEY `idx_payment_status` (`payment_status`),
  KEY `idx_invoice_date` (`invoice_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Table structure for table `invoice_items`
--
CREATE TABLE `invoice_items` (
  `item_id` int(11) NOT NULL AUTO_INCREMENT,
  `invoice_id` int(11) NOT NULL,
  `description` varchar(255) NOT NULL,
  `item_type` varchar(50) DEFAULT NULL,
  `quantity` decimal(10,2) DEFAULT 1.00,
  `unit_price` decimal(10,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`item_id`),
  FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`invoice_id`) ON DELETE CASCADE,
  KEY `idx_invoice_id` (`invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Table structure for table `billing_settings`
--
CREATE TABLE `billing_settings` (
  `setting_id` int(11) NOT NULL AUTO_INCREMENT,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`setting_id`),
  UNIQUE KEY `setting_key` (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `billing_settings`
--
INSERT INTO `billing_settings` (`setting_key`, `setting_value`, `description`) VALUES
('company_address', 'Address', 'Company address for invoices'),
('company_email', 'email@company.com', 'Company email for invoices'),
('company_name', 'Hotel Management System', 'Company name for invoices'),
('company_phone', 'Phone', 'Company phone for invoices'),
('due_days', '7', 'Payment due days from invoice date'),
('invoice_prefix', 'INV', 'Invoice number prefix'),
('tax_rate', '18', 'Default tax rate percentage');

--
-- Table structure for table `payments`
--
CREATE TABLE `payments` (
  `payment_id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `guest_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` enum('Cash','Card','UPI','Online','Cheque') DEFAULT 'Cash',
  `payment_type` enum('Advance','Payment','Adjustment') DEFAULT 'Payment',
  `payment_status` enum('Pending','Completed','Failed','Cancelled') DEFAULT 'Pending',
  `transaction_id` varchar(100) DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`payment_id`),
  KEY `booking_id`     (`booking_id`),
  KEY `guest_id`       (`guest_id`),
  KEY `payment_status` (`payment_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `refunds`
--
CREATE TABLE `refunds` (
  `refund_id` int(11) NOT NULL AUTO_INCREMENT,
  `payment_id` int(11) DEFAULT NULL,
  `invoice_id` int(11) DEFAULT NULL,
  `booking_id` int(11) NOT NULL,
  `guest_id` int(11) NOT NULL,
  `refund_number` varchar(50) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `refund_status` enum('Pending','Approved','Processed','Rejected') DEFAULT 'Pending',
  `refund_method` enum('Original','Account','Cheque') DEFAULT 'Original',
  `processed_date` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `approved_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`refund_id`),
  KEY `payment_id`             (`payment_id`),
  KEY `booking_id`             (`booking_id`),
  KEY `guest_id`               (`guest_id`),
  KEY `refund_status`          (`refund_status`),
  KEY `idx_refunds_invoice_id` (`invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `financial_management`
--
CREATE TABLE `financial_management` (
  `financial_id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL,
  `revenue_type` enum('Room','Service','Other') DEFAULT 'Room',
  `amount` decimal(10,2) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `transaction_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`financial_id`),
  KEY `idx_booking_id`       (`booking_id`),
  KEY `idx_transaction_date` (`transaction_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `hotel_policies`
--
CREATE TABLE `hotel_policies` (
  `policy_id` int(11) NOT NULL AUTO_INCREMENT,
  `policy_name` varchar(100) NOT NULL,
  `policy_value` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `uq_policy_name` (`policy_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Seed data for table `hotel_policies`
--
INSERT INTO `hotel_policies` (`policy_name`, `policy_value`, `description`) VALUES
('late_checkout_fee_percent', '20',  'Percentage of nightly rate charged for late checkout'),
('early_checkout_penalty',    '10',  'Percentage of unused nights refund withheld as penalty'),
('cancellation_hours',        '24',  'Hours before check-in for penalty-free cancellation'),
('max_extension_nights',      '30',  'Maximum number of nights a stay can be extended')
ON DUPLICATE KEY UPDATE policy_value = VALUES(policy_value);

-- --------------------------------------------------------

--
-- Table structure for table `staff_salaries`
--
CREATE TABLE `staff_salaries` (
  `salary_id` int(11) NOT NULL AUTO_INCREMENT,
  `staff_id` int(11) NOT NULL,
  `payment_month` varchar(7) NOT NULL COMMENT 'YYYY-MM',
  `base_salary` decimal(10,2) NOT NULL,
  `bonus` decimal(10,2) DEFAULT 0.00,
  `deductions` decimal(10,2) DEFAULT 0.00,
  `overtime_hours` decimal(5,2) DEFAULT 0.00,
  `overtime_amount` decimal(10,2) DEFAULT 0.00,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_date` date NOT NULL,
  `payment_method` enum('Cash','Bank Transfer','Cheque','UPI') DEFAULT 'Bank Transfer',
  `payment_reference` varchar(100) DEFAULT NULL,
  `payment_status` enum('Pending','Partially Paid','Paid','Cancelled') DEFAULT 'Pending',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`salary_id`),
  KEY `idx_staff_id`       (`staff_id`),
  KEY `idx_payment_month`  (`payment_month`),
  KEY `idx_payment_status` (`payment_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `salary_payment_transactions`
--
CREATE TABLE `salary_payment_transactions` (
  `transaction_id` int(11) NOT NULL AUTO_INCREMENT,
  `salary_id` int(11) NOT NULL,
  `staff_id` int(11) NOT NULL,
  `payment_month` varchar(7) NOT NULL COMMENT 'YYYY-MM',
  `transaction_type` enum('Advance','Final','Adjustment') DEFAULT 'Advance',
  `amount` decimal(10,2) NOT NULL,
  `payment_date` date NOT NULL,
  `payment_method` enum('Cash','Bank Transfer','Cheque','UPI') DEFAULT 'Bank Transfer',
  `payment_reference` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`transaction_id`),
  KEY `idx_salary_id` (`salary_id`),
  KEY `idx_staff_id` (`staff_id`),
  KEY `idx_payment_month` (`payment_month`),
  KEY `idx_payment_date` (`payment_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `expense_records`
--
CREATE TABLE `expense_records` (
  `expense_id` int(11) NOT NULL AUTO_INCREMENT,
  `expense_type` enum('Salary','Maintenance','Inventory','Utilities','Marketing','Rent','Other') DEFAULT 'Other',
  `description` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `expense_date` date NOT NULL,
  `payment_method` enum('Cash','Bank Transfer','Cheque','UPI','Card') DEFAULT 'Bank Transfer',
  `vendor_name` varchar(100) DEFAULT NULL,
  `invoice_number` varchar(50) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `staff_id` int(11) DEFAULT NULL,
  `maintenance_log_id` int(11) DEFAULT NULL,
  `inventory_item_id` int(11) DEFAULT NULL,
  `payment_status` enum('Pending','Paid','Cancelled') DEFAULT 'Pending',
  `approved_by` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`expense_id`),
  KEY `idx_expense_date`   (`expense_date`),
  KEY `idx_expense_type`   (`expense_type`),
  KEY `idx_payment_status` (`payment_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `income_records`
--
CREATE TABLE `income_records` (
  `income_id` int(11) NOT NULL AUTO_INCREMENT,
  `income_type` enum('Room Booking','Service','Restaurant','Laundry','Other') DEFAULT 'Other',
  `description` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `income_date` date NOT NULL,
  `payment_method` enum('Cash','Card','UPI','Online','Bank Transfer') DEFAULT 'Cash',
  `booking_id` int(11) DEFAULT NULL,
  `service_order_id` int(11) DEFAULT NULL,
  `invoice_number` varchar(50) DEFAULT NULL,
  `guest_name` varchar(100) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`income_id`),
  KEY `idx_income_date` (`income_date`),
  KEY `idx_income_type` (`income_type`),
  KEY `idx_booking_id`  (`booking_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure for view `payment_summary`
--
CREATE OR REPLACE VIEW `payment_summary` AS
SELECT
  `p`.`payment_id`       AS `payment_id`,
  `p`.`booking_id`       AS `booking_id`,
  `p`.`invoice_id`       AS `invoice_id`,
  `p`.`guest_id`         AS `guest_id`,
  `p`.`amount`           AS `amount`,
  `p`.`payment_method`   AS `payment_method`,
  `p`.`payment_status`   AS `payment_status`,
  `p`.`transaction_id`   AS `transaction_id`,
  `p`.`reference_number` AS `reference_number`,
  `p`.`notes`            AS `notes`,
  `p`.`created_at`       AS `created_at`,
  `p`.`updated_at`       AS `updated_at`,
  `g`.`name`             AS `guest_name`,
  `g`.`email`            AS `guest_email`,
  `b`.`check_in`         AS `check_in`,
  `b`.`check_out`        AS `check_out`,
  `r`.`room_number`      AS `room_number`
FROM (((`payments` `p`
  LEFT JOIN `guests`   `g` ON (`p`.`guest_id`   = `g`.`guest_id`))
  LEFT JOIN `bookings` `b` ON (`p`.`booking_id` = `b`.`booking_id`))
  LEFT JOIN `rooms`    `r` ON (`b`.`room_id`    = `r`.`room_id`));

--
-- Constraints for table `invoices`
-- (room_id FK missing from original dump — added here)
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `invoices_ibfk_2` FOREIGN KEY (`guest_id`)   REFERENCES `guests`   (`guest_id`)   ON DELETE CASCADE,
  ADD CONSTRAINT `invoices_ibfk_3` FOREIGN KEY (`room_id`)    REFERENCES `rooms`    (`room_id`)    ON DELETE CASCADE;

--
-- Constraints for table `service_orders`
--
ALTER TABLE `service_orders`
  ADD CONSTRAINT `service_orders_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings`  (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `service_orders_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `services`  (`service_id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`guest_id`)   REFERENCES `guests`   (`guest_id`)   ON DELETE CASCADE;

--
-- Constraints for table `refunds`
--
ALTER TABLE `refunds`
  ADD CONSTRAINT `refunds_ibfk_1` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`payment_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `refunds_ibfk_2` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `refunds_ibfk_3` FOREIGN KEY (`guest_id`)   REFERENCES `guests`   (`guest_id`)   ON DELETE CASCADE;

--
-- Constraints for table `financial_management`
--
ALTER TABLE `financial_management`
  ADD CONSTRAINT `financial_management_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE;

--
-- Constraints for table `staff_salaries`
--
ALTER TABLE `staff_salaries`
  ADD CONSTRAINT `fk_salary_staff` FOREIGN KEY (`staff_id`) REFERENCES `housekeeping_staff` (`staff_id`) ON DELETE CASCADE;

--
-- Additional billing_settings entries (idempotent)
--
INSERT INTO `billing_settings` (`setting_key`, `setting_value`, `description`) VALUES
('currency_symbol', '₹',    'Currency symbol for billing'),
('check_in_time',   '12:00','Standard check-in time'),
('check_out_time',  '11:00','Standard check-out time')
ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value);

-- ============================================================
-- ROOM ASSET MANAGEMENT TABLES
-- ============================================================

-- --------------------------------------------------------
--
-- Table structure for table `asset_categories`
--
CREATE TABLE `asset_categories` (
  `category_id` int(11) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `uq_category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Seed data for table `asset_categories`
--
INSERT INTO `asset_categories` (`category_name`, `description`) VALUES
('TV & Electronics', 'Television, remote controls, set-top boxes, radios'),
('Furniture', 'Beds, chairs, tables, wardrobes, sofas'),
('Bathroom Fixtures', 'Towel rails, shower heads, taps, toilet accessories'),
('Appliances', 'Air conditioners, refrigerators, microwaves, kettles'),
('Lighting', 'Ceiling lights, bedside lamps, bathroom lights'),
('Bedding & Linen', 'Mattresses, pillows, duvets, bedsheets'),
('Safety Equipment', 'Fire extinguishers, smoke detectors, first aid kits'),
('Kitchen Items', 'Cups, glasses, plates, cutlery, coffee makers');

-- --------------------------------------------------------
--
-- Table structure for table `room_assets`
-- (Asset catalogue — defines what should be in each room type)
--
CREATE TABLE `room_assets` (
  `asset_id` int(11) NOT NULL AUTO_INCREMENT,
  `asset_name` varchar(100) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `quantity_per_room` int(11) NOT NULL DEFAULT 1,
  `room_type` enum('Single','Double','Suite','Deluxe') DEFAULT NULL COMMENT 'NULL = applies to all room types',
  `is_critical` tinyint(1) DEFAULT 0,
  `estimated_value` decimal(10,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`asset_id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_room_type` (`room_type`),
  CONSTRAINT `room_assets_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `asset_categories` (`category_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
--
-- Table structure for table `room_asset_instances`
-- (Actual physical asset items tracked per room)
--
CREATE TABLE `room_asset_instances` (
  `instance_id` int(11) NOT NULL AUTO_INCREMENT,
  `room_id` int(11) NOT NULL,
  `asset_name` varchar(100) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `serial_number` varchar(100) DEFAULT NULL,
  `barcode` varchar(100) DEFAULT NULL,
  `purchase_date` date DEFAULT NULL,
  `purchase_cost` decimal(10,2) DEFAULT 0.00,
  `current_condition` enum('New','Good','Fair','Poor','Damaged') DEFAULT 'Good',
  `is_functional` tinyint(1) DEFAULT 1,
  `last_maintenance_date` date DEFAULT NULL,
  `next_maintenance_date` date DEFAULT NULL,
  `warranty_expiry` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`instance_id`),
  KEY `idx_room_id` (`room_id`),
  KEY `idx_category_id` (`category_id`),
  KEY `idx_condition` (`current_condition`),
  CONSTRAINT `room_asset_instances_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE,
  CONSTRAINT `room_asset_instances_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `asset_categories` (`category_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
--
-- Table structure for table `room_asset_history`
-- (Audit log — every change to a room asset instance)
--
CREATE TABLE `room_asset_history` (
  `history_id` int(11) NOT NULL AUTO_INCREMENT,
  `instance_id` int(11) NOT NULL,
  `room_id` int(11) DEFAULT NULL,
  `action_type` enum('Added','Removed','Moved','Condition Changed','Maintenance','Inspected') NOT NULL,
  `previous_room_id` int(11) DEFAULT NULL,
  `previous_condition` varchar(50) DEFAULT NULL,
  `new_condition` varchar(50) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `performed_by` varchar(100) DEFAULT NULL,
  `performed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`history_id`),
  KEY `idx_instance_id` (`instance_id`),
  KEY `idx_room_id` (`room_id`),
  KEY `idx_performed_at` (`performed_at`),
  CONSTRAINT `room_asset_history_ibfk_1` FOREIGN KEY (`instance_id`) REFERENCES `room_asset_instances` (`instance_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ============================================================
-- ROOM INSPECTION TABLES
-- ============================================================

-- --------------------------------------------------------
--
-- Table structure for table `room_inspections`
--
CREATE TABLE `room_inspections` (
  `inspection_id` int(11) NOT NULL AUTO_INCREMENT,
  `booking_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `inspector_name` varchar(100) DEFAULT NULL,
  `general_notes` text DEFAULT NULL,
  `overall_status` enum('Pass','Fail','Missing Items','Damaged Items','Issues Found') DEFAULT 'Pass',
  `inspection_completed` tinyint(1) DEFAULT 0,
  `inspection_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`inspection_id`),
  KEY `idx_booking_id` (`booking_id`),
  KEY `idx_room_id` (`room_id`),
  KEY `idx_status` (`overall_status`),
  KEY `idx_date` (`inspection_date`),
  CONSTRAINT `room_inspections_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  CONSTRAINT `room_inspections_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
--
-- Table structure for table `inspection_items`
-- (Individual asset check results within an inspection)
--
CREATE TABLE `inspection_items` (
  `inspection_item_id` int(11) NOT NULL AUTO_INCREMENT,
  `inspection_id` int(11) NOT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `status` enum('Present','Missing','Damaged','Needs Replacement','Extra') DEFAULT 'Present',
  `quantity_expected` int(11) DEFAULT 1,
  `quantity_found` int(11) DEFAULT 1,
  `condition_notes` text DEFAULT NULL,
  `damage_cost` decimal(10,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`inspection_item_id`),
  KEY `idx_inspection_id` (`inspection_id`),
  KEY `idx_asset_id` (`asset_id`),
  CONSTRAINT `inspection_items_ibfk_1` FOREIGN KEY (`inspection_id`) REFERENCES `room_inspections` (`inspection_id`) ON DELETE CASCADE,
  CONSTRAINT `inspection_items_ibfk_2` FOREIGN KEY (`asset_id`) REFERENCES `room_assets` (`asset_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------
--
-- Table structure for table `asset_charges`
-- (Charges billed to guests for missing/damaged assets found at inspection)
--
CREATE TABLE `asset_charges` (
  `charge_id` int(11) NOT NULL AUTO_INCREMENT,
  `inspection_item_id` int(11) DEFAULT NULL,
  `booking_id` int(11) NOT NULL,
  `guest_id` int(11) NOT NULL,
  `asset_name` varchar(100) NOT NULL,
  `charge_amount` decimal(10,2) NOT NULL,
  `charge_type` enum('Missing','Damaged','Replacement') DEFAULT 'Damaged',
  `payment_status` enum('Pending','Paid','Waived') DEFAULT 'Pending',
  `notes` text DEFAULT NULL,
  `charged_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL,
  PRIMARY KEY (`charge_id`),
  KEY `idx_booking_id` (`booking_id`),
  KEY `idx_guest_id` (`guest_id`),
  KEY `idx_payment_status` (`payment_status`),
  CONSTRAINT `asset_charges_ibfk_1` FOREIGN KEY (`inspection_item_id`) REFERENCES `inspection_items` (`inspection_item_id`) ON DELETE SET NULL,
  CONSTRAINT `asset_charges_ibfk_2` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  CONSTRAINT `asset_charges_ibfk_3` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ============================================================
-- VIEWS FOR ROOM ASSETS & INSPECTIONS
-- ============================================================

--
-- View: `v_room_asset_inventory`
-- Full per-room asset list, used by RoomAssetInstance.getAll() / search() / getNeedingMaintenance()
--
CREATE OR REPLACE VIEW `v_room_asset_inventory` AS
SELECT
  rai.instance_id,
  rai.room_id,
  rai.asset_name,
  rai.category_id,
  rai.description,
  rai.serial_number,
  rai.barcode,
  rai.purchase_date,
  rai.purchase_cost,
  rai.current_condition,
  rai.is_functional,
  rai.last_maintenance_date,
  rai.next_maintenance_date,
  rai.warranty_expiry,
  rai.notes,
  rai.created_by,
  rai.created_at,
  rai.updated_at,
  ac.category_name,
  r.room_number,
  r.room_type
FROM `room_asset_instances` rai
LEFT JOIN `asset_categories` ac ON rai.category_id = ac.category_id
LEFT JOIN `rooms` r ON rai.room_id = r.room_id;

--
-- View: `v_room_asset_summary`
-- Aggregate asset stats per room, used by RoomAssetInstance.getRoomSummary() / getAllRoomSummaries()
--
CREATE OR REPLACE VIEW `v_room_asset_summary` AS
SELECT
  r.room_id,
  r.room_number,
  r.room_type,
  COUNT(rai.instance_id)                                                     AS total_assets,
  SUM(CASE WHEN rai.is_functional = 1 THEN 1 ELSE 0 END)                    AS functional_count,
  SUM(CASE WHEN rai.is_functional = 0 THEN 1 ELSE 0 END)                    AS non_functional_count,
  SUM(CASE WHEN rai.next_maintenance_date IS NOT NULL
           AND rai.next_maintenance_date <= CURDATE() THEN 1 ELSE 0 END)    AS needs_maintenance_count,
  COALESCE(SUM(rai.purchase_cost), 0)                                        AS total_value
FROM `rooms` r
LEFT JOIN `room_asset_instances` rai ON r.room_id = rai.room_id
GROUP BY r.room_id, r.room_number, r.room_type;

--
-- View: `room_inspection_checklist`
-- Per-room asset checklist derived from room_assets catalogue,
-- used by RoomAsset.getInspectionChecklist(roomId)
--
CREATE OR REPLACE VIEW `room_inspection_checklist` AS
SELECT
  r.room_id,
  r.room_number,
  r.room_type,
  ra.asset_id,
  ra.asset_name,
  ac.category_name,
  ra.quantity_per_room,
  ra.is_critical,
  ra.estimated_value
FROM `rooms` r
JOIN `room_assets` ra ON (ra.room_type IS NULL OR ra.room_type = r.room_type)
LEFT JOIN `asset_categories` ac ON ra.category_id = ac.category_id
ORDER BY r.room_id, ac.category_name, ra.asset_name;

--
-- View: `inspection_summary`
-- Denormalised inspection list with room and guest info,
-- used by RoomInspection.getAll() / getByBookingId() / getByRoomId() / getRecentIssues()
--
CREATE OR REPLACE VIEW `inspection_summary` AS
SELECT
  ri.inspection_id,
  ri.booking_id,
  ri.room_id,
  ri.inspector_name,
  ri.general_notes,
  ri.overall_status,
  ri.inspection_completed,
  ri.inspection_date,
  ri.completed_at,
  ri.created_at,
  ri.updated_at,
  r.room_number,
  r.room_type,
  g.name  AS guest_name,
  g.phone AS guest_phone
FROM `room_inspections` ri
JOIN `rooms`    r ON ri.room_id   = r.room_id
JOIN `bookings` b ON ri.booking_id = b.booking_id
JOIN `guests`   g ON b.guest_id   = g.guest_id;

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
