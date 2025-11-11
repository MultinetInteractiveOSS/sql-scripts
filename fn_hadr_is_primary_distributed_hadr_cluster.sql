CREATE OR ALTER FUNCTION [dbo].[fn_hadr_is_primary_distributed_hadr_cluster]
(
    @DB_NAME NVARCHAR(64)
)
RETURNS BIT
AS
BEGIN
    DECLARE @CURRENT_HAG NVARCHAR(32);
    DECLARE @IsPrimary BIT = 0;

    -- Get the current (non-distributed) AG name on this instance
    SELECT @CURRENT_HAG = name
    FROM sys.availability_groups
    WHERE is_distributed = 0;

    -- Check if this replica is the PRIMARY in the distributed AG
    IF EXISTS (
        SELECT 1
        FROM sys.availability_groups ag
        INNER JOIN sys.availability_replicas ar 
            ON ag.group_id = ar.group_id
        INNER JOIN sys.dm_hadr_availability_replica_states ars 
            ON ar.replica_id = ars.replica_id
        WHERE ag.is_distributed = 1
          AND ars.is_local = 1
          AND ar.replica_server_name = @CURRENT_HAG
          AND ars.role = 1
          AND sys.fn_hadr_is_primary_replica(@DB_NAME) = 1
    )
    BEGIN
        SET @IsPrimary = 1;
    END

    RETURN @IsPrimary;
END
GO
