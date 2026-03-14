-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 13, 2026 at 04:40 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


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
CREATE  FUNCTION `check_room_availability_enhanced` (`p_room_id` INT, `p_start_date` DATE, `p_end_date` DATE) RETURNS LONGTEXT CHARSET utf8mb4 COLLATE utf8mb4_bin READS SQL DATA BEGIN
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

CREATE  FUNCTION `GetCheckoutType` (`checkout_date` DATE, `checkout_time_val` TIME) RETURNS VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_general_ci DETERMINISTIC READS SQL DATA BEGIN
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
-- Table structure for table `asset_categories`
--

CREATE TABLE `asset_categories` (
  `category_id` int(11) NOT NULL,
  `category_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `asset_categories`
--

INSERT INTO `asset_categories` (`category_id`, `category_name`, `description`, `created_at`) VALUES
(1, 'TV & Electronics', 'Television, remote controls, set-top boxes, radios', '2026-03-11 04:52:02'),
(2, 'Furniture', 'Beds, chairs, tables, wardrobes, sofas', '2026-03-11 04:52:02'),
(3, 'Bathroom Fixtures', 'Towel rails, shower heads, taps, toilet accessories', '2026-03-11 04:52:02'),
(4, 'Appliances', 'Air conditioners, refrigerators, microwaves, kettles', '2026-03-11 04:52:02'),
(5, 'Lighting', 'Ceiling lights, bedside lamps, bathroom lights', '2026-03-11 04:52:02'),
(6, 'Bedding & Linen', 'Mattresses, pillows, duvets, bedsheets', '2026-03-11 04:52:02'),
(7, 'Safety Equipment', 'Fire extinguishers, smoke detectors, first aid kits', '2026-03-11 04:52:02'),
(8, 'Kitchen Items', 'Cups, glasses, plates, cutlery, coffee makers', '2026-03-11 04:52:02');

-- --------------------------------------------------------

--
-- Table structure for table `asset_charges`
--

CREATE TABLE `asset_charges` (
  `charge_id` int(11) NOT NULL,
  `inspection_item_id` int(11) DEFAULT NULL,
  `booking_id` int(11) NOT NULL,
  `guest_id` int(11) NOT NULL,
  `asset_name` varchar(100) NOT NULL,
  `charge_amount` decimal(10,2) NOT NULL,
  `charge_type` enum('Missing','Damaged','Replacement') DEFAULT 'Damaged',
  `payment_status` enum('Pending','Paid','Waived') DEFAULT 'Pending',
  `notes` text DEFAULT NULL,
  `charged_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `billing_settings`
--

CREATE TABLE `billing_settings` (
  `setting_id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `billing_settings`
--

INSERT INTO `billing_settings` (`setting_id`, `setting_key`, `setting_value`, `description`, `created_at`, `updated_at`) VALUES
(1, 'company_address', 'Address', 'Company address for invoices', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(2, 'company_email', 'email@company.com', 'Company email for invoices', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(3, 'company_name', 'Hotel Management System', 'Company name for invoices', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(4, 'company_phone', 'Phone', 'Company phone for invoices', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(5, 'due_days', '7', 'Payment due days from invoice date', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(6, 'invoice_prefix', 'INV', 'Invoice number prefix', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(7, 'tax_rate', '0', 'Default tax rate percentage', '2026-03-11 04:52:02', '2026-03-11 05:04:31'),
(8, 'currency_symbol', '???', 'Currency symbol for billing', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(9, 'check_in_time', '12:00', 'Standard check-in time', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(10, 'check_out_time', '11:00', 'Standard check-out time', '2026-03-11 04:52:02', '2026-03-11 04:52:02');

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

--
-- Dumping data for table `bookings`
--

INSERT INTO `bookings` (`booking_id`, `guest_id`, `room_id`, `check_in`, `check_out`, `number_of_guests`, `room_price`, `total_amount`, `discount_type`, `discount_value`, `discount_reason`, `advance_payment`, `payment_status`, `payment_method`, `booking_source`, `booking_status`, `special_requests`, `actual_checkin_time`, `actual_checkout_time`, `checkout_type`, `is_early_checkout`, `late_checkout_fee`, `early_checkout_reason`, `is_extension`, `parent_booking_id`, `booking_group_id`, `cancellation_reason`, `created_at`, `updated_at`) VALUES
(1, 1, 2, '2026-03-11', '2026-03-13', 1, 1500.00, 3540.00, 'None', 0.00, '', 44.00, 'Partial', 'Cash', 'Walk-in', 'CheckedOut', '', '2026-03-11 12:25:28', '2026-03-11 06:25:42', 'Early', 1, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 06:25:20', '2026-03-11 06:25:42'),
(2, 6, 3, '2026-03-13', '2026-03-18', 1, 2500.00, 14750.00, 'None', 0.00, '', 0.00, 'Pending', 'Cash', 'Walk-in', 'CheckedOut', '', '2026-03-11 19:40:20', '2026-03-11 13:40:32', 'Early', 1, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 13:40:00', '2026-03-11 13:40:32'),
(3, 9, 3, '2026-03-11', '2026-03-13', 1, 2500.00, 5900.00, 'None', 0.00, '', 222.00, 'Partial', 'Cash', 'Walk-in', 'CheckedIn', '', '2026-03-11 19:51:06', NULL, 'Standard', 0, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 13:50:55', '2026-03-11 13:51:06'),
(4, 14, 8, '2026-03-11', '2026-03-12', 1, 1500.00, 1500.00, 'None', 0.00, NULL, 0.00, 'Paid', 'Cash', 'Walk-in', 'CheckedOut', NULL, '2026-03-11 20:31:51', '2026-03-11 17:12:24', 'Early', 1, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 14:31:51', '2026-03-11 17:12:24'),
(5, 3, 2, '2026-03-11', '2026-03-12', 1, 1500.00, 1500.00, 'None', 0.00, NULL, 0.00, 'Paid', 'Cash', 'Walk-in', 'CheckedOut', NULL, '2026-03-11 20:34:16', '2026-03-11 15:31:04', 'Early', 1, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 14:34:16', '2026-03-11 16:07:34'),
(6, 15, 9, '2026-03-11', '2026-03-12', 1, 1500.00, 1770.00, 'None', 0.00, '', 300.00, 'Partial', 'Cash', 'Walk-in', 'CheckedOut', '', '2026-03-11 23:18:23', '2026-03-11 17:20:35', 'Early', 1, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 17:17:54', '2026-03-11 17:20:35'),
(7, 6, 2, '2026-03-11', '2026-03-12', 1, 1500.00, 1500.00, 'None', 0.00, NULL, 0.00, 'Paid', 'Cash', 'Walk-in', 'CheckedOut', NULL, '2026-03-11 23:26:48', '2026-03-11 17:33:45', 'Early', 1, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 17:26:47', '2026-03-11 17:33:54'),
(8, 1, 10, '2026-03-12', '2026-03-20', 1, 1500.00, 14160.00, 'None', 0.00, '', 55.00, 'Partial', 'Cash', 'Walk-in', 'CheckedIn', '', '2026-03-11 23:39:40', NULL, 'Standard', 0, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-11 17:32:15', '2026-03-11 17:39:40'),
(9, 1, 9, '2026-03-12', '2026-03-15', 1, 1500.00, 5310.00, 'None', 0.00, '', 44.00, 'Partial', 'Cash', 'Walk-in', 'Confirmed', '', NULL, NULL, 'Standard', 0, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-12 09:46:41', '2026-03-12 09:46:41'),
(10, 1, 2, '2026-03-12', '2026-03-13', 1, 1500.00, 1770.00, 'None', 0.00, '', 78.95, 'Paid', 'Cash', 'Walk-in', 'CheckedIn', '', '2026-03-12 20:16:14', NULL, 'Standard', 0, 0.00, NULL, 0, NULL, '1773324941661', NULL, '2026-03-12 14:15:41', '2026-03-12 14:16:37'),
(11, 1, 29, '2026-03-12', '2026-03-13', 1, 8000.00, 9440.00, 'None', 0.00, '', 421.05, 'Partial', 'Cash', 'Walk-in', 'CheckedOut', '', '2026-03-12 23:22:24', '2026-03-12 17:22:38', 'Early', 1, 0.00, NULL, 0, NULL, '1773324941661', NULL, '2026-03-12 14:15:41', '2026-03-12 17:22:38'),
(12, 1, 9, '2026-03-20', '2026-03-25', 1, 1500.00, 8850.00, 'None', 0.00, '', 0.00, 'Pending', 'Cash', 'Walk-in', 'Confirmed', 'df', NULL, NULL, 'Standard', 0, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-12 14:24:35', '2026-03-12 14:24:35'),
(13, 16, 8, '2026-03-14', '2026-03-17', 1, 1500.00, 4500.00, 'None', 0.00, '', 500.00, 'Partial', 'Cash', 'Walk-in', 'Confirmed', '\n[Date Modified: 2026-03-13 16:23:56] From 2026-03-13 00:00:00.000 - 2026-03-14 00:00:00.000 to 2026-03-14 - 2026-03-17 (1 nights to 3 nights)', NULL, NULL, 'Standard', 0, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-13 07:56:43', '2026-03-13 10:23:56'),
(14, 17, 11, '2026-03-15', '2026-03-17', 3, 2500.00, 5900.00, 'None', 0.00, '', 0.00, 'Pending', 'Cash', 'Walk-in', 'Confirmed', '', NULL, NULL, 'Standard', 0, 0.00, NULL, 0, NULL, NULL, NULL, '2026-03-13 10:41:19', '2026-03-13 10:41:19');

-- --------------------------------------------------------

--
-- Stand-in structure for view `booking_details`
-- (See below for the actual view)
--
CREATE TABLE `booking_details` (
`booking_id` int(11)
,`guest_id` int(11)
,`room_id` int(11)
,`check_in` date
,`check_out` date
,`number_of_guests` int(11)
,`number_of_nights` int(11)
,`room_price` decimal(10,2)
,`total_amount` decimal(10,2)
,`advance_payment` decimal(10,2)
,`payment_status` enum('Pending','Partial','Paid')
,`payment_method` enum('Cash','Card','Debit Card','UPI','Online')
,`discount_type` enum('None','Percentage','Fixed')
,`discount_value` decimal(10,2)
,`discount_reason` varchar(100)
,`booking_source` enum('Walk-in','Phone','Online','OTA','Corporate','Other')
,`booking_status` enum('Confirmed','CheckedIn','CheckedOut','Cancelled','NoShow')
,`special_requests` text
,`cancellation_reason` varchar(255)
,`actual_checkin_time` datetime
,`actual_checkout_time` datetime
,`checkout_type` enum('Early','Standard','Late')
,`is_early_checkout` tinyint(1)
,`late_checkout_fee` decimal(10,2)
,`early_checkout_reason` varchar(255)
,`is_extension` tinyint(1)
,`parent_booking_id` int(11)
,`booking_group_id` varchar(50)
,`created_at` timestamp
,`updated_at` timestamp
,`guest_name` varchar(100)
,`guest_phone` varchar(15)
,`guest_email` varchar(100)
,`room_number` varchar(10)
,`room_type` enum('Single','Double','Suite','Deluxe')
,`current_room_price` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `booking_details_enhanced`
-- (See below for the actual view)
--
CREATE TABLE `booking_details_enhanced` (
`booking_id` int(11)
,`guest_id` int(11)
,`room_id` int(11)
,`check_in` date
,`check_out` date
,`number_of_guests` int(11)
,`number_of_nights` int(11)
,`room_price` decimal(10,2)
,`total_amount` decimal(10,2)
,`advance_payment` decimal(10,2)
,`payment_status` enum('Pending','Partial','Paid')
,`payment_method` enum('Cash','Card','Debit Card','UPI','Online')
,`discount_type` enum('None','Percentage','Fixed')
,`discount_value` decimal(10,2)
,`discount_reason` varchar(100)
,`booking_source` enum('Walk-in','Phone','Online','OTA','Corporate','Other')
,`booking_status` enum('Confirmed','CheckedIn','CheckedOut','Cancelled','NoShow')
,`special_requests` text
,`cancellation_reason` varchar(255)
,`actual_checkin_time` datetime
,`actual_checkout_time` datetime
,`checkout_type` enum('Early','Standard','Late')
,`is_early_checkout` tinyint(1)
,`late_checkout_fee` decimal(10,2)
,`early_checkout_reason` varchar(255)
,`is_extension` tinyint(1)
,`parent_booking_id` int(11)
,`booking_group_id` varchar(50)
,`created_at` timestamp
,`updated_at` timestamp
,`guest_name` varchar(100)
,`guest_phone` varchar(15)
,`guest_email` varchar(100)
,`room_number` varchar(10)
,`room_type` enum('Single','Double','Suite','Deluxe')
,`current_room_price` decimal(10,2)
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
(2, 2, 3, 'Regular Clean', 'In Progress', 'Medium', '2026-03-08', '10:00:00', NULL, NULL, 'Standard daily cleaning', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, 3, NULL, 'Quick Clean', 'Not Started', 'Low', '2026-03-08', '11:00:00', NULL, NULL, 'Tidy up and restock amenities', NULL, 1, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(8, 3, NULL, 'Turnover', 'Not Started', 'High', '2026-03-11', NULL, NULL, NULL, 'Auto-generated on checkout of booking #2', NULL, NULL, '2026-03-11 13:40:32', '2026-03-11 13:40:32'),
(9, 2, NULL, 'Turnover', 'Not Started', 'High', '2026-03-11', NULL, NULL, NULL, 'Auto-generated on checkout of booking #5', NULL, NULL, '2026-03-11 15:31:04', '2026-03-11 15:31:04'),
(10, 8, NULL, 'Turnover', 'Not Started', 'High', '2026-03-11', NULL, NULL, NULL, 'Auto-generated on checkout of booking #4', NULL, NULL, '2026-03-11 17:12:24', '2026-03-11 17:12:24'),
(11, 9, NULL, 'Turnover', 'Completed', 'High', '2026-03-11', NULL, '2026-03-13 11:43:57', '2026-03-13 11:44:07', 'Auto-generated on checkout of booking #6 - Completed: Task completed', NULL, NULL, '2026-03-11 17:20:35', '2026-03-13 05:44:07'),
(12, 2, NULL, 'Turnover', 'Not Started', 'High', '2026-03-11', NULL, NULL, NULL, 'Auto-generated on checkout of booking #7', NULL, NULL, '2026-03-11 17:33:45', '2026-03-11 17:33:45'),
(13, 29, NULL, 'Turnover', 'Not Started', 'High', '2026-03-12', NULL, NULL, NULL, 'Auto-generated on checkout of booking #11', NULL, NULL, '2026-03-12 17:22:38', '2026-03-12 17:22:38');

-- --------------------------------------------------------

--
-- Table structure for table `expense_records`
--

CREATE TABLE `expense_records` (
  `expense_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `financial_management`
--

CREATE TABLE `financial_management` (
  `financial_id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `revenue_type` enum('Room','Service','Other') DEFAULT 'Room',
  `amount` decimal(10,2) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `transaction_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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

--
-- Dumping data for table `guests`
--

INSERT INTO `guests` (`guest_id`, `name`, `phone`, `email`, `id_proof`, `id_type`, `address`, `created_at`, `updated_at`) VALUES
(1, 'wretrt', '01728518343', 'shaykhul2004@gmail.com', '345', 'NID', 'Nalchity, Barisal', '2026-03-11 06:25:20', '2026-03-11 06:25:20'),
(2, 'werwe343334', '3235', '', '444', 'NID', '', '2026-03-11 12:49:22', '2026-03-11 12:49:22'),
(3, 'werwe343334', '01753313905', '', '444345634563456', 'NID', '', '2026-03-11 12:49:39', '2026-03-11 12:49:39'),
(4, 'werwe343334', '01753313905', '', '444345634563456', 'NID', '', '2026-03-11 12:49:56', '2026-03-11 12:49:56'),
(5, 'wertert', '01728518343', 'shaykhul2004@gmail.com', '243', 'NID', 'Nalchity, Barisal', '2026-03-11 12:50:34', '2026-03-11 12:50:34'),
(6, 'name', '01728518343', 'shaykhul2004@gmail.com', '12', 'NID', 'Nalchity, Barisal', '2026-03-11 13:40:00', '2026-03-11 13:40:20'),
(7, 'asdf', 'sfggdf', '', '2134231412', 'NID', '', '2026-03-11 13:50:02', '2026-03-11 13:50:02'),
(8, 'asdf', 'sfggdf', '', '2134231412', 'NID', '', '2026-03-11 13:50:08', '2026-03-11 13:50:08'),
(9, 'sfsdfg', '01728518343', 'shaykhul2004@gmail.com', '25345', 'NID', 'Nalchity, Barisal', '2026-03-11 13:50:55', '2026-03-11 13:50:55'),
(10, 'Mahin', '01753313906', '', '122345434235', 'NID', '', '2026-03-11 14:14:17', '2026-03-11 14:14:17'),
(11, 'Ana Franq', 'O1753313789', '', '2353245346', 'NID', '', '2026-03-11 14:20:54', '2026-03-11 14:20:54'),
(12, 'siam', '01753313893', '', '4232345324', 'NID', '', '2026-03-11 14:22:10', '2026-03-11 14:22:10'),
(13, 'Nimu', '01753313784', '', '345645645', 'NID', '', '2026-03-11 14:27:45', '2026-03-11 14:27:45'),
(14, 'Ridu', '017533313456', '', '123413415542', 'NID', '', '2026-03-11 14:31:51', '2026-03-11 14:31:51'),
(15, 'Shaykhul Shaykhul', '01728518343', 'shaykhul2004@gmail.com', 'ee54', 'NID', 'rfgs', '2026-03-11 17:17:54', '2026-03-13 05:41:56'),
(16, 'wretrt', '0172851834', 'shaykhul2004@gmail.com', '345', 'NID', 'Nalchity, Barisal', '2026-03-13 07:56:43', '2026-03-13 07:56:43'),
(17, 'name', '0123234235', '', '', 'NID', 'address', '2026-03-13 10:41:19', '2026-03-13 10:41:19');

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

--
-- Dumping data for table `guest_sessions`
--

INSERT INTO `guest_sessions` (`session_id`, `booking_id`, `guest_id`, `access_token`, `token_pin`, `is_active`, `created_at`, `expires_at`, `checked_out_at`, `last_accessed`, `access_count`) VALUES
(1, 1, 1, 'd9886b12a698bc1f97dc05423df98632ac0fe77c1006c485ec512a08b9b42f06', '981815', 0, '2026-03-11 06:25:28', NULL, '2026-03-11 06:25:42', NULL, 0),
(2, 2, 6, 'f99a9bbd63a7e64d0f032307ed7652cc51ea78650a4d2a0429a17633c0139ee9', '109085', 0, '2026-03-11 13:40:20', NULL, '2026-03-11 13:40:32', NULL, 0),
(3, 3, 9, 'ed8e3f8e924745b2d8bcc4c9c7af109adf0a3d21e15e2eaf6fc361eb71134d2c', '406782', 1, '2026-03-11 13:51:06', NULL, NULL, NULL, 0),
(4, 4, 14, '3c82f453e20a81b173a1706e9cfd5e5b439989046fee33873228d35707a2709b', '794968', 0, '2026-03-11 14:31:51', NULL, '2026-03-11 17:12:24', NULL, 0),
(5, 5, 3, '9553f611437b281b98b206e003216b65108af6a39ea690be9aee503ce6602792', '196063', 0, '2026-03-11 14:34:16', NULL, '2026-03-11 15:31:04', NULL, 0),
(6, 6, 15, '78e7adfbcfb1829c71e61ee2b6734e0f846182fe24dba26e47782a0e8c3c331f', '829048', 0, '2026-03-11 17:18:23', NULL, '2026-03-11 17:20:35', NULL, 0),
(7, 7, 6, '758d914f61c3e1dd0fe02b771dd988cbb1d5f05fc6fb789be91633ee17230bae', '246599', 0, '2026-03-11 17:26:48', NULL, '2026-03-11 17:33:45', NULL, 0),
(8, 8, 1, '38c41bfab065fb01c0f8e6245135858673bf7c993c129865a795dfb3ea7e1245', '230311', 1, '2026-03-11 17:39:40', NULL, NULL, NULL, 0),
(9, 10, 1, '6b0d8fe9de2dd2d9008c05a8ce38d710f22f484d1baa92523b4056d0664d00e7', '428689', 1, '2026-03-12 14:16:14', NULL, NULL, NULL, 0),
(10, 11, 1, '19c9548ec549ad1fc4bfe461f8fc522610ce3c2fe2ce2263a81b01cd6e962adc', '618367', 0, '2026-03-12 17:22:24', NULL, '2026-03-12 17:22:38', NULL, 0);

-- --------------------------------------------------------

--
-- Table structure for table `hotel_policies`
--

CREATE TABLE `hotel_policies` (
  `policy_id` int(11) NOT NULL,
  `policy_name` varchar(100) NOT NULL,
  `policy_value` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `hotel_policies`
--

INSERT INTO `hotel_policies` (`policy_id`, `policy_name`, `policy_value`, `description`, `created_at`, `updated_at`) VALUES
(1, 'late_checkout_fee_percent', '20', 'Percentage of nightly rate charged for late checkout', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(2, 'early_checkout_penalty', '10', 'Percentage of unused nights refund withheld as penalty', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(3, 'cancellation_hours', '24', 'Hours before check-in for penalty-free cancellation', '2026-03-11 04:52:02', '2026-03-11 04:52:02'),
(4, 'max_extension_nights', '30', 'Maximum number of nights a stay can be extended', '2026-03-11 04:52:02', '2026-03-11 04:52:02');

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

--
-- Dumping data for table `hotel_users`
--

INSERT INTO `hotel_users` (`user_id`, `username`, `password_hash`, `full_name`, `role`, `is_active`, `last_login_at`, `created_at`, `updated_at`) VALUES
(1, 'admin', '$2a$10$Esh/NQsVP6/f9GZrs1E3xuk0weyZq8R0n7jJEJ3OzHWQRrpUQc8tq', 'System Administrator', 'Admin', 1, '2026-03-13 16:29:23', '2026-03-13 05:06:34', '2026-03-13 10:29:23');

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

INSERT INTO `housekeeping_staff` (`staff_id`, `staff_name`, `phone`, `email`, `role`, `shift`, `status`, `assigned_floors`, `hire_date`, `monthly_salary`, `created_at`, `updated_at`) VALUES
(1, 'Priya Sharma', '9876543220', 'priya@hotel.com', 'Supervisor', 'Morning', 'Active', '1,2,3', NULL, 0.00, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(2, 'Rajesh Kumar', '9876543221', 'rajesh@hotel.com', 'Housekeeper', 'Morning', 'Active', '1,2', NULL, 0.00, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(3, 'Anita Singh', '9876543222', 'anita@hotel.com', 'Housekeeper', 'Morning', 'Active', '2,3', NULL, 0.00, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(5, 'Neha Gupta', '9876543224', 'neha@hotel.com', 'Housekeeper', 'Afternoon', 'Active', '1,4', NULL, 0.00, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(6, 'Suresh Verma', '9876543225', 'suresh@hotel.com', 'Manager', 'Morning', 'Active', '1,2,3,4', NULL, 0.00, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(7, 'Deepa Nair', '9876543226', 'deepa@hotel.com', 'Housekeeper', 'Night', 'On Leave', '2,3', NULL, 0.00, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(8, 'Arjun Singh', '9876543227', 'arjun@hotel.com', 'Housekeeper', 'Night', 'Active', '1,3,4', NULL, 0.00, '2026-03-08 06:24:41', '2026-03-08 06:24:41'),
(9, 'UI Action Menu Test', '01700000022', 'ui.staff@test.com', 'Housekeeper', 'Morning', 'Active', '3', NULL, 18000.00, '2026-03-13 05:50:19', '2026-03-13 05:50:19'),
(10, 'Shaykhul', '01728518343', 'shaykhul2004@gmail.com', 'Manager', 'Morning', 'Active', NULL, NULL, 23000.00, '2026-03-13 05:52:20', '2026-03-13 05:58:34'),
(11, 'Rahim', '01728518343', 'shaykhul2004@gmail.com', 'Housekeeper', 'Morning', 'Active', '2', NULL, 9000.00, '2026-03-13 08:08:52', '2026-03-13 08:08:52'),
(12, 'staff1', '01728518343', 'shaykhul2004@gmail.com', 'Housekeeper', 'Morning', 'Active', '3', NULL, 11999.99, '2026-03-13 08:53:17', '2026-03-13 08:53:17'),
(13, 'Habibur Rahman', '01745656', NULL, 'Housekeeper', 'Morning', 'Active', NULL, NULL, 8000.00, '2026-03-13 09:04:24', '2026-03-13 09:04:24');

-- --------------------------------------------------------

--
-- Table structure for table `income_records`
--

CREATE TABLE `income_records` (
  `income_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `inspection_items`
--

CREATE TABLE `inspection_items` (
  `inspection_item_id` int(11) NOT NULL,
  `inspection_id` int(11) NOT NULL,
  `asset_id` int(11) DEFAULT NULL,
  `status` enum('Present','Missing','Damaged','Needs Replacement','Extra') DEFAULT 'Present',
  `quantity_expected` int(11) DEFAULT 1,
  `quantity_found` int(11) DEFAULT 1,
  `condition_notes` text DEFAULT NULL,
  `damage_cost` decimal(10,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `inspection_summary`
-- (See below for the actual view)
--
CREATE TABLE `inspection_summary` (
`inspection_id` int(11)
,`booking_id` int(11)
,`room_id` int(11)
,`inspector_name` varchar(100)
,`general_notes` text
,`overall_status` enum('Pass','Fail','Missing Items','Damaged Items','Issues Found')
,`inspection_completed` tinyint(1)
,`inspection_date` timestamp
,`completed_at` datetime
,`created_at` timestamp
,`updated_at` timestamp
,`room_number` varchar(10)
,`room_type` enum('Single','Double','Suite','Deluxe')
,`guest_name` varchar(100)
,`guest_phone` varchar(15)
);

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

INSERT INTO `inventory_items` (`item_id`, `item_name`, `category_id`, `unit`, `unit_cost`, `description`, `supplier_name`, `supplier_phone`, `status`, `is_checkin_item`, `checkin_qty_per_guest`, `created_at`, `updated_at`) VALUES
(1, 'Bath Towel', 1, 'Pieces', 150.00, 'Premium cotton bath towel (white)', 'Linen World', '9876543210', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(2, 'Bed Sheet', 1, 'Pieces', 250.00, 'Cotton bed sheet set (queen size)', 'Linen World', '9876543210', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(3, 'Pillow Cover', 1, 'Pieces', 80.00, 'Cotton pillow cover', 'Linen World', '9876543210', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(4, 'Blanket', 1, 'Pieces', 300.00, 'Warm blanket (double size)', 'Linen World', '9876543210', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(5, 'Soap Bar', 2, 'Pieces', 20.00, 'Guest soap bar', 'Hygiene Plus', '9876543211', 'Active', 1, 1, '2026-03-08 06:24:40', '2026-03-11 04:52:00'),
(6, 'Shampoo Bottle', 2, 'Bottles', 150.00, 'Premium shampoo (250ml)', 'Hygiene Plus', '9876543211', 'Active', 1, 1, '2026-03-08 06:24:40', '2026-03-11 04:52:00'),
(7, 'Conditioner Bottle', 2, 'Bottles', 150.00, 'Conditioner (250ml)', 'Hygiene Plus', '9876543211', 'Active', 1, 1, '2026-03-08 06:24:40', '2026-03-11 04:52:00'),
(8, 'Toothbrush', 2, 'Pieces', 15.00, 'Disposable toothbrush', 'Hygiene Plus', '9876543211', 'Active', 1, 1, '2026-03-08 06:24:40', '2026-03-11 04:52:00'),
(9, 'Floor Cleaner', 3, 'Liters', 200.00, 'Multi-purpose floor cleaner (5L)', 'Clean Care', '9876543212', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(10, 'Disinfectant Spray', 3, 'Bottles', 180.00, 'Room disinfectant spray (500ml)', 'Clean Care', '9876543212', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(11, 'Dish Soap', 3, 'Liters', 100.00, 'Liquid dish soap (1L)', 'Clean Care', '9876543212', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(12, 'Paper Plates', 4, 'Sets', 50.00, 'Disposable paper plates (50pcs)', 'Kitchen Plus', '9876543213', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(13, 'Glass Cups', 4, 'Sets', 300.00, 'Glass cups set (6pcs)', 'Kitchen Plus', '9876543213', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(14, 'Stainless Steel Cutlery', 4, 'Sets', 400.00, 'Cutlery set (6 place)', 'Kitchen Plus', '9876543213', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(15, 'Laundry Detergent', 5, 'Kg', 250.00, 'Laundry detergent powder (1kg)', 'Wash World', '9876543214', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(16, 'Fabric Softener', 5, 'Liters', 200.00, 'Fabric softener (1L)', 'Wash World', '9876543214', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(17, 'Stain Remover', 5, 'Bottles', 180.00, 'Stain remover spray (500ml)', 'Wash World', '9876543214', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(18, 'Office Notepad', 6, 'Pieces', 30.00, 'Spiral notepads', 'Paper Co', '9876543215', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(19, 'Ballpoint Pen', 6, 'Boxes', 150.00, 'Ballpoint pens box (50pcs)', 'Paper Co', '9876543215', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(20, 'Folder', 6, 'Pieces', 20.00, 'Plastic folder', 'Paper Co', '9876543215', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(21, 'Light Bulb', 7, 'Pieces', 80.00, 'LED bulb 10W', 'Electricals', '9876543216', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(22, 'Battery', 7, 'Boxes', 400.00, 'AA batteries (12 pack)', 'Electricals', '9876543216', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(23, 'Coffee Powder', 8, 'Kg', 500.00, 'Premium instant coffee (250g)', 'Beverages Co', '9876543217', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(24, 'Tea Bags', 8, 'Boxes', 300.00, 'Tea bags box (100pcs)', 'Beverages Co', '9876543217', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(25, 'Sugar', 8, 'Kg', 60.00, 'White sugar (1kg)', 'Beverages Co', '9876543217', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40'),
(26, 'Biscuits', 8, 'Boxes', 200.00, 'Assorted biscuits box', 'Beverages Co', '9876543217', 'Active', 0, 1, '2026-03-08 06:24:40', '2026-03-08 06:24:40');

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
(5, 5, 40, 10, 100, 50, 800.00, NULL, '2026-03-12 17:22:24', '2026-03-08 06:24:40', '2026-03-12 17:22:24'),
(6, 6, 40, 10, 100, 50, 6000.00, NULL, '2026-03-12 17:22:25', '2026-03-08 06:24:40', '2026-03-12 17:22:25'),
(7, 7, 40, 10, 100, 50, 6000.00, NULL, '2026-03-12 17:22:25', '2026-03-08 06:24:40', '2026-03-12 17:22:25'),
(8, 8, 40, 10, 100, 50, 600.00, NULL, '2026-03-12 17:22:25', '2026-03-08 06:24:40', '2026-03-12 17:22:25'),
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

--
-- Dumping data for table `inventory_transactions`
--

INSERT INTO `inventory_transactions` (`transaction_id`, `item_id`, `transaction_type`, `quantity_change`, `previous_quantity`, `new_quantity`, `notes`, `created_by`, `booked_against`, `created_at`) VALUES
(1, 5, 'Consume', -1, 50, 49, 'Auto Check-In: Booking #1 (1 guest)', 'System', 1, '2026-03-11 06:25:28'),
(2, 6, 'Consume', -1, 50, 49, 'Auto Check-In: Booking #1 (1 guest)', 'System', 1, '2026-03-11 06:25:28'),
(3, 7, 'Consume', -1, 50, 49, 'Auto Check-In: Booking #1 (1 guest)', 'System', 1, '2026-03-11 06:25:28'),
(4, 8, 'Consume', -1, 50, 49, 'Auto Check-In: Booking #1 (1 guest)', 'System', 1, '2026-03-11 06:25:29'),
(5, 5, 'Consume', -1, 49, 48, 'Auto Check-In: Booking #2 (1 guest)', 'System', 2, '2026-03-11 13:40:20'),
(6, 6, 'Consume', -1, 49, 48, 'Auto Check-In: Booking #2 (1 guest)', 'System', 2, '2026-03-11 13:40:20'),
(7, 7, 'Consume', -1, 49, 48, 'Auto Check-In: Booking #2 (1 guest)', 'System', 2, '2026-03-11 13:40:20'),
(8, 8, 'Consume', -1, 49, 48, 'Auto Check-In: Booking #2 (1 guest)', 'System', 2, '2026-03-11 13:40:20'),
(9, 5, 'Consume', -1, 48, 47, 'Auto Check-In: Booking #3 (1 guest)', 'System', 3, '2026-03-11 13:51:06'),
(10, 6, 'Consume', -1, 48, 47, 'Auto Check-In: Booking #3 (1 guest)', 'System', 3, '2026-03-11 13:51:06'),
(11, 7, 'Consume', -1, 48, 47, 'Auto Check-In: Booking #3 (1 guest)', 'System', 3, '2026-03-11 13:51:06'),
(12, 8, 'Consume', -1, 48, 47, 'Auto Check-In: Booking #3 (1 guest)', 'System', 3, '2026-03-11 13:51:06'),
(13, 5, 'Consume', -1, 47, 46, 'Auto Check-In: Booking #4 (1 guest)', 'System', 4, '2026-03-11 14:31:51'),
(14, 6, 'Consume', -1, 47, 46, 'Auto Check-In: Booking #4 (1 guest)', 'System', 4, '2026-03-11 14:31:51'),
(15, 7, 'Consume', -1, 47, 46, 'Auto Check-In: Booking #4 (1 guest)', 'System', 4, '2026-03-11 14:31:51'),
(16, 8, 'Consume', -1, 47, 46, 'Auto Check-In: Booking #4 (1 guest)', 'System', 4, '2026-03-11 14:31:51'),
(17, 5, 'Consume', -1, 46, 45, 'Auto Check-In: Booking #5 (1 guest)', 'System', 5, '2026-03-11 14:34:16'),
(18, 6, 'Consume', -1, 46, 45, 'Auto Check-In: Booking #5 (1 guest)', 'System', 5, '2026-03-11 14:34:16'),
(19, 7, 'Consume', -1, 46, 45, 'Auto Check-In: Booking #5 (1 guest)', 'System', 5, '2026-03-11 14:34:16'),
(20, 8, 'Consume', -1, 46, 45, 'Auto Check-In: Booking #5 (1 guest)', 'System', 5, '2026-03-11 14:34:16'),
(21, 5, 'Consume', -1, 45, 44, 'Auto Check-In: Booking #6 (1 guest)', 'System', 6, '2026-03-11 17:18:23'),
(22, 6, 'Consume', -1, 45, 44, 'Auto Check-In: Booking #6 (1 guest)', 'System', 6, '2026-03-11 17:18:23'),
(23, 7, 'Consume', -1, 45, 44, 'Auto Check-In: Booking #6 (1 guest)', 'System', 6, '2026-03-11 17:18:23'),
(24, 8, 'Consume', -1, 45, 44, 'Auto Check-In: Booking #6 (1 guest)', 'System', 6, '2026-03-11 17:18:23'),
(25, 5, 'Consume', -1, 44, 43, 'Auto Check-In: Booking #7 (1 guest)', 'System', 7, '2026-03-11 17:26:48'),
(26, 6, 'Consume', -1, 44, 43, 'Auto Check-In: Booking #7 (1 guest)', 'System', 7, '2026-03-11 17:26:48'),
(27, 7, 'Consume', -1, 44, 43, 'Auto Check-In: Booking #7 (1 guest)', 'System', 7, '2026-03-11 17:26:48'),
(28, 8, 'Consume', -1, 44, 43, 'Auto Check-In: Booking #7 (1 guest)', 'System', 7, '2026-03-11 17:26:48'),
(29, 5, 'Consume', -1, 43, 42, 'Auto Check-In: Booking #8 (1 guest)', 'System', 8, '2026-03-11 17:39:40'),
(30, 6, 'Consume', -1, 43, 42, 'Auto Check-In: Booking #8 (1 guest)', 'System', 8, '2026-03-11 17:39:40'),
(31, 7, 'Consume', -1, 43, 42, 'Auto Check-In: Booking #8 (1 guest)', 'System', 8, '2026-03-11 17:39:40'),
(32, 8, 'Consume', -1, 43, 42, 'Auto Check-In: Booking #8 (1 guest)', 'System', 8, '2026-03-11 17:39:40'),
(33, 5, 'Consume', -1, 42, 41, 'Auto Check-In: Booking #10 (1 guest)', 'System', 10, '2026-03-12 14:16:14'),
(34, 6, 'Consume', -1, 42, 41, 'Auto Check-In: Booking #10 (1 guest)', 'System', 10, '2026-03-12 14:16:14'),
(35, 7, 'Consume', -1, 42, 41, 'Auto Check-In: Booking #10 (1 guest)', 'System', 10, '2026-03-12 14:16:14'),
(36, 8, 'Consume', -1, 42, 41, 'Auto Check-In: Booking #10 (1 guest)', 'System', 10, '2026-03-12 14:16:14'),
(37, 5, 'Consume', -1, 41, 40, 'Auto Check-In: Booking #11 (1 guest)', 'System', 11, '2026-03-12 17:22:24'),
(38, 6, 'Consume', -1, 41, 40, 'Auto Check-In: Booking #11 (1 guest)', 'System', 11, '2026-03-12 17:22:25'),
(39, 7, 'Consume', -1, 41, 40, 'Auto Check-In: Booking #11 (1 guest)', 'System', 11, '2026-03-12 17:22:25'),
(40, 8, 'Consume', -1, 41, 40, 'Auto Check-In: Booking #11 (1 guest)', 'System', 11, '2026-03-12 17:22:25');

-- --------------------------------------------------------

--
-- Table structure for table `invoices`
--

CREATE TABLE `invoices` (
  `invoice_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `invoices`
--

INSERT INTO `invoices` (`invoice_id`, `booking_id`, `invoice_number`, `guest_id`, `room_id`, `subtotal`, `tax_amount`, `total_amount`, `amount_paid`, `amount_due`, `invoice_date`, `due_date`, `payment_status`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 'INV000001', 1, 2, 3540.00, 0.00, 3540.00, 144.00, 3396.00, '2026-03-11', '2026-03-18', 'Partial', 'Room: 102 | Guest: wretrt | Period: 2026-03-11 to 2026-03-13', '2026-03-11 06:25:28', '2026-03-11 16:21:12'),
(2, 2, 'INV000011', 6, 3, 14750.00, 0.00, 14750.00, 0.00, 14750.00, '2026-03-11', '2026-03-18', 'Pending', 'Room: 201 | Guest: name | Period: 2026-03-13 to 2026-03-18', '2026-03-11 13:40:20', '2026-03-11 13:40:20'),
(3, 3, 'INV000021', 9, 3, 5900.00, 0.00, 5900.00, 0.00, 5900.00, '2026-03-11', '2026-03-18', 'Pending', 'Room: 201 | Guest: sfsdfg | Period: 2026-03-11 to 2026-03-13', '2026-03-11 13:51:06', '2026-03-11 13:51:06'),
(4, 4, 'INV000031', 14, 8, 1500.00, 0.00, 1500.00, 3033.00, 0.00, '2026-03-11', '2026-03-18', 'Paid', 'Room: 6A | Guest: Ridu | Period: 2026-03-11 to 2026-03-12', '2026-03-11 14:31:51', '2026-03-11 16:08:17'),
(5, 5, 'INV000041', 3, 2, 1500.00, 0.00, 1500.00, 7500.00, 0.00, '2026-03-11', '2026-03-18', 'Paid', 'Room: 102 | Guest: werwe343334 | Period: 2026-03-11 to 2026-03-12', '2026-03-11 14:34:16', '2026-03-11 16:07:34'),
(6, 6, 'INV000051', 15, 9, 1770.00, 0.00, 1770.00, 300.00, 1470.00, '2026-03-11', '2026-03-18', 'Partial', 'Room: 6B | Guest: nafmsad | Period: 2026-03-11 to 2026-03-12', '2026-03-11 17:17:55', '2026-03-11 17:17:55'),
(7, 7, 'INV000061', 6, 2, 1500.00, 0.00, 1500.00, 1500.00, 0.00, '2026-03-11', '2026-03-18', 'Paid', 'Room: 102 | Guest: name | Period: 2026-03-11 to 2026-03-12', '2026-03-11 17:26:48', '2026-03-11 17:33:54'),
(8, 8, 'INV000071', 1, 10, 14160.00, 0.00, 14160.00, 55.00, 14105.00, '2026-03-11', '2026-03-18', 'Partial', 'Room: 6C | Guest: wretrt | Period: 2026-03-12 to 2026-03-20', '2026-03-11 17:32:16', '2026-03-11 17:32:16'),
(9, 9, 'INV000081', 1, 9, 5310.00, 0.00, 5310.00, 44.00, 5266.00, '2026-03-12', '2026-03-19', 'Partial', 'Room: 6B | Guest: wretrt | Period: 2026-03-12 to 2026-03-15', '2026-03-12 09:46:41', '2026-03-12 09:46:41'),
(10, 10, 'INV000091', 1, 2, 3770.00, 0.00, 3770.00, 3770.00, 0.00, '2026-03-12', '2026-03-19', 'Paid', 'Room: 102 | Guest: wretrt | Period: 2026-03-12 to 2026-03-13', '2026-03-12 14:15:41', '2026-03-12 14:23:23'),
(12, 12, 'INV000101', 1, 9, 8850.00, 0.00, 8850.00, 0.00, 8850.00, '2026-03-12', '2026-03-19', 'Pending', 'Room: 6B | Guest: wretrt | Period: 2026-03-20 to 2026-03-25', '2026-03-12 14:24:35', '2026-03-12 14:24:35'),
(13, 11, 'INV000111', 1, 29, 9440.00, 0.00, 9440.00, 421.05, 9018.95, '2026-03-12', '2026-03-19', 'Partial', 'Room: 7K | Guest: wretrt | Period: 2026-03-12 to 2026-03-13', '2026-03-12 17:22:24', '2026-03-12 17:22:24'),
(14, 13, 'INV000121', 16, 8, 1770.00, 0.00, 1770.00, 500.00, 1270.00, '2026-03-13', '2026-03-20', 'Partial', 'Room: 6A | Guest: wretrt | Period: 2026-03-13 to 2026-03-14', '2026-03-13 07:56:43', '2026-03-13 07:56:43'),
(15, 14, 'INV000131', 17, 11, 5900.00, 0.00, 5900.00, 0.00, 5900.00, '2026-03-13', '2026-03-20', 'Pending', 'Room: 6D | Guest: name | Period: 2026-03-15 to 2026-03-17', '2026-03-13 10:41:19', '2026-03-13 10:41:19');

-- --------------------------------------------------------

--
-- Table structure for table `invoice_items`
--

CREATE TABLE `invoice_items` (
  `item_id` int(11) NOT NULL,
  `invoice_id` int(11) NOT NULL,
  `description` varchar(255) NOT NULL,
  `item_type` varchar(50) DEFAULT NULL,
  `quantity` decimal(10,2) DEFAULT 1.00,
  `unit_price` decimal(10,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `invoice_items`
--

INSERT INTO `invoice_items` (`item_id`, `invoice_id`, `description`, `item_type`, `quantity`, `unit_price`, `total_price`, `created_at`) VALUES
(1, 1, 'Room 102 - 2 nights', 'Room', 2.00, 1500.00, 3540.00, '2026-03-11 06:25:28'),
(2, 2, 'Room 201 - 5 nights', 'Room', 5.00, 2500.00, 14750.00, '2026-03-11 13:40:20'),
(3, 3, 'Room 201 - 2 nights', 'Room', 2.00, 2500.00, 5900.00, '2026-03-11 13:51:06'),
(4, 4, 'Room 6A - 1 nights', 'Room', 1.00, 1500.00, 1500.00, '2026-03-11 14:31:51'),
(5, 5, 'Room 102 - 1 nights', 'Room', 1.00, 1500.00, 1500.00, '2026-03-11 14:34:16'),
(6, 6, 'Room 6B - 1 nights', 'Room', 1.00, 1500.00, 1770.00, '2026-03-11 17:17:55'),
(7, 7, 'Room 102 - 1 nights', 'Room', 1.00, 1500.00, 1500.00, '2026-03-11 17:26:48'),
(8, 8, 'Room 6C - 8 nights', 'Room', 8.00, 1500.00, 14160.00, '2026-03-11 17:32:16'),
(9, 9, 'Room 6B - 3 nights', 'Room', 3.00, 1500.00, 5310.00, '2026-03-12 09:46:41'),
(10, 10, 'Room 102 - 1 nights', 'Room', 1.00, 1500.00, 1770.00, '2026-03-12 14:15:41'),
(11, 10, 'ac broken', 'Service', 1.00, 2000.00, 2000.00, '2026-03-12 14:22:55'),
(12, 12, 'Room 6B - 5 nights', 'Room', 5.00, 1500.00, 8850.00, '2026-03-12 14:24:35'),
(13, 13, 'Room 7K - 1 nights', 'Room', 1.00, 8000.00, 9440.00, '2026-03-12 17:22:24'),
(14, 14, 'Room 6A - 1 nights', 'Room', 1.00, 1500.00, 1770.00, '2026-03-13 07:56:43'),
(15, 15, 'Room 6D - 2 nights', 'Room', 2.00, 2500.00, 5900.00, '2026-03-13 10:41:19');

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
(3, 3, 'HVAC', 'AC not cooling properly', 'Critical', 'In Progress', 'Arun', 'Housekeeping Staff', '2026-03-08 06:24:41', NULL, 3500.00, NULL, NULL, 'Compressor may need repair', '2026-03-08 06:24:41', '2026-03-13 10:25:44');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `type` varchar(50) NOT NULL COMMENT 'check_in, check_out, booking, payment, overdue, maintenance, housekeeping, system',
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `reference_type` varchar(50) DEFAULT NULL COMMENT 'booking, guest, room, payment, invoice',
  `reference_id` int(11) DEFAULT NULL,
  `priority` enum('low','normal','high','urgent') DEFAULT 'normal',
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `read_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`notification_id`, `type`, `title`, `message`, `reference_type`, `reference_id`, `priority`, `is_read`, `created_at`, `read_at`) VALUES
(1, 'system', 'Test Notification', 'System is running smoothly', NULL, NULL, 'normal', 1, '2026-03-12 14:57:51', '2026-03-12 16:17:03'),
(2, 'booking', 'New Booking Created', 'John Doe booked Room 101 (2026-03-12 to 2026-03-15)', 'booking', 1, 'normal', 1, '2026-03-12 14:58:03', '2026-03-12 16:16:49'),
(3, 'check_in', 'Guest Checked In', 'Jane Smith checked into Room 205', 'booking', 2, 'high', 1, '2026-03-12 14:58:03', '2026-03-12 16:17:04'),
(4, 'today_checkins', '📅 2 Check-ins Today', '2 guests are expected to check in today', NULL, NULL, 'normal', 1, '2026-03-12 15:14:36', '2026-03-12 16:16:47'),
(5, 'check_in', 'Guest Checked In', 'wretrt checked into Room 7K', 'booking', 11, 'normal', 0, '2026-03-12 17:22:25', NULL),
(6, 'check_out', 'Guest Checked Out', 'wretrt checked out of Room 7K', 'booking', 11, 'normal', 1, '2026-03-12 17:22:38', '2026-03-12 19:14:09'),
(7, 'no_show', '⚠️ Guest No-Show', 'wretrt did not arrive for Room 6B (Expected: Thu Mar 12 2026 06:00:00 GMT+0600 (Bangladesh Standard Time))', 'booking', 9, 'high', 1, '2026-03-12 18:04:43', '2026-03-13 05:19:04'),
(8, 'today_checkouts', '📅 2 Check-outs Today', '2 guests are scheduled to check out today', NULL, NULL, 'normal', 0, '2026-03-12 18:04:43', NULL),
(9, 'booking', 'New Booking Created', 'wretrt booked Room 6A (2026-03-13 to 2026-03-14)', 'booking', 13, 'normal', 0, '2026-03-13 07:56:43', NULL),
(10, 'today_checkins', '📅 1 Check-in Today', '1 guest is expected to check in today', NULL, NULL, 'normal', 1, '2026-03-13 07:58:43', '2026-03-13 10:24:38'),
(11, 'booking', 'New Booking Created', 'name booked Room 6D (2026-03-15 to 2026-03-17)', 'booking', 14, 'normal', 0, '2026-03-13 10:41:20', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`payment_id`, `booking_id`, `invoice_id`, `guest_id`, `amount`, `payment_method`, `payment_type`, `payment_status`, `transaction_id`, `reference_number`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 44.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-11 06:25:28', '2026-03-11 06:25:28'),
(2, 3, 3, 9, 222.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-11 13:51:06', '2026-03-11 13:51:06'),
(3, 5, 5, 3, 1500.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Quick payment - full amount', '2026-03-11 15:30:51', '2026-03-11 15:30:51'),
(4, 5, 5, 3, 1500.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Quick payment - full amount', '2026-03-11 15:31:24', '2026-03-11 15:31:24'),
(5, 5, 5, 3, 1500.00, 'Cash', 'Payment', 'Completed', NULL, NULL, '33', '2026-03-11 15:31:43', '2026-03-11 15:31:43'),
(6, 4, 4, 14, 1500.00, 'Cash', 'Payment', 'Completed', NULL, '44', 'd', '2026-03-11 15:55:03', '2026-03-11 15:55:03'),
(7, 4, 4, 14, 1500.00, 'Cash', 'Payment', 'Completed', NULL, '44', 'd', '2026-03-11 15:55:08', '2026-03-11 15:55:08'),
(8, 5, 5, 3, 1500.00, 'Cash', 'Payment', 'Completed', NULL, '44s', 'f', '2026-03-11 16:04:47', '2026-03-11 16:04:47'),
(9, 5, 5, 3, 1500.00, 'Cash', 'Payment', 'Completed', NULL, '1234335', 'd', '2026-03-11 16:07:34', '2026-03-11 16:07:34'),
(10, 4, 4, 14, 33.00, 'Cash', 'Payment', 'Completed', NULL, '5', 'f', '2026-03-11 16:08:17', '2026-03-11 16:08:17'),
(11, 1, 1, 1, 100.00, 'Cash', 'Payment', 'Completed', NULL, NULL, NULL, '2026-03-11 16:21:12', '2026-03-11 16:21:12'),
(12, 1, 99999, 1, 100.00, 'Cash', 'Payment', 'Completed', NULL, NULL, NULL, '2026-03-11 16:23:43', '2026-03-11 16:23:43'),
(13, 1, 99999, 1, 100.00, 'Cash', 'Payment', 'Completed', NULL, NULL, NULL, '2026-03-11 16:23:45', '2026-03-11 16:23:45'),
(14, 1, 99999, 1, 100.00, 'Cash', 'Payment', 'Completed', NULL, NULL, NULL, '2026-03-11 16:24:58', '2026-03-11 16:24:58'),
(15, 1, 99999, 1, 100.00, 'Cash', 'Payment', 'Completed', NULL, NULL, NULL, '2026-03-11 16:25:09', '2026-03-11 16:25:09'),
(16, 1, 99999, 1, 100.00, 'Cash', 'Payment', 'Completed', NULL, NULL, NULL, '2026-03-11 16:25:11', '2026-03-11 16:25:11'),
(17, 6, 6, 15, 300.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-11 17:17:55', '2026-03-11 17:17:55'),
(18, 8, 8, 1, 55.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-11 17:32:16', '2026-03-11 17:32:16'),
(19, 7, 7, 6, 1500.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Checkout balance payment', '2026-03-11 17:33:54', '2026-03-11 17:33:54'),
(20, 9, 9, 1, 44.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-12 09:46:41', '2026-03-12 09:46:41'),
(21, 10, 10, 1, 78.95, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-12 14:15:41', '2026-03-12 14:15:41'),
(22, 10, 10, 1, 1691.05, 'Cash', 'Payment', 'Completed', NULL, '534', 'sdf', '2026-03-12 14:16:37', '2026-03-12 14:16:37'),
(23, 10, 10, 1, 2000.00, 'Cash', 'Payment', 'Completed', NULL, '243', 'dgf', '2026-03-12 14:23:23', '2026-03-12 14:23:23'),
(24, 11, 13, 1, 421.05, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-12 17:22:24', '2026-03-12 17:22:24'),
(25, 13, 14, 16, 500.00, 'Cash', 'Payment', 'Completed', NULL, NULL, 'Advance payment (paid at booking)', '2026-03-13 07:56:43', '2026-03-13 07:56:43');

-- --------------------------------------------------------

--
-- Stand-in structure for view `payment_summary`
-- (See below for the actual view)
--
CREATE TABLE `payment_summary` (
`payment_id` int(11)
,`booking_id` int(11)
,`invoice_id` int(11)
,`guest_id` int(11)
,`amount` decimal(10,2)
,`payment_method` enum('Cash','Card','UPI','Online','Cheque')
,`payment_status` enum('Pending','Completed','Failed','Cancelled')
,`transaction_id` varchar(100)
,`reference_number` varchar(100)
,`notes` text
,`created_at` timestamp
,`updated_at` timestamp
,`guest_name` varchar(100)
,`guest_email` varchar(100)
,`check_in` date
,`check_out` date
,`room_number` varchar(10)
);

-- --------------------------------------------------------

--
-- Table structure for table `refunds`
--

CREATE TABLE `refunds` (
  `refund_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(2, '102', 'Single', 1500.00, 1, 2, 'Booked', 'Single room with city view', 'WiFi, TV, AC', '2026-03-08 06:24:41', '2026-03-12 14:16:14'),
(3, '201', 'Double', 2500.00, 1, 2, '', 'Spacious double room', 'WiFi, TV, AC, Mini-bar', '2026-03-08 06:24:41', '2026-03-11 17:45:48'),
(8, '6A', 'Single', 1500.00, 1, 2, 'Available', '6th floor single room with city view', 'WiFi, TV, AC', '2026-03-11 14:21:16', '2026-03-11 17:12:24'),
(9, '6B', 'Single', 1500.00, 1, 2, 'Available', '6th floor single room, garden-facing', 'WiFi, TV, AC', '2026-03-11 14:21:16', '2026-03-11 17:20:35'),
(10, '6C', 'Single', 1500.00, 1, 2, '', '6th floor cozy single room', 'WiFi, TV, AC', '2026-03-11 14:21:16', '2026-03-11 17:45:48'),
(11, '6D', 'Double', 2500.00, 1, 2, 'Available', '6th floor double room with balcony', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(12, '6E', 'Double', 2500.00, 1, 2, 'Available', '6th floor spacious double room', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(13, '6F', 'Double', 2500.00, 1, 2, 'Available', '6th floor double room, city view', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(14, '6G', 'Double', 2500.00, 1, 2, 'Available', '6th floor double room, quiet wing', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(15, '6H', 'Deluxe', 4000.00, 1, 3, 'Available', '6th floor deluxe room with premium décor', 'WiFi, TV, AC, Mini-bar, Safe', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(16, '6I', 'Deluxe', 4000.00, 1, 3, 'Available', '6th floor deluxe room, panoramic view', 'WiFi, TV, AC, Mini-bar, Safe', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(17, '6J', 'Deluxe', 4500.00, 2, 4, 'Available', '6th floor deluxe twin room', 'WiFi, TV, AC, Mini-bar, Safe, Bathtub', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(18, '6K', 'Suite', 6000.00, 2, 4, 'Available', '6th floor suite with separate living area', 'WiFi, TV, AC, Mini-bar, Jacuzzi, Safe, Bathtub', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(19, '7A', 'Single', 1800.00, 1, 2, 'Available', '7th floor single room with great view', 'WiFi, TV, AC', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(20, '7B', 'Single', 1800.00, 1, 2, 'Available', '7th floor single room, quiet side', 'WiFi, TV, AC', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(21, '7C', 'Double', 2800.00, 1, 2, 'Available', '7th floor double room, city view', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(22, '7D', 'Double', 2800.00, 1, 2, 'Available', '7th floor double room with balcony', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(23, '7E', 'Double', 2800.00, 1, 2, 'Available', '7th floor spacious double room', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(24, '7F', 'Double', 2800.00, 1, 2, 'Available', '7th floor double room, corner unit', 'WiFi, TV, AC, Mini-bar', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(25, '7G', 'Deluxe', 4500.00, 1, 3, 'Available', '7th floor deluxe room, premium furnishing', 'WiFi, TV, AC, Mini-bar, Safe, Bathtub', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(26, '7H', 'Deluxe', 4500.00, 1, 3, 'Available', '7th floor deluxe room with skyline view', 'WiFi, TV, AC, Mini-bar, Safe, Bathtub', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(27, '7I', 'Deluxe', 5000.00, 2, 4, 'Available', '7th floor deluxe twin, top-floor comfort', 'WiFi, TV, AC, Mini-bar, Safe, Bathtub', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(28, '7J', 'Suite', 7000.00, 2, 4, 'Available', '7th floor premium suite with living room', 'WiFi, TV, AC, Mini-bar, Jacuzzi, Safe, Bathtub, Kitchen', '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(29, '7K', 'Suite', 8000.00, 2, 4, 'Available', '7th floor presidential suite, full amenities', 'WiFi, TV, AC, Mini-bar, Jacuzzi, Safe, Bathtub, Kitchen, Butler', '2026-03-11 14:21:16', '2026-03-12 17:22:38');

-- --------------------------------------------------------

--
-- Table structure for table `room_assets`
--

CREATE TABLE `room_assets` (
  `asset_id` int(11) NOT NULL,
  `asset_name` varchar(100) NOT NULL,
  `category_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `quantity_per_room` int(11) NOT NULL DEFAULT 1,
  `room_type` enum('Single','Double','Suite','Deluxe') DEFAULT NULL COMMENT 'NULL = applies to all room types',
  `is_critical` tinyint(1) DEFAULT 0,
  `estimated_value` decimal(10,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `room_asset_history`
--

CREATE TABLE `room_asset_history` (
  `history_id` int(11) NOT NULL,
  `instance_id` int(11) NOT NULL,
  `room_id` int(11) DEFAULT NULL,
  `action_type` enum('Added','Removed','Moved','Condition Changed','Maintenance','Inspected') NOT NULL,
  `previous_room_id` int(11) DEFAULT NULL,
  `previous_condition` varchar(50) DEFAULT NULL,
  `new_condition` varchar(50) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `performed_by` varchar(100) DEFAULT NULL,
  `performed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `room_asset_instances`
--

CREATE TABLE `room_asset_instances` (
  `instance_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(2, 2, 'Dirty', NULL, NULL, 'Initial setup', '2026-03-08 06:24:41', '2026-03-11 06:25:42'),
(3, 3, 'Dirty', NULL, NULL, 'Initial setup', '2026-03-08 06:24:41', '2026-03-11 13:40:32'),
(8, 8, 'Dirty', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 17:12:24'),
(9, 9, 'Dirty', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 17:20:35'),
(10, 10, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(11, 11, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(12, 12, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(13, 13, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(14, 14, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(15, 15, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(16, 16, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(17, 17, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(18, 18, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(19, 19, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(20, 20, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(21, 21, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(22, 22, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(23, 23, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(24, 24, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(25, 25, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(26, 26, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(27, 27, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(28, 28, 'Clean', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-11 14:21:16'),
(29, 29, 'Dirty', NULL, NULL, NULL, '2026-03-11 14:21:16', '2026-03-12 17:22:38');

-- --------------------------------------------------------

--
-- Table structure for table `room_inspections`
--

CREATE TABLE `room_inspections` (
  `inspection_id` int(11) NOT NULL,
  `booking_id` int(11) NOT NULL,
  `room_id` int(11) NOT NULL,
  `inspector_name` varchar(100) DEFAULT NULL,
  `general_notes` text DEFAULT NULL,
  `overall_status` enum('Pass','Fail','Missing Items','Damaged Items','Issues Found') DEFAULT 'Pass',
  `inspection_completed` tinyint(1) DEFAULT 0,
  `inspection_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `room_inspection_checklist`
-- (See below for the actual view)
--
CREATE TABLE `room_inspection_checklist` (
`room_id` int(11)
,`room_number` varchar(10)
,`room_type` enum('Single','Double','Suite','Deluxe')
,`asset_id` int(11)
,`asset_name` varchar(100)
,`category_name` varchar(100)
,`quantity_per_room` int(11)
,`is_critical` tinyint(1)
,`estimated_value` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `salary_payment_transactions`
--

CREATE TABLE `salary_payment_transactions` (
  `transaction_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `salary_payment_transactions`
--

INSERT INTO `salary_payment_transactions` (`transaction_id`, `salary_id`, `staff_id`, `payment_month`, `transaction_type`, `amount`, `payment_date`, `payment_method`, `payment_reference`, `notes`, `created_at`, `updated_at`) VALUES
(1, 6, 10, '2026-03', 'Final', 23000.00, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 07:23:53', '2026-03-13 07:23:53'),
(2, 8, 2, '2026-05', 'Advance', 5000.00, '2026-03-10', 'Cash', 'ADV001', NULL, '2026-03-13 07:32:11', '2026-03-13 07:32:11'),
(3, 8, 2, '2026-05', 'Final', 15000.00, '2026-03-13', 'Bank Transfer', 'FIN001', NULL, '2026-03-13 07:32:11', '2026-03-13 07:32:11'),
(4, 7, 1, '2026-04', 'Advance', 19999.99, '2026-03-13', 'Cash', NULL, NULL, '2026-03-13 07:36:14', '2026-03-13 07:36:14'),
(5, 5, 10, '2026-03', 'Advance', 22999.97, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 07:39:15', '2026-03-13 07:39:15'),
(6, 9, 3, '2026-06', 'Final', 15000.50, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 07:39:43', '2026-03-13 07:39:43'),
(7, 3, 6, '2026-03', 'Advance', 49999.98, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 07:39:56', '2026-03-13 07:39:56'),
(8, 11, 3, '2026-08', 'Final', 15000.50, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 07:40:30', '2026-03-13 07:40:30'),
(9, 12, 2, '2026-08', 'Advance', 10000.16, '2026-03-10', 'Cash', NULL, NULL, '2026-03-13 07:40:30', '2026-03-13 07:40:30'),
(10, 12, 2, '2026-08', 'Final', 10000.17, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 07:40:30', '2026-03-13 07:40:30'),
(11, 13, 1, '2026-09', 'Final', 20000.00, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:06:39', '2026-03-13 08:06:39'),
(12, 14, 2, '2026-09', 'Final', 19999.99, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:06:40', '2026-03-13 08:06:40'),
(13, 15, 3, '2026-09', 'Advance', 10000.01, '2026-03-10', 'Cash', NULL, NULL, '2026-03-13 08:06:40', '2026-03-13 08:06:40'),
(14, 16, 11, '2026-03', 'Final', 11999.99, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:24:41', '2026-03-13 08:24:41'),
(15, 19, 11, '2026-06', 'Final', 10300.00, '2026-03-13', 'Bank Transfer', NULL, 'June salary payment', '2026-03-13 08:26:33', '2026-03-13 08:26:33'),
(16, 20, 11, '2026-07', 'Final', 10300.00, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:26:46', '2026-03-13 08:26:46'),
(17, 21, 11, '2026-08', 'Final', 10300.00, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:26:54', '2026-03-13 08:26:54'),
(18, 18, 11, '2026-05', 'Final', 10299.99, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:29:32', '2026-03-13 08:29:32'),
(19, 17, 1, '2026-05', 'Final', 3249.99, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:47:49', '2026-03-13 08:47:49'),
(20, 15, 3, '2026-09', 'Advance', 9999.99, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:48:09', '2026-03-13 08:48:09'),
(21, 4, 6, '2026-03', 'Final', 49999.99, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:48:48', '2026-03-13 08:48:48'),
(22, 23, 10, '2026-09', 'Final', 23000.00, '2026-03-13', 'Bank Transfer', NULL, NULL, '2026-03-13 08:51:11', '2026-03-13 08:51:11');

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
,`order_status` enum('Pending','InProgress','Completed','Invoiced','Cancelled')
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
-- Table structure for table `staff_salaries`
--

CREATE TABLE `staff_salaries` (
  `salary_id` int(11) NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `staff_salaries`
--

INSERT INTO `staff_salaries` (`salary_id`, `staff_id`, `payment_month`, `base_salary`, `bonus`, `deductions`, `overtime_hours`, `overtime_amount`, `total_amount`, `payment_date`, `payment_method`, `payment_reference`, `payment_status`, `notes`, `created_at`, `updated_at`) VALUES
(1, 1, '2026-03', 12000.00, 2000.00, 0.00, 0.00, 0.00, 14000.00, '2026-03-13', 'Cash', '', 'Paid', '', '2026-03-13 05:29:33', '2026-03-13 06:34:54'),
(2, 6, '2026-03', 50000.00, 0.00, 0.00, 0.00, 0.00, 50000.00, '2026-03-13', 'Cash', '', 'Pending', '', '2026-03-13 06:59:21', '2026-03-13 06:59:21'),
(3, 6, '2026-03', 50000.00, 0.00, 0.00, 0.00, 0.00, 50000.00, '2026-03-13', 'Cash', '', 'Partially Paid', '', '2026-03-13 06:59:22', '2026-03-13 07:39:56'),
(4, 6, '2026-03', 50000.00, 0.00, 0.00, 0.00, 0.00, 50000.00, '2026-03-13', 'Cash', '', 'Partially Paid', '', '2026-03-13 06:59:23', '2026-03-13 08:48:48'),
(5, 10, '2026-03', 23000.00, 0.00, 0.00, 0.00, 0.00, 23000.00, '2026-03-13', 'Cash', '', 'Partially Paid', '', '2026-03-13 07:12:38', '2026-03-13 07:39:15'),
(6, 10, '2026-03', 23000.00, 0.00, 0.00, 0.00, 0.00, 23000.00, '2026-03-13', 'Cash', '', 'Paid', '', '2026-03-13 07:12:39', '2026-03-13 07:23:53'),
(7, 1, '2026-04', 20000.00, 0.00, 0.00, 0.00, 0.00, 20000.00, '2026-03-13', 'Bank Transfer', NULL, 'Partially Paid', 'Test salary - should have full balance', '2026-03-13 07:31:44', '2026-03-13 07:36:14'),
(8, 2, '2026-05', 20000.00, 0.00, 0.00, 0.00, 0.00, 20000.00, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Test salary - should have full balance', '2026-03-13 07:32:11', '2026-03-13 07:32:11'),
(9, 3, '2026-06', 15000.50, 0.00, 0.00, 0.00, 0.00, 15000.50, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Precision test salary', '2026-03-13 07:39:43', '2026-03-13 07:39:43'),
(11, 3, '2026-08', 15000.50, 0.00, 0.00, 0.00, 0.00, 15000.50, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Precision test salary', '2026-03-13 07:40:30', '2026-03-13 07:40:30'),
(12, 2, '2026-08', 20000.33, 0.00, 0.00, 0.00, 0.00, 20000.33, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Another precision test', '2026-03-13 07:40:30', '2026-03-13 07:40:30'),
(13, 1, '2026-09', 20000.00, 0.00, 0.00, 0.00, 0.00, 20000.00, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Test full payment', '2026-03-13 08:06:39', '2026-03-13 08:06:39'),
(14, 2, '2026-09', 19999.99, 0.00, 0.00, 0.00, 0.00, 19999.99, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Test with 0.01 decimal', '2026-03-13 08:06:39', '2026-03-13 08:06:40'),
(15, 3, '2026-09', 20000.00, 0.00, 0.00, 0.00, 0.00, 20000.00, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Test partial payment', '2026-03-13 08:06:40', '2026-03-13 08:48:09'),
(16, 11, '2026-03', 9000.00, 3000.00, 0.00, 0.00, 0.00, 12000.00, '2026-03-13', 'Cash', '', 'Partially Paid', '', '2026-03-13 08:11:21', '2026-03-13 08:24:41'),
(17, 1, '2026-05', 0.00, 1500.00, 750.00, 0.00, 2500.00, 3250.00, '2026-03-13', 'Bank Transfer', NULL, 'Partially Paid', 'May test salary', '2026-03-13 08:25:54', '2026-03-13 08:47:49'),
(18, 11, '2026-05', 9000.00, 500.00, 200.00, 0.00, 1000.00, 10300.00, '2026-03-13', 'Bank Transfer', NULL, 'Partially Paid', 'May monthly test', '2026-03-13 08:26:08', '2026-03-13 08:29:32'),
(19, 11, '2026-06', 9000.00, 500.00, 200.00, 0.00, 1000.00, 10300.00, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'June monthly test', '2026-03-13 08:26:33', '2026-03-13 08:26:33'),
(20, 11, '2026-07', 9000.00, 500.00, 200.00, 0.00, 1000.00, 10300.00, '2026-03-13', 'Bank Transfer', NULL, 'Paid', 'Test', '2026-03-13 08:26:46', '2026-03-13 08:26:46'),
(21, 11, '2026-08', 9000.00, 500.00, 200.00, 0.00, 1000.00, 10300.00, '2026-03-13', 'Bank Transfer', NULL, 'Paid', NULL, '2026-03-13 08:26:54', '2026-03-13 08:26:54'),
(22, 9, '2026-03', 18000.00, 1999.99, 0.00, 0.00, 0.00, 19999.99, '2026-03-13', 'Cash', '', 'Pending', '', '2026-03-13 08:28:28', '2026-03-13 08:28:28'),
(23, 10, '2026-09', 23000.00, 0.00, 0.00, 0.00, 0.00, 23000.00, '2026-03-13', 'Bank Transfer', NULL, 'Paid', NULL, '2026-03-13 08:51:11', '2026-03-13 08:51:11'),
(24, 13, '2026-03', 8000.00, 1999.99, 0.00, 0.00, 0.00, 9999.99, '2026-03-13', 'Bank Transfer', NULL, 'Pending', '', '2026-03-13 09:07:01', '2026-03-13 09:07:01'),
(26, 13, '2026-06', 10000.00, 0.00, 0.00, 0.00, 0.00, 10000.00, '2026-03-13', 'Bank Transfer', NULL, 'Pending', NULL, '2026-03-13 09:09:57', '2026-03-13 09:09:57');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_room_asset_inventory`
-- (See below for the actual view)
--
CREATE TABLE `v_room_asset_inventory` (
`instance_id` int(11)
,`room_id` int(11)
,`asset_name` varchar(100)
,`category_id` int(11)
,`description` text
,`serial_number` varchar(100)
,`barcode` varchar(100)
,`purchase_date` date
,`purchase_cost` decimal(10,2)
,`current_condition` enum('New','Good','Fair','Poor','Damaged')
,`is_functional` tinyint(1)
,`last_maintenance_date` date
,`next_maintenance_date` date
,`warranty_expiry` date
,`notes` text
,`created_by` varchar(100)
,`created_at` timestamp
,`updated_at` timestamp
,`category_name` varchar(100)
,`room_number` varchar(10)
,`room_type` enum('Single','Double','Suite','Deluxe')
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_room_asset_summary`
-- (See below for the actual view)
--
CREATE TABLE `v_room_asset_summary` (
`room_id` int(11)
,`room_number` varchar(10)
,`room_type` enum('Single','Double','Suite','Deluxe')
,`total_assets` bigint(21)
,`functional_count` decimal(22,0)
,`non_functional_count` decimal(22,0)
,`needs_maintenance_count` decimal(22,0)
,`total_value` decimal(32,2)
);

-- --------------------------------------------------------

--
-- Structure for view `booking_details`
--
DROP TABLE IF EXISTS `booking_details`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `booking_details`  AS SELECT `b`.`booking_id` AS `booking_id`, `b`.`guest_id` AS `guest_id`, `b`.`room_id` AS `room_id`, `b`.`check_in` AS `check_in`, `b`.`check_out` AS `check_out`, `b`.`number_of_guests` AS `number_of_guests`, `b`.`number_of_nights` AS `number_of_nights`, `b`.`room_price` AS `room_price`, `b`.`total_amount` AS `total_amount`, `b`.`advance_payment` AS `advance_payment`, `b`.`payment_status` AS `payment_status`, `b`.`payment_method` AS `payment_method`, `b`.`discount_type` AS `discount_type`, `b`.`discount_value` AS `discount_value`, `b`.`discount_reason` AS `discount_reason`, `b`.`booking_source` AS `booking_source`, `b`.`booking_status` AS `booking_status`, `b`.`special_requests` AS `special_requests`, `b`.`cancellation_reason` AS `cancellation_reason`, `b`.`actual_checkin_time` AS `actual_checkin_time`, `b`.`actual_checkout_time` AS `actual_checkout_time`, `b`.`checkout_type` AS `checkout_type`, `b`.`is_early_checkout` AS `is_early_checkout`, `b`.`late_checkout_fee` AS `late_checkout_fee`, `b`.`early_checkout_reason` AS `early_checkout_reason`, `b`.`is_extension` AS `is_extension`, `b`.`parent_booking_id` AS `parent_booking_id`, `b`.`booking_group_id` AS `booking_group_id`, `b`.`created_at` AS `created_at`, `b`.`updated_at` AS `updated_at`, `g`.`name` AS `guest_name`, `g`.`phone` AS `guest_phone`, `g`.`email` AS `guest_email`, `r`.`room_number` AS `room_number`, `r`.`room_type` AS `room_type`, `r`.`price` AS `current_room_price` FROM ((`bookings` `b` join `guests` `g` on(`b`.`guest_id` = `g`.`guest_id`)) join `rooms` `r` on(`b`.`room_id` = `r`.`room_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `booking_details_enhanced`
--
DROP TABLE IF EXISTS `booking_details_enhanced`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `booking_details_enhanced`  AS SELECT `b`.`booking_id` AS `booking_id`, `b`.`guest_id` AS `guest_id`, `b`.`room_id` AS `room_id`, `b`.`check_in` AS `check_in`, `b`.`check_out` AS `check_out`, `b`.`number_of_guests` AS `number_of_guests`, `b`.`number_of_nights` AS `number_of_nights`, `b`.`room_price` AS `room_price`, `b`.`total_amount` AS `total_amount`, `b`.`advance_payment` AS `advance_payment`, `b`.`payment_status` AS `payment_status`, `b`.`payment_method` AS `payment_method`, `b`.`discount_type` AS `discount_type`, `b`.`discount_value` AS `discount_value`, `b`.`discount_reason` AS `discount_reason`, `b`.`booking_source` AS `booking_source`, `b`.`booking_status` AS `booking_status`, `b`.`special_requests` AS `special_requests`, `b`.`cancellation_reason` AS `cancellation_reason`, `b`.`actual_checkin_time` AS `actual_checkin_time`, `b`.`actual_checkout_time` AS `actual_checkout_time`, `b`.`checkout_type` AS `checkout_type`, `b`.`is_early_checkout` AS `is_early_checkout`, `b`.`late_checkout_fee` AS `late_checkout_fee`, `b`.`early_checkout_reason` AS `early_checkout_reason`, `b`.`is_extension` AS `is_extension`, `b`.`parent_booking_id` AS `parent_booking_id`, `b`.`booking_group_id` AS `booking_group_id`, `b`.`created_at` AS `created_at`, `b`.`updated_at` AS `updated_at`, `g`.`name` AS `guest_name`, `g`.`phone` AS `guest_phone`, `g`.`email` AS `guest_email`, `r`.`room_number` AS `room_number`, `r`.`room_type` AS `room_type`, `r`.`price` AS `current_room_price` FROM ((`bookings` `b` join `guests` `g` on(`b`.`guest_id` = `g`.`guest_id`)) join `rooms` `r` on(`b`.`room_id` = `r`.`room_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `inspection_summary`
--
DROP TABLE IF EXISTS `inspection_summary`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `inspection_summary`  AS SELECT `ri`.`inspection_id` AS `inspection_id`, `ri`.`booking_id` AS `booking_id`, `ri`.`room_id` AS `room_id`, `ri`.`inspector_name` AS `inspector_name`, `ri`.`general_notes` AS `general_notes`, `ri`.`overall_status` AS `overall_status`, `ri`.`inspection_completed` AS `inspection_completed`, `ri`.`inspection_date` AS `inspection_date`, `ri`.`completed_at` AS `completed_at`, `ri`.`created_at` AS `created_at`, `ri`.`updated_at` AS `updated_at`, `r`.`room_number` AS `room_number`, `r`.`room_type` AS `room_type`, `g`.`name` AS `guest_name`, `g`.`phone` AS `guest_phone` FROM (((`room_inspections` `ri` join `rooms` `r` on(`ri`.`room_id` = `r`.`room_id`)) join `bookings` `b` on(`ri`.`booking_id` = `b`.`booking_id`)) join `guests` `g` on(`b`.`guest_id` = `g`.`guest_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `payment_summary`
--
DROP TABLE IF EXISTS `payment_summary`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `payment_summary`  AS SELECT `p`.`payment_id` AS `payment_id`, `p`.`booking_id` AS `booking_id`, `p`.`invoice_id` AS `invoice_id`, `p`.`guest_id` AS `guest_id`, `p`.`amount` AS `amount`, `p`.`payment_method` AS `payment_method`, `p`.`payment_status` AS `payment_status`, `p`.`transaction_id` AS `transaction_id`, `p`.`reference_number` AS `reference_number`, `p`.`notes` AS `notes`, `p`.`created_at` AS `created_at`, `p`.`updated_at` AS `updated_at`, `g`.`name` AS `guest_name`, `g`.`email` AS `guest_email`, `b`.`check_in` AS `check_in`, `b`.`check_out` AS `check_out`, `r`.`room_number` AS `room_number` FROM (((`payments` `p` left join `guests` `g` on(`p`.`guest_id` = `g`.`guest_id`)) left join `bookings` `b` on(`p`.`booking_id` = `b`.`booking_id`)) left join `rooms` `r` on(`b`.`room_id` = `r`.`room_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `room_inspection_checklist`
--
DROP TABLE IF EXISTS `room_inspection_checklist`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `room_inspection_checklist`  AS SELECT `r`.`room_id` AS `room_id`, `r`.`room_number` AS `room_number`, `r`.`room_type` AS `room_type`, `ra`.`asset_id` AS `asset_id`, `ra`.`asset_name` AS `asset_name`, `ac`.`category_name` AS `category_name`, `ra`.`quantity_per_room` AS `quantity_per_room`, `ra`.`is_critical` AS `is_critical`, `ra`.`estimated_value` AS `estimated_value` FROM ((`rooms` `r` join `room_assets` `ra` on(`ra`.`room_type` is null or `ra`.`room_type` = `r`.`room_type`)) left join `asset_categories` `ac` on(`ra`.`category_id` = `ac`.`category_id`)) ORDER BY `r`.`room_id` ASC, `ac`.`category_name` ASC, `ra`.`asset_name` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `service_order_details`
--
DROP TABLE IF EXISTS `service_order_details`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `service_order_details`  AS SELECT `so`.`order_id` AS `order_id`, `so`.`quantity` AS `quantity`, `so`.`unit_price` AS `unit_price`, `so`.`total_price` AS `total_price`, `so`.`order_status` AS `order_status`, `so`.`special_instructions` AS `special_instructions`, `so`.`ordered_at` AS `ordered_at`, `so`.`completed_at` AS `completed_at`, `s`.`service_name` AS `service_name`, `s`.`category` AS `category`, `b`.`booking_id` AS `booking_id`, `g`.`name` AS `guest_name`, `g`.`phone` AS `guest_phone`, `r`.`room_number` AS `room_number` FROM ((((`service_orders` `so` join `services` `s` on(`so`.`service_id` = `s`.`service_id`)) join `bookings` `b` on(`so`.`booking_id` = `b`.`booking_id`)) join `guests` `g` on(`b`.`guest_id` = `g`.`guest_id`)) join `rooms` `r` on(`b`.`room_id` = `r`.`room_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_room_asset_inventory`
--
DROP TABLE IF EXISTS `v_room_asset_inventory`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `v_room_asset_inventory`  AS SELECT `rai`.`instance_id` AS `instance_id`, `rai`.`room_id` AS `room_id`, `rai`.`asset_name` AS `asset_name`, `rai`.`category_id` AS `category_id`, `rai`.`description` AS `description`, `rai`.`serial_number` AS `serial_number`, `rai`.`barcode` AS `barcode`, `rai`.`purchase_date` AS `purchase_date`, `rai`.`purchase_cost` AS `purchase_cost`, `rai`.`current_condition` AS `current_condition`, `rai`.`is_functional` AS `is_functional`, `rai`.`last_maintenance_date` AS `last_maintenance_date`, `rai`.`next_maintenance_date` AS `next_maintenance_date`, `rai`.`warranty_expiry` AS `warranty_expiry`, `rai`.`notes` AS `notes`, `rai`.`created_by` AS `created_by`, `rai`.`created_at` AS `created_at`, `rai`.`updated_at` AS `updated_at`, `ac`.`category_name` AS `category_name`, `r`.`room_number` AS `room_number`, `r`.`room_type` AS `room_type` FROM ((`room_asset_instances` `rai` left join `asset_categories` `ac` on(`rai`.`category_id` = `ac`.`category_id`)) left join `rooms` `r` on(`rai`.`room_id` = `r`.`room_id`)) ;

-- --------------------------------------------------------

--
-- Structure for view `v_room_asset_summary`
--
DROP TABLE IF EXISTS `v_room_asset_summary`;

CREATE ALGORITHM=UNDEFINED  SQL SECURITY DEFINER VIEW `v_room_asset_summary`  AS SELECT `r`.`room_id` AS `room_id`, `r`.`room_number` AS `room_number`, `r`.`room_type` AS `room_type`, count(`rai`.`instance_id`) AS `total_assets`, sum(case when `rai`.`is_functional` = 1 then 1 else 0 end) AS `functional_count`, sum(case when `rai`.`is_functional` = 0 then 1 else 0 end) AS `non_functional_count`, sum(case when `rai`.`next_maintenance_date` is not null and `rai`.`next_maintenance_date` <= curdate() then 1 else 0 end) AS `needs_maintenance_count`, coalesce(sum(`rai`.`purchase_cost`),0) AS `total_value` FROM (`rooms` `r` left join `room_asset_instances` `rai` on(`r`.`room_id` = `rai`.`room_id`)) GROUP BY `r`.`room_id`, `r`.`room_number`, `r`.`room_type` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `asset_categories`
--
ALTER TABLE `asset_categories`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `uq_category_name` (`category_name`);

--
-- Indexes for table `asset_charges`
--
ALTER TABLE `asset_charges`
  ADD PRIMARY KEY (`charge_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_guest_id` (`guest_id`),
  ADD KEY `idx_payment_status` (`payment_status`),
  ADD KEY `asset_charges_ibfk_1` (`inspection_item_id`);

--
-- Indexes for table `billing_settings`
--
ALTER TABLE `billing_settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

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
-- Indexes for table `expense_records`
--
ALTER TABLE `expense_records`
  ADD PRIMARY KEY (`expense_id`),
  ADD KEY `idx_expense_date` (`expense_date`),
  ADD KEY `idx_expense_type` (`expense_type`),
  ADD KEY `idx_payment_status` (`payment_status`);

--
-- Indexes for table `financial_management`
--
ALTER TABLE `financial_management`
  ADD PRIMARY KEY (`financial_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_transaction_date` (`transaction_date`);

--
-- Indexes for table `guests`
--
ALTER TABLE `guests`
  ADD PRIMARY KEY (`guest_id`);

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
-- Indexes for table `hotel_policies`
--
ALTER TABLE `hotel_policies`
  ADD PRIMARY KEY (`policy_id`),
  ADD UNIQUE KEY `uq_policy_name` (`policy_name`);

--
-- Indexes for table `hotel_users`
--
ALTER TABLE `hotel_users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_hotel_users_username` (`username`),
  ADD KEY `idx_hotel_users_role` (`role`),
  ADD KEY `idx_hotel_users_active` (`is_active`);

--
-- Indexes for table `housekeeping_staff`
--
ALTER TABLE `housekeeping_staff`
  ADD PRIMARY KEY (`staff_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_role` (`role`);

--
-- Indexes for table `income_records`
--
ALTER TABLE `income_records`
  ADD PRIMARY KEY (`income_id`),
  ADD KEY `idx_income_date` (`income_date`),
  ADD KEY `idx_income_type` (`income_type`),
  ADD KEY `idx_booking_id` (`booking_id`);

--
-- Indexes for table `inspection_items`
--
ALTER TABLE `inspection_items`
  ADD PRIMARY KEY (`inspection_item_id`),
  ADD KEY `idx_inspection_id` (`inspection_id`),
  ADD KEY `idx_asset_id` (`asset_id`);

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
-- Indexes for table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`invoice_id`),
  ADD UNIQUE KEY `invoice_number` (`invoice_number`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_guest_id` (`guest_id`),
  ADD KEY `idx_payment_status` (`payment_status`),
  ADD KEY `idx_invoice_date` (`invoice_date`),
  ADD KEY `invoices_ibfk_3` (`room_id`);

--
-- Indexes for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD PRIMARY KEY (`item_id`),
  ADD KEY `idx_invoice_id` (`invoice_id`);

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
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_is_read` (`is_read`),
  ADD KEY `idx_type` (`type`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_priority` (`priority`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `guest_id` (`guest_id`),
  ADD KEY `payment_status` (`payment_status`);

--
-- Indexes for table `refunds`
--
ALTER TABLE `refunds`
  ADD PRIMARY KEY (`refund_id`),
  ADD KEY `payment_id` (`payment_id`),
  ADD KEY `booking_id` (`booking_id`),
  ADD KEY `guest_id` (`guest_id`),
  ADD KEY `refund_status` (`refund_status`),
  ADD KEY `idx_refunds_invoice_id` (`invoice_id`);

--
-- Indexes for table `rooms`
--
ALTER TABLE `rooms`
  ADD PRIMARY KEY (`room_id`),
  ADD UNIQUE KEY `room_number` (`room_number`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_room_type` (`room_type`);

--
-- Indexes for table `room_assets`
--
ALTER TABLE `room_assets`
  ADD PRIMARY KEY (`asset_id`),
  ADD KEY `idx_category_id` (`category_id`),
  ADD KEY `idx_room_type` (`room_type`);

--
-- Indexes for table `room_asset_history`
--
ALTER TABLE `room_asset_history`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `idx_instance_id` (`instance_id`),
  ADD KEY `idx_room_id` (`room_id`),
  ADD KEY `idx_performed_at` (`performed_at`);

--
-- Indexes for table `room_asset_instances`
--
ALTER TABLE `room_asset_instances`
  ADD PRIMARY KEY (`instance_id`),
  ADD KEY `idx_room_id` (`room_id`),
  ADD KEY `idx_category_id` (`category_id`),
  ADD KEY `idx_condition` (`current_condition`);

--
-- Indexes for table `room_cleaning_status`
--
ALTER TABLE `room_cleaning_status`
  ADD PRIMARY KEY (`status_id`),
  ADD UNIQUE KEY `room_id` (`room_id`),
  ADD KEY `idx_room` (`room_id`),
  ADD KEY `idx_status` (`cleaning_status`);

--
-- Indexes for table `room_inspections`
--
ALTER TABLE `room_inspections`
  ADD PRIMARY KEY (`inspection_id`),
  ADD KEY `idx_booking_id` (`booking_id`),
  ADD KEY `idx_room_id` (`room_id`),
  ADD KEY `idx_status` (`overall_status`),
  ADD KEY `idx_date` (`inspection_date`);

--
-- Indexes for table `salary_payment_transactions`
--
ALTER TABLE `salary_payment_transactions`
  ADD PRIMARY KEY (`transaction_id`),
  ADD KEY `idx_salary_id` (`salary_id`),
  ADD KEY `idx_staff_id` (`staff_id`),
  ADD KEY `idx_payment_month` (`payment_month`),
  ADD KEY `idx_payment_date` (`payment_date`);

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
-- Indexes for table `staff_salaries`
--
ALTER TABLE `staff_salaries`
  ADD PRIMARY KEY (`salary_id`),
  ADD KEY `idx_staff_id` (`staff_id`),
  ADD KEY `idx_payment_month` (`payment_month`),
  ADD KEY `idx_payment_status` (`payment_status`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `asset_categories`
--
ALTER TABLE `asset_categories`
  MODIFY `category_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `asset_charges`
--
ALTER TABLE `asset_charges`
  MODIFY `charge_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `billing_settings`
--
ALTER TABLE `billing_settings`
  MODIFY `setting_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `bookings`
--
ALTER TABLE `bookings`
  MODIFY `booking_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `cleaning_tasks`
--
ALTER TABLE `cleaning_tasks`
  MODIFY `task_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `expense_records`
--
ALTER TABLE `expense_records`
  MODIFY `expense_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `financial_management`
--
ALTER TABLE `financial_management`
  MODIFY `financial_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `guests`
--
ALTER TABLE `guests`
  MODIFY `guest_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `guest_sessions`
--
ALTER TABLE `guest_sessions`
  MODIFY `session_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `hotel_policies`
--
ALTER TABLE `hotel_policies`
  MODIFY `policy_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `hotel_users`
--
ALTER TABLE `hotel_users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `housekeeping_staff`
--
ALTER TABLE `housekeeping_staff`
  MODIFY `staff_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `income_records`
--
ALTER TABLE `income_records`
  MODIFY `income_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `inspection_items`
--
ALTER TABLE `inspection_items`
  MODIFY `inspection_item_id` int(11) NOT NULL AUTO_INCREMENT;

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
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;

--
-- AUTO_INCREMENT for table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `invoice_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `invoice_items`
--
ALTER TABLE `invoice_items`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `maintenance_logs`
--
ALTER TABLE `maintenance_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `refunds`
--
ALTER TABLE `refunds`
  MODIFY `refund_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rooms`
--
ALTER TABLE `rooms`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `room_assets`
--
ALTER TABLE `room_assets`
  MODIFY `asset_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `room_asset_history`
--
ALTER TABLE `room_asset_history`
  MODIFY `history_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `room_asset_instances`
--
ALTER TABLE `room_asset_instances`
  MODIFY `instance_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `room_cleaning_status`
--
ALTER TABLE `room_cleaning_status`
  MODIFY `status_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `room_inspections`
--
ALTER TABLE `room_inspections`
  MODIFY `inspection_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `salary_payment_transactions`
--
ALTER TABLE `salary_payment_transactions`
  MODIFY `transaction_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

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
-- AUTO_INCREMENT for table `staff_salaries`
--
ALTER TABLE `staff_salaries`
  MODIFY `salary_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `asset_charges`
--
ALTER TABLE `asset_charges`
  ADD CONSTRAINT `asset_charges_ibfk_1` FOREIGN KEY (`inspection_item_id`) REFERENCES `inspection_items` (`inspection_item_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `asset_charges_ibfk_2` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `asset_charges_ibfk_3` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE;

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
-- Constraints for table `financial_management`
--
ALTER TABLE `financial_management`
  ADD CONSTRAINT `financial_management_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE;

--
-- Constraints for table `guest_sessions`
--
ALTER TABLE `guest_sessions`
  ADD CONSTRAINT `guest_sessions_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `guest_sessions_ibfk_2` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE;

--
-- Constraints for table `inspection_items`
--
ALTER TABLE `inspection_items`
  ADD CONSTRAINT `inspection_items_ibfk_1` FOREIGN KEY (`inspection_id`) REFERENCES `room_inspections` (`inspection_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `inspection_items_ibfk_2` FOREIGN KEY (`asset_id`) REFERENCES `room_assets` (`asset_id`) ON DELETE SET NULL;

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
-- Constraints for table `invoices`
--
ALTER TABLE `invoices`
  ADD CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `invoices_ibfk_2` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `invoices_ibfk_3` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;

--
-- Constraints for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD CONSTRAINT `invoice_items_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`invoice_id`) ON DELETE CASCADE;

--
-- Constraints for table `maintenance_logs`
--
ALTER TABLE `maintenance_logs`
  ADD CONSTRAINT `maintenance_logs_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `payments_ibfk_2` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE;

--
-- Constraints for table `refunds`
--
ALTER TABLE `refunds`
  ADD CONSTRAINT `refunds_ibfk_1` FOREIGN KEY (`payment_id`) REFERENCES `payments` (`payment_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `refunds_ibfk_2` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `refunds_ibfk_3` FOREIGN KEY (`guest_id`) REFERENCES `guests` (`guest_id`) ON DELETE CASCADE;

--
-- Constraints for table `room_assets`
--
ALTER TABLE `room_assets`
  ADD CONSTRAINT `room_assets_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `asset_categories` (`category_id`) ON DELETE SET NULL;

--
-- Constraints for table `room_asset_history`
--
ALTER TABLE `room_asset_history`
  ADD CONSTRAINT `room_asset_history_ibfk_1` FOREIGN KEY (`instance_id`) REFERENCES `room_asset_instances` (`instance_id`) ON DELETE CASCADE;

--
-- Constraints for table `room_asset_instances`
--
ALTER TABLE `room_asset_instances`
  ADD CONSTRAINT `room_asset_instances_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `room_asset_instances_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `asset_categories` (`category_id`) ON DELETE SET NULL;

--
-- Constraints for table `room_cleaning_status`
--
ALTER TABLE `room_cleaning_status`
  ADD CONSTRAINT `room_cleaning_status_ibfk_1` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;

--
-- Constraints for table `room_inspections`
--
ALTER TABLE `room_inspections`
  ADD CONSTRAINT `room_inspections_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `room_inspections_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`room_id`) ON DELETE CASCADE;

--
-- Constraints for table `salary_payment_transactions`
--
ALTER TABLE `salary_payment_transactions`
  ADD CONSTRAINT `fk_salary_tx_salary` FOREIGN KEY (`salary_id`) REFERENCES `staff_salaries` (`salary_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_salary_tx_staff` FOREIGN KEY (`staff_id`) REFERENCES `housekeeping_staff` (`staff_id`) ON DELETE CASCADE;

--
-- Constraints for table `service_orders`
--
ALTER TABLE `service_orders`
  ADD CONSTRAINT `service_orders_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`booking_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `service_orders_ibfk_2` FOREIGN KEY (`service_id`) REFERENCES `services` (`service_id`) ON DELETE CASCADE;

--
-- Constraints for table `staff_salaries`
--
ALTER TABLE `staff_salaries`
  ADD CONSTRAINT `fk_salary_staff` FOREIGN KEY (`staff_id`) REFERENCES `housekeeping_staff` (`staff_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
