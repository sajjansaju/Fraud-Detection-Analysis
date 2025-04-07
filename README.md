# 🔐 Fraud Detection with SQL – 💳Transaction Data Analysis
This project analyzes a financial transactions dataset using PostgreSQL to detect fraud patterns. It includes basic, intermediate, and advanced SQL queries covering fraud rates, balance inconsistencies, high-risk accounts, and top 1% high-value frauds.


---
## 🛡️ License

This project is licensed under the CC BY-NC-ND 4.0 License.  
Unauthorized reposting or modification is strictly prohibited.  
[View License](http://creativecommons.org/licenses/by-nc-nd/4.0/)

📩 For access or collaboration requests, please email me at: navakumarsajjan@gmail.com

---
## 📁 Dataset Description

The dataset consists of simulated financial transactions with the following key columns:

- `step`: Hourly time step from the start of the simulation
- `type`: Type of transaction (e.g., PAYMENT, TRANSFER, CASH_OUT)
- `amount`: Amount of the transaction
- `nameOrig`: Sender account
- `oldbalanceOrg`: Sender's balance before the transaction
- `newbalanceOrig`: Sender's balance after the transaction
- `nameDest`: Recipient account
- `oldbalanceDest`: Recipient’s balance before the transaction
- `newbalanceDest`: Recipient’s balance after the transaction
- `isFraud`: 1 if the transaction is fraudulent, 0 otherwise


The dataset used is publicly available on Kaggle: https://www.kaggle.com/datasets/amanalisiddiqui/fraud-detection-dataset?select=AIML+Dataset.csv

---

## 🎯 Project Goals

- Identify and explore fraud trends
- Detect balance manipulation patterns
- Analyze account behaviors that may indicate fraud
- Highlight high-value suspicious transactions

---

## 🔎 SQL Query Categories

### ✅ Basic Queries 
- Total transactions and fraud count
- Unique transaction types
- Top 5 highest transaction amounts

### ⚙️ Intermediate Queries 
- Fraud rate by transaction type
- Top suspicious sender accounts
- Transaction volume over time
- Zero balance patterns

### 🚨 Advanced Queries 
- Balance mismatches indicating manipulation
- Accounts appearing as both sender and receiver
- High-value frauds (top 1% by amount)
- Running total of frauds over time
- Loop transaction pattern detection

---

## 📊 Tools Used

- **PostgreSQL**: Querying and analysis
- **pgAdmin**: SQL editor

---

## 🔎 SQL Query

**1)Total transactions and fraud count**
```sql
select count(*) as total_transactions,
sum(isfraud) as fraud_count
from transactions;
```
The dataset contains a total of 1,048,575 transactions.
Out of these, 1,142 transactions were already identified as fraudulent, making up a very small but critical portion of the data.

**2)List of unique transaction types**
```sql
select distinct type
from transactions;
```
The dataset includes **five unique transaction types**: `CASH_IN`, `CASH_OUT`, `DEBIT`, `PAYMENT`, and `TRANSFER`.  
These represent the various ways money is moved within the system and form the basis for deeper fraud analysis.


**3)Top 5 highest distinct transaction amounts**
```sql
select distinct amount
from transactions
order by amount desc
limit 5;
```
These large transactions are often worth closer inspection as they may pose a **higher fraud risk** or involve **significant financial movement**.

**4)Fraud rate by transaction type**
```sql
select type,
count(isfraud) as no_of_transactions,
round(sum(isfraud)::decimal /count(*) * 100,2) as fraud_rate
from transactions
group by type;
```
`TRANSFER` and `CASH_OUT` transactions show significantly higher fraud rates (0.65% and 0.15%), while `CASH_IN`, `DEBIT`, and `PAYMENT` have a fraud rate of 0.00%, indicating they are generally safer.

**5)Top 5 suspicious sender accounts by fraud count**
```sql
select nameorig as sender_account,
count(isfraud) as no_of_fraud
from transactions
where isfraud = 1
group by sender_account
order by no_of_fraud desc
limit 5;
```
Each of these accounts (`C1000937208`, `C1002446735`, etc.) has committed fraud at least once, highlighting them as **potentially suspicious or compromised** users.

