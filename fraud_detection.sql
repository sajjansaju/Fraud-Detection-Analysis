--Basic Queries to understand dataset

--1)Total transactions and fraud count
select count(*) as total_transactions,
sum(isfraud) as fraud_count
from transactions;

--2)List of unique transaction types
select distinct type
from transactions;

--3)Top 5 highest distinct transaction amounts
select distinct amount
from transactions
order by amount desc
limit 5;

--- Intermediate Queries to discover patters 

--4)Fraud rate by transaction type
select type,
count(isfraud) as no_of_transactions,
round(sum(isfraud)::decimal /count(*) * 100,2) as fraud_rate
from transactions
group by type;

--5)Top 5 suspicious sender accounts by fraud count
select nameorig as sender_account,
count(isfraud) as no_of_fraud
from transactions
where isfraud = 1
group by sender_account
order by no_of_fraud desc
limit 5;


--6)Transaction count over time (by step)
select step as unit_of_time,
count(*)
from transactions
group by unit_of_time
order by unit_of_time asc;

--7)Zero Balance Patterns: Detects transactions where amount transfered or paid to recipients show zero balance.
Select *
from transactions
where type in ('TRANSFER','PAYMENT')
and newbalanceDest = 0
and amount > 0;

--Advanced Queries for insights and anomaly detection

--8)Mismatch in balances (possible manipulation or allowing overdrafts and simply zeroing out balances)
select *
from transactions
where (type in ('CASH_OUT','DEBIT','PAYMENT','TRANSFER') and (oldbalanceorg <> newbalanceorig + amount)) 
or 
(type ='CASH_IN' and (oldbalanceorg <> newbalanceorig - amount));

--9)Looping or round-tripping (money goes out, then comes back in)
SELECT DISTINCT t1.nameOrig
FROM transactions t1
JOIN transactions t2
  ON t1.nameOrig = t2.nameDest
  AND t1.amount = t2.amount;

--10)Running total of frauds over time
SELECT step,
       SUM(isFraud) AS no_of_frauds,
       SUM(SUM(isFraud)) OVER (ORDER BY step) AS running_total_frauds
FROM transactions
GROUP BY step
ORDER BY step;

--11)Most frequently targeted accounts in fraud cases
select namedest,
sum(isfraud) as times_targeted
from transactions
where isfraud = 1
group by namedest
order by times_targeted desc
limit 10;

--12)High-value fraud transactions (top 1%)
SELECT *
FROM transactions
WHERE isFraud = 1
  AND amount > (
      SELECT PERCENTILE_CONT(0.99) 
      WITHIN GROUP (ORDER BY amount)
      FROM transactions
  );










