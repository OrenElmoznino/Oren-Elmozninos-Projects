use master
create database Sales
go
use Sales

create table CreditCard
(
CreditCardID int primary key identity(1,1),
CardType nvarchar(50) not null,
CardNumber nvarchar(25) not null,
ExpMonth tinyint not null,
ExpYear smallint not null,
ModifiedDate datetime not null default getdate(),
constraint CreditCard_ExpMonth_CK check (ExpMonth >=1 and ExpMonth <= 12),
constraint CreditCard_ExpYear_CK check (ExpYear >= 1950), --introduction of the modern credit card ;)
constraint CreditCard_CardNumber_UQ unique(CardNumber), --Every CreditCardID represents a specific, single credit card - therefore the numbers should also be unique
constraint CreditCard_CardNumber_CK check (len(CardNumber) between 12 and 19) --Credit card numbers don't tend to be shorter than 12 characters or longer than 19
)

insert into CreditCard
values
('Visa', '1234567890123456', 12, 2024, '2024-6-30'),
('Visa', '9080706050403020', 3, 2026, default),
('MasterCard', '111111111111111', 10, 2030, '2024-7-12'),
('AmEx', '222222222222222', 2, 2027, '2022-1-1'),
('Visa', '0000000000000001', 1, 2031, '2019-2-12'),
('Visa', '0000000000000002', 5, 2029, '2002-11-16'),
('MasterCard', '111222333444555', 6, 2026, default),
('AmEx', '100200300400500', 9, 2028, '2020-3-14'),
('Visa', '0112358132134558', 7, 2027, '2021-6-6'),
('MasterCard', '314159265358979', 10, 2041, '2015-3-14')
create table SpecialOfferProduct
(
SpecialOfferID int not null,
ProductID int not null,
ModifiedDate datetime default getdate(),
constraint SpecialOfferIProduct_SpecialOfferID_ProductID_PK primary key (SpecialOfferID, ProductID)
)

insert into SpecialOfferProduct
values
(1,1,default),
(1,2,default),
(1,3,default),
(1,4,default),
(1,5,default),
(2,1,'2024-12-31'),
(2,3,'2024-12-31'),
(2,5,'2024-12-31'),
(3,4,'2024-1-1'),
(4,1,null)


create table SalesTerritory
(
TerritoryID int primary key identity(1,1),
Name nvarchar(50) not null,
CountryRegionCode nvarchar(3) not null,
[Group] nvarchar(50) not null,
SalesYTD money not null,
SalesLastYear money not null,
CostYTD money not null,
CostLastYear money not null,
ModifiedDate datetime not null default getdate(),
constraint SalesTerritory_SalesYTD_CK check (SalesYTD > 0),
constraint SalesTerritory_SalesLastYear_CK check (SalesLastYear >= 0),
constraint SalesTerritory_CostYTD_CK check (CostYTD > 0),
constraint SalesTerritory_CostLastYear_CK check (CostLastYear >= 0)
-- Logic behind last four constraints: Sales and Cost cannot get a negative value - you can't sell or buy for negative money... 
)

insert into SalesTerritory
values
('Tel Aviv', 'ISR', 'Asia', 693580.32, 1000000, 50000, 121054.43, default),
('Sharon', 'ISR', 'Asia', 42000, 2100.21, 100210, 3100, '2024-11-16'),
('Darom', 'ISR', 'Asia', 123456.78, 765432, 1236.4,3001.32 , default),
('Tzafon', 'ISR', 'Asia', 600000, 780543, 121212, 8887.43, default),
('Jerusalem', 'ISR', 'Asia', 900999, 1234567, 8765.4, 9876.5, '2023-6-5'),
('China', 'CHN', 'Asia', 3000000, 2000000, 170000, 310000, default),
('France', 'FRA', 'Europe', 320000, 970000, 100000, 2000000, default),
('United States', 'USA', 'North America', 9100000, 10000000, 210000, 314159.265, '2023-7-21'),
('England', 'UK', 'Europe', 710920, 1234567, 8765.4, 12345.6, default),
('Scotland', 'UK', 'Europe', 12345.32, 400, 3100, 987.73, default)

create table Customer
(
CustomerID int primary key identity(1,1),
PersonID int,
StoreID int,
TerritoryID int,
AccountNumber int not null,
ModifiedDate datetime not null default getdate(),
constraint Customer_TerritoryID_FK foreign key (TerritoryID)
		references SalesTerritory(TerritoryID),
constraint Customer_AccountNumber_UQ unique(AccountNumber) -- Customer's account number is an identifier and therefore must be unique
)

