-- Canonical queries behind the case-queue dashboard.
-- Run through the viper-stage MCP (query_database), or paste into SSMS.
-- Open means VoidDate and CompleteDate are both null. Derek is TAGClient-NellisD.

-- 1. Headline counts
SELECT COUNT(CaseID) AS TotalOpen,
       SUM(CASE WHEN DueDate < GETDATE() THEN 1 ELSE 0 END) AS Overdue,
       SUM(CASE WHEN DueDate >= GETDATE() AND DueDate < DATEADD(day,7,GETDATE()) THEN 1 ELSE 0 END) AS DueNext7,
       SUM(CASE WHEN DueDate IS NULL THEN 1 ELSE 0 END) AS NoDueDate,
       MIN(DateCreated) AS OldestCreated
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD';

-- 2. Project parents. DevStatus = 'Project' is the only marker; CaseProject is
-- populated for one project only, so it cannot be used to find the parents.
SELECT CaseID, CaseTitle, DueDate, DevCaseType, CaseImpact, DateCreated
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD'
  AND DevStatus = 'Project'
ORDER BY CaseID;

-- 3. Overdue, every one of them
SELECT CaseID, CaseTitle, DueDate, DATEDIFF(day, DueDate, GETDATE()) AS DaysLate
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD'
  AND DueDate < GETDATE()
ORDER BY DueDate;

-- 4. Everything with a date in the next 8 weeks, which is what the timeline renders
SELECT CaseID, CaseTitle, DueDate, DevRanking, CaseImpact
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD'
  AND DueDate >= GETDATE() AND DueDate < DATEADD(week, 8, GETDATE())
ORDER BY DueDate, DevRanking;

-- 5. Work-thread buckets. Title prefixes carry the grouping the schema does not.
SELECT CASE
         WHEN CaseTitle LIKE '(CI3-4 guard)%' OR CHARINDEX('guard_', CaseTitle) > 0 THEN 'guard sprocs'
         WHEN CaseTitle LIKE '(CI3-4)%' THEN 'CI3-4 migration'
         WHEN CaseTitle LIKE '%Snout%' OR CaseTitle LIKE '(SNOUT)%' THEN 'Snout'
         WHEN CaseTitle LIKE 'Vuln%' OR CaseTitle LIKE '%OSV%' THEN 'Vuln/OSV'
         WHEN CaseTitle LIKE 'JS Error%' THEN 'JS error cases'
         ELSE 'other'
       END AS Bucket,
       COUNT(CaseID) AS Cases,
       SUM(CASE WHEN DueDate < GETDATE() THEN 1 ELSE 0 END) AS Overdue,
       MIN(DueDate) AS EarliestDue
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD'
GROUP BY CASE
         WHEN CaseTitle LIKE '(CI3-4 guard)%' OR CHARINDEX('guard_', CaseTitle) > 0 THEN 'guard sprocs'
         WHEN CaseTitle LIKE '(CI3-4)%' THEN 'CI3-4 migration'
         WHEN CaseTitle LIKE '%Snout%' OR CaseTitle LIKE '(SNOUT)%' THEN 'Snout'
         WHEN CaseTitle LIKE 'Vuln%' OR CaseTitle LIKE '%OSV%' THEN 'Vuln/OSV'
         WHEN CaseTitle LIKE 'JS Error%' THEN 'JS error cases'
         ELSE 'other'
       END
ORDER BY COUNT(CaseID) DESC;

-- 6. CI4 due curve, the cliff chart
SELECT CONVERT(varchar(7), DueDate, 120) AS DueMonth, COUNT(CaseID) AS Cases
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD'
  AND CaseTitle LIKE '(CI3-4)%'
GROUP BY CONVERT(varchar(7), DueDate, 120)
ORDER BY DueMonth;

-- 7. DevStatus spread, the finding the page is named after
SELECT ISNULL(DevStatus,'(none)') AS DevStatus, ISNULL(DevCaseType,'(none)') AS DevCaseType, COUNT(CaseID) AS Cases
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NULL AND AssignedTo = 'TAGClient-NellisD'
GROUP BY DevStatus, DevCaseType
ORDER BY COUNT(CaseID) DESC;

-- 8. Closed since a given date, to name what moved between runs
SELECT CaseID, CaseTitle, CompleteDate
FROM cases
WHERE VoidDate IS NULL AND CompleteDate IS NOT NULL AND AssignedTo = 'TAGClient-NellisD'
  AND CompleteDate >= '2026-08-19'
ORDER BY CompleteDate DESC;
