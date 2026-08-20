/*
    REFERENCE COPY for /dev:sql Step 5b. Frozen as-shipped; read it, do not run it.

    Case 355075 | NESCO parity differential
    Run AFTER the numbered change scripts (new Procore_TimeCardBulkSync + e_procoreCustomField seeds live).

    Proves programmatically that the refactored bulk sync is behavior-identical for NESCO:
    deploys the PRE-CHANGE proc body (from git master) as Procore_TimeCardBulkSync_355075Baseline,
    runs baseline and current against the SAME branch-complete synthetic payload (real NESCO
    employee/project/cost-code ids spliced in at runtime), captures landed rows + error output
    inside rolled-back transactions, and EXCEPT-diffs the outcomes in both directions.

    OUTPUT: expect FIVE grids (each run emits its Errors + Actions pair in View mode);
    the verdict is the LAST grid. Copy the LAST grid WITH HEADERS into the RESULTS block below.

    Vacuousness guard: the verdict FAILS if fewer than 3 corpus entries actually landed,
    so a broken corpus (all rows skipped) cannot masquerade as a pass.

    Side effects: none. Both runs roll back; PunchCalculate writes for the 2020-dated corpus
    roll back with them; the baseline proc is dropped at the end. Window 2020-01-05..2020-01-10
    is used so the proc's void-sweep cannot touch real NESCO rows even transiently.
*/

IF OBJECT_ID('dbo.Procore_TimeCardBulkSync_355075Baseline') IS NOT NULL
    DROP PROCEDURE dbo.Procore_TimeCardBulkSync_355075Baseline;
GO

