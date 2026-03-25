CREATE TABLE RAW_ROOM_MASTER (
    RoomID          NUMBER PRIMARY KEY,
    RoomType        VARCHAR2(50),
    FloorNumber     NUMBER,
    BedType         VARCHAR2(50),
    BaseRate        NUMBER,
    RoomStatus      VARCHAR2(50),
    MaxOccupancy    NUMBER,
    Amenities       VARCHAR2(50),
    LastCleanedDate DATE
);

CREATE TABLE RAW_GUEST_MASTER (
    GuestID          NUMBER PRIMARY KEY,
    FirstName        VARCHAR2(50),
    LastName         VARCHAR2(50),
    Gender           VARCHAR2(50),
    DateOfBirth      DATE,
    Email            VARCHAR2(50),
    PhoneNumber      VARCHAR2(50),
    AddressLine1     VARCHAR2(50),
    AddressLine2     VARCHAR2(50),
    City             VARCHAR2(50),
    State            VARCHAR2(50),
    Country          VARCHAR2(50),
    IDProofType      VARCHAR2(50),
    IDProofNumber    VARCHAR2(50),
    RegistrationDate DATE
);

CREATE TABLE RAW_CHECKIN_CHECKOUT (
    StayID           NUMBER,
    GuestID          NUMBER,
    RoomID           NUMBER,
    CheckinDateTime  DATE,
    CheckoutDateTime DATE,
    BookingSource    VARCHAR2(50),
    NumberOfGuests   NUMBER,
    RoomRate         VARCHAR2(50),
    ExtraCharges     NUMBER,
    DiscountAmount   NUMBER,
    TotalAmount      NUMBER,
    PaymentMode      VARCHAR2(50),
    Status           VARCHAR2(50),
    LastUpdated      DATE
);

CREATE TABLE STG_GUEST_STAY (
    StayID            NUMBER           PRIMARY KEY,
    GuestID           NUMBER           NOT NULL,
    RoomID            NUMBER           NOT NULL,
    GuestFullName     VARCHAR2(50),
    RoomType          VARCHAR2(50),
    BedType           VARCHAR2(50),
    CheckinDateTime   DATE,
    CheckoutDateTime  DATE,
    BookingSource     VARCHAR2(50),
    NumberOfGuests    NUMBER,
    RoomRate          NUMBER,
    ExtraCharges      NUMBER     DEFAULT 0,
    DiscountAmount    NUMBER     DEFAULT 0,
    TotalAmount       NUMBER,
    StayDuration      NUMBER(10,2),
    StayDurationDays  NUMBER(10,2),
    PaymentMode       VARCHAR2(50),
    Status            VARCHAR2(50),
    LastUpdated       DATE,
    ETL_LOAD_DATE     DATE             DEFAULT SYSDATE,
    ETL_STATUS        VARCHAR2(50)     DEFAULT 'ACTIVE'
);

CREATE TABLE DAILY_OCCUPANCY_REPORT (
    ReportID       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ReportDate     DATE,
    TotalCheckins  NUMBER,
    TotalCheckouts NUMBER,
    OccupiedRooms  NUMBER,
    TotalRevenue   NUMBER(10,2),
    AvgRoomRate    NUMBER(10,2),
    RoomType       VARCHAR2(50),
    CreatedAt      DATE             DEFAULT SYSDATE
);

CREATE TABLE STAY_AUDIT_LOG (
    AuditID     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    StayID      NUMBER,
    ActionType  VARCHAR2(50),
    OldStatus   VARCHAR2(50),
    NewStatus   VARCHAR2(50),
    OldTotalAmt NUMBER(10,2),
    NewTotalAmt NUMBER(10,2),
    ChangedBy   VARCHAR2(50)     DEFAULT USER,
    ChangedOn   DATE             DEFAULT SYSDATE
);


CREATE OR REPLACE PROCEDURE PRC_GENERATE_DAILY_REPORT AS
BEGIN
    INSERT INTO DAILY_OCCUPANCY_REPORT (
        ReportDate,
        TotalCheckins,
        TotalCheckouts,
        OccupiedRooms,
        TotalRevenue,
        AvgRoomRate,
        RoomType
    )
    SELECT 
        TRUNC(SYSDATE) AS ReportDate,
        COUNT(CASE WHEN TRUNC(CheckinDateTime) = TRUNC(SYSDATE) THEN 1 END) AS TotalCheckins,
        COUNT(CASE WHEN TRUNC(CheckoutDateTime) = TRUNC(SYSDATE) THEN 1 END) AS TotalCheckouts,
        COUNT(CASE WHEN Status = 'CheckedIn' THEN 1 END) AS OccupiedRooms,
        SUM(CASE WHEN Status = 'CheckedOut' AND TRUNC(CheckoutDateTime) = TRUNC(SYSDATE) THEN TotalAmount ELSE 0 END) AS TotalRevenue,
        AVG(RoomRate) AS AvgRoomRate,
        RoomType
    FROM STG_GUEST_STAY
    GROUP BY RoomType;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error generating report: ' || SQLERRM);
END;
/

CREATE OR REPLACE TRIGGER TRG_STAY_CHANGE_AUDIT
AFTER INSERT OR UPDATE ON STG_GUEST_STAY
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO STAY_AUDIT_LOG (StayID, ActionType, NewStatus, NewTotalAmt)
        VALUES (:NEW.StayID, 'INSERT', :NEW.Status, :NEW.TotalAmount);
    ELSIF UPDATING THEN
        INSERT INTO STAY_AUDIT_LOG (
            StayID, 
            ActionType, 
            OldStatus, 
            NewStatus, 
            OldTotalAmt, 
            NewTotalAmt
        )
        VALUES (
            :NEW.StayID, 
            'UPDATE', 
            :OLD.Status, 
            :NEW.Status, 
            :OLD.TotalAmount, 
            :NEW.TotalAmount
        );
    END IF;
END;
/


