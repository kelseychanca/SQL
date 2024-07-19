/*SQL Data Exploration*/
--Retrieve all data from the Supermarket_Detail table
SELECT *
FROM PortfolioProject..[Supermarket_Detail];

--Total price of each transaction
SELECT YEAR (date) AS Year, product_categories_id AS Product_ID, quantities AS Quantities, prices AS Price, quantities*prices AS Total_Price
FROM PortfolioProject..[Supermarket_Detail]
ORDER BY Year, Product_ID;

--Join table to get product categories
SELECT YEAR(date) AS Year, c.product_categories_item AS Product_Categories, quantities AS Quantities, prices AS Prices, quantities*prices AS Total_Price
FROM PortfolioProject..[Supermarket_Detail] s, PortfolioProject..[Categories] c
WHERE s.product_categories_id = c.product_categories_id
ORDER BY Year, Product_Categories;

--Total price for each category per year, calculated using a join table
SELECT YEAR(date) AS Year, c.product_categories_item AS Product_Categories, SUM(quantities*prices) AS Total_Price
FROM PortfolioProject..[Supermarket_Detail] s, PortfolioProject..[Categories] c
WHERE s.product_categories_id = c.product_categories_id
GROUP BY YEAR(date), c.product_categories_item
ORDER BY Year, Product_Categories;

--Rounded Annual Totals
SELECT YEAR(date) AS Year, ROUND(SUM(quantities*prices),2) AS Total_Price
FROM PortfolioProject..[Supermarket_Detail]
GROUP BY YEAR(date)
ORDER BY Year, Total_Price;

--Total price for each category per year, along with rounded annual totals and their division as a percentage
SELECT t1.Year, t1.Product_Categories, ROUND(t1.Total_Price, 2) AS Total_Price, 
		t2.Total_Price AS Total_Price_Per_Year, ROUND((t1.Total_Price / t2.Total_Price) * 100, 2) AS Percentage
FROM
  (
	SELECT YEAR(s.date) AS Year, c.product_categories_item AS Product_Categories, SUM(s.quantities * s.prices) AS Total_Price
    FROM PortfolioProject..[Supermarket_Detail] s, PortfolioProject..[Categories] c 
	WHERE s.product_categories_id = c.product_categories_id
	GROUP BY YEAR(s.date), c.product_categories_item
  ) t1 --Total price for each category per year
,
  (
	SELECT YEAR(date) AS Year, SUM(quantities * prices) AS Total_Price
    FROM PortfolioProject..[Supermarket_Detail]
    GROUP BY YEAR(date)
  ) t2 --Rounded Annual Totals
WHERE t1.Year = t2.Year
ORDER BY t1.Year, t1.Product_Categories;

--Find the city total price in 2021
SELECT YEAR(date) AS Year, city AS City, SUM(quantities * prices) AS Total_Price
FROM PortfolioProject..[Supermarket_Detail]
WHERE YEAR(date) LIKE '%2021%'
GROUP BY YEAR(date), city
ORDER BY Year, City;

--Find the highest total price per city in 2021
SELECT Year, MAX(Total_Price) AS Total_Price
FROM(
	SELECT YEAR(date) AS Year, city AS City, SUM(quantities * prices) AS Total_Price
	FROM PortfolioProject..[Supermarket_Detail]
	WHERE YEAR(date) LIKE '%2021%'
	GROUP BY YEAR(date), city
) AS t1
GROUP BY Year;

--Find the city with the highest total price in 2021
WITH t1 AS (
    SELECT YEAR(date) AS Year, city AS City, SUM(quantities * prices) AS Total_Price
	FROM PortfolioProject..[Supermarket_Detail]
	WHERE YEAR(date) LIKE '%2021%'
	GROUP BY YEAR(date), city
)
SELECT t1.Year, t1.City, t1.Total_Price AS Total_Price
FROM t1, 
	(
		SELECT Year, MAX(Total_Price) AS Total_Price
		FROM t1
		GROUP BY Year
	) AS t2 
WHERE t1.Year = t2.Year AND t1.Total_Price = t2.Total_Price;