--==================================================================
-- Baseline: pre-change proc body from git origin/master, renamed
--==================================================================
CREATE OR ALTER PROC dbo.Procore_TimeCardBulkSync_355075Baseline(
    @User      VARCHAR(50),
    @Client    VARCHAR(50),
    @StartDate DATE,
    @EndDate   DATE,
    @TimeCards JSON,
    @Output    VARCHAR(50) = 'View'
) AS
BEGIN
    /*
    --*******************
    --?  DECLARATIONS
    --*******************
    */
    DECLARE
        @LogTable LogTable,
        @ErrorTable ErrorTable,
        @ActionTable ActionTable,
        @FailedSources VARCHAR(MAX),
        @PunchCalcRowId INT,
        @PunchCalcMaxRowId INT,
        @PunchCalcEmployee VARCHAR(50),
        @PunchCalcDate DATE,
        @Total INT,
        @SuccessCount INT,
        @FailureCount INT;

    SELECT * INTO #t_TimeOld FROM Dannysprostate.temp.t_Time#Copy;
    SELECT * INTO #t_TimeNew FROM Dannysprostate.temp.t_Time#Copy;

    SELECT * INTO #RequestOld FROM Dannysprostate.temp.Request#Copy;
    SELECT * INTO #RequestNew FROM Dannysprostate.temp.Request#Copy;

    --? Used to pick relevant fields from the JSON for the given client
    CREATE TABLE #CustomFieldMeta (
        Client       VARCHAR(50),
        LsType       VARCHAR(50),
        FieldId      VARCHAR(100),
        DefaultValue VARCHAR(255)
    )

    CREATE TABLE #TimeZoneOffset (
        Employee VARCHAR(50),
        Day      DATE,
        Offset   INT
    )

    CREATE TABLE #PunchCalculateParam (
        RowId    INT IDENTITY,
        Employee VARCHAR(50),
        Date     DATE
    )

    CREATE TABLE #TimeCard (
        --? Fields directly from TimeCard
        ProjectId     BIGINT,
        TimeCardId    BIGINT,
        Client        VARCHAR(50),
        EmployeeId    VARCHAR(50),
        Status        VARCHAR(50),
        CostCode      VARCHAR(50),
        CostCodeName  VARCHAR(500),
        Date          DATE,
        Hours         DECIMAL(12, 2),
        LocationId    VARCHAR(255),
        LunchTime     VARCHAR(50),
        TimeIn        DATETIME,
        TimeOut       DATETIME,
        TimeCardType  VARCHAR(50),
        DeletedAt     DATETIME,
        CustomFields  NVARCHAR(MAX),
        --? Derived fields
        Employee      VARCHAR(50),
        TableToUse    VARCHAR(50),
        IntegrationId VARCHAR(255),
        OvernightYn   BIT,
        Source        VARCHAR(255),
        ApprovedDate  DATETIME,
        ApproveBy     VARCHAR(50),
        LS1           VARCHAR(255),
        LS2           VARCHAR(255),
        LS3           VARCHAR(255),
        LS1RowId      VARCHAR(500),
        LS2RowId      VARCHAR(500),
        LS3RowId      VARCHAR(500)
    );

    /*
    --*******************
    --? Parse TimeCards
    --*******************
    */
    INSERT INTO #TimeCard (ProjectId, TimeCardId, Client, EmployeeId, Status, CostCode, CostCodeName, Date, Hours,
                           LocationId, LunchTime, TimeIn, TimeOut, TimeCardType, DeletedAt, CustomFields)
    SELECT JSON_VALUE(value, '$.projectId'),
           JSON_VALUE(value, '$.timeCardId'),
           -- DN : This may need to be changed later to support multiple clients/subs
           @Client, -- JSON_VALUE(value, '$.timeCardClient'),
           JSON_VALUE(value, '$.employeeId'),
           JSON_VALUE(value, '$.status'),
           JSON_VALUE(value, '$.costCode'),
           JSON_VALUE(value, '$.costCodeName'),
           JSON_VALUE(value, '$.date'),
           CAST(JSON_VALUE(value, '$.hours') AS DECIMAL(12, 2)),
           JSON_VALUE(value, '$.locationId'),
           JSON_VALUE(value, '$.lunchTime'),
           TRY_CAST(JSON_VALUE(value, '$.timeIn') AS DATETIME),
           TRY_CAST(JSON_VALUE(value, '$.timeOut') AS DATETIME),
           JSON_VALUE(value, '$.timeCardType'),
           TRY_CAST(JSON_VALUE(value, '$.deletedAt') AS DATETIME),
           JSON_QUERY(value, '$.customFields')
    FROM OPENJSON(@TimeCards);

    -- Employee lookup and validation
    UPDATE TC
    SET Employee = Entity
    FROM #TimeCard TC
    INNER JOIN l_objectold EE
        ON EE.EntityOwner = TC.Client
    WHERE RIGHT(REPLICATE('0', 5) + EE.EmployeeNumber, 5) = RIGHT(REPLICATE('0', 5) + TC.EmployeeId, 5);

    INSERT INTO @ErrorTable (ErrorNumber, Domain, [Source], Severity, [Message])
    SELECT 1,
           'Integrations',
           'Procore_TimeCardBulkSync',
           'High',
           CONCAT('Employee ID not found in our system: ', EmployeeId)
    FROM #TimeCard
    WHERE Employee IS NULL
    GROUP BY EmployeeId

    -- Procore uses zulu time so we need to convert it back to the home timezone for the EE for processing purposes.
    INSERT INTO #TimeZoneOffset (Employee, Day, Offset)
    SELECT TC.Employee,
           TC.Date,
           TZ.Offset - 7
    FROM #TimeCard TC
    CROSS APPLY dbo.TimeZone(TC.Employee, TC.Date, TC.Date) TZ
    GROUP BY TC.Employee, TC.Date, TZ.Offset

    UPDATE TC
    SET TimeIn  = DATEADD(HH, TZ.Offset, TC.TimeIn),
        TimeOut = DATEADD(HH, TZ.Offset, TC.TimeOut)
    FROM #TimeCard TC
    INNER JOIN #TimeZoneOffset TZ
        ON TZ.Employee = TC.Employee
        AND TZ.Day = TC.Date

    -- Other computed fields
    UPDATE #TimeCard
    SET TableToUse    = IIF(Status = 'Approved', IIF(TimeIn IS NULL, 't_Time', 'Request'), NULL),
        ApprovedDate  = IIF(Status = 'Approved', GETDATE(), NULL),
        ApproveBy     = IIF(Status = 'Approved', 'Procore', NULL),
        OvernightYn   = IIF(DATEPART(HH, TimeIn) > DATEPART(HH, TimeOut), '1', '0'), --we only want to look at the hours here, not the date
        Source        = 'Procore-' + CAST(TimeCardId AS VARCHAR),
        IntegrationId = CONCAT('Procore-',
                               CAST(ProjectId AS VARCHAR),
                               IIF(ISNULL(LocationId, '') <> '', '>' + LocationId, ''))
    WHERE Employee IS NOT NULL;

    --? Custom Fields
    --? DN : For now this can work as a "shivved" lookup table. In the future, if
    --? more clients require this treatment we can move this to a real table.
    INSERT INTO #CustomFieldMeta (Client, LsType, FieldId, DefaultValue)
    VALUES
        ('NESCO', 'LS2', 562949953936283, 'Field'),
        ('NESCO', 'LS3', NULL, NULL);

    /*
    --*******************
    --? LS- Lookups
    --*******************
    */
    -- LS1
    UPDATE TC
    SET LS1RowId = Item
    FROM #TimeCard TC
    INNER JOIN l_integrationIDLookup ID
        ON ID.client = TC.Client
        AND ID.app_id = CAST(TC.ProjectId AS VARCHAR)
    WHERE ID.ItemType = 'Project'

    UPDATE TC
    SET LS1 = LS.LS1
    FROM #TimeCard TC
    INNER JOIN e_LS1 LS
        ON LS.RowId = TC.LS1RowId
        AND LS.ClientParent = TC.Client

    IF EXISTS (SELECT * FROM #CustomFieldMeta WHERE LsType = 'LS1')
        BEGIN
            UPDATE TC
            SET LS1 = COALESCE(
                    NULLIF(IIF(JSON_VALUE(CustomFields.value, '$.dataType') = 'lov_entry',
                               JSON_VALUE(CustomFields.value, '$.value.label'),
                               JSON_VALUE(CustomFields.value, '$.value')),
                           ''
                    ), CF.DefaultValue)
            FROM #TimeCard TC
            INNER JOIN #CustomFieldMeta CF
                ON CF.Client = TC.Client
            CROSS APPLY OPENJSON(TC.CustomFields) AS CustomFields
            WHERE CF.LsType = 'LS1'
              AND JSON_VALUE(CustomFields.value, '$.active') = 'true'
              AND JSON_VALUE(CustomFields.value, '$.id') = CF.FieldId
        END

    -- LS2
    UPDATE TC
    SET LS2RowId = Item
    FROM #TimeCard TC
    INNER JOIN l_integrationIDLookup ID
        ON ID.client = TC.Client
        AND ID.app_id = TC.CostCode
    WHERE ID.ItemType = 'CostCode'

    UPDATE TC
    SET LS2 = LS.LS2
    FROM #TimeCard TC
    INNER JOIN e_LS2 LS
        ON LS.RowId = TC.LS2RowId
        AND LS.ClientParent = TC.Client

    IF EXISTS (SELECT * FROM #CustomFieldMeta WHERE LsType = 'LS2')
        BEGIN
            UPDATE TC
            SET LS2 = COALESCE(
                    NULLIF(IIF(JSON_VALUE(CustomFields.value, '$.dataType') = 'lov_entry',
                               JSON_VALUE(CustomFields.value, '$.value.label'),
                               JSON_VALUE(CustomFields.value, '$.value')),
                           ''
                    ), CF.DefaultValue)
            FROM #TimeCard TC
            INNER JOIN #CustomFieldMeta CF
                ON CF.Client = TC.Client
            CROSS APPLY OPENJSON(TC.CustomFields) AS CustomFields
            WHERE CF.LsType = 'LS2'
              AND JSON_VALUE(CustomFields.value, '$.active') = 'true'
              AND JSON_VALUE(CustomFields.value, '$.id') = CF.FieldId
        END

    -- LS3
    --? DN : Currently, an explicit row in #CustomFieldMeta is required for LS3.
    --? Additionally, a lack of FieldId is indicative of which "LS" we map CostCodes to
    IF EXISTS (SELECT * FROM #CustomFieldMeta WHERE LsType = 'LS3' AND FieldId IS NULL)
        BEGIN
            -- Primary lookup: match by CostCode (standard_cost_code_id)
            UPDATE TC
            SET LS3RowId = ISNULL(ID.Item, CF.DefaultValue)
            FROM #TimeCard TC
            INNER JOIN #CustomFieldMeta CF
                ON CF.Client = TC.Client
            LEFT JOIN l_integrationIDLookup ID
                ON ID.client = TC.Client
                AND ID.app_id = TC.CostCode
                AND ID.ItemType = 'CostCode'
            WHERE CF.LsType = 'LS3'
              AND CF.FieldId IS NULL
              AND ID.Item IS NOT NULL

            -- Fallback: match by CostCodeName when standard_cost_code_id is null
            UPDATE TC
            SET LS3RowId = ID.Item
            FROM #TimeCard TC
            INNER JOIN l_integrationIDLookup ID
                ON ID.client = TC.Client
                AND ID.Description = TC.CostCodeName
                AND ID.ItemType = 'CostCode'
                AND ID.App = 'Procore'
                AND ID.Void_date IS NULL
            WHERE TC.LS3RowId IS NULL
              AND TC.CostCodeName IS NOT NULL
              AND ID.Item IS NOT NULL

            UPDATE TC
            SET LS3 = LS.Item
            FROM #TimeCard TC
            INNER JOIN e_Assign LS
                ON LS.RowId = TC.LS3RowId
                AND LS.Entity = TC.Client
            WHERE LS.ItemType = 'LS3'
        END

    IF EXISTS (SELECT * FROM #CustomFieldMeta WHERE LsType = 'LS3' AND FieldId IS NOT NULL)
        BEGIN
            UPDATE TC
            SET LS3 = COALESCE(
                    NULLIF(IIF(JSON_VALUE(CustomFields.value, '$.dataType') = 'lov_entry',
                               JSON_VALUE(CustomFields.value, '$.value.label'),
                               JSON_VALUE(CustomFields.value, '$.value')),
                           ''
                    ), CF.DefaultValue)
            FROM #TimeCard TC
            INNER JOIN #CustomFieldMeta CF
                ON CF.Client = TC.Client
            CROSS APPLY OPENJSON(TC.CustomFields) AS CustomFields
            WHERE CF.LsType = 'LS3'
              AND JSON_VALUE(CustomFields.value, '$.active') = 'true'
              AND JSON_VALUE(CustomFields.value, '$.id') = CF.FieldId
        END

    -- Validations
    INSERT INTO @ErrorTable (ErrorNumber, Domain, [Source], Severity, [Message])
    SELECT 2,
           'Integrations',
           'Procore_TimeCardBulkSync',
           'High',
           CONCAT(
                   'Cost code "', CostCodeName, '" for time card ID ', TimeCardId, ' has an unmapped/missing',
                   IIF(LS1 IS NULL, ' Job', ''),
                   IIF(LS1 IS NULL AND LS2 IS NULL, ' and', ''),
                   IIF(LS2 IS NULL, ' Task', ''))
    FROM #TimeCard
    WHERE LS1 IS NULL
       OR LS2 IS NULL

    /*
    --*******************
    --? Table Actions
    --*******************
    */
    ----------------------
    --? t_time UPDATE
    ----------------------
    BEGIN TRY
        UPDATE TT
        SET Date          = TC.Date,
            LS1           = TC.LS1,
            LS2           = TC.LS2,
            LS3           = TC.LS3,
            BaseRequested = TC.Hours,
            BaseDisplayed = TC.Hours,
            Status        = TC.Status,
            ApprovedDate  = TC.ApprovedDate
        OUTPUT DELETED.* INTO #t_TimeOld
        FROM t_time TT
        INNER JOIN #TimeCard TC
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
        WHERE TC.TableToUse = 't_Time'
          AND TT.VoidDate IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL

        INSERT INTO @ActionTable (Action, Id)
        SELECT 'Updated', TC.TimeCardId
        FROM #t_TimeOld TT
        INNER JOIN #TimeCard TC
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
        WHERE TC.TableToUse = 't_Time'
        GROUP BY TC.TimeCardId
    END TRY
    BEGIN CATCH
        SELECT @FailedSources += STRING_AGG('|' + TC.Source + ' (' + TC.EmployeeId + ')', '|')
        FROM t_time TT
        INNER JOIN #TimeCard TC
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
        WHERE TC.TableToUse = 't_Time'
          AND TT.VoidDate IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL
    END CATCH

    ----------------------
    --? t_time INSERT
    ----------------------
    BEGIN TRY
        INSERT INTO t_Time (Client, Employee, Date, LS1, LS2, LS3, BaseRequested, BaseDisplayed, Status, ApprovedDate,
                            Source)
        OUTPUT INSERTED.* INTO #t_TimeNew
        SELECT TC.Client,
               TC.Employee,
               TC.Date,
               TC.LS1,
               TC.LS2,
               TC.LS3,
               Hours,
               Hours,
               TC.Status,
               TC.ApprovedDate,
               TC.Source
        FROM #TimeCard TC
        LEFT JOIN t_Time TT
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
            AND TT.VoidDate IS NULL
        WHERE TC.TableToUse = 't_Time'
          AND TT.RowID IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL

        INSERT INTO @ActionTable (Action, Id)
        SELECT 'Created', TC.TimeCardId
        FROM #t_TimeNew TT
        INNER JOIN #TimeCard TC
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
        WHERE TC.TableToUse = 't_Time'
        GROUP BY TC.TimeCardId
    END TRY
    BEGIN CATCH
        SELECT @FailedSources += STRING_AGG('|' + TC.Source + ' (' + TC.EmployeeId + ')', '|')
        FROM #TimeCard TC
        LEFT JOIN t_Time TT
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
            AND TT.VoidDate IS NULL
        WHERE TC.TableToUse = 't_Time'
          AND TT.RowID IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL
    END CATCH

    ----------------------
    --? t_time VOID
    ----------------------
    BEGIN TRY
        -- Void out any time records that were removed on the Procore side
        UPDATE TT
        SET VoidDate = GETDATE()
        FROM (SELECT *
              FROM t_Time
              WHERE Client = @Client -- This may be a problem if time cards include multiple clients
                AND VoidDate IS NULL
                AND Date BETWEEN @StartDate AND @EndDate) TT
        LEFT JOIN #TimeCard TC
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
            AND TC.TableToUse = 't_Time'
        WHERE TC.TimeCardId IS NULL
          AND TT.Source LIKE 'Procore%'
    END TRY
    BEGIN CATCH
        INSERT INTO @ErrorTable (ErrorNumber, Domain, [Source], Severity, [Message])
        SELECT 3,
               'Integrations',
               'Procore_TimeCardBulkSync',
               'Low',
               'The following time card sources could not be voided:<br/>' + STRING_AGG(TT.Source, ', ')
        FROM (SELECT *
              FROM t_Time
              WHERE Client = @Client
                AND VoidDate IS NULL
                AND Date BETWEEN @StartDate AND @EndDate) TT
        LEFT JOIN #TimeCard TC
            ON TT.Source = TC.Source
            AND TT.Employee = TC.Employee
            AND TC.TableToUse = 't_Time'
        WHERE TC.TimeCardId IS NULL
    END CATCH

    ----------------------
    --? Request UPDATE
    ----------------------
    BEGIN TRY
        UPDATE R
        SET Date            = TC.Date,
            TimeIn          = TC.TimeIn,
            TimeOut         = TC.TimeOut,
            OriginalTimeIn  = TC.TimeIn,
            OriginalTimeOut = TC.TimeOut,
            BreakTime       = TC.LunchTime,
            BreakSource     = IIF(TC.Lunchtime IS NOT NULL, 'Manual', NULL),
            WorkLS1         = TC.LS1,
            WorkLS2         = TC.LS2,
            WorkLS3         = TC.LS3,
            ApproveDate     = TC.ApprovedDate,
            ApproveBy       = TC.ApproveBy,
            OvernightYn     = TC.OvernightYn,
            Shift           = IIF(TC.TimeCardType = 'Swing Shift', 'Swing', NULL),
            VoidDate        = IIF(ISNULL(TC.DeletedAt, '') <> '', TC.DeletedAt, NULL)
        OUTPUT DELETED.* INTO #RequestOld
        FROM Request R
        INNER JOIN #TimeCard TC
            ON R.Source = TC.Source
            AND R.Employee = TC.Employee
        WHERE TC.TableToUse = 'Request'
          AND R.VoidDate IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL

        INSERT INTO @ActionTable (Action, Id)
        SELECT 'Updated', TC.TimeCardId
        FROM #RequestOld R
        INNER JOIN #TimeCard TC
            ON R.Source = TC.Source
            AND R.Employee = TC.Employee
        WHERE TC.TableToUse = 'Request'
        GROUP BY TC.TimeCardId
    END TRY
    BEGIN CATCH
        SELECT @FailedSources += STRING_AGG('|' + TC.Source + ' (' + TC.EmployeeId + ')', '|')
        FROM Request R
        INNER JOIN #TimeCard TC
            ON R.Source = TC.Source
            AND R.Employee = TC.Employee
        WHERE TC.TableToUse = 'Request'
          AND R.VoidDate IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL
    END CATCH

    ----------------------
    --? Request INSERT
    ----------------------
    BEGIN TRY
        INSERT INTO Request (Client, Employee, Date, InputTypeIn, InputTypeOut, LocationIn, LocationOut, OriginalTimeIn,
                             OriginalTimeOut, TimeIn, TimeOut, BreakTime, BreakSource, WorkLS1, WorkLS2, WorkLS3,
                             Source, REquestType, ApproveDate, ApproveBy, OvernightYn, Shift)
        OUTPUT INSERTED.* INTO #RequestNew
        SELECT @Client,
               TC.Employee,
               TC.Date,
               'Procore',
               'Procore',
               TC.Source,
               TC.Source,
               TC.TimeIn,
               TC.TimeOut,
               TC.TimeIn,
               TC.TimeOut,
               TC.LunchTime,
               IIF(TC.Lunchtime IS NOT NULL, 'Manual', NULL),
               TC.LS1,
               TC.LS2,
               TC.LS3,
               TC.Source,
               'Punch',
               IIF(TC.Status = 'Approved', GETDATE(), NULL),
               IIF(TC.Status = 'Approved', 'Procore', NULL),
               TC.OvernightYn,
               IIF(TC.TimeCardType = 'Swing Shift', 'Swing', NULL)
        FROM #TimeCard TC
        LEFT JOIN Request R
            ON TC.Source = R.Source
            AND TC.Employee = R.Employee
            AND R.VoidDate IS NULL
        WHERE TC.TableToUse = 'Request'
          AND R.RequestID IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL

        INSERT INTO @ActionTable (Action, Id)
        SELECT 'Created', TC.TimeCardId
        FROM #TimeCard TC
        LEFT JOIN #RequestNew R
            ON TC.Source = R.Source
            AND TC.Employee = R.Employee
        WHERE TC.TableToUse = 'Request'
        GROUP BY TC.TimeCardId
    END TRY
    BEGIN CATCH
        SELECT @FailedSources += STRING_AGG('|' + TC.Source + ' (' + TC.EmployeeId + ')', '|')
        FROM #TimeCard TC
        LEFT JOIN Request R
            ON TC.Source = R.Source
            AND TC.Employee = R.Employee
            AND R.VoidDate IS NULL
        WHERE TC.TableToUse = 'Request'
          AND R.RequestID IS NULL
          AND TC.LS1 IS NOT NULL
          AND TC.LS2 IS NOT NULL
          AND TC.Employee IS NOT NULL
    END CATCH

    ----------------------
    --? Request VOID
    ----------------------
    BEGIN TRY
        -- Void out any request records that were removed on the Procore side
        UPDATE R
        SET VoidDate = GETDATE()
        FROM (SELECT *
              FROM Request
              WHERE Client = @Client -- This may be a problem if time cards include multiple clients
                AND VoidDate IS NULL
                AND Date BETWEEN @StartDate AND @EndDate) R
        LEFT JOIN #TimeCard TC
            ON R.Source = TC.Source
            AND R.Employee = TC.Employee
            AND TC.TableToUse = 'Request'
        WHERE TC.TimeCardId IS NULL
          AND R.Source LIKE 'Procore%'
    END TRY
    BEGIN CATCH
        INSERT INTO @ErrorTable (ErrorNumber, Domain, [Source], Severity, [Message])
        SELECT 4,
               'Integrations',
               'Procore_TimeCardBulkSync',
               'Low',
               'The following time card request sources could not be voided:<br/>' + STRING_AGG(R.Source, ', ')
        FROM (SELECT *
              FROM Request
              WHERE Client = @Client
                AND VoidDate IS NULL
                AND DATE BETWEEN @StartDate AND @EndDate) R
        LEFT JOIN #TimeCard TC
            ON R.Source = TC.Source
            AND R.Employee = TC.Employee
            AND TC.TableToUse = 'Request'
        WHERE TC.TimeCardId IS NULL
    END CATCH

    IF @FailedSources <> ''
        BEGIN
            INSERT INTO @ErrorTable (ErrorNumber, Domain, [Source], Severity, [Message])
            SELECT 5,
                   'Integrations',
                   'Procore_TimeCardBulkSync',
                   'Low',
                   'Time card source (employee ID) failed to sync: ' + S.value
            FROM STRING_SPLIT(@FailedSources, '|') S
            WHERE S.value <> ''
            GROUP BY S.value
        END

    /*
    --*******************
    --?     LOGGING
    --*******************
    */
    SELECT @Total = COUNT(*)
    FROM #TimeCard

    SELECT @SuccessCount = COUNT(*)
    FROM #t_TimeNew

    SELECT @SuccessCount += COUNT(*)
    FROM #RequestNew

    SELECT @FailureCount = @Total - @SuccessCount

    EXEC Procore_Update_LastSync
         @User = @User,
         @Client = @Client,
         @Type = 'PullTimeCardLastSync',
         @SilentYn = 1,
         @Start = @StartDate,
         @End = @EndDate,
         @Total = @Total,
         @SuccessCount = @SuccessCount,
         @FailureCount = @FailureCount

    -- Insert new records for diffing old (DELETED.*) records
    INSERT INTO #t_TimeNew
    SELECT N.*
    FROM t_Time N
    INNER JOIN #t_TimeOld O ON O.RowId = N.RowId

    INSERT INTO #RequestNew
    SELECT N.*
    FROM Request N
    INNER JOIN #RequestOld O ON O.RequestID = N.RequestID

    -- Actual log table inserts
    INSERT INTO @LogTable (ChangeType, DataSource, Entity, ItemType, Item, OldValue, NewValue)
    SELECT IIF(O.RowId IS NULL, 'Insert', 'Update'),
           'Procore_TimeCardBulkSync',
           N.Client,
           't_Time',
           N.RowId,
           (SELECT O.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS [OldValue],
           (SELECT N.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS [NewValue]
    FROM #t_TimeNew N
    LEFT JOIN #t_TimeOld O ON N.RowId = O.RowId
    WHERE (SELECT O.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) <>
          (SELECT N.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)

    INSERT INTO @LogTable (ChangeType, DataSource, Entity, ItemType, Item, OldValue, NewValue)
    SELECT IIF(O.RequestID IS NULL, 'Insert', 'Update'),
           'Procore_TimeCardBulkSync',
           N.Client,
           'Request',
           N.RequestID,
           (SELECT O.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS [OldValue],
           (SELECT N.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) AS [NewValue]
    FROM #RequestNew N
    LEFT JOIN #RequestOld O ON N.RequestID = O.RequestID
    WHERE (SELECT O.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES) <>
          (SELECT N.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES)

    EXEC LogLogTable @LogTable = @LogTable, @User = @User;
    EXEC LogErrorTable @ErrorTable = @ErrorTable, @User = @User;

    /*
    --*******************
    --? Run PunchCalculate
    --*******************
    */
    INSERT INTO #PunchCalculateParam (Employee, Date)
    SELECT Employee, Date
    FROM #TimeCard
    WHERE TableToUse IS NOT NULL
      AND LS1 IS NOT NULL
      AND LS2 IS NOT NULL
    GROUP BY Employee, Date

    SELECT @PunchCalcRowId = MIN(RowId),
           @PunchCalcMaxRowId = MAX(RowId)
    FROM #PunchCalculateParam

    IF @Output <> 'Debug'
        BEGIN
            WHILE @PunchCalcRowId <= @PunchCalcMaxRowId
                BEGIN
                    SELECT @PunchCalcEmployee = Employee,
                           @PunchCalcDate = Date
                    FROM #PunchCalculateParam
                    WHERE RowId = @PunchCalcRowId

                    EXEC PunchCalculate
                         @Employee = @PunchCalcEmployee,
                         @Date = @PunchCalcDate,
                         @User = 'Procore',
                         @Mode = 'Update',
                         @CacheYN = 1,
                         @OvertimeCalculateYN = 1

                    SET @PunchCalcRowId += 1
                END
        END

    /*
    --*******************
    --?     OUTPUT
    --*******************
    */
    IF @Output <> 'Debug'
        BEGIN
            SELECT 'Errors' AS [TableName], ErrorNumber, Message FROM @ErrorTable;
            SELECT 'Actions' AS [TableName], Action, Id FROM @ActionTable;
        END

    IF @Output = 'Debug'
        BEGIN
            SELECT '#TimeCard' AS [TableName], * FROM #TimeCard
            SELECT '#CustomFieldMeta' AS [TableName], * FROM #CustomFieldMeta
            SELECT '#TimeZoneOffset' AS [TableName], * FROM #TimeZoneOffset
            SELECT '#PunchCalculateParam' AS [TableName], * FROM #PunchCalculateParam
            SELECT '@ActionTable' AS [TableName], * FROM @ActionTable
            SELECT '@ErrorTable' AS [TableName], * FROM @ErrorTable
            SELECT '@LogTable' AS [TableName], * FROM @LogTable

            SELECT '#t_TimeNew' AS [TableName], *
            FROM #t_TimeNew
            UNION ALL
            SELECT '#t_TimeOld' AS [TableName], *
            FROM #t_TimeOld

            SELECT '#RequestNew' AS [TableName], *
            FROM #RequestNew
            UNION ALL
            SELECT '#RequestOld' AS [TableName], *
            FROM #RequestOld

            SELECT 'InvalidTimeCard' AS [TableName], *
            FROM #TimeCard
            WHERE Employee IS NULL
               OR LS1 IS NULL
               OR LS2 IS NULL
        END
END
GO

--==================================================================
-- Harness: corpus build, dual run (rolled back), differential diff
--==================================================================
SET NOCOUNT ON;

DECLARE
    @Employee VARCHAR(50), @EmployeeNumber VARCHAR(50),
    @ProjectId VARCHAR(100), @CostCodeId VARCHAR(100), @CostCodeName VARCHAR(500),
    @TimeCards NVARCHAR(MAX),
    @Field VARCHAR(50) = '562949953936283',
    @T0 DATETIME;

-- Real NESCO anchors: employee, a MAPPED project row, a MAPPED CostCode row
SELECT TOP 1 @Employee = Entity, @EmployeeNumber = employeenumber
FROM l_objectold
WHERE EntityOwner = 'NESCO' AND ISNULL(employeenumber, '') <> ''
ORDER BY Entity;

SELECT TOP 1 @ProjectId = app_id
FROM l_integrationIdLookup
WHERE client = 'NESCO' AND App = 'Procore' AND ItemType = 'Project'
  AND Void_date IS NULL AND ISNULL(Item, '') <> '' AND app_id NOT LIKE '%:%'
ORDER BY row_id;

SELECT TOP 1 @CostCodeId = app_id, @CostCodeName = [Description]
FROM l_integrationIdLookup
WHERE client = 'NESCO' AND App = 'Procore' AND ItemType = 'CostCode'
  AND Void_date IS NULL AND ISNULL(Item, '') <> ''
ORDER BY row_id;

IF @Employee IS NULL OR @ProjectId IS NULL
    BEGIN
        SELECT 'ABORT: missing NESCO anchors (employee or mapped project)' AS check_name;
        RETURN;
    END

-- Branch-complete corpus (ids 3550750001+; window 2020-01-06..08):
--  ..01 approved hours, lov field set            -> LS2 label-stamp path
--  ..02 approved hours, lov value empty          -> DefaultValue 'Field' path
--  ..03 approved hours, field inactive           -> skip-field path
--  ..04 approved hours, no custom fields         -> no-field path
--  ..05 approved punch, lov field set            -> Request/WorkLS2 path
--  ..06 approved hours, costCode set             -> LS3 primary (app_id) path
--  ..07 approved hours, costCodeName only        -> LS3 fallback (Description) path
--  ..08 pending                                  -> approval-skip path
--  ..09 approved hours, non-lov string value     -> raw $.value path
--  ..10 unknown employee                         -> employee-validation path
SELECT @TimeCards = CONCAT('[',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750001,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":null,"costCodeName":null,"date":"2020-01-06","hours":"8.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"lov_entry","value":{"id":562949953965004,"label":"Operator"},"active":true}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750002,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":null,"costCodeName":null,"date":"2020-01-06","hours":"7.5","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"lov_entry","value":{"id":0,"label":""},"active":true}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750003,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":null,"costCodeName":null,"date":"2020-01-07","hours":"6.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"lov_entry","value":{"id":562949953965004,"label":"Electrical"},"active":false}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750004,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":null,"costCodeName":null,"date":"2020-01-07","hours":"5.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750005,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":null,"costCodeName":null,"date":"2020-01-08","hours":null,"locationId":null,"lunchTime":"30","timeIn":"2020-01-08T13:00:00Z","timeOut":"2020-01-08T21:30:00Z","timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"lov_entry","value":{"id":562949953965004,"label":"Laborer"},"active":true}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750006,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":', ISNULL('"' + @CostCodeId + '"', 'null'), ',"costCodeName":null,"date":"2020-01-06","hours":"4.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"lov_entry","value":{"id":562949953965004,"label":"Operator"},"active":true}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750007,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":null,"costCodeName":', ISNULL('"' + STRING_ESCAPE(@CostCodeName, 'json') + '"', 'null'), ',"date":"2020-01-07","hours":"3.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"lov_entry","value":{"id":562949953965004,"label":"Operator"},"active":true}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750008,"employeeId":"', @EmployeeNumber, '","status":"pending","costCode":null,"costCodeName":null,"date":"2020-01-08","hours":"8.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"lov_entry","value":{"id":562949953965004,"label":"Operator"},"active":true}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750009,"employeeId":"', @EmployeeNumber, '","status":"Approved","costCode":null,"costCodeName":null,"date":"2020-01-08","hours":"2.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[{"id":', @Field, ',"label":"Work Performed Description","dataType":"string","value":"Electrical","active":true}]},',
  '{"projectId":', @ProjectId, ',"timeCardId":3550750010,"employeeId":"00000x","status":"Approved","costCode":null,"costCodeName":null,"date":"2020-01-06","hours":"1.0","locationId":null,"lunchTime":null,"timeIn":null,"timeOut":null,"timeCardType":"Regular Time","deletedAt":null,"customFields":[]}',
  ']');

