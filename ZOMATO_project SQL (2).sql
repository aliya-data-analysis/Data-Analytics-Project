--  -------------------CREATING DATABASE---------------------------
create database zomato;
use zomato;
--  --------------------checking whether local file import is enabled or not------------
SHOW VARIABLES LIKE 'local_infile';

--  -------------------enabling local file import ----------------------
SET GLOBAL local_infile = 1;

-- --------------------CREATING COUNTRY TABLE------------------
CREATE TABLE  COUNTRY (
    CountryID INT PRIMARY KEY,
    CountryName VARCHAR(50) NOT NULL
);
-- -------------------INSERTING VALUES IN COUNTRY TABLE---------------
INSERT INTO COUNTRY (CountryID, Countryname) VALUES
(1, 'India'),
(14, 'Australia'),
(30, 'Brazil'),
(37, 'Canada'),
(94, 'Indonesia'),
(148, 'New Zealand'),
(162, 'Phillippines'),
(166, 'Qatar'),
(184, 'Singapore'),
(189, 'South Africa'),
(191, 'Sri Lanka'),
(208, 'Turkey'),
(214, 'United Arab Emirates'),
(215, 'United Kingdom'),
(216, 'United States');

-- --------------------CREATING CURRENCY TABLE------------------
CREATE TABLE  CURRENCY (
    Currency VARCHAR(50) PRIMARY KEY,
    USDRate DOUBLE
);
-- -------------------INSERTING VALUES IN CURRENCY TABLE---------------
INSERT INTO CURRENCY (Currency, USDRate) VALUES
('Indian Rupees(Rs.)', 0.012),
('Dollar($)', 1),
('Pounds(Œ£)', 1.24),
('NewZealand($)', 0.6),
('Emirati Diram(AED)', 0.27),
('Brazilian Real(R$)', 0.2),
('Turkish Lira(TL)', 0.05),
('Qatari Rial(QR)', 0.27),
('Rand(R)', 0.051),
('Botswana Pula(P)', 0.073),
('Sri Lankan Rupee(LKR)', 0.0034),
('Indonesian Rupiah(IDR)', 0.000067);
-- --------------------CREATING MAIN TABLE WITH FOREIGN KEYS------------------
CREATE TABLE MAIN (
    RestaurantID INT,
    RestaurantName VARCHAR(100),
    CountryCode INT,
    City VARCHAR(50),
    Cuisines VARCHAR(100),
    Currency VARCHAR(50),
    Has_Table_booking INT,
    Has_Online_delivery INT,
    Is_delivering_now INT,
    Switch_to_order_menu INT,
    Price_range INT,
    Votes INT,
    Average_Cost_for_two INT,
    Rating DOUBLE,
    Year_Opening INT,
    Month_Opening INT,
    Day_Opening INT,
    Datekey_Opening DATE,
    -- Foreign keys
    CONSTRAINT fk_country FOREIGN KEY (CountryCode) REFERENCES COUNTRY(CountryID),
    CONSTRAINT fk_currency FOREIGN KEY (Currency) REFERENCES CURRENCY(Currency)
);


set global local_infile = 1;
show variables like 'loclal_infile';
-- --------------------------IMPORTING FILE---------------------
LOAD DATA LOCAL INFILE "C:\Users\new\Documents\Copy of Zomata - Copy (2).csv"
INTO TABLE main_table
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


-- ------------------CHEKING HOW MANY BLABK ROWS AR PRESENT----------------
SELECT COUNT(*) 
FROM main
WHERE Average_Cost_for_two = 0;

set sql_safe_updates = 0;
-- -------------------UPDATING 0 TO NULL IN Average_Cost_for_two---------------
UPDATE main
SET Average_Cost_for_two = NULL
WHERE Average_Cost_for_two = 0;

-- ---------------VERIFYING HOW MANY ROWS ARE IMPORTED------------------
select count(*) from MAIN;
DESCRIBE MAIN;

-- ------------------------CREATING CALENDAR TABLE-----------------------
CREATE TABLE Calendar (
    CalendarDate DATE PRIMARY KEY,
    Year INT,
    MonthNo INT,
    MonthFullName VARCHAR(20),
    Quarter VARCHAR(5),
    YearMonth VARCHAR(10),
    WeekdayNo INT,
    WeekdayName VARCHAR(20),
    FinancialMonth VARCHAR(5),
    FinancialQuarter VARCHAR(5)
);