insert into Customer
values
(213456,234,1,476, default),
(678932,547,9,777, '2020-3-14'),
(null,234,1,1234, default),
(123456,null,1,600, '2004-4-4'),
(123457,999,4,314, default),
(null,547,7,2100, default),
(123458,999,10,12345, '2010-9-12'),
(null,547,2,9090, default),
(null,null,3,2348, default),
(123459,999,4,9785, default)

create table SalesPerson
(
BusinessEntityID int primary key identity(1,1),
TerritoryID int,
SalesQuota money,
Bonus money not null default 0,
CommissionPct smallmoney not null,
SalesYTD money not null,
SalesLastYear money not null,
ModifiedDate datetime not null default getdate(),
constraint SalesPerson_TerritoryID_FK foreign key (TerritoryID)
		references SalesTerritory(TerritoryID),
constraint SalesPerson_CommissionPct_CK check (CommissionPct >= 0 and CommissionPct <= 1), -- Employee can't take a negative % of the transaction for themselves, or more than all of it
constraint SalesPerson_SalesYTD_CK check (SalesYTD >= 0), -- You can't sell for a negative value
constraint SalesPerson_SalesLastYear_CK check (SalesLastYear >=0), -- You can't sell for a negative value
constraint SalesPerson_SalesQuota_CK check (SalesQuota >= 0 or SalesQuota is null), -- Doesn't make sense for the quota to be negative; we still have to allow nulls so the two valid options for the quota are to be non-negative or to be null
constraint SalesPerson_Bonus_CK check (Bonus >= 0) -- Assuming Bonus is given to a salesperson for meeting their quota - doesn't make sense for the bonus to be negative (you wouldn't decrease their salary for doing their job properly)
)

insert into SalesPerson
values
(3, 50000, 5000, 0.03, 200000, 300000, '2019-12-12'),
(2, 25000, 1200, 0.05, 10000, 50000, '2019-12-12'),
(9, null, default, 0.01, 130000, 220000, '2019-12-12'),
(1, 75000, 7500, 0.10, 53012.12, 75757, default),
(10, 30000, 2000, 0.06, 31415.92, 42066, '2019-12-12'),
(1, null, default, 0.03, 8000, 5000, default),
(4, 51000, 1500, 0.07, 20000, 100000, '2019-12-12'),
(7, 21000, 1300, 0.08, 2000, 21212, default),
(8, 54892, default, 0.02, 12121, 76543, default),
(4, 97800, 2131, 0.06, 130000, 120000, '2019-12-12')

create table Address
(
AddressID int primary key identity(1,1),
AddressLine1 nvarchar(60) not null,
AddressLine2 nvarchar(60),
City nvarchar(30) not null,
StateProvinceID int not null,
PostalCode nvarchar(15) not null, -- I didn't make it unique because in small towns many houses can share the same postal code
ModifiedDate datetime not null default getdate()
)

insert into Address
values
('Random St. 7','Apt 1','Tel Aviv',1,'10000','1997-3-11'),
('Olive St. 3',null,'New York City',31,'87654','1965-2-4'),
('Silk Av. 6','Floor 3, Apt 7','Beijing',943,'90652',default),
('Placeholder Rd.','POB 334','Paris',11,'24726','2024-7-26'),
('Filler Alley 6', null,'Dundee',2,'010101',default),
('4 Privet Drive',null,'Little Whinging',44,'9007','1980-7-31'),
('155 Country Lane',null,'Cottington',45,'424242','2001-5-25'),
('221B Baker Street',null,'London',46,'123456',default),
('12 Rue Gotlib','21 Ar.','Paris',11,'0102030405','2015-10-19'),
('Apple Road 15',null,'Tel Aviv',1,'10001',default)