DECLARE @Landed TABLE (
    RunName    VARCHAR(10),
    Tbl        VARCHAR(10),
    Source     VARCHAR(255),
    Employee   VARCHAR(50),
    Date       DATE,
    LS1        VARCHAR(255),
    LS2        VARCHAR(255),
    LS3        VARCHAR(255),
    Hours      MONEY,
    TimeIn     DATETIME,
    TimeOut    DATETIME,
    BreakTime  MONEY
);
DECLARE @Errs TABLE (RunName VARCHAR(10), Message NVARCHAR(1000));

--------------------------------------------------------------
-- Run 1: BASELINE (pre-change body), captured, rolled back
--------------------------------------------------------------
SELECT @T0 = GETDATE();
BEGIN TRAN;
EXEC dbo.Procore_TimeCardBulkSync_355075Baseline
     @User = '355075-parity', @Client = 'NESCO',
     @StartDate = '2020-01-05', @EndDate = '2020-01-10', @TimeCards = @TimeCards;

INSERT INTO @Landed (RunName, Tbl, Source, Employee, Date, LS1, LS2, LS3, Hours, TimeIn, TimeOut, BreakTime)
SELECT 'baseline', 't_time', Source, Employee, Date, LS1, LS2, LS3, BaseRequested, NULL, NULL, NULL
FROM t_time WHERE Source LIKE 'Procore-35507500%' AND VoidDate IS NULL
UNION ALL
SELECT 'baseline', 'Request', Source, Employee, Date, WorkLS1, WorkLS2, WorkLS3, NULL, TimeIn, TimeOut, BreakTime
FROM Request WHERE Source LIKE 'Procore-35507500%' AND VoidDate IS NULL;

