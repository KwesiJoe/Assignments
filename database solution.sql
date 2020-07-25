--1 The number of users that Wave has can be found in the users table by using the COUNT function to get the number of records in the table
SELECT COUNT(*) FROM "PostgreSQL".users;


--2 Number of 'sent' transactions that were made in CFA
SELECT COUNT(*) FROM "PostgreSQL".transfers
WHERE send_amount_currency = 'CFA';


--3 Number of users that have sent a transfer in CFA
SELECT COUNT(distinct u_id) FROM "PostgreSQL".transfers
WHERE send_amount_currency = 'CFA';


--4 Number of agent transactions grouped by months in 2018. month_created is the month extracted from the when_created field 
SELECT EXTRACT(month FROM when_created) as month_created, COUNT(*) FROM "PostgreSQL".agent_transactions
WHERE EXTRACT(year FROM when_created) = '2018'
GROUP BY EXTRACT(month FROM when_created)


--5 To get the number of net depositors and withdrawers, I first tag the sum of the amount of each agent as a 'net withdrawer' if the sum is positive 
--or a 'net depositer' if the sum is negative. Then count the result of the query for each tag. 
SELECT status, COUNT(status) FROM (
SELECT SUM(amount),
CASE
 WHEN SUM(amount)>0 THEN 'net depositors'
 WHEN SUM(amount)<0 THEN 'net withdrawer'
END AS status 
FROM "PostgreSQL".agent_transactions
WHERE when_created > NOW() - INTERVAL '7days'
GROUP BY u_id
ORDER BY u_id ASC
) 
AS net
GROUP BY status
;

--6 “atx volume city summary” table: volume of agent transactions created
--in the last week, grouped by city.
SELECT agents.city, sum(agent_transactions.amount) as volume 
INTO "atx volume city summary"
FROM "PostgreSQL".agent_transactions
JOIN "PostgreSQL".agents
ON agents.agent_id = agent_transactions.agent_id
WHERE agent_transactions.when_created > NOW() - INTERVAL '7 days'
GROUP BY city
;


--7 grouping city by country in the “atx volume city summary” table

SELECT  agents.country, agents.city, "atx volume city summary".volume 
FROM "PostgreSQL".agent_transactions
JOIN "atx volume city summary"
ON agents.city = "atx volume city summary".city
WHERE agent_transactions.when_created > NOW() - INTERVAL '7 days'
GROUP BY city, country
;

--8 
SELECT wallets.ledger_location AS country,
       transfers.kind AS transferkind,
       SUM(transfers.send_amount_scalar) AS volume
FROM "PostgreSQL".wallets
JOIN "PostgreSQL".transfers 
ON wallets.wallet_id = transfers.source_wallet_id
WHERE transfers.when_created > NOW() - INTERVAL '7 days'
GROUP BY country, transferkind
ORDER BY country ASC, transferkind DESC;


--10
SELECT wallets.wallet_id, sum(transfers.send_amount_scalar) 
FROM "PostgreSQL".wallets
JOIN "PostgreSQL".transfers
ON wallets.wallet_id = transfers.source_wallet_id
WHERE transfers.when_created > NOW() - INTERVAL '1 month' AND currency = 'CFA' AND transfers.send_amount_scalar > '10000000'
GROUP BY wallets.wallet_id;