-- -------------FILLING ALL THE COLUMNS BASED ON CALENDARDATE-----------------
UPDATE Calendar
SET 
    Year = YEAR(CalendarDate),                                  -- --------EXTRACT THE YEAR --------------
    MonthNo = MONTH(CalendarDate),                              -- --------EXTRACT MONTH----------------
    MonthFullName = DATE_FORMAT(CalendarDate, '%M'),            -- --------EXTRACT MONTHFULLNAME---------
    Quarter = CONCAT('Q', QUARTER(CalendarDate)),               -- --------EXTRACT QUARTER BASED ON CALENDER------
    YearMonth = DATE_FORMAT(CalendarDate, '%Y-%b'),				-- --------EXTRACT YAER - MONTH--------------
    WeekdayNo = WEEKDAY(CalendarDate) + 1,           			-- --------EXTRACT WEEKDAY NUMBER(MONDAY-1,...,SUNDAY-7)-------
    WeekdayName = DATE_FORMAT(CalendarDate, '%W'),				-- --------EXTRACT WEEKDAY NAME(MONDAY,TUESDAY,..etc)-----------
    FinancialMonth = CONCAT('FM', 								-- EXTRACT FINANCIAL MONTH BASED ON APRIL-MARCH (financial year)------
                            CASE 
                                WHEN MONTH(CalendarDate) >= 4 THEN MONTH(CalendarDate) - 3
                                ELSE MONTH(CalendarDate) + 9
                            END),
    FinancialQuarter = CONCAT('FQ', 						-- -------EXTRACT FINANCIAL QUARTER BASED ON FINANCIAL MONTH----------
                              CASE 
                                WHEN MONTH(CalendarDate) >= 4 THEN CEIL((MONTH(CalendarDate)-3)/3)
                                ELSE CEIL((MONTH(CalendarDate)+9)/3)
                              END);
select * from calendar;

-- -----------------------------Adding foreign key constraint from MAIN table to Calendar table-------------------
ALTER TABLE MAIN
ADD CONSTRAINT fk_calendar
FOREIGN KEY (Datekey_Opening) REFERENCES Calendar(CalendarDate);

describe main;
describe country;
describe currency;
describe calendar;


-------- Q3  converting average cost for two into USD -----------

SELECT 
    m.RestaurantName,
    m.Average_Cost_for_two,
    c.USDRate,
    (m.Average_Cost_for_two * c.USDRate) AS Cost_in_USD
FROM main m
JOIN CURRENCY c
ON m.Currency = c.Currency;

alter table main add column cost_in_usd double;

update main m
join currency c
on m.currency = c.currency
set m.cost_in_usd = m.average_cost_for_two * c.usdrate;

select RestaurantName, average_cost_for_two, cost_in_usd from main;

select * from main;
-------- Q4  Number of restaurents based on city and country -----------



SELECT 
    c.CountryName,
    m.City,
    COUNT(m.RestaurantID) AS Total_Restaurants
FROM main m
JOIN COUNTRY c
ON m.CountryCode = c.CountryID
GROUP BY c.CountryName, m.City
ORDER BY Total_Restaurants DESC;




-- Number of resturants based on opening based on Year , Quarter , Month -----

SELECT 
    c.Year,
    c.Quarter,
    c.MonthFullName AS Month,
    COUNT(m.RestaurantID) AS Number_of_Restaurants
FROM main m
JOIN calendar c
    ON m.Datekey_Opening = c.CalendarDate
GROUP BY 
    c.Year,
    c.Quarter,
    c.MonthFullName
ORDER BY 
    c.Year,
    c.Quarter,
    MIN(c.MonthNo);
    
    
    -- Count of Resturants based on Average Ratings ----
SELECT 
    CASE 
        WHEN Rating >= 4 THEN 'Excellent (4-5)'
        WHEN Rating >= 3 THEN 'Good (3-4)'
        WHEN Rating >= 2 THEN 'Average (2-3)'
        ELSE 'Poor (0-2)'
    END AS Rating_Category,
    COUNT(RestaurantID) AS Number_of_Restaurants
FROM main
GROUP BY Rating_Category
ORDER BY Number_of_Restaurants DESC;

-- Q7: Number of Restaurants by Price Bucket
use zomato;
SELECT
    CASE
        WHEN Average_Cost_for_two IS NULL THEN 'Unknown'
        WHEN Average_Cost_for_two < 500 THEN 'Low'
        WHEN Average_Cost_for_two <= 2000 THEN 'Medium'
        ELSE 'High'
    END AS Price_Bucket,
    COUNT(*) AS Total_Restaurants
FROM main
GROUP BY Price_Bucket
ORDER BY Total_Restaurants DESC;

-- Q8: Percentage of Restaurants with Table Booking

SELECT 
    COUNT(*) AS Total_Restaurants,
    
    SUM(CASE 
            WHEN Has_Table_booking = 1 THEN 1 
            ELSE 0 
        END) AS Table_Booking_Count,
    
    ROUND(
        (SUM(CASE 
                WHEN Has_Table_booking = 1 THEN 1 
                ELSE 0 
            END) * 100.0) / COUNT(*),
        2
    ) AS Table_Booking_Percentage
FROM MAIN;
 
 #Q 9:
 
 
SELECT 
    (CAST(SUM(CASE WHEN Has_Online_delivery = 'Yes' THEN 1 ELSE 0 END) AS BINARY) / 
    COUNT(*)) * 100 AS PercentageOnlineDelivery
FROM main;

#Q 10:

SELECT                                        
    RestaurantName,
    City,
    Cuisines,
    Rating
FROM
    main 
    WHERE
    Cuisines like '%Italian%'
    AND 
    City = 'Mumbai'
    AND Rating>=4.0

ORDER BY
Rating DESC;

-- toatl number of restaurants
SELECT COUNT(*) AS Total_Restaurants
FROM main;

-- avg rating
SELECT ROUND(AVG(Rating), 2) AS Avg_Rating
FROM main;

-- 
SELECT ROUND(AVG(cost_in_usd), 2) AS Avg_Cost_USD
FROM main;