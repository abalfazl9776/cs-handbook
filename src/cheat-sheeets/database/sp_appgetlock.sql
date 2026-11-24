
	DECLARE @rc int;
EXEC @rc = sp_getapplock
    @Resource = 'MyJobLock',
    @LockMode = 'Exclusive',
    @LockOwner = 'Session',
    @LockTimeout = 0; -- 0 = don't wait, return immediately

SELECT @rc AS LockResult; -- >=0 success, <0 failure


EXEC sp_releaseapplock
    @Resource = 'MyJobLock',
    @LockOwner = 'Session';

