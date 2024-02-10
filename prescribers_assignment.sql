--1a) Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.
SELECT npi, total_claim_count
FROM prescription
ORDER BY 2 DESC
--Answer: NPI 1912011792, 4538 claims

--1b) Repeat the above, but this time report the nppes_provider_first_name, 
--nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, total_claim_count, prescriber.npi
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE total_claim_count IS NOT NULL
ORDER BY total_claim_count DESC;
--Answer: David Coffey, Family Practice, 4538 claims

--2a) Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi
WHERE total_claim_count IS NOT NULL
GROUP BY 1
ORDER BY SUM(total_claim_count) DESC;
--Answer: Family Practice, with 9,752,347 claims

--2b) Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY sum DESC;
--Answer: Nurse Practitioner, with 900,845 claims

--2c) Challenge Question: Are there any specialties that appear in the prescriber table that have no
--associated prescriptions in the prescription table?
WITH cte AS ((SELECT specialty_description, SUM(total_claim_count) as claims
FROM prescriber
FULL OUTER JOIN prescription
ON prescriber.npi = prescription.npi
GROUP BY 1
ORDER BY SUM(total_claim_count) DESC))
SELECT specialty_description, claims
FROM cte
WHERE claims IS NULL;

--Answer: Yes, there are 15 specialties with no prescriptions.

-------2d) Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, 
--report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?
SELECT specialty_description AS specialty
FROM prescriber
FULL OUTER JOIN prescription
USING(npi)
FULL OUTER JOIN drug
USING (drug_name)
LIMIT 5
-------Answer:

--3a) Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost)
FROM prescription
INNER JOIN drug
USING (drug_name)
GROUP BY 1
ORDER BY 2 DESC;
-------Answer: Insulin glargine, human recombinant analog with a total of $104,264,066.35

--3b) Which drug (generic_name) has the highest total cost per day? 
--Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT generic_name, ROUND(SUM(total_drug_cost)/365, 2) AS cost_per_day
FROM prescription
INNER JOIN drug
USING (drug_name)
GROUP BY 1
ORDER BY 2 DESC;
-------Answer: Insulin glargine, human recombinant analog, with a cost of $285,654.98 per day

--4a) For each drug in the drug table, return the drug name and then a column named 'drug_type' 
--which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug;

--4b) Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost)
--on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
WITH cost_by_type AS (SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug)
SELECT drug_type, SUM(total_drug_cost)
FROM cost_by_type
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type;
-------Answer: More was spent on opioids, with a total of $105,080,626.37, vs a total of $38,435,121.26 spent on antibiotics.

--5a) How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, 
--not just Tennessee.
SELECT state, COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
GROUP BY state;
-------Answer: There are 10 CBSAs in Tennessee.

--5b) Which cbsa has the largest combined population? Which has the smallest?
--Report the CBSA name and total population.
SELECT state, cbsaname, SUM(population)
FROM cbsa
INNER JOIN fips_county
USING (fipscounty)
INNER JOIN population
USING (fipscounty)
GROUP BY state, cbsaname
ORDER BY sum DESC;
-------Answer: Largest: Nashville-Davidson--Murfreesboro--Franklin CBSA, population 1,830,410
--			   Smallest: Morristown CBSA, population 116,352

--5c) What is the largest (in terms of population) county which is not included in a CBSA?
--Report the county name and population.
SELECT county, state, population
FROM cbsa
FULL OUTER JOIN fips_county
USING (fipscounty)
FULL OUTER JOIN population
USING (fipscounty)
WHERE cbsa IS NULL AND population IS NOT NULL
ORDER BY population DESC;
-------Answer: Sevier County, population 95,523

--6a) Find all rows in the prescription table where total_claims is at least 3000.
--Report the drug_name and the total_claim_count.
SELECT drug_name, SUM(total_claim_count)
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name
ORDER BY sum DESC;
-------Answer: 7 rows. Levothyroxine sodium, 9262 claims; oxydocodone HCL, 4538 claims; lisinopril, 3655 claims;
--					   gabapentin, 3531 claims; hydrocodone-acetominophen, 3376 claims; mirtazapine, 3085 claims;
--					   furosemide, 3083 claims.

--6b) For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
WITH big_claims AS (SELECT drug_name, SUM(total_claim_count) AS claims
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name
ORDER BY claims DESC)
SELECT drug_name, claims, opioid_drug_flag AS opioid
FROM big_claims
INNER JOIN drug
using (drug_name);

--6c) Add another column to you answer from the previous part which gives the
--prescriber first and last name associated with each row.
WITH big_claims AS (SELECT npi, drug_name, SUM(total_claim_count) AS claims
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name, npi
ORDER BY claims DESC)
SELECT drug_name, claims, opioid_drug_flag AS opioid, nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name
FROM big_claims
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING (npi);

--7 )The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
--and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

--7a) First, create a list of all npi/drug_name combinations for pain management specialists 
--(specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
--where the drug is an opioid (opioid_drug_flag = 'Y'). Warning: Double-check your query before running it. 
--You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT prescriber.npi AS npi, nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name, drug_name, specialty_description, nppes_provider_city
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
ORDER BY npi;

--7b) Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
--whether or not the prescriber had any claims. You should report the npi, the drug name,
--and the number of claims (total_claim_count).
SELECT prescriber.npi AS npi, drug.drug_name AS brand_name, generic_name, SUM(total_claim_count) AS claims
FROM prescriber
CROSS JOIN drug
FULL OUTER JOIN prescription
USING(drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, generic_name, drug.drug_name
ORDER BY prescriber.npi;

--7c) Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
--Hint - Google the COALESCE function.
SELECT prescriber.npi AS npi, drug.drug_name AS brand_name, generic_name, COALESCE(SUM(total_claim_count), 0) AS claims
FROM prescriber
CROSS JOIN drug
FULL OUTER JOIN prescription
USING(drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, generic_name, drug.drug_name
ORDER BY prescriber.npi;
