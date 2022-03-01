/*
Covid19 Data Exploration By Guofen Dai (This dataset is updated to Feb 22, 2022)
Dataset URL: https://ourworldindata.org/covid-deaths
             https://ourworldindata.org/covid-vaccinations
Skills Used: Select, Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select Covid Deaths and Vaccinations Data that we are going to be starting with

Select *
From CovidDeaths

Select *
From CovidVaccinations

-- Check the highest number of new cases and the average number of new cases.  

Select MAX(new_cases) as maxnew_cases, AVG(new_cases) as avgnew_cases
From CovidDeaths

-- 1/19/2022 was reported the highest number of new COVID-19 cases ever recorded for a single day.  
Select continent, location, date, total_cases, new_cases, total_deaths, new_deaths,total_tests, new_tests, positive_rate, population
From CovidDeaths
Order by new_cases desc

-- Check the location and date of the top new deaths for a single day. 
Select continent, location, date, total_deaths, new_deaths, population
From CovidDeaths
Where continent is not null 

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you get covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where location = 'China'
and continent is not null 
order by 1,2

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentageOfPopulationInfected
From CovidDeaths
order by location,date

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentageOfPopulationInfected
From CovidDeaths
Where location like '%states%'
order by location,date

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentageOfPopulationInfected
From CovidDeaths
Group by Location, Population
order by PercentageOfPopulationInfected desc

-- Infection Rate compared to Population in United States
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentageOfPopulationInfected
From CovidDeaths
Where location like '%states%'
Group by Location, Population
order by PercentageOfPopulationInfected desc

-- Countries with Highest Death Count
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- Group by Continent

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where location like '%united%'
and continent is not null
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

-- Daily Global COVID Cases
SELECT date, SUM(new_cases) as TotalCases, SUM(cast(total_deaths as int)) as TotalDeaths
FROM CovidDeaths
WHERE Continent is not null
GROUP BY date
Order by date desc

-- Checking United States Numbers
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
Where location like '%states%'
and continent is not null 
Group By date
order by 1,2

--Max death pct in United States was 9.09% on March 2,2020
--between 2020-01-30 & 2022-02-22 (25 months)

Select DATEDIFF(MONTH,min(date),max(date)) as time_bound_of_death_data 
From CovidDeaths

Select mc.location as countries, max(mc.max_cases) as maxes, max(cd.date) as dates
from
(Select location, max(total_cases) as max_cases 
From CovidDeaths
Group by location) mc
Inner join CovidDeaths cd on cd.location = mc.location
Group by mc.location
Having max(cd.total_cases) = max(mc.max_cases)


Select date, total_cases, location, new_deaths, new_deaths/total_cases as deathpct
From CovidDeaths
Where location = 'United States'
Order by deathpct desc


Select date, total_cases, location, new_deaths, new_deaths/total_cases as deathpct
From CovidDeaths
Where location = 'United States'
Order by deathpct desc


-- Total Cases as of 22/2/2022 Global COVID Cases
Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  as WorldDeathRate
From CovidDeaths
Where Continent is not null


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select *
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Using CTE(Common Table Expression) to perform Calculation total population that vaccinated 

with PopVSVac (Continent, location,date, population,new_vaccinations, TotVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,SUM(CONVERT(int,new_vaccinations)) OVER (Partition by dea.location order by dea.date) as TotVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	on dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
select *,(TotVaccinated/population) as VaccinatedRate
FROM popVSVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
from PercentPopulationVaccinated

--Case
SELECT date, location, total_cases,new_cases, total_deaths, new_deaths,
CASE
    WHEN new_cases > 10000 THEN 'Out of control'
	WHEN new_cases BETWEEN 1000 AND 10000 THEN 'Hard to control'
	ELSE 'In control'
END AS Status
FROM CovidDeaths
WHERE new_cases is NOT NULL
and location = 'World'
ORDER BY new_cases DESC


