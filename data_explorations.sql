SELECT *
FROM portfolio_project..covid_deaths
--WHERE continent IS NOT NULL
ORDER BY 2,3,4;

SELECT *
FROM portfolio_project..covid_vaccination
--WHERE continent IS NOT NULL
ORDER BY 3,4;

--1 the data that we are going to be using
SELECT 
	location, 
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM portfolio_project..covid_deaths
WHERE continent is not null
ORDER BY 2;
-- the result shows that the death starts after a month 
-- of the first case and then it ramps up dangerously

--2 Looking at total cases vs total deaths
-- possibility of death after contracting covid in your country
SELECT 
	location, 
	date,
	total_cases,
	total_deaths,
	ROUND(CONVERT(float,total_deaths)/CAST(total_cases AS float) * 100,2) AS death_percentage
FROM portfolio_project..covid_deaths
WHERE location = 'india'
ORDER BY 1,2;

--3 looking at total_cases vs population
--this shows the percentage of population that contrcted covid
SELECT 
	location, 
	date,
	population,
	total_cases,
	(total_cases/population) * 100 AS covid_percentage 
FROM portfolio_project..covid_deaths
WHERE continent IS NULL
--WHERE location = 'india'
ORDER BY 1,2;


--4 looking at countries with highest infection rates compared to population
SELECT 
	location, 
	MAX(population) AS population,
	isnull(Max(total_cases),0) AS highest_infection_rate,
	isnull((max(total_cases)/population), 0) * 100 AS covid_percentage 
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;


--5 Showing the countries with highest death count irrespective of population
SELECT 
	location, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

--6 looking at countries with highest death rates compared to population
SELECT 
	location, 
	MAX(population) AS population,
	isnull(Max(total_deaths),0) AS highest_death_rate,
	isnull((max(total_deaths)/population), 0) * 100 AS death_percentage 
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC;
-- in this case we can see that USA is still in the 4th place 
-- Note countries like england value is actually NULL because death_rate and cases is null. 


--7 Looking at the death count in each continent
SELECT 
	continent, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count 
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
-- WHERE continent IS NULL
GROUP BY continent
ORDER BY 2 DESC;


-- looking for global numbers
--8 cases to death percentage
SELECT
	date,
	sum(cast(new_cases as int)) AS total_cases,
	sum(cast(new_deaths as float)) AS total_deaths,
	CASE
	WHEN sum(new_cases) = 0 then NULL 
	ELSE sum(CONVERT(int,new_deaths))/sum(new_cases) * 100 
	END AS death_percentage
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1;
-- note when we are doing the max of total_cases then it is giving us the max 
-- value by comparing it with other locations


--9 death percentage across the world 
SELECT
	sum(cast(new_cases as int)) AS total_cases,
	sum(cast(new_deaths as float)) AS total_deaths,
	CASE
	WHEN sum(new_cases) = 0 then NULL 
	ELSE sum(CONVERT(int,new_deaths))/sum(new_cases) * 100 
	END AS death_percentage
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL 
--GROUP BY date
ORDER BY 1;


--10 joining death table with vaccination table 
SELECT *
FROM portfolio_project..covid_deaths d
JOIN portfolio_project..covid_vaccination v
ON d.date = v.date 
AND d.location = v.location
WHERE D.continent IS NOT NULL
ORDER BY 3,4;

--11 looking for total population vs vaccinatio(on each day)
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations
FROM portfolio_project..covid_deaths d
JOIN portfolio_project..covid_vaccination v
ON d.date = v.date 
AND d.location = v.location
WHERE D.continent IS NOT NULL
ORDER BY 2,1;

--12 looking for total population vs vaccination (total)
-- not by using the total vaccination 
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(CAST(v.new_vaccinations AS INT)) over(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths d
JOIN portfolio_project..covid_vaccination v
ON d.date = v.date 
AND d.location = v.location
WHERE D.continent IS NOT NULL
ORDER BY 2,1;

-- not grouped by countries
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(CAST(v.new_vaccinations AS INT)) over(ORDER BY d.location, d.date) AS rolling_people_vaccinated
	-- not grouped by countries
FROM portfolio_project..covid_deaths d
JOIN portfolio_project..covid_vaccination v
ON d.date = v.date 
AND d.location = v.location
WHERE D.continent IS NOT NULL
ORDER BY 2,1;

--13 vaccination rate by population in a country
WITH vaccinated AS (
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(CAST(v.new_vaccinations AS INT)) over(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths d
JOIN portfolio_project..covid_vaccination v
ON d.date = v.date 
AND d.location = v.location
WHERE D.continent IS NOT NULL
--ORDER BY 2,1
)
SELECT
	*,
	(rolling_people_vaccinated/population) *100 AS vaccinated_rate
FROM vaccinated
--WHERE date = '2021-04-30'

-- ALTERNATIVE with subquery

SELECT *, (rolling_people_vaccinated/population) *100 AS vaccinated_rate
FROM(
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(CAST(v.new_vaccinations AS INT)) over(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths d
JOIN portfolio_project..covid_vaccination v
ON d.date = v.date 
AND d.location = v.location
WHERE D.continent IS NOT NULL
--ORDER BY 2,1
) AS vaccinated


--14 Alternative with temporary table
DROP TABLE IF EXISTS #peoplevaccinated
CREATE TABLE #peoplevaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric, 
rolling_people_vaccinated numeric
)

INSERT INTO #peoplevaccinated
SELECT 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(CAST(v.new_vaccinations AS INT)) over(PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM portfolio_project..covid_deaths d
JOIN portfolio_project..covid_vaccination v
ON d.date = v.date 
AND d.location = v.location
WHERE D.continent IS NOT NULL

SELECT
	*,
	(rolling_people_vaccinated/population) *100 AS vaccinated_rate
FROM #peoplevaccinated
ORDER BY 2,3;