INSERT INTO @Errs (RunName, Message)
SELECT 'baseline', Message
FROM DannysProstate.dbo.ErrorTableLog
WHERE Source = 'Procore_TimeCardBulkSync' AND CreatedBy = '355075-parity' AND CreatedDate >= @T0;
ROLLBACK TRAN;

--------------------------------------------------------------
-- Run 2: CURRENT proc, identical input, captured, rolled back
--------------------------------------------------------------
SELECT @T0 = GETDATE();
BEGIN TRAN;
EXEC dbo.Procore_TimeCardBulkSync
     @User = '355075-parity', @Client = 'NESCO',
     @StartDate = '2020-01-05', @EndDate = '2020-01-10', @TimeCards = @TimeCards;

INSERT INTO @Landed (RunName, Tbl, Source, Employee, Date, LS1, LS2, LS3, Hours, TimeIn, TimeOut, BreakTime)
SELECT 'current', 't_time', Source, Employee, Date, LS1, LS2, LS3, BaseRequested, NULL, NULL, NULL
FROM t_time WHERE Source LIKE 'Procore-35507500%' AND VoidDate IS NULL
UNION ALL
SELECT 'current', 'Request', Source, Employee, Date, WorkLS1, WorkLS2, WorkLS3, NULL, TimeIn, TimeOut, BreakTime
FROM Request WHERE Source LIKE 'Procore-35507500%' AND VoidDate IS NULL;

