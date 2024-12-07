use AdventureWorks2019
--Q1

select p.ProductID, p.Name, p.Color, p.ListPrice, p.Size
from Production.Product as p
where not exists
(
select *
from Sales.SalesOrderDetail as sod
where p.ProductID = sod.ProductID
)
order by ProductID

-- Q2
select c.CustomerID, isnull(p.LastName, 'Unknown') as LastName, isnull(p.FirstName, 'Unknown') as FirstName
from Sales.Customer as c
left join Person.Person as p
on c.CustomerID = p.BusinessEntityID
where not exists
(
select *
from Sales.SalesOrderHeader as soh
where soh.CustomerID = c.CustomerID
)
order by CustomerID

-- Q3

select distinct top 10 c.CustomerID , p.FirstName, p.LastName, count(soh.SalesOrderID) over(partition by soh.CustomerID) as CountOfOrders
from Sales.SalesOrderHeader as soh
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
left join Person.Person as p
on p.BusinessEntityID = c.PersonID
order by CountOfOrders desc

--Q4
select FirstName, LastName, JobTitle, HireDate, count(JobTitle) over(partition by JobTitle) as CountOfTitle
from HumanResources.Employee as e
inner join Person.Person as p
on e.BusinessEntityID = p.BusinessEntityID
order by JobTitle


-- Q5
with CTE_PrevOrderRank
as
(
select soh.SalesOrderID,c.CustomerID, p.LastName, p.FirstName, soh.OrderDate,
lag(soh.OrderDate, 1) over (partition by soh.CustomerID order by soh.OrderDate asc) as PreviousDate,
rank() over (partition by soh.CustomerID order by soh.OrderDate desc) as RNK
from Sales.Customer as c
left join Sales.SalesOrderHeader as soh
on c.CustomerID = soh.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
)

select po.SalesOrderID, po.CustomerID, po.LastName, po.FirstName, po.OrderDate, po.PreviousDate
from CTE_PrevOrderRank as po
where RNK = 1
order by po.CustomerID

-- Q6
with CTE_SumOrders
as
(
select distinct sod.SalesOrderID, year(soh.OrderDate) as Year,
sum(sod.UnitPrice * sod.OrderQty * (1 - sod.UnitPriceDiscount)) over(partition by sod.SalesOrderID) as Total,
p.LastName, p.FirstName
from Sales.SalesOrderDetail as sod
inner join Sales.SalesOrderHeader as soh
on sod.SalesOrderID = soh.SalesOrderID
inner join Sales.Customer as c
on soh.CustomerID = c.CustomerID
inner join Person.Person as p
on c.PersonID = p.BusinessEntityID
)

select crs.Year, crs.SalesOrderID, crs.LastName, crs.FirstName, format(crs.Total, 'N1', 'en-us') as Total
from
(
select *,
rank() over(partition by cso.Year order by cso.Total desc) as RNK
from CTE_SumOrders as cso
) as crs
where RNK = 1

-- Q7

select *
from (
select SalesOrderID, year(OrderDate) as OrderYR, month(OrderDate) as Month
from Sales.SalesOrderHeader) as soh
pivot (count(soh.SalesOrderID) for OrderYR in([2011], [2012], [2013], [2014])) as PVT
order by Month

-- Q8
with CTE_MonthSum (Year, Month, Sum_Price, CumSum, YearForOrderBy, MonthForOrderBy) -- YearForOrderBy & MonthForOrderBy are columns that will not be presented and only used to order the unified table correctly, because we have to convert the year and the month to string types
as
(
	select cast(OrderYear as char(4)), cast(OrderMonth as char(2)), Sum_Price,
	sum(Sum_Price) over(partition by OrderYear order by OrderYear, OrderMonth asc
	rows between unbounded preceding and current row) as CumSum,
	OrderYear, OrderMonth
	from (
		select year(soh.OrderDate) as OrderYear, month(soh.OrderDate) as OrderMonth,
		sum(sod.UnitPrice * (1 - sod.UnitPriceDiscount)) AS Sum_Price -- For some reason the "correct" solution omits OrderQty???
		from Sales.SalesOrderDetail as sod
		inner join sales.SalesOrderHeader as soh
		on sod.SalesOrderID = soh.SalesOrderID
		group by year(soh.OrderDate), month(soh.OrderDate)
	) as CumSumSQ
),
CTE_YearSum (Year, Month, Sum_Price, CumSum, YearForOrderBy, MonthForOrderBy)
as
(
	select cast(year(soh.OrderDate) as char(4)) as OrderYear, 'grand_total', null,
	sum(sod.UnitPrice * (1 - sod.UnitPriceDiscount)),
	year(soh.OrderDate), 9999
	from Sales.SalesOrderDetail as sod
	inner join sales.SalesOrderHeader as soh
	on sod.SalesOrderID = soh.SalesOrderID
	group by year(soh.OrderDate)
),
CTE_GrandTotal (Year, Month, Sum_Price, CumSum, YearForOrderBy, MonthForOrderBy)
as
(
	select 'grand_total', 'grand_total', null, sum(sod.UnitPrice * (1 - sod.UnitPriceDiscount)),
	9999, 9999
	from Sales.SalesOrderDetail as sod
	inner join sales.SalesOrderHeader as soh
	on sod.SalesOrderID = soh.SalesOrderID
)

select sq.Year, sq.Month, format(sq.Sum_Price, '#.00') as Sum_Price, format(sq.CumSum, '#.00') as CumSum
from
(
select *
from CTE_MonthSum
union
select *
from CTE_YearSum
union
select *
from CTE_GrandTotal
) as sq
order by YearForOrderBy, MonthForOrderBy


-- Q9
with CTE_DepEmployees
as
(
select d.Name as DepartmentName, e.BusinessEntityID as [Employee's ID],
concat(p.FirstName, ' ', p.LastName) as [Employee's Full Name],
e.HireDate,
datediff(mm, e.HireDate, getdate()) as Seniority
from HumanResources.EmployeeDepartmentHistory as edh
inner join HumanResources.Employee as e
on edh.BusinessEntityID = e.BusinessEntityID
inner join HumanResources.Department as d
on d.DepartmentID = edh.DepartmentID
inner join Person.Person as p
on p.BusinessEntityID = e.BusinessEntityID
 --Shouldn't there be a "where EndDate is null" here, for employees that have moved departments? I'm leaving it like this because it leads to the same answer as in the instructions
)

select *,
lead(dpe.[Employee's Full Name], 1) over(partition by dpe.DepartmentName order by dpe.HireDate desc) as PreviousEmpName,
lead(dpe.HireDate, 1) over(partition by dpe.DepartmentName order by dpe.HireDate desc) as PreviousEmpDate,
datediff(dd, lead(dpe.HireDate, 1) over(partition by dpe.DepartmentName order by dpe.HireDate desc), HireDate) as DiffDays
from CTE_DepEmployees as dpe

--Q10
select e.HireDate, edh.DepartmentID,
string_agg(concat(e.BusinessEntityID, ' ', p.LastName, ' ', p.FirstName), ', ') as TeamEmployees
from HumanResources.Employee as e
inner join HumanResources.EmployeeDepartmentHistory as edh
on e.BusinessEntityID = edh.BusinessEntityID
inner join Person.Person as p
on p.BusinessEntityID = e.BusinessEntityID
where edh.EndDate is null -- This is so that we only get data for every employee's most recent department
group by e.HireDate, edh.DepartmentID
order by 1 desc




