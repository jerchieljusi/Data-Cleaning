# Nashville Housing Data Cleaning

Cleaning your data is an important process in the early process of data analysis. This is to ensure your data is valid and proper before doing any big step to having a data driven solution to the problem at hand. Few cases that makes your data "dirty" is having incomplete data where your data is missing values, inconsistent data where maybe the data type is not correct, or even duplicate data where some data just repeats itself. Obviously, there are many steps and aspects to consider when cleaning data. I feel that those are just the very common ones I have seen so far. 

For this repo, I decided to practice data cleaning using SQL Server. I am using the [Nashville Housing Dataset](https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx)

## Creating copy of original table
I make it a practice to always create a copy of the original table before doing any queries so that I can preserve the original data. If any mistakes were to occur, I can refer back to the original data to fix the error.

```sql 
DROP TABLE IF EXISTS dbo.housing_new; 
SELECT * INTO dbo.housing_new FROM dbo.housing;
```

From this point on, we will be using dbo.housing_new as the table to get data from 

## Standardized SaleDate format
Saledate column is in datetime format. Briefly looking at the data, the time for all rows are 0 which I see no real purpose for analysis so we should remove them. 

```sql
ALTER TABLE dbo.housing_new
ALTER COLUMN SaleDate DATE; 
```
### Populate null values on PropertyAddress with exisiting data 
Let's check the null values on PropertyAddress

```sql
SELECT * 
FROM dbo.housing_new
WHERE PropertyAddress IS NULL; 
```

Briefly looking over the ID, there are some ParcelID that repeats so we can assume that the ParcelID that are the same will also having the same PropertyAddress. We can use the ParcelID with existing PropertyAddress as the reference point for the missing address with the same ParcelId. 

I used the JOIN() to join the data within itself to see that PropertyAddress that have NULL values will have an already existing PropertyAddress. 

```sql
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM dbo.housing_new AS a
JOIN dbo.housing_new AS b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL; 
```
By using ISNULL() we can populate the null in a.PropertyAddress with existing address from b.PropertyAddress. 
ISNULL() SYNTAX
```sql
ISNULL(check_expression, replacement_value);
```
### Overview of ISNULL()
check_expression: expression to be checked for NULL (can be of any type).
replacement_value: expression to be returned if check_expression is NULL. 

```sql
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
FROM dbo.housing_new AS a
JOIN dbo.housing_new AS b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE a
  SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
 from dbo.housing_new AS a
 JOIN dbo.housing_new AS b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;
```
## Breaking address into individual columns (address, city)

PropertyAddress contains of address and city with a delimited of ','. We will use SUBSTRING() and CHARINDEX() to separate the address and city. 
SUBSTRING() Syntax
```sql
SUBSTRING(expression, start, length)
```
### Overview of SUBSTRING()
Expression: character, binary, text.
Start: expression that specifies where the returned characters start.
Length: positive integer that specifies how many characters of the expresssion will be returned.

CHARINDEX Syntax
```sql 
CHARINDEX(expressionToFind, ExpressionToSearch, [StartLocation])
```
### Overview of CHARINDEX()
ExpressionToFind: a character expression containing the sequence to find.
ExpressionToSearch: a character expression to search 
Start_Location: an integer expression at which the search starts. 

```sql 
SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, 
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM dbo.housing_new;
```
Add the two columns to our existing data

```sql
ALTER TABLE dbo.housing_new 
ADD PropertyStreetAddress NVARCHAR(255);
```
```sql
ALTER TABLE dbo.housing_new
ADD PropertyCity NVARCHAR(255);
```
```sql
UPDATE dbo.housing_new
	SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
```
```sql
UPDATE dbo.housing_new
	SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
```
We will do the same thing to OwnerAddress column using PARSENAME(). 
PARSENAME() Syntax
```sql
PARSENAME('columnname',objectpiece)
```
### Overview of PARSENAME()
columnname: parameter that holds the name of the object for which to retrieve the specified object part
objectpiece: object part to return 

```sql
SELECT 
	PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 3) AS Address,
	PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 2) AS City,
	PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 1) AS State 
FROM dbo.housing_new
```
***NOTE: the original delimited for this is ',', however, PARSENAME does not recognize commas. I used REPLACE to change the comma to a period '.'.***

Create and update new columns. 

```sql
ALTER TABLE dbo.housing_new 
ADD OwnerStreetAddress NVARCHAR(255)
```
```sql
ALTER TABLE dbo.housing_new 
ADD OwnerCity NVARCHAR(255)
```
```sql
ALTER TABLE dbo.housing_new 
ADD OwnerState NVARCHAR(255)
```
```sql
UPDATE dbo.housing_new 
SET OwnerStreetAddress= PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 3) 
```
```sql
UPDATE dbo.housing_new 
SET OwnerCity= PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 2) 
```
```sql
UPDATE dbo.housing_new 
SET OwnerState= PARSENAME(REPLACE(OWNERADDRESS, ',', '.'), 1)
```

## Changing SoldAsVacant column to only Yes and No values
```sql
UPDATE dbo.housing_new
SET SoldAsVacant = (
SELECT 
	CASE 
	 WHEN SoldAsVacant = 'Y' THEN 'Yes' 
	 WHEN SoldAsVacant = 'N' THEN 'No' 
	 ELSE SoldAsVacant 
	 END AS SoldAsVacant)
FROM dbo.housing_new
```
