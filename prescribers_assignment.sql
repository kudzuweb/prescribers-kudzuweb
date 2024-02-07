--1a) Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.
SELECT npi, total_claim_count
FROM prescription
ORDER BY 2 DESC
--Answer: NPI 1912011792, 4538 claims

--1b) Repeat the above, but this time report the nppes_provider_first_name, 
--nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT *
FROM prescriber
LEFT JOIN prescription
ON prescriber.npi = prescription.npi;
SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, total_claim_count
FROM
--Answer: