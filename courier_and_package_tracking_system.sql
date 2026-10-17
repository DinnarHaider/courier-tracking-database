

DROP DATABASE IF EXISTS courier_tracking;
CREATE DATABASE courier_tracking;
USE courier_tracking;

-- TABLE 1: Customer

CREATE TABLE Customer (
    CustomerID   VARCHAR(10)  PRIMARY KEY,
    Name         VARCHAR(100) NOT NULL,
    Email        VARCHAR(100) NOT NULL UNIQUE,
    Phone        VARCHAR(15)  NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    CreatedAt    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- TABLE 2: Address

CREATE TABLE Address (
    AddressID  VARCHAR(10)  PRIMARY KEY,
    CustomerID VARCHAR(10)  NOT NULL,
    Street     VARCHAR(150) NOT NULL,
    City       VARCHAR(50)  NOT NULL,
    Province   VARCHAR(50)  NOT NULL,
    PostalCode VARCHAR(10)  NOT NULL,
    Country    VARCHAR(50)  NOT NULL DEFAULT 'Pakistan',
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);


-- TABLE 3: Parcel

CREATE TABLE Parcel (
    ParcelID      VARCHAR(10)   PRIMARY KEY,
    CustomerID    VARCHAR(10)   NOT NULL,
    Weight        DECIMAL(6,2)  NOT NULL,
    Dimensions    VARCHAR(50)   NOT NULL,
    ParcelType    VARCHAR(30)   NOT NULL,
    DeclaredValue DECIMAL(10,2) NOT NULL,
    Status        VARCHAR(30)   NOT NULL DEFAULT 'Pending',
    CreatedAt     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);


-- TABLE 4: Hub  

CREATE TABLE Hub (
    HubID    VARCHAR(10)  PRIMARY KEY,
    HubName  VARCHAR(100) NOT NULL,
    City     VARCHAR(50),
    Province VARCHAR(50)
);


-- TABLE 5: Shipment 

CREATE TABLE Shipment (
    ShipmentID           VARCHAR(10) PRIMARY KEY,
    ParcelID             VARCHAR(10) NOT NULL,
    OriginAddressID      VARCHAR(10) NOT NULL,
    DestinationAddressID VARCHAR(10) NOT NULL,
    EstimatedDelivery    DATE        NOT NULL,
    ActualDelivery       DATE,
    FOREIGN KEY (ParcelID)             REFERENCES Parcel(ParcelID),
    FOREIGN KEY (OriginAddressID)      REFERENCES Address(AddressID),
    FOREIGN KEY (DestinationAddressID) REFERENCES Address(AddressID)
);


-- TABLE 6: Route

CREATE TABLE Route (
    RouteID          VARCHAR(10)  PRIMARY KEY,
    OriginHubID      VARCHAR(10),
    DestinationHubID VARCHAR(10),
    Distance         DECIMAL(6,2),
    FOREIGN KEY (OriginHubID)      REFERENCES Hub(HubID),
    FOREIGN KEY (DestinationHubID) REFERENCES Hub(HubID)
);


-- TABLE 7: DeliveryAgent 

CREATE TABLE DeliveryAgent (
    AgentID          VARCHAR(10)  PRIMARY KEY,
    FullName         VARCHAR(100) NOT NULL,
    CNIC             CHAR(15)     NOT NULL UNIQUE,
    Phone            VARCHAR(20)  NOT NULL UNIQUE,
    Email            VARCHAR(100) NOT NULL UNIQUE,
    VehicleType      ENUM('Bike', 'Van', 'Truck') NOT NULL,
    HireDate         DATE         NOT NULL,
    EmploymentStatus ENUM('Active', 'On Leave', 'Inactive') NOT NULL DEFAULT 'Active',
    BaseHubID        VARCHAR(10)  NOT NULL,
    CONSTRAINT fk_deliveryagent_hub
        FOREIGN KEY (BaseHubID) REFERENCES Hub(HubID)
);


-- TABLE 8: VehicleAssignment

CREATE TABLE VehicleAssignment (
    AssignmentID     VARCHAR(10)  PRIMARY KEY,
    RouteID          VARCHAR(10),
    AgentID          VARCHAR(10),
    ShipmentID       VARCHAR(10),
    VehicleNumber    VARCHAR(20),
    DriverName       VARCHAR(100),
    AssignmentStatus ENUM('Assigned', 'Dispatched', 'In Transit',
                          'Out for Delivery', 'Delivered', 'Cancelled')
                     NOT NULL DEFAULT 'Assigned',
    DepartureTime    DATETIME,
    ArrivalTime      DATETIME,
    FOREIGN KEY (RouteID)    REFERENCES Route(RouteID),
    FOREIGN KEY (AgentID)    REFERENCES DeliveryAgent(AgentID),
    FOREIGN KEY (ShipmentID) REFERENCES Shipment(ShipmentID)
);


-- TABLE 9: TrackingLog

CREATE TABLE TrackingLog (
    LogID        VARCHAR(10) PRIMARY KEY,
    ParcelID     VARCHAR(10),
    HubID        VARCHAR(10),
    AssignmentID VARCHAR(10),
    Status       VARCHAR(50),
    UpdatedAt    DATETIME,
    FOREIGN KEY (ParcelID)     REFERENCES Parcel(ParcelID),
    FOREIGN KEY (HubID)        REFERENCES Hub(HubID),
    FOREIGN KEY (AssignmentID) REFERENCES VehicleAssignment(AssignmentID)
);

CREATE INDEX idx_tracking_parcel_time ON TrackingLog (ParcelID, UpdatedAt);


-- TABLE 10: UserRole

CREATE TABLE UserRole (
    UserRoleID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    RoleName   ENUM('Sender', 'Receiver', 'CorporateClient', 'PriorityCustomer') NOT NULL,
    IsActive   BOOLEAN  NOT NULL DEFAULT TRUE,
    AssignedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_userrole_customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT uq_userrole_customer_role
        UNIQUE (CustomerID, RoleName)
);


-- TABLE 11: Invoice

CREATE TABLE Invoice (
    InvoiceID      VARCHAR(10)   PRIMARY KEY,
    CustomerID     VARCHAR(10)   NOT NULL,
    ShipmentID     VARCHAR(10)   NOT NULL,
    InvoiceDate    DATE          NOT NULL,
    SubtotalAmount DECIMAL(10,2) NOT NULL,
    TaxAmount      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    TotalAmount    DECIMAL(10,2) NOT NULL,
    DueDate        DATE          NOT NULL,
    InvoiceStatus  ENUM('Unpaid', 'Partially Paid', 'Paid', 'Overdue') NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT fk_invoice_customer
        FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    CONSTRAINT fk_invoice_shipment
        FOREIGN KEY (ShipmentID) REFERENCES Shipment(ShipmentID),
    CONSTRAINT uq_invoice_shipment
        UNIQUE (ShipmentID)
);


-- TABLE 12: Payment

CREATE TABLE Payment (
    PaymentID        VARCHAR(10)   PRIMARY KEY,
    InvoiceID        VARCHAR(10)   NOT NULL,
    PaymentDate      DATETIME      NOT NULL,
    AmountPaid       DECIMAL(10,2) NOT NULL,
    PaymentMethod    ENUM('Cash', 'Credit Card', 'Debit Card',
                          'EasyPaisa', 'JazzCash', 'Bank Transfer') NOT NULL,
    PaymentReference VARCHAR(50)   UNIQUE,
    PaymentStatus    ENUM('Pending', 'Completed', 'Failed', 'Refunded') NOT NULL DEFAULT 'Completed',
    CONSTRAINT fk_payment_invoice
        FOREIGN KEY (InvoiceID) REFERENCES Invoice(InvoiceID)
);

CREATE INDEX idx_userrole_customer_active ON UserRole      (CustomerID, IsActive);
CREATE INDEX idx_deliveryagent_hub_status ON DeliveryAgent (BaseHubID, EmploymentStatus);
CREATE INDEX idx_invoice_customer_status  ON Invoice       (CustomerID, InvoiceStatus);
CREATE INDEX idx_payment_method_date      ON Payment       (PaymentMethod, PaymentDate);
CREATE INDEX idx_payment_invoice_status   ON Payment       (InvoiceID, PaymentStatus);


-- TABLE 13: Complaint

CREATE TABLE Complaint (
    ComplaintID   INT          PRIMARY KEY AUTO_INCREMENT,
    CustomerID    VARCHAR(10)  NOT NULL,
    ParcelID      VARCHAR(10)  NOT NULL,
    ComplaintType VARCHAR(50)  NOT NULL,
    Description   TEXT,
    Status        VARCHAR(20)  NOT NULL DEFAULT 'Open',
    CreatedAt     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (ParcelID)   REFERENCES Parcel(ParcelID)
);


-- TABLE 14: ComplaintResolution

CREATE TABLE ComplaintResolution (
    ResolutionID    INT         PRIMARY KEY AUTO_INCREMENT,
    ComplaintID     INT         NOT NULL UNIQUE,
    AgentID         VARCHAR(10) NOT NULL,
    ResolutionNotes TEXT,
    ResolvedAt      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ResolutionType  VARCHAR(50),
    FOREIGN KEY (ComplaintID) REFERENCES Complaint(ComplaintID),
    FOREIGN KEY (AgentID)     REFERENCES DeliveryAgent(AgentID)
);


-- TABLE 15: Notification

CREATE TABLE Notification (
    NotificationID INT         PRIMARY KEY AUTO_INCREMENT,
    CustomerID     VARCHAR(10) NOT NULL,
    ParcelID       VARCHAR(10),
    Message        TEXT        NOT NULL,
    Channel        VARCHAR(20) NOT NULL,
    SentAt         DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    IsRead         TINYINT(1)  NOT NULL DEFAULT 0,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
    FOREIGN KEY (ParcelID)   REFERENCES Parcel(ParcelID)
);


-- TABLE 16: Report

CREATE TABLE Report (
    ReportID    INT         PRIMARY KEY AUTO_INCREMENT,
    ReportType  VARCHAR(50) NOT NULL,
    GeneratedBy VARCHAR(10) NOT NULL,
    GeneratedAt DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Parameters  TEXT,
    Summary     TEXT
);



--  SAMPLE DATA

INSERT INTO Customer VALUES
('C001', 'Ahmed Raza',      'ahmed.raza@gmail.com',   '03001234567', 'hashed_pw_001', '2025-01-10 09:00:00'),
('C002', 'Sara Khan',       'sara.khan@yahoo.com',    '03111234567', 'hashed_pw_002', '2025-01-12 10:15:00'),
('C003', 'Bilal Mahmood',   'bilal.m@hotmail.com',    '03211234567', 'hashed_pw_003', '2025-01-15 11:30:00'),
('C004', 'Fatima Noor',     'fatima.noor@gmail.com',  '03311234567', 'hashed_pw_004', '2025-01-18 08:45:00'),
('C005', 'Usman Tariq',     'usman.tariq@gmail.com',  '03411234567', 'hashed_pw_005', '2025-01-20 13:00:00'),
('C006', 'Zainab Ali',      'zainab.ali@outlook.com', '03451234567', 'hashed_pw_006', '2025-01-22 14:20:00'),
('C007', 'Hassan Malik',    'hassan.malik@gmail.com', '03501234567', 'hashed_pw_007', '2025-01-25 09:10:00'),
('C008', 'Ayesha Siddiqui', 'ayesha.s@gmail.com',     '03551234567', 'hashed_pw_008', '2025-01-28 16:00:00'),
('C009', 'Imran Javed',     'imran.javed@gmail.com',  '03601234567', 'hashed_pw_009', '2025-02-01 10:00:00'),
('C010', 'Mariam Qureshi',  'mariam.q@yahoo.com',     '03701234567', 'hashed_pw_010', '2025-02-03 11:45:00');


INSERT INTO Address VALUES
('A001', 'C001', 'House 12, Block B, Gulberg',   'Lahore',     'Punjab',             '54000', 'Pakistan'),
('A002', 'C002', 'Flat 5, Clifton Block 4',      'Karachi',    'Sindh',              '75600', 'Pakistan'),
('A003', 'C003', 'Street 9, G-11 Markaz',        'Islamabad',  'Islamabad Capital',  '44000', 'Pakistan'),
('A004', 'C004', 'House 77, Saddar Bazaar',      'Rawalpindi', 'Punjab',             '46000', 'Pakistan'),
('A005', 'C005', 'Plot 3, Phase 6, DHA',         'Lahore',     'Punjab',             '54792', 'Pakistan'),
('A006', 'C006', 'House 22, Latifabad Unit 6',   'Hyderabad',  'Sindh',              '71000', 'Pakistan'),
('A007', 'C007', 'Flat 9, Model Town Extension', 'Multan',     'Punjab',             '60000', 'Pakistan'),
('A008', 'C008', 'House 4, University Road',     'Peshawar',   'Khyber Pakhtunkhwa', '25000', 'Pakistan'),
('A009', 'C009', 'Plot 18, Satellite Town',      'Quetta',     'Balochistan',        '87300', 'Pakistan'),
('A010', 'C010', 'House 31, Canal Road',         'Faisalabad', 'Punjab',             '38000', 'Pakistan');


INSERT INTO Parcel VALUES
('P001', 'C001', 1.50,  '30x20x15 cm', 'Document',    500.00,   'In Transit', '2025-02-05 08:00:00'),
('P002', 'C002', 3.20,  '40x30x20 cm', 'Electronics', 15000.00, 'Delivered',  '2025-02-06 09:00:00'),
('P003', 'C003', 0.80,  '20x15x10 cm', 'Document',    200.00,   'Pending',    '2025-02-07 10:00:00'),
('P004', 'C004', 5.00,  '50x40x30 cm', 'Clothing',    3000.00,  'In Transit', '2025-02-08 11:00:00'),
('P005', 'C005', 12.00, '60x50x40 cm', 'Fragile',     25000.00, 'At Hub',     '2025-02-09 12:00:00'),
('P006', 'C006', 2.30,  '35x25x18 cm', 'Medicine',    8000.00,  'Delivered',  '2025-02-10 08:30:00'),
('P007', 'C007', 7.50,  '55x45x35 cm', 'Electronics', 45000.00, 'Pending',    '2025-02-11 09:30:00'),
('P008', 'C008', 0.50,  '15x10x5 cm',  'Document',    100.00,   'In Transit', '2025-02-12 10:30:00'),
('P009', 'C009', 4.70,  '45x35x25 cm', 'Clothing',    5000.00,  'At Hub',     '2025-02-13 11:30:00'),
('P010', 'C010', 3.00,  '40x30x20 cm', 'Electronics', 12000.00, 'Delivered',  '2025-02-14 12:30:00');


INSERT INTO Hub VALUES
('H001', 'Lahore Hub',     'Lahore',     'Punjab'),
('H002', 'Karachi Hub',    'Karachi',    'Sindh'),
('H003', 'Islamabad Hub',  'Islamabad',  'ICT'),
('H004', 'Peshawar Hub',   'Peshawar',   'KPK'),
('H005', 'Quetta Hub',     'Quetta',     'Balochistan'),
('H006', 'Multan Hub',     'Multan',     'Punjab'),
('H007', 'Faisalabad Hub', 'Faisalabad', 'Punjab'),
('H008', 'Rawalpindi Hub', 'Rawalpindi', 'Punjab'),
('H009', 'Hyderabad Hub',  'Hyderabad',  'Sindh'),
('H010', 'Sialkot Hub',    'Sialkot',    'Punjab');


INSERT INTO Shipment VALUES
('SH001', 'P001', 'A001', 'A002', '2025-02-10', '2025-02-09'),
('SH002', 'P002', 'A002', 'A003', '2025-02-12', '2025-02-11'),
('SH003', 'P003', 'A003', 'A004', '2025-02-14', NULL),
('SH004', 'P004', 'A004', 'A005', '2025-02-15', NULL),
('SH005', 'P005', 'A005', 'A006', '2025-02-16', '2025-02-15'),
('SH006', 'P006', 'A006', 'A007', '2025-02-17', '2025-02-16'),
('SH007', 'P007', 'A007', 'A008', '2025-02-18', NULL),
('SH008', 'P008', 'A008', 'A009', '2025-02-19', NULL),
('SH009', 'P009', 'A009', 'A010', '2025-02-20', '2025-02-19'),
('SH010', 'P010', 'A010', 'A001', '2025-02-21', '2025-02-20');


INSERT INTO Route VALUES
('R001', 'H001', 'H002', 1210),
('R002', 'H002', 'H003', 1400),
('R003', 'H003', 'H004',  180),
('R004', 'H004', 'H005',  900),
('R005', 'H001', 'H003',  375),
('R006', 'H006', 'H007',  250),
('R007', 'H007', 'H008',  200),
('R008', 'H008', 'H001',  270),
('R009', 'H009', 'H002',  160),
('R010', 'H010', 'H001',  130);


INSERT INTO DeliveryAgent (AgentID, FullName, CNIC, Phone, Email, VehicleType, HireDate, EmploymentStatus, BaseHubID) VALUES
('AG001', 'Ali Raza',      '35202-1234567-1', '0300-1112233', 'ali.raza@swiftcourier.pk',      'Bike',  '2024-01-15', 'Active',   'H001'),
('AG002', 'Bilal Ahmed',   '35202-2234567-2', '0301-2113344', 'bilal.ahmed@swiftcourier.pk',   'Van',   '2024-02-10', 'Active',   'H002'),
('AG003', 'Hamza Tariq',   '35202-3234567-3', '0302-3114455', 'hamza.tariq@swiftcourier.pk',   'Bike',  '2024-03-05', 'On Leave', 'H003'),
('AG004', 'Usman Khalid',  '35202-4234567-4', '0303-4115566', 'usman.khalid@swiftcourier.pk',  'Truck', '2024-04-11', 'Active',   'H004'),
('AG005', 'Zainab Noor',   '35202-5234567-5', '0304-5116677', 'zainab.noor@swiftcourier.pk',   'Van',   '2024-05-09', 'Active',   'H005'),
('AG006', 'Areeba Khan',   '35202-6234567-6', '0305-6117788', 'areeba.khan@swiftcourier.pk',   'Bike',  '2024-06-19', 'Active',   'H001'),
('AG007', 'Hassan Iqbal',  '35202-7234567-7', '0306-7118899', 'hassan.iqbal@swiftcourier.pk',  'Truck', '2024-07-14', 'Inactive', 'H002'),
('AG008', 'Mariam Fatima', '35202-8234567-8', '0307-8119900', 'mariam.fatima@swiftcourier.pk', 'Van',   '2024-08-21', 'Active',   'H003'),
('AG009', 'Saad Qureshi',  '35202-9234567-9', '0308-9121011', 'saad.qureshi@swiftcourier.pk',  'Bike',  '2024-09-03', 'Active',   'H004'),
('AG010', 'Hira Saleem',   '35202-1034567-0', '0309-1022122', 'hira.saleem@swiftcourier.pk',   'Van',   '2024-10-12', 'Active',   'H005');


INSERT INTO VehicleAssignment
    (AssignmentID, RouteID, AgentID, ShipmentID, VehicleNumber, DriverName, AssignmentStatus, DepartureTime, ArrivalTime)
VALUES
('VA001', 'R001', 'AG001', 'SH001', 'LEA-1234', 'Ali Khan',    'Delivered',        '2026-05-01 08:00:00', '2026-05-02 08:00:00'),
('VA002', 'R002', 'AG002', 'SH002', 'KHI-5678', 'Ahmed Raza',  'Delivered',        '2026-05-01 09:00:00', '2026-05-02 12:00:00'),
('VA003', 'R003', 'AG003', 'SH003', 'ISB-2345', 'Usman Tariq', 'In Transit',       '2026-05-01 10:00:00', '2026-05-01 14:00:00'),
('VA004', 'R004', 'AG004', 'SH004', 'PEW-8765', 'Bilal Ahmed', 'In Transit',       '2026-05-01 11:00:00', '2026-05-02 15:00:00'),
('VA005', 'R005', 'AG005', 'SH005', 'LHR-1122', 'Hamza Ali',   'Delivered',        '2026-05-01 07:00:00', '2026-05-01 13:00:00'),
('VA006', 'R006', 'AG001', 'SH006', 'MUL-4455', 'Zain Malik',  'Delivered',        '2026-05-01 06:00:00', '2026-05-01 10:00:00'),
('VA007', 'R007', 'AG002', 'SH007', 'FSD-7788', 'Saad Khan',   'Assigned',         '2026-05-01 05:00:00', '2026-05-01 09:00:00'),
('VA008', 'R008', 'AG003', 'SH008', 'RWP-9988', 'Danish Ali',  'Dispatched',       '2026-05-01 04:00:00', '2026-05-01 08:00:00'),
('VA009', 'R009', 'AG004', 'SH009', 'HYD-2233', 'Imran Shah',  'Delivered',        '2026-05-01 03:00:00', '2026-05-01 07:00:00'),
('VA010', 'R010', 'AG005', 'SH010', 'SKT-6677', 'Faizan Ali',  'Delivered',        '2026-05-01 02:00:00', '2026-05-01 06:00:00');


INSERT INTO TrackingLog VALUES
('T001', 'P001', 'H001', 'VA001', 'Dispatched', '2026-05-01 08:00:00'),
('T002', 'P001', 'H003', 'VA003', 'In Transit', '2026-05-01 14:00:00'),
('T003', 'P001', 'H002', 'VA002', 'Arrived',    '2026-05-02 08:00:00'),
('T004', 'P002', 'H002', 'VA002', 'Dispatched', '2026-05-01 09:00:00'),
('T005', 'P002', 'H003', 'VA003', 'In Transit', '2026-05-01 18:00:00'),
('T006', 'P003', 'H004', 'VA004', 'Arrived',    '2026-05-01 20:00:00'),
('T007', 'P004', 'H005', 'VA004', 'Pending',    '2026-05-01 21:00:00'),
('T008', 'P005', 'H006', 'VA006', 'Dispatched', '2026-05-01 07:00:00'),
('T009', 'P006', 'H007', 'VA007', 'In Transit', '2026-05-01 11:00:00'),
('T010', 'P007', 'H008', 'VA008', 'Delivered',  '2026-05-01 16:00:00');

INSERT INTO UserRole (UserRoleID, CustomerID, RoleName, IsActive, AssignedAt) VALUES
('UR001', 'C001', 'Sender',           TRUE,  '2026-03-01 09:00:00'),
('UR002', 'C002', 'Sender',           TRUE,  '2026-03-02 09:15:00'),
('UR003', 'C003', 'Receiver',         TRUE,  '2026-03-03 10:30:00'),
('UR004', 'C004', 'CorporateClient',  TRUE,  '2026-03-04 11:00:00'),
('UR005', 'C005', 'Sender',           TRUE,  '2026-03-05 12:00:00'),
('UR006', 'C006', 'PriorityCustomer', TRUE,  '2026-03-06 12:30:00'),
('UR007', 'C007', 'Receiver',         TRUE,  '2026-03-07 13:00:00'),
('UR008', 'C008', 'CorporateClient',  TRUE,  '2026-03-08 13:45:00'),
('UR009', 'C009', 'Sender',           FALSE, '2026-03-09 14:00:00'),
('UR010', 'C010', 'PriorityCustomer', TRUE,  '2026-03-10 15:20:00');


INSERT INTO Invoice
    (InvoiceID, CustomerID, ShipmentID, InvoiceDate, SubtotalAmount, TaxAmount, DiscountAmount, TotalAmount, DueDate, InvoiceStatus)
VALUES
('INV001', 'C001', 'SH001', '2026-04-01', 1800.00, 180.00,   0.00, 1980.00, '2026-04-08', 'Paid'),
('INV002', 'C002', 'SH002', '2026-04-02', 2500.00, 250.00, 100.00, 2650.00, '2026-04-09', 'Partially Paid'),
('INV003', 'C003', 'SH003', '2026-04-03', 3200.00, 320.00,   0.00, 3520.00, '2026-04-10', 'Overdue'),
('INV004', 'C004', 'SH004', '2026-04-04', 1200.00, 120.00,   0.00, 1320.00, '2026-04-11', 'Paid'),
('INV005', 'C005', 'SH005', '2026-04-05', 3750.00, 375.00,   0.00, 4125.00, '2026-04-12', 'Unpaid'),
('INV006', 'C006', 'SH006', '2026-04-06', 4500.00, 450.00,   0.00, 4950.00, '2026-04-13', 'Paid'),
('INV007', 'C007', 'SH007', '2026-04-07', 1450.00, 145.00,   0.00, 1595.00, '2026-04-14', 'Paid'),
('INV008', 'C008', 'SH008', '2026-04-08', 2900.00, 290.00,   0.00, 3190.00, '2026-04-15', 'Partially Paid'),
('INV009', 'C009', 'SH009', '2026-04-09', 4950.00, 495.00,   0.00, 5445.00, '2026-04-16', 'Overdue'),
('INV010', 'C010', 'SH010', '2026-04-10', 2350.00, 235.00,   0.00, 2585.00, '2026-04-17', 'Paid');


INSERT INTO Payment
    (PaymentID, InvoiceID, PaymentDate, AmountPaid, PaymentMethod, PaymentReference, PaymentStatus)
VALUES
('PAY001', 'INV001', '2026-04-02 10:30:00', 1980.00, 'Debit Card',    'DB-540112',  'Completed'),
('PAY002', 'INV002', '2026-04-04 11:00:00', 1000.00, 'EasyPaisa',     'EP-874221',  'Completed'),
('PAY003', 'INV002', '2026-04-06 15:20:00',  500.00, 'EasyPaisa',     'EP-874889',  'Completed'),
('PAY004', 'INV004', '2026-04-06 12:10:00', 1320.00, 'JazzCash',      'JC-221109',  'Completed'),
('PAY005', 'INV006', '2026-04-08 16:45:00', 4950.00, 'Bank Transfer', 'IBFT-99811', 'Completed'),
('PAY006', 'INV007', '2026-04-09 14:35:00', 1595.00, 'Cash',          NULL,         'Completed'),
('PAY007', 'INV008', '2026-04-11 09:50:00', 1800.00, 'EasyPaisa',     'EP-875102',  'Completed'),
('PAY008', 'INV010', '2026-04-12 13:25:00', 2585.00, 'Credit Card',   'CC-662190',  'Completed'),
('PAY009', 'INV005', '2026-04-07 17:05:00', 1000.00, 'EasyPaisa',     'EP-875401',  'Pending'),
('PAY010', 'INV009', '2026-04-13 18:40:00',  500.00, 'EasyPaisa',     'EP-875777',  'Failed');


INSERT INTO Complaint (CustomerID, ParcelID, ComplaintType, Description, Status, CreatedAt) VALUES
('C001', 'P001', 'Delay',          'Parcel was supposed to arrive 3 days ago.',               'Open',        '2026-03-01 09:15:00'),
('C002', 'P002', 'Damage',         'Box arrived crushed, item inside is broken.',              'Resolved',    '2026-03-02 10:30:00'),
('C003', 'P003', 'Lost',           'Tracking shows delivered but parcel not received.',        'In Progress', '2026-03-03 11:00:00'),
('C004', 'P004', 'Wrong Delivery', 'Received someone else''s parcel.',                         'Open',        '2026-03-04 12:45:00'),
('C005', 'P005', 'Delay',          'No movement on tracking for 5 days.',                     'Open',        '2026-03-05 08:20:00'),
('C006', 'P006', 'Damage',         'Phone screen cracked during transit.',                    'Resolved',    '2026-03-06 14:00:00'),
('C007', 'P007', 'Lost',           'Parcel marked as delivered but not at address.',           'In Progress', '2026-03-07 09:50:00'),
('C008', 'P008', 'Delay',          'Estimated delivery was last week.',                       'Closed',      '2026-03-08 13:30:00'),
('C009', 'P009', 'Wrong Delivery', 'Label says my name but contents belong to someone else.', 'Open',        '2026-03-09 10:10:00'),
('C010', 'P010', 'Damage',         'Fragile sticker ignored, glassware shattered.',           'Open',        '2026-03-10 11:55:00'),
('C001', 'P002', 'Delay',          'Second complaint — replacement parcel also delayed.',     'Open',        '2026-03-11 15:00:00');


INSERT INTO ComplaintResolution (ComplaintID, AgentID, ResolutionNotes, ResolvedAt, ResolutionType) VALUES
(2,  'AG003', 'Refund issued to customer wallet. Apology sent via email.',                '2026-03-05 10:00:00', 'Refund'),
(6,  'AG004', 'Replacement dispatched. Original parcel collected for inspection.',        '2026-03-08 14:30:00', 'Redelivery'),
(8,  'AG002', 'Confirmed delivery with photo evidence. Customer accepted resolution.',    '2026-03-10 09:00:00', 'Investigation'),
(3,  'AG005', 'Parcel located at Lahore hub. Redelivery scheduled for tomorrow.',         '2026-03-09 16:00:00', 'Redelivery'),
(7,  'AG003', 'Investigation opened with a field agent. Customer notified of progress.',  '2026-03-11 11:00:00', 'Investigation'),
(4,  'AG001', 'Correct parcel retrieved and delivered. Misdirected parcel returned.',     '2026-03-07 13:00:00', 'Redelivery'),
(1,  'AG002', 'Parcel delayed at Karachi hub due to weather. Delivered next day.',        '2026-03-04 17:00:00', 'Apology'),
(5,  'AG004', 'Tracking issue fixed. Parcel was at Islamabad hub, now out for delivery.', '2026-03-08 10:30:00', 'Investigation'),
(9,  'AG005', 'Wrong label identified at sorting center. Correct parcel sent.',           '2026-03-12 09:00:00', 'Redelivery'),
(10, 'AG001', 'Refund approved for damaged goods. Customer submitted photos as proof.',   '2026-03-13 14:00:00', 'Refund');


INSERT INTO Notification (CustomerID, ParcelID, Message, Channel, SentAt, IsRead) VALUES
('C001', 'P001', 'Your parcel P001 is out for delivery today.',                         'SMS',   '2026-03-01 08:00:00', 1),
('C002', 'P002', 'Your parcel P002 has been dispatched from Karachi hub.',              'Email', '2026-03-02 09:00:00', 1),
('C003', 'P003', 'Your parcel P003 is currently at Lahore sorting center.',             'App',   '2026-03-03 10:00:00', 0),
('C004', 'P004', 'Delivery attempt failed for P004. Please reschedule.',                'SMS',   '2026-03-04 13:00:00', 1),
('C005', 'P005', 'Your parcel P005 has been delayed. New ETA: 3 days.',                 'Email', '2026-03-05 11:00:00', 0),
('C006', 'P006', 'Replacement parcel for P006 has been dispatched.',                   'SMS',   '2026-03-06 15:00:00', 1),
('C007', 'P007', 'We are investigating the status of your parcel P007.',                'Email', '2026-03-07 10:30:00', 1),
('C008', 'P008', 'Your parcel P008 has been delivered. Thank you!',                     'App',   '2026-03-08 16:00:00', 1),
('C009', 'P009', 'Your complaint regarding P009 has been resolved.',                   'SMS',   '2026-03-09 12:00:00', 0),
('C010', 'P010', 'Refund for P010 has been processed. Allow 2-3 business days.',        'Email', '2026-03-10 14:00:00', 1),
('C001', NULL,   'Your account password was changed. Contact us if this was not you.',  'Email', '2026-03-11 08:00:00', 0);


INSERT INTO Report (ReportType, GeneratedBy, GeneratedAt, Parameters, Summary) VALUES
('Monthly Summary',    'AG001', '2026-03-01 09:00:00', 'Month: February 2026',                'Total parcels: 520. Delivered: 490. Pending: 30.'),
('Complaint Analysis', 'AG002', '2026-03-02 10:00:00', 'Month: February 2026',                'Total complaints: 45. Resolved: 38. Open: 7.'),
('Agent Performance',  'AG003', '2026-03-03 11:00:00', 'AgentID: 1-10, Month: February 2026', 'Top agent: Agent 4 with 98% delivery success rate.'),
('Revenue Report',     'AG001', '2026-03-04 12:00:00', 'Month: February 2026',                'Total revenue: PKR 1,250,000. Refunds issued: PKR 45,000.'),
('Hub Activity',       'AG004', '2026-03-05 13:00:00', 'HubID: all, Week: 1 March 2026',      'Karachi hub processed most parcels: 210 this week.'),
('Delay Analysis',     'AG002', '2026-03-06 14:00:00', 'Status: Delayed, Month: Feb 2026',    'Average delay: 2.3 days. Main cause: weather disruptions.'),
('Monthly Summary',    'AG001', '2026-04-01 09:00:00', 'Month: March 2026',                   'Total parcels: 610. Delivered: 580. Pending: 30.'),
('Complaint Analysis', 'AG003', '2026-04-02 10:00:00', 'Month: March 2026',                   'Total complaints: 52. Resolved: 44. Open: 8.'),
('Agent Performance',  'AG002', '2026-04-03 11:00:00', 'AgentID: 1-10, Month: March 2026',    'Most improved agent: Agent 7 with 95% success rate.'),
('Damage Report',      'AG005', '2026-04-04 12:00:00', 'ComplaintType: Damage, Q1 2026',      'Total damage claims: 18. Refunds issued: 14. Redeliveries: 4.');


--  QUERIES

-- a. Find all parcels belonging to a specific customer (C001)

SELECT * FROM Parcel WHERE CustomerID = 'C001';


-- b. Join customer with their address

SELECT c.Name, c.Email, a.Street, a.City, a.Province, a.PostalCode
FROM Customer c
JOIN Address a ON c.CustomerID = a.CustomerID;


-- c. Find all shipments along with their origin and destination city

SELECT s.ShipmentID, s.EstimatedDelivery,
       o.City AS OriginCity,
       d.City AS DestinationCity
FROM Shipment s
JOIN Address o ON s.OriginAddressID      = o.AddressID
JOIN Address d ON s.DestinationAddressID = d.AddressID;


-- d. Find current (most recent) status of parcel P001

SELECT *
FROM TrackingLog
WHERE ParcelID = 'P001'
ORDER BY UpdatedAt DESC
LIMIT 1;


-- e. Find all parcels currently at hub H001

SELECT *
FROM TrackingLog
WHERE HubID = 'H001';


-- f. Join to get full tracking details with hub name

SELECT t.ParcelID, t.Status, t.UpdatedAt, h.HubName
FROM TrackingLog t
JOIN Hub h ON t.HubID = h.HubID;


-- g. Find all outstanding invoices for customer C005

SELECT i.InvoiceID,
       c.Name          AS CustomerName,
       i.ShipmentID,
       i.TotalAmount,
       i.DueDate,
       i.InvoiceStatus
FROM Invoice i
JOIN Customer c ON i.CustomerID = c.CustomerID
WHERE i.CustomerID = 'C005'
  AND i.InvoiceStatus IN ('Unpaid', 'Partially Paid', 'Overdue');


-- h. Get agent workload — active shipments assigned per agent

SELECT da.AgentID,
       da.FullName                             AS AgentName,
       da.BaseHubID,
       COUNT(DISTINCT va.ShipmentID)           AS ActiveAssignedParcels
FROM DeliveryAgent da
LEFT JOIN VehicleAssignment va
       ON va.AgentID          = da.AgentID
      AND va.AssignmentStatus IN ('Assigned', 'Dispatched', 'In Transit', 'Out for Delivery')
GROUP BY da.AgentID, da.FullName, da.BaseHubID
ORDER BY ActiveAssignedParcels DESC, da.FullName;


-- i. Find all payments made via EasyPaisa

SELECT p.PaymentID,
       c.Name          AS CustomerName,
       p.AmountPaid,
       p.PaymentDate,
       p.PaymentReference,
       p.PaymentStatus
FROM Payment p
JOIN Invoice  i ON p.InvoiceID  = i.InvoiceID
JOIN Customer c ON i.CustomerID = c.CustomerID
WHERE p.PaymentMethod = 'EasyPaisa'
ORDER BY p.PaymentDate DESC;


-- j. Find all open complaints ordered by date

SELECT c.ComplaintID,
       cu.Name          AS CustomerName,
       c.ParcelID,
       c.ComplaintType,
       c.Description,
       c.CreatedAt
FROM Complaint c
JOIN Customer cu ON c.CustomerID = cu.CustomerID
WHERE c.Status = 'Open'
ORDER BY c.CreatedAt ASC;


-- k. Join complaints with resolution details

SELECT c.ComplaintID,
       cu.Name          AS CustomerName,
       c.ComplaintType,
       c.Status,
       cr.ResolutionType,
       cr.ResolutionNotes,
       cr.ResolvedAt,
       da.FullName      AS ResolvedByAgent
FROM Complaint c
JOIN Customer cu              ON c.CustomerID  = cu.CustomerID
LEFT JOIN ComplaintResolution cr ON c.ComplaintID = cr.ComplaintID
LEFT JOIN DeliveryAgent da    ON cr.AgentID     = da.AgentID
ORDER BY c.ComplaintID;


-- l. Count complaints by type

SELECT ComplaintType,
       COUNT(ComplaintID) AS TotalComplaints
FROM Complaint
GROUP BY ComplaintType
ORDER BY TotalComplaints DESC;


-- m. Insert a new customer

INSERT INTO Customer (CustomerID, Name, Email, Phone, PasswordHash, CreatedAt)
VALUES ('C011', 'Sara Ahmed', 'sara@email.com', '03001234567',
        SHA2('securepassword', 256), NOW());


-- n. Insert a new parcel for an existing customer

INSERT INTO Parcel (ParcelID, CustomerID, Weight, Dimensions, ParcelType, DeclaredValue, Status)
VALUES ('P021', 'C011', 2.50, '30x20x10 cm', 'Standard', 1500.00, 'Pending');


-- o. Update parcel status when it moves to a new hub

UPDATE Parcel
SET Status = 'In Transit'
WHERE ParcelID = 'P021';


-- p. Mark an invoice as paid after payment is received

UPDATE Invoice
SET InvoiceStatus = 'Paid'
WHERE InvoiceID = 'INV005';


-- q. Cross-module integration query joining all four modules

SELECT c.CustomerID,
       c.Name AS CustomerName,
       p.ParcelID,
       s.ShipmentID,
       tl.Status AS LatestTrackingStatus,
       h.HubName,
       da.FullName AS AssignedAgent,
       i.InvoiceStatus,
       pay.PaymentStatus,
       comp.ComplaintType,
       comp.Status AS ComplaintStatus
FROM Customer c
JOIN Parcel p ON p.CustomerID = c.CustomerID
JOIN Shipment s ON s.ParcelID = p.ParcelID
LEFT JOIN TrackingLog tl
       ON tl.ParcelID = p.ParcelID
      AND tl.UpdatedAt = (
          SELECT MAX(t2.UpdatedAt)
          FROM TrackingLog t2
          WHERE t2.ParcelID = p.ParcelID
      )
LEFT JOIN Hub h ON tl.HubID = h.HubID
LEFT JOIN VehicleAssignment va ON va.ShipmentID = s.ShipmentID
LEFT JOIN DeliveryAgent da ON va.AgentID = da.AgentID
LEFT JOIN Invoice i ON i.ShipmentID = s.ShipmentID
LEFT JOIN Payment pay ON pay.InvoiceID = i.InvoiceID
LEFT JOIN Complaint comp ON comp.ParcelID = p.ParcelID
ORDER BY c.CustomerID, p.ParcelID;


-- r. GenerateInvoice — creates an invoice record for a given ShipmentID

DELIMITER //
CREATE PROCEDURE GenerateInvoice(IN p_ShipmentID VARCHAR(10))
BEGIN
    DECLARE v_CustomerID VARCHAR(10);
    DECLARE v_InvoiceID  VARCHAR(10);

    SELECT p.CustomerID INTO v_CustomerID
    FROM Shipment s
    JOIN Parcel p ON s.ParcelID = p.ParcelID
    WHERE s.ShipmentID = p_ShipmentID;

    SET v_InvoiceID = CONCAT('INV', LPAD((SELECT COUNT(*) + 1 FROM Invoice), 3, '0'));

    INSERT INTO Invoice (InvoiceID, CustomerID, ShipmentID, SubtotalAmount, TaxAmount, DiscountAmount, TotalAmount,
                         InvoiceDate, DueDate, InvoiceStatus)
    VALUES (v_InvoiceID, v_CustomerID, p_ShipmentID, 0.00, 0.00, 0.00, 0.00,
            CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'Unpaid');
END //
DELIMITER ;


-- s. GetParcelHistory — returns full tracking timeline for a parcel with hub details

DELIMITER //
CREATE PROCEDURE GetParcelHistory(IN p_ParcelID VARCHAR(10))
BEGIN
    SELECT t.ParcelID,
           t.Status,
           t.UpdatedAt,
           h.HubName,
           h.City
    FROM TrackingLog t
    JOIN Hub h ON t.HubID = h.HubID
    WHERE t.ParcelID = p_ParcelID
    ORDER BY t.UpdatedAt ASC;
END //
DELIMITER ;


-- t. trg_TrackingLog_Notify — auto-inserts a Notification whenever a parcel status changes

DELIMITER //
CREATE TRIGGER trg_TrackingLog_Notify
AFTER INSERT ON TrackingLog
FOR EACH ROW
BEGIN
    DECLARE v_CustomerID VARCHAR(10);
    DECLARE v_NotifID    VARCHAR(10);

    SELECT p.CustomerID INTO v_CustomerID
    FROM Parcel p
    WHERE p.ParcelID = NEW.ParcelID;

    SET v_NotifID = CONCAT('N', LPAD((SELECT COUNT(*) + 1 FROM Notification), 3, '0'));

    INSERT INTO Notification (NotificationID, CustomerID, ParcelID, Message,
                               Channel, SentAt, IsRead)
    VALUES (v_NotifID, v_CustomerID, NEW.ParcelID,
            CONCAT('Your parcel ', NEW.ParcelID, ' status updated to: ', NEW.Status),
            'SMS', NOW(), FALSE);
END //
DELIMITER ;
