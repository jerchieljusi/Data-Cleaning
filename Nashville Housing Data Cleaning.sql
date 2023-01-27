--/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP (1000) [UniqueID ]
--      ,[ParcelID]
--      ,[LandUse]
--      ,[PropertyAddress]
--      ,[SaleDate]
--      ,[SalePrice]
--      ,[LegalReference]
--      ,[SoldAsVacant]
--      ,[OwnerName]
--      ,[OwnerAddress]
--      ,[Acreage]
--      ,[TaxDistrict]
--      ,[LandValue]
--      ,[BuildingValue]
--      ,[TotalValue]
--      ,[YearBuilt]
--      ,[Bedrooms]
--      ,[FullBath]
--      ,[HalfBath]
--  FROM [Nashville Housing].[dbo].[housing]

SELECT * 
FROM dbo.housing

-- Create a copy of the original table to preserve original data before continuing.
-- If any mistakes were done throughout the analysis process, we have the original data to refer back to fix them.

DROP TABLE IF EXISTS dbo.housing_new;
SELECT * INTO dbo.housing_new FROM dbo.housing;

-- From this point on, we should be using our new table of dbo.housing_new

-- Standardized SaleDate format 
-- SaleDate is in datetime format, however, time in this case serves no real purpose so it's best to remove them to have an efficient format. 

ALTER TABLE dbo.housing_new 
ALTER COLUMN SaleDate DATE;

-- Populate PropertyAddress Data
-- Some cells in the PropertyAddress column are missing its address.

SELECT * 
FROM dbo.housing_new
WHERE PropertyAddress IS NULL

-- The PropertyAddress should not change. If we have a reference point to base it off of, we can populate the address.
-- Briefly looking over the ID, there are some ParcelID that repeats so we can assume that the all ParcelID that are the same will also have the same PropertyAddress. 
-- We can use ParcelID with existing PropertyAddress as the reference point for the missing address with the same ParcelID. Let's check!

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM dbo.housing_new AS a
JOIN dbo.housing_new AS b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL 

-- By using ISNULL() we can populate the null in a.PropertyAddress with existing address from b.PropertyAddress
-- ISNULL(a.PropertyAddress, b.PropertyAddress) 

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
FROM dbo.housing_new AS a
JOIN dbo.housing_new AS b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL 

-- Use UPDATE to update our existing table with the address we got from b.PropertyAddress to a.PropertyAddress 

UPDATE a
	SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM dbo.housing_new AS a
JOIN dbo.housing_new AS b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL 


-- BREAKINGOUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY) 

-- PropertyAddress contains the address and city with a delimiter of ','. 
-- We will be using SUBSTRING and CHARINDEX to separte the address and city.
-- SYNTAX: SUBSTRING(expression, start, length)
-- Expression: character, binary, text.
-- Start: expression that specifies where the returned characters start.
-- Length: positive integer that specifies how many characters of the expresssion will be returned.
-- SYNTAX: CHARINDEX(expressionToFind, ExpressionToSear [, Start_Location])
-- ExpressionToFind: a character expression containing the sequence to find.
-- ExpressionToSearch: a character expression to search 
-- Start_Location: an integer expression at which the search starts. 

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, 
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM dbo.housing_new
-- -1 will basically the query not to include our delimiter ",". 

-- We need to add these two columns to our existing data

ALTER TABLE dbo.housing_new 
ADD PropertyStreetAddress NVARCHAR(255)

ALTER TABLE dbo.housing_new
ADD PropertyCity NVARCHAR(255)
	
-- Now update those column by inputting the split address and city we got
UPDATE dbo.housing_new
	SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

UPDATE dbo.housing_new
	SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- We will do the same thing to the OwnerAddress column using PARSENAME
-- SYNTAX: ('columnname', objectpiece) 
-- columnname: parameter that holds the name of the object for which to retrieve the specified object part
-- objectpiece: object part to return 
-- We used REPLACE() in this case to replace the ',' to '.' because REPLACE() only recognizes periods and not commas. 
SELECT 
	PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 3) AS Address,
	PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 2) AS City,
	PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 1) AS State 
FROM dbo.housing_new

-- Create new columns for the Address, City, and State from the OwnerAddress field 
ALTER TABLE dbo.housing_new 
ADD OwnerStreetAddress NVARCHAR(255)

ALTER TABLE dbo.housing_new 
ADD OwnerCity NVARCHAR(255)

ALTER TABLE dbo.housing_new 
ADD OwnerState NVARCHAR(255)

-- Update our table with the new information we have 

UPDATE dbo.housing_new 
SET OwnerStreetAddress= PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 3) 

UPDATE dbo.housing_new 
SET OwnerCity= PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 2) 


UPDATE dbo.housing_new 
SET OwnerState= PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 1)

-- Briefly looking at the data, it seems that in the column SoldAsVacant the data recorded are Yes, No, Y and N
-- Lets fix this so that the only data recorded are Yes and No
-- Since we are only updating one column, we can use a subquery to change and update our SoldAsVacant data

UPDATE dbo.housing_new
SET SoldAsVacant = (
SELECT 
	CASE 
	 WHEN SoldAsVacant = 'Y' THEN 'Yes' 
	 WHEN SoldAsVacant = 'N' THEN 'No' 
	 ELSE SoldAsVacant 
	 END AS SoldAsVacant)
FROM dbo.housing_new