create table ShipMethod
(
ShipMethodID int primary key identity(1,1),
Name nvarchar(50) not null,
ShipBase money not null,
ShipRate money not null,
ModifiedDate datetime not null default getdate(),
constraint ShipMethod_Name_UQ unique(Name), --Each ShipMethodID corresponds to a name and each ShipMethodID must be unique - therefore, method names cannot repeat as well 
constraint ShipMethod_ShipBase_CK check (ShipBase >= 0),
constraint ShipMethod_ShipRate_CK check (ShipRate >= 0) -- Shipping can't have negative costs
)
insert into ShipMethod
values
('Car - Standard',10,1.25,default),
('Car - Next Day Delivery',15.15,2.25,'2021-12-11'),
('Cargo Plane',50,12.15,'2010-3-3'),
('Cargo Ship',20,3.99,'2000-2-2'),
('Motorcycle - Standard',5.75,0.99,default),
('Motorcycle - Express',7.75,1.5,'2017-9-6'),
('F-35 Lightning Falcon II',75,20,'2006-12-15'),
('Unicycle Express',0.5,0.15,default),
('Snail Delivery',1.15,0.65,'2002-11-16'),
('Carrier Pigeon',1.5,1.5,'1990-5-12')

create table CurrencyRate
(
CurrencyRateID int primary key identity(1,1),
CurrencyRateDate datetime not null,
FromCurrencyCode nchar(3) not null,
ToCurrencyCode nchar(3) not null,
AverageRate money not null,
EndOfDayRate money not null,
ModifiedDate datetime not null default getdate(),
constraint CurrencyRate_AverageRate_CK check (AverageRate > 0), -- See below
constraint CurrencyRate_EndOfDayRate_CK check (EndOfDayRate > 0) -- Money has to have positive value
)

insert into CurrencyRate
values
('2024-08-09','NIS', 'USD', 3.5,3.7304769,'2024-08-09'),
('2024-08-09','NIS', 'EUR', 4,4.0707912,'2024-08-09'),
('2024-08-09','NIS', 'GBP', 5,4.7510042,'2024-08-09'),
('2024-08-09','NIS', 'CNY', 0.5,0.52045317,'2024-08-09'),
('2024-08-09','NIS', 'NIS', 1,1,'2024-08-09'),
('2024-08-01','NIS', 'USD', 3.5,3.75657,'2024-08-01'),
('2024-08-01','NIS', 'EUR', 4,4.06604,'2024-08-01'),
('2024-08-01','NIS', 'GBP', 5,4.82432,'2024-08-01'),
('2024-08-01','NIS', 'CNY', 0.5,0.51979,'2024-08-01'),
('2024-08-01','NIS', 'NIS', 1,1,'2024-08-01')


create table SalesOrderHeader
(
SalesOrderID int primary key identity(1,1),
RevisionNumber tinyint not null,
OrderDate datetime not null default getdate(),
DueDate datetime not null,
ShipDate datetime,
Status tinyint not null,
SalesOrderNumber int not null,
CustomerID int not null,
SalesPersonID int,
TerritoryID int,
BillToAddressID int not null,
ShipToAddressID int not null,
ShipMethodID int not null,
CreditCardID int,
CreditCardApprovalCode varchar(15),
CurrencyRateID int,
SubTotal money not null,
TaxAmt money not null,
Freight money not null,
constraint SalesOrderHeader_CustomerID_FK foreign key (CustomerID)
	references Customer(CustomerID),
constraint SalesOrderHeader_TerritoryID_FK foreign key (TerritoryID)
	references SalesTerritory(TerritoryID),
constraint SalesOrderHeader_SalesPersonID_FK foreign key (SalesPersonID)
	references SalesPerson(BusinessEntityID),
constraint SalesOrderHeader_CreditCardID_FK foreign key (CreditCardID)
	references CreditCard(CreditCardID),
constraint SalesOrderHeader_ShipMethodID_FK foreign key (ShipMethodID)
	references ShipMethod(ShipMethodID),
constraint SalesOrderHeader_CurrencyRateID_FK foreign key (CurrencyRateID)
	references CurrencyRate(CurrencyRateID),
constraint SalesOrderHeader_BillToAddressID_FK foreign key (BillToAddressID)
	references Address(AddressID),
constraint SalesOrderHeader_ShipToAddressID_FK foreign key (ShipToAddressID)
	references Address(AddressID),
constraint SalesOrderHeader_OrderDate_DueDate_CK check (OrderDate <= DueDate),
constraint SalesOrderHeader_OrderDate_ShipDate_CK check (OrderDate <= ShipDate or ShipDate is null),
constraint SalesOrderHeader_SubTotal_CK check (SubTotal >= 0),
constraint SalesOrderHeader_TaxAmt_CK check (TaxAmt >= 0),
constraint SalesOrderHeader_Freight_CK check (Freight >= 0)

)
insert into SalesOrderHeader
values
(6, default, '2024-08-23', null, 5, 1, 1, 4,
1, 2, 2, 10, 1, 'CC1Apr1',
3, 4000, 450, 300),
(6, '2024-08-01', '2024-08-05', '2024-08-03', 1, 2, 7, 5,
10, 7, 8, 4, null, null,
null, 5000, 500, 200),
(6, '2023-12-12', '2024-1-1', '2024-1-15', 3, 3, 6, 8,
7, 1, 1, 6, 7, 'CC7Apr1',
10, 200, 10.30, 4),
(6, '2024-7-7', '2024-7-21', '2024-7-12', 1, 4, 5, 10,
4, 7, 7, 7, 8, 'CC8Apr1',
8, 8000, 960, 400),
(6, '2024-8-12', '2024-8-26', null, 5, 5, 1, 6,
1, 2, 2, 10, 1, 'CC1Apr2',
3, 3000, 250, 20),
(6, default, '2024-9-1', '2024-8-23', 1, 6, 3, 4,
1, 8, 8, 9, 2, 'CC2Apr1',
2, 7632, 800, 658),
(6, '2023-12-31', '2024-1-14', null, 5, 7, 5, 10,
4, 6, 3, 1, 3, 'CC3Apr1',
null, 600, 60, 200),
(6, '2024-8-8', '2024-8-20', '2024-8-10', 1, 8, 5, 7,
4, 7, 6, 10, 8, 'CC8Apr2',
10, 8999, 776, 843),
(6, '2023-12-12', '2024-1-1', null, 5, 9, 2, 3,
9, 4, 5, 1, 6, 'CC6Apr1',
7, 2003.121, 120, 400),
(6, default, '2024-9-1', null, 3, 10, 8, 2,
2, 10, 9, 2, null, null,
4, 3141.592, 653.58, 97.9323)