INSERT INTO @Errs (RunName, Message)
SELECT 'current', Message
FROM DannysProstate.dbo.ErrorTableLog
WHERE Source = 'Procore_TimeCardBulkSync' AND CreatedBy = '355075-parity' AND CreatedDate >= @T0;
ROLLBACK TRAN;

--------------------------------------------------------------
-- Verdict (LAST GRID): row-level EXCEPT diff both directions
--------------------------------------------------------------
DECLARE @BaseCount INT, @CurrCount INT, @DiffAB INT, @DiffBA INT, @ErrBase INT, @ErrCurr INT, @ErrDiff INT;

SELECT @BaseCount = COUNT(*) FROM @Landed WHERE RunName = 'baseline';
SELECT @CurrCount = COUNT(*) FROM @Landed WHERE RunName = 'current';

SELECT @DiffAB = COUNT(*) FROM (
    SELECT Tbl, Source, Employee, Date, LS1, LS2, LS3, Hours, TimeIn, TimeOut, BreakTime FROM @Landed WHERE RunName = 'baseline'
    EXCEPT
    SELECT Tbl, Source, Employee, Date, LS1, LS2, LS3, Hours, TimeIn, TimeOut, BreakTime FROM @Landed WHERE RunName = 'current') D;

SELECT @DiffBA = COUNT(*) FROM (
    SELECT Tbl, Source, Employee, Date, LS1, LS2, LS3, Hours, TimeIn, TimeOut, BreakTime FROM @Landed WHERE RunName = 'current'
    EXCEPT
    SELECT Tbl, Source, Employee, Date, LS1, LS2, LS3, Hours, TimeIn, TimeOut, BreakTime FROM @Landed WHERE RunName = 'baseline') D;