--Retrieve the top 5 results for the total price in each year and city for the year 2021
SELECT TOP 5 YEAR(date) AS Year, city AS City, SUM(quantities * prices) AS Total_Price
FROM PortfolioProject..[Supermarket_Detail]
WHERE YEAR(date) LIKE '%2021%'
GROUP BY YEAR(date), city
ORDER BY Total_Price DESC;

-- Drop the table if it already exists
IF OBJECT_ID('PortfolioProject..[TopCitySales]', 'U') IS NOT NULL
    DROP TABLE PortfolioProject..[TopCitySales];
GO

-- Create the table with the desired columns
CREATE TABLE PortfolioProject..[TopCitySales]
(
    Year INT,
    City VARCHAR(255),
    Total_Price DECIMAL(18, 2)
);
GO

-- Switch to the target database context
USE PortfolioProject;
GO

-- Drop the view if it already exists
IF OBJECT_ID('TopCitySales_View', 'V') IS NOT NULL
    DROP VIEW TopCitySales_View;
GO

-- Create the view based on the SQL query
CREATE VIEW TopCitySales_View AS
SELECT TOP 5 YEAR(date) AS Year, city AS City, SUM(quantities * prices) AS Total_Price
FROM Supermarket_Detail
WHERE YEAR(date) LIKE '%2021%'
GROUP BY YEAR(date), city
ORDER BY Total_Price DESC;
GO

-- Insert the data into the table using the SQL query
INSERT INTO PortfolioProject..[TopCitySales] (Year, City, Total_Price)
SELECT TOP 5 YEAR(date) AS Year, city AS City, SUM(quantities * prices) AS Total_Price
FROM PortfolioProject..[Supermarket_Detail]
WHERE YEAR(date) LIKE '%2021%'
GROUP BY YEAR(date), city
ORDER BY Total_Price DESC;

--Retrieve the count of payment methods used per year
SELECT YEAR(date) AS Year, payment_methods AS Payment_Methods, Count(payment_methods) AS Count
FROM PortfolioProject..[Supermarket_Detail]
WHERE payment_methods IN ('Cash', 'Credit Card', 'Debit Card')
GROUP BY YEAR(date), payment_methods
ORDER BY Year, Payment_Methods;

--Calculate the count of each payment method per year
SELECT
    Year,
    SUM(CASE WHEN payment_methods = 'Cash' THEN 1 ELSE 0 END) AS Cash,
    SUM(CASE WHEN payment_methods = 'Credit Card' THEN 1 ELSE 0 END) AS Credit_Card,
    SUM(CASE WHEN payment_methods = 'Debit Card' THEN 1 ELSE 0 END) AS Debit_Card
FROM
    (
        SELECT YEAR(date) AS Year, payment_methods
        FROM PortfolioProject..[Supermarket_Detail]
        WHERE payment_methods IN ('Cash', 'Credit Card', 'Debit Card')
    ) AS t1
GROUP BY Year
ORDER BY Year;

--PivotTable Payment Methods and Counts per Year in dynamic
DECLARE @PaymentMethods NVARCHAR(MAX);
DECLARE @NumberOfPaymentMethods NVARCHAR(MAX);

-- Step 1: Retrieve distinct payment methods
SELECT @PaymentMethods = STRING_AGG(QUOTENAME(payment_methods), ', ')
FROM (
    SELECT DISTINCT payment_methods
    FROM PortfolioProject..[Supermarket_Detail]
    WHERE payment_methods IS NOT NULL
) AS PaymentMethodList;

-- Step 2: Construct the dynamic SQL query
SET @NumberOfPaymentMethods = '
SELECT Year,' + @PaymentMethods + '
FROM
    (
        SELECT YEAR(date) AS Year, payment_methods
        FROM PortfolioProject..[Supermarket_Detail]
        WHERE payment_methods IS NOT NULL
    ) AS SourceTable
PIVOT
(
    COUNT(payment_methods)
    FOR payment_methods IN (' + @PaymentMethods + ')
) AS PivotTable
ORDER BY Year;'; --Converts rows into columns, counting each payment method

-- Step 3: Execute the dynamic SQL query
EXEC sp_executesql @NumberOfPaymentMethods;