**6)Transaction count over time (by step)**
```sql
select step as unit_of_time,
count(*)
from transactions
group by unit_of_time
order by unit_of_time asc;
```
It reveals **spikes in transaction activity** around steps 18-20 and 33-44, which may be important periods for deeper fraud investigation or system load analysis.

**7)Zero Balance Patterns: Detects transactions where amount transfered or paid to recipients show zero balance.**
```sql
Select *
from transactions
where type in ('TRANSFER','PAYMENT')
and newbalanceDest = 0
and amount > 0;
```
where the **recipient's balance remains zero** even after receiving a `TRANSFER` or `PAYMENT`.  
Such behavior may indicate **fake or inactive destination accounts**, often used in fraud to disguise money movement or siphon funds undetected.

**8)Mismatch in balances (possible manipulation or allowing overdrafts and simply zeroing out balances)**
```sql
select *
from transactions
where (type in ('CASH_OUT','DEBIT','PAYMENT','TRANSFER') and (oldbalanceorg <> newbalanceorig + amount)) 
or 
(type ='CASH_IN' and (oldbalanceorg <> newbalanceorig - amount));
```
This query identifies **balance mismatches**, where the expected change in the sender’s balance does not align with the transaction amount.  
Such mismatches like paying more than the available balance or incorrect balance updates may indicate **manipulation**, **overdrafts**, or systems **bypassing validation rules**, which can be exploited in fraud attempts.

**9)Looping or round-tripping (money goes out, then comes back in)**
```sql
SELECT DISTINCT t1.nameOrig
FROM transactions t1
JOIN transactions t2
  ON t1.nameOrig = t2.nameDest
  AND t1.amount = t2.amount;
```
No matching patterns were found in the dataset, suggesting **no direct evidence of looping behavior** under this condition.

**10)Running total of frauds over time**
```sql
SELECT step,
       SUM(isFraud) AS no_of_frauds,
       SUM(SUM(isFraud)) OVER (ORDER BY step) AS running_total_frauds
FROM transactions
GROUP BY step
ORDER BY step;
```
It reveals how fraud accumulates over time, with the total reaching **1,142 fraudulent transactions by step 95**, highlighting **continuous fraudulent activity throughout the dataset**.

**11)Most frequently targeted accounts in fraud cases**
```sql
select namedest,
sum(isfraud) as times_targeted
from transactions
where isfraud = 1
group by namedest
order by times_targeted desc
limit 10;
```
This query identifies **destination accounts that were repeatedly targeted in fraudulent transactions**.  
Each account listed (e.g., `C200064275`, `C803116137`) appeared **twice as a fraud target**, which could indicate they are **mule accounts or part of a fraud network**.

**12)High-value fraud transactions (top 1%)**
```sql
SELECT *
FROM transactions
WHERE isFraud = 1
  AND amount > (
      SELECT PERCENTILE_CONT(0.99) 
      WITHIN GROUP (ORDER BY amount)
      FROM transactions
  );
```
These large transactions, such as those exceeding $10 million, pose a **higher financial risk** and often involve **sophisticated fraud attempts**, making them critical for deeper investigation.

---

## 🧾 Findings

- The majority of fraudulent transactions were concentrated in `TRANSFER` and `CASH_OUT` types, suggesting these are high-risk categories.
- Several transactions showed balance inconsistencies and zero balance patterns, indicating possible manipulation or system loopholes.
- While no direct looping transactions were found, repeated use of the same destination accounts in frauds raises flags about potential mule accounts.
- High-value frauds (top 1%) involved transaction amounts exceeding $10 million, highlighting the importance of prioritizing large transfers for scrutiny.

---

This project showcases how SQL can be effectively used to detect fraud by analyzing transactional behavior, balance flows, and anomalies. It reflects my ability to think critically, apply logic based rules, and uncover insights from raw data. These skills are directly transferable to real world roles in data analysis, fraud detection, and business intelligence where uncovering hidden risks can save organizations significant time and money.
