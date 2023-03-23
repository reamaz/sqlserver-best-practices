DECLARE @Time TIME,
        @RowsToDelete INT,
        @PurgeDataPriorToDate DATETIME2,
        @RowsDeleted INT,
        @EndLoopTime TIME,
        @StartLoopTime TIME
SELECT @RowsToDelete = 5000
SELECT @EndLoopTime = '20:00:00'
SELECT @StartLoopTime = '08:00:00'

SELECT @TIME = CAST(GETDATE() AS TIME)
SELECT @PurgeDataPriorToDate = DATEADD(dd, -7, GETDATE())

SELECT @RowsDeleted = 1

SET NOCOUNT ON


WHILE @RowsDeleted > 0 AND NOT (@Time BETWEEN @StartLoopTime AND @EndLoopTime)
BEGIN --Loop

    DELETE TOP (@RowsToDelete)
    FROM Application.Logs
    WHERE EventTime < @PurgeDataPriorToDate

    CHECKPOINT

    --Pause for 1s before the next iteration
    WAITFOR DELAY '00:00:01'
    --Reset the time to verify that the loop will stop if it enters business hours.
    SELECT @TIME = CAST(GETDATE() AS TIME)
    SELECT @RowsDeleted = @@ROWCOUNT

    IF (@Time BETWEEN '08:00:00' AND '20:00:00')
        PRINT 'Loop stopped - in prohibited time range'

    IF @@ROWCOUNT = 0
        PRINT 'Loop stopped - no more rows to delete'
END --Loop
