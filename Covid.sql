--select * from PortfolioProject..CovidDeaths;
--select location,date,total_cases,new_cases,total_deaths,population from PortfolioProject..CovidDeaths order by 1,2;

--SELECT 
--    location,
--    date,
--    total_cases,
--    total_deaths,
--    CASE 
--        WHEN total_cases = 0 THEN NULL -- Handle division by zero by returning NULL
--        ELSE CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT) *100-- Perform division only if total_cases is not zero
--    END AS deathratio 
--FROM 
--    PortfolioProject..CovidDeaths 
--WHERE location like '%states%'
--ORDER BY 
--    1, 2;

--select location,date,total_cases,population,
--case
--    when total_cases=0 or population=0 then NULL
--	else cast(total_cases as float)/cast(population as bigint)*100
--end as cases_perpop
--from PortfolioProject..CovidDeaths order by 1,2;

--SELECT 
--    location,
--    date,
--    total_cases,
--    population,
--    CASE
--        WHEN total_cases = 0 OR TRY_CAST(population AS FLOAT) = 0 THEN NULL
--        ELSE CAST(total_cases AS FLOAT) / CAST(population AS FLOAT) * 100
--    END AS cases_perpop
--FROM 
--    PortfolioProject..CovidDeaths 
--ORDER BY 
--    1, 2;

--SELECT 
--    location,
--    population,
--	max(total_cases) as highest_cases,
--    CASE
--        WHEN max(cast(total_cases as float))=0 or TRY_CAST(population AS FLOAT) = 0 THEN NULL
--        ELSE max(CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100
--    END AS cases_perpop
--FROM 
--    PortfolioProject..CovidDeaths 
--group by location,population
--ORDER BY 
--    1, 2;

--SELECT 
--    location,
--    population,
--    MAX(total_cases) AS highest_cases,
--    CASE
--        WHEN MAX(CAST(total_cases AS FLOAT)) = 0 OR TRY_CAST(population AS FLOAT) = 0 THEN NULL
--        ELSE MAX(CAST(total_cases AS FLOAT)) / NULLIF(TRY_CAST(population AS FLOAT), 0) * 100
--    END AS cases_perpop
--FROM 
--    PortfolioProject..CovidDeaths 
--GROUP BY 
--    location, population
--ORDER BY 
--    cases_perpop desc;

--select continent,max(cast(total_deaths as int)) as totaldthcount
--from PortfolioProject..CovidDeaths where continent is not null 
--group by continent
--order by totaldthcount desc;

--select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations from PortfolioProject..CovidDeaths dea
--join PortfolioProject..CovidVaccinations vac
--on dea.location=vac.location and dea.date=vac.date
--order by 2,3;

/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



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
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
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
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


