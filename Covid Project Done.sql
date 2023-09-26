
SELECT *
FROM Covid_Project..Covid_deaths
ORDER BY 3,4

--SELECT *
--FROM Covid_Project..Covid_vaccinations
--ORDER BY 3,4

--Select Data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Project..Covid_deaths
ORDER BY 1,2

-- LOOK AT Philippines

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Project..Covid_deaths
WHERE Location = 'Philippines'
ORDER BY 1,2

-- Look at Total Cases VS Total Deaths in Philippines
-- We use CAST to conver total_cases column which is a varcahr to float so we can divide
-- We are getting at Death Percentage
SELECT Location, date, total_cases, total_deaths, total_deaths/CAST(total_cases as Float)*100 as Death_Percentage
FROM Covid_deaths
WHERE Location = 'Philippines'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Get the average of population vs total cases
SELECT Location, date, population, total_cases, CAST(total_cases as Float)/population*100 as Cases_Percentage_Per_Population
FROM Covid_deaths
WHERE Location = 'Philippines'
ORDER BY 1,2

-- Looking at Countries with highest infection rate compared to population
-- We use MAX in total cases
-- WE need to add Group By
SELECT Location, population, MAX(total_cases) AS Highest_Infection_Count, CAST(MAX(total_cases) as Float)/population*100 as Cases_Percentage_Per_Population
FROM Covid_deaths
GROUP BY location, population
ORDER BY Cases_Percentage_Per_Population DESC

-- Showing Countries with highest death count per population
-- We use CAST again on total deaths because it is in NVARCHAR
SELECT Location, MAX(CAST(Total_deaths as INT)) as Total_Death_Count
FROM Covid_Project..Covid_deaths
WHERE continent IS NOT NULL	
GROUP BY location
ORDER BY Total_Death_Count DESC

-- In the query above there are data that shows up that should not be part of location like WORLD or Continents
-- We verified this by exploring the data using the query below
--SELECT *
--FROM Covid_Project..Covid_deaths
--ORDER BY 3,4
-- We added WHERE clause to get rid of those

-- Break it down by Continent

SELECT continent, MAX(CAST(Total_deaths as INT)) as Total_Death_Count
FROM Covid_Project..Covid_deaths
WHERE continent IS NOT NULL	
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- There seems to be missing data so lets try IS NULL
-- change continent with location

SELECT location, MAX(CAST(Total_deaths as INT)) as Total_Death_Count
FROM Covid_Project..Covid_deaths
WHERE continent IS NULL	
GROUP BY location
ORDER BY Total_Death_Count DESC

-- Data like high income, uppder middle income, lower middle income and low income show up
-- We could use this

-- Looking at the Global Numbers

SELECT date, total_cases, total_deaths, total_deaths/CAST(total_cases as Float)*100 as Death_Percentage
FROM Covid_deaths
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- This query wont work because of the aggregate function error 
-- We add SUM(new_cases) to get the total across the world per date

SELECT date, SUM(new_cases)
FROM Covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2 

-- Add SUM of new_deaths but we need to cast it too as it is nvarchar
--We also ADD Death Percentage

SELECT date, SUM(new_cases), SUM(CAST(new_deaths AS INT)), SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_Percentage
FROM Covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2 

-- The query above returns a divided by zero error because there are some where new cases = 0
-- We add a WHERE clause where new_cases <> 0 (not equal to zero)

SELECT date, SUM(new_cases) AS Cases, SUM(CAST(new_deaths AS INT)) AS Deaths, 
SUM(cast(new_deaths as INT))/SUM(new_cases)*100 AS Death_Percentage 
FROM Covid_deaths
WHERE continent IS NOT NULL AND new_cases <> 0
GROUP BY date
ORDER BY 1,2

-- If we get rid of the date and group by we get the total in the world 
SELECT SUM(new_cases) AS Cases, SUM(CAST(new_deaths AS INT)) AS Deaths, 
SUM(cast(new_deaths as INT))/SUM(new_cases)*100 AS Death_Percentage 
FROM Covid_deaths
WHERE continent IS NOT NULL AND new_cases <> 0
--GROUP BY date
ORDER BY 1,2

-- Check covid_vaccinations table

SELECT *
FROM Covid_vaccinations

 
 -- JOINING TWO TABLES
 -- Looking at total populiation vs vaccination
 -- We join both tables on location and date
 -- The partition by creates a new column where it shows a running balance per day of the vaccinations
 -- We then added and order by to arrange them by location and date

 SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
 , SUM(CAST(cv.new_vaccinations AS INT)) OVER 
 (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Running_Total_Vaccinations
 FROM Covid_deaths AS CD
 JOIN Covid_vaccinations AS CV
 ON CD.location = CV.location
 AND CD.date = CV.date
 WHERE cd.continent IS NOT NULL AND cd.location = 'Philippines'
 ORDER BY 2,3

 -- USE CTE (common table expression) a temporary named result
 -- CTE containts AS and enclose the original query with ()
 -- Because if we want to get the average of the vaccination vs population we cannot
 -- use the column Running_Total_Vaccination because we just made that for the query
 -- Get rid of ORDER BY

 WITH PopVsVacc (Contintent, Location, Date, Population, New_Vaccinations, Running_Total_Vaccinations)
 AS 
 (
 SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
 , SUM(CAST(cv.new_vaccinations AS INT)) OVER 
 (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Running_Total_Vaccinations
 FROM Covid_deaths AS CD
 JOIN Covid_vaccinations AS CV
 ON CD.location = CV.location
 AND CD.date = CV.date
 WHERE cd.continent IS NOT NULL AND cd.location = 'Philippines'
 )
 SELECT *, (Running_Total_Vaccinations/Population)*100 AS Vacc_Percent
 FROM PopVsVacc

 -- The query above will show the running total of vaccinations made per day and the percentage 

 -- Create view to store data for visualizations

 -- VIEW OF Locations with running total of vaccinations 
 CREATE VIEW Vacc_Percent AS 
WITH PopVsVacc (Contintent, Location, Date, Population, New_Vaccinations, Running_Total_Vaccinations)
 AS 
 (
 SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
 , SUM(CAST(cv.new_vaccinations AS INT)) OVER 
 (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS Running_Total_Vaccinations
 FROM Covid_deaths AS CD
 JOIN Covid_vaccinations AS CV
 ON CD.location = CV.location
 AND CD.date = CV.date
 WHERE cd.continent IS NOT NULL AND cd.location = 'Philippines'
 )
 SELECT *, (Running_Total_Vaccinations/Population)*100 AS Vacc_Percent
 FROM PopVsVacc

 GO

 -- VIEW With total death count per continent
 CREATE VIEW Total_Death_Location AS
 SELECT location, MAX(CAST(Total_deaths as INT)) as Total_Death_Count
FROM Covid_Project..Covid_deaths
WHERE continent IS NULL	
GROUP BY location

GO 

-- VIEW with highest infection count per location
CREATE VIEW Highest_Infection_Location AS
SELECT Location, population, MAX(total_cases) AS Highest_Infection_Count, CAST(MAX(total_cases) as Float)/population*100 as Cases_Percentage_Per_Population
FROM Covid_deaths
GROUP BY location, population

GO


-- VIEW WITH TOTAL DEATH COUNT Per Location
CREATE VIEW Highest_Death_Count_Location AS
SELECT Location, MAX(CAST(Total_deaths as INT)) as Total_Death_Count
FROM Covid_Project..Covid_deaths
WHERE continent IS NOT NULL	
GROUP BY location