SELECT @ErrBase = COUNT(*) FROM @Errs WHERE RunName = 'baseline';
SELECT @ErrCurr = COUNT(*) FROM @Errs WHERE RunName = 'current';

SELECT @ErrDiff = COUNT(*) FROM (
    (SELECT Message FROM @Errs WHERE RunName = 'baseline' EXCEPT SELECT Message FROM @Errs WHERE RunName = 'current')
    UNION ALL
    (SELECT Message FROM @Errs WHERE RunName = 'current' EXCEPT SELECT Message FROM @Errs WHERE RunName = 'baseline')) D;

SELECT check_name, expected, actual, detail
FROM (
    SELECT CAST('01_corpus_not_vacuous' AS NVARCHAR(60)) AS check_name,
           CAST('>= 3' AS NVARCHAR(40)) AS expected,
           CAST(@BaseCount AS NVARCHAR(40)) AS actual,
           CAST(IIF(@BaseCount >= 3, 'pass', 'FAIL: corpus landed too little to prove anything') AS NVARCHAR(400)) AS detail
    UNION ALL
    SELECT '02_landed_row_counts_equal', CAST(@BaseCount AS NVARCHAR(40)), CAST(@CurrCount AS NVARCHAR(40)),
           IIF(@BaseCount = @CurrCount, 'pass', 'FAIL')
    UNION ALL
    SELECT '03_diff_baseline_minus_current', '0', CAST(@DiffAB AS NVARCHAR(40)), IIF(@DiffAB = 0, 'pass', 'FAIL')
    UNION ALL
    SELECT '04_diff_current_minus_baseline', '0', CAST(@DiffBA AS NVARCHAR(40)), IIF(@DiffBA = 0, 'pass', 'FAIL')
    UNION ALL
    SELECT '05_error_sets_identical', '0', CAST(@ErrDiff AS NVARCHAR(40)),
           CONCAT(IIF(@ErrDiff = 0, 'pass', 'FAIL'), ' (baseline ', @ErrBase, ' / current ', @ErrCurr, ' error rows)')
    UNION ALL
    SELECT '06_verdict', 'PARITY',
           IIF(@BaseCount >= 3 AND @BaseCount = @CurrCount AND @DiffAB = 0 AND @DiffBA = 0 AND @ErrDiff = 0, 'PARITY', 'DIVERGENT'),
           CONCAT('anchors: ', @Employee, ' / project ', @ProjectId, ' / costcode ', ISNULL(@CostCodeId, '(none)'))
) checks
ORDER BY check_name;
GO

DROP PROCEDURE dbo.Procore_TimeCardBulkSync_355075Baseline;
GO

/* ==== RESULTS: paste the LAST grid WITH HEADERS below this line ====

Round 2 (2026-08-13, after corpus fix: row 09 raw-string value -> real e_ls2 row):

check_name                      expected  actual  detail
01_corpus_not_vacuous           >= 3      6       pass
02_landed_row_counts_equal      6         6       pass
03_diff_baseline_minus_current  0         0       pass
04_diff_current_minus_baseline  0         0       pass
05_error_sets_identical         0         0       pass (baseline 4 / current 4 error rows)
06_verdict                      PARITY    PARITY  anchors: NESCO-AbeytaU / project 562949954650321 / costcode 562949956182224

Round 1 (2026-08-13): diff checks all passed but vacuousness guard fired (1 landed);
root cause = synthetic corpus value violating FK_t_Time_e_LS2, aborting the whole
set-based INSERT identically in both runs. Surfaced the pre-existing @FailedSources
NULL-concat swallow (error #5 unreachable). Corpus fixed; see PLAN fix notes.

==== END RESULTS ==== */
