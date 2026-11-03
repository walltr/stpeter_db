CREATE DATABASE IF NOT EXISTS st_peter_funeral_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE st_peter_funeral_db;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS vw_arrangement_balance;
DROP VIEW IF EXISTS vw_upcoming_funeral_schedules;
DROP VIEW IF EXISTS vw_billing_summary;

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS system_settings;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS billing_items;
DROP TABLE IF EXISTS billing;
DROP TABLE IF EXISTS arrangement_status_history;
DROP TABLE IF EXISTS funeral_schedules;
DROP TABLE IF EXISTS arrangement_services;
DROP TABLE IF EXISTS funeral_arrangements;
DROP TABLE IF EXISTS package_services;
DROP TABLE IF EXISTS service_packages;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS service_categories;
DROP TABLE IF EXISTS deceased_persons;
DROP TABLE IF EXISTS clients;
DROP TABLE IF EXISTS payment_methods;
DROP TABLE IF EXISTS arrangement_statuses;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;

SET FOREIGN_KEY_CHECKS = 1;

-- 1. ROLES
CREATE TABLE roles (
    role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. PERMISSIONS
CREATE TABLE permissions (
    permission_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    permission_key VARCHAR(100) NOT NULL UNIQUE,
    permission_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL
) ENGINE=InnoDB;

-- 3. ROLE PERMISSIONS
CREATE TABLE role_permissions (
    role_id INT UNSIGNED NOT NULL,
    permission_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permissions_role
      FOREIGN KEY (role_id) REFERENCES roles(role_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission
      FOREIGN KEY (permission_id) REFERENCES permissions(permission_id)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 4. USERS
CREATE TABLE users (
    user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_id INT UNSIGNED NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    middle_name VARCHAR(80) NULL,
    last_name VARCHAR(80) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    username VARCHAR(60) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(30) NULL,
    account_status ENUM('Active','Inactive','Locked') NOT NULL DEFAULT 'Active',
    last_login_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role
      FOREIGN KEY (role_id) REFERENCES roles(role_id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 5. CLIENTS
CREATE TABLE clients (
    client_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    middle_name VARCHAR(80) NULL,
    last_name VARCHAR(80) NOT NULL,
    relationship_to_deceased VARCHAR(80) NULL,
    contact_number VARCHAR(30) NOT NULL,
    email VARCHAR(150) NULL,
    address TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_clients_name (last_name, first_name),
    INDEX idx_clients_contact (contact_number)
) ENGINE=InnoDB;

-- 6. DECEASED PERSONS
CREATE TABLE deceased_persons (
    deceased_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    middle_name VARCHAR(80) NULL,
    last_name VARCHAR(80) NOT NULL,
    suffix VARCHAR(20) NULL,
    date_of_birth DATE NULL,
    date_of_death DATE NOT NULL,
    age_at_death SMALLINT UNSIGNED NULL,
    sex ENUM('Male','Female','Not Specified') NOT NULL DEFAULT 'Not Specified',
    place_of_death VARCHAR(255) NULL,
    cause_of_death VARCHAR(255) NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_deceased_age CHECK (age_at_death IS NULL OR age_at_death <= 130),
    CONSTRAINT chk_deceased_dates CHECK (date_of_birth IS NULL OR date_of_birth <= date_of_death),
    INDEX idx_deceased_name (last_name, first_name)
) ENGINE=InnoDB;

-- 7. SERVICE CATEGORIES
CREATE TABLE service_categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 8. SERVICES
CREATE TABLE services (
    service_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    service_name VARCHAR(150) NOT NULL,
    description TEXT NULL,
    standard_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_services_price CHECK (standard_price >= 0),
    CONSTRAINT fk_services_category
      FOREIGN KEY (category_id) REFERENCES service_categories(category_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    UNIQUE KEY uq_service_category_name (category_id, service_name)
) ENGINE=InnoDB;

-- 9. SERVICE PACKAGES
CREATE TABLE service_packages (
    package_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    package_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT NULL,
    package_price DECIMAL(12,2) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_package_price CHECK (package_price >= 0)
) ENGINE=InnoDB;

-- 10. PACKAGE SERVICES
CREATE TABLE package_services (
    package_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1.00,
    PRIMARY KEY (package_id, service_id),
    CONSTRAINT chk_package_service_quantity CHECK (quantity > 0),
    CONSTRAINT fk_package_services_package
      FOREIGN KEY (package_id) REFERENCES service_packages(package_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_package_services_service
      FOREIGN KEY (service_id) REFERENCES services(service_id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 11. ARRANGEMENT STATUSES
CREATE TABLE arrangement_statuses (
    status_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    is_terminal TINYINT(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- 12. FUNERAL ARRANGEMENTS
CREATE TABLE funeral_arrangements (
    arrangement_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reference_code VARCHAR(40) NOT NULL UNIQUE,
    client_id INT UNSIGNED NOT NULL,
    deceased_id INT UNSIGNED NOT NULL,
    package_id INT UNSIGNED NULL,
    status_id INT UNSIGNED NOT NULL,
    handled_by INT UNSIGNED NOT NULL,
    arrangement_date DATE NOT NULL,
    special_requests TEXT NULL,
    internal_notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_arrangements_client
      FOREIGN KEY (client_id) REFERENCES clients(client_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_arrangements_deceased
      FOREIGN KEY (deceased_id) REFERENCES deceased_persons(deceased_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_arrangements_package
      FOREIGN KEY (package_id) REFERENCES service_packages(package_id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_arrangements_status
      FOREIGN KEY (status_id) REFERENCES arrangement_statuses(status_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_arrangements_user
      FOREIGN KEY (handled_by) REFERENCES users(user_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_arrangements_date (arrangement_date),
    INDEX idx_arrangements_client (client_id),
    INDEX idx_arrangements_status (status_id)
) ENGINE=InnoDB;

-- 13. ARRANGEMENT SERVICES
-- Stores the selected services and price at the time of arrangement.
CREATE TABLE arrangement_services (
    arrangement_service_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    arrangement_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1.00,
    agreed_unit_price DECIMAL(12,2) NOT NULL,
    notes VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_arrangement_service_quantity CHECK (quantity > 0),
    CONSTRAINT chk_arrangement_service_price CHECK (agreed_unit_price >= 0),
    CONSTRAINT fk_arrangement_services_arrangement
      FOREIGN KEY (arrangement_id) REFERENCES funeral_arrangements(arrangement_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_arrangement_services_service
      FOREIGN KEY (service_id) REFERENCES services(service_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_arrangement_services_arrangement (arrangement_id)
) ENGINE=InnoDB;

-- 14. FUNERAL SCHEDULES
CREATE TABLE funeral_schedules (
    schedule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    arrangement_id INT UNSIGNED NOT NULL,
    schedule_type ENUM('Wake','Chapel','Church','Funeral','Burial','Other') NOT NULL,
    schedule_title VARCHAR(150) NOT NULL,
    venue VARCHAR(255) NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NULL,
    schedule_status ENUM('Scheduled','Completed','Cancelled','Rescheduled') NOT NULL DEFAULT 'Scheduled',
    notes TEXT NULL,
    created_by INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_schedule_time CHECK (end_datetime IS NULL OR end_datetime >= start_datetime),
    CONSTRAINT fk_schedules_arrangement
      FOREIGN KEY (arrangement_id) REFERENCES funeral_arrangements(arrangement_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_schedules_user
      FOREIGN KEY (created_by) REFERENCES users(user_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_schedules_start (start_datetime),
    INDEX idx_schedules_arrangement (arrangement_id)
) ENGINE=InnoDB;

-- 15. ARRANGEMENT STATUS HISTORY
CREATE TABLE arrangement_status_history (
    history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    arrangement_id INT UNSIGNED NOT NULL,
    status_id INT UNSIGNED NOT NULL,
    changed_by INT UNSIGNED NOT NULL,
    change_notes VARCHAR(500) NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_status_history_arrangement
      FOREIGN KEY (arrangement_id) REFERENCES funeral_arrangements(arrangement_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_status_history_status
      FOREIGN KEY (status_id) REFERENCES arrangement_statuses(status_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_status_history_user
      FOREIGN KEY (changed_by) REFERENCES users(user_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_status_history_arrangement_date (arrangement_id, changed_at)
) ENGINE=InnoDB;

-- 16. BILLING
CREATE TABLE billing (
    billing_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    arrangement_id INT UNSIGNED NOT NULL UNIQUE,
    invoice_number VARCHAR(40) NOT NULL UNIQUE,
    billing_date DATE NOT NULL,
    due_date DATE NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    other_charges DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    billing_status ENUM('Unpaid','Partially Paid','Paid','Cancelled') NOT NULL DEFAULT 'Unpaid',
    prepared_by INT UNSIGNED NOT NULL,
    notes TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_billing_discount CHECK (discount_amount >= 0),
    CONSTRAINT chk_billing_other_charges CHECK (other_charges >= 0),
    CONSTRAINT chk_billing_due_date CHECK (due_date IS NULL OR due_date >= billing_date),
    CONSTRAINT fk_billing_arrangement
      FOREIGN KEY (arrangement_id) REFERENCES funeral_arrangements(arrangement_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_billing_user
      FOREIGN KEY (prepared_by) REFERENCES users(user_id)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 17. BILLING ITEMS
CREATE TABLE billing_items (
    billing_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    billing_id INT UNSIGNED NOT NULL,
    arrangement_service_id INT UNSIGNED NULL,
    item_description VARCHAR(255) NOT NULL,
    quantity DECIMAL(10,2) NOT NULL DEFAULT 1.00,
    unit_price DECIMAL(12,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_billing_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_billing_item_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_billing_item_line_total CHECK (line_total >= 0),
    CONSTRAINT fk_billing_items_billing
      FOREIGN KEY (billing_id) REFERENCES billing(billing_id)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_billing_items_arrangement_service
      FOREIGN KEY (arrangement_service_id) REFERENCES arrangement_services(arrangement_service_id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_billing_items_billing (billing_id)
) ENGINE=InnoDB;

-- 18. PAYMENT METHODS
CREATE TABLE payment_methods (
    payment_method_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    method_name VARCHAR(60) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- 19. PAYMENTS
CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    billing_id INT UNSIGNED NOT NULL,
    payment_method_id INT UNSIGNED NOT NULL,
    received_by INT UNSIGNED NOT NULL,
    receipt_number VARCHAR(50) NOT NULL UNIQUE,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL,
    reference_number VARCHAR(100) NULL,
    notes VARCHAR(500) NULL,
    payment_status ENUM('Recorded','Voided') NOT NULL DEFAULT 'Recorded',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_payment_amount CHECK (amount > 0),
    CONSTRAINT fk_payments_billing
      FOREIGN KEY (billing_id) REFERENCES billing(billing_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_payments_method
      FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_payments_user
      FOREIGN KEY (received_by) REFERENCES users(user_id)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_payments_billing_date (billing_id, payment_date)
) ENGINE=InnoDB;

-- 20. AUDIT LOGS
CREATE TABLE audit_logs (
    audit_log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NULL,
    action_type VARCHAR(60) NOT NULL,
    table_affected VARCHAR(100) NULL,
    record_id VARCHAR(60) NULL,
    action_description TEXT NULL,
    ip_address VARCHAR(45) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_user
      FOREIGN KEY (user_id) REFERENCES users(user_id)
      ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_audit_logs_created (created_at),
    INDEX idx_audit_logs_user (user_id)
) ENGINE=InnoDB;

-- 21. SYSTEM SETTINGS
CREATE TABLE system_settings (
    setting_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NULL,
    description VARCHAR(255) NULL,
    updated_by INT UNSIGNED NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_system_settings_user
      FOREIGN KEY (updated_by) REFERENCES users(user_id)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;