create table SalesOrderDetail
(
SalesOrderID int not null,
SalesOrderDetailID int not null,
CarrierTrackingNumber nvarchar(25), -- not unique - same carrier can carry multiple products
OrderQty smallint not null,
ProductID int not null,
SpecialOfferID int not null,
UnitPrice money not null,
UnitPriceDiscount money not null,
ModifiedDate datetime not null default getdate(),
constraint SalesOrderDetail_SalesOrderID_FK foreign key (SalesOrderID)
	references SalesOrderHeader(SalesOrderID),
constraint SalesOrderDetail_SalesOrderID_SalesOrderDetailID_PK primary key (SalesOrderID, SalesOrderDetailID),
constraint SalesOrderDetail_SpecialOfferID_ProductID_FK foreign key (SpecialOfferID,ProductID)
	references SpecialOfferProduct(SpecialOfferID, ProductID),
constraint SalesOrderDetail_OrderQty_CK check (OrderQty > 0), -- Doesn't make sense to order no items or a negative number of items
constraint SalesOrderDetail_UnitPrice_CK check (UnitPrice >= 0),
constraint SalesOrderDetail_UnitPriceDiscount_CK check (UnitPriceDiscount >= 0 and UnitPriceDiscount <=1) -- A discount greater than 100% doesn't make sense (would mean you're getting paid to get the product), and a discount smaller than 0% is not a discount but a price markup
)

insert into SalesOrderDetail
values
(1, 1, 'CTN1', 6, 5, 1, 200, 0.04, '2024-09-08'),
(7, 2, 'CTN7', 12, 4, 3, 40.95, 0.10, '2024-07-08'),
(1, 3, 'CTN1', 1, 2, 1, 35.12, 0.04, '2024-09-08'),
(2, 4, 'CTN2', 7, 2, 1, 35.12, 0.04, '2024-08-10'),
(5, 5,'CTN5', 13, 1, 4, 31.41, 0, '2023-01-09'),
(9, 6, 'CTN9', 32, 3, 2, 100, 0.50, '2025-1-1'),
(4, 7, 'CTN4', 10, 2, 1, 35.12, 0.04, '2024-09-08'),
(10, 8, 'CTN10', 2, 5, 2, 200, 0.50, '2025-1-1'),
(7, 9, 'CTN7', 8, 1, 4, 31.41, 0, '2024-07-08'),
(6, 10, null, 41, 4, 1, 40.95, 0.04, '2024-09-08')





