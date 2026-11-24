	-- 1. Database-level permissions
	
	-- Shows permissions granted directly on the database itself.
	
	-- Examples:
	
	-- CONNECT
	-- CREATE TABLE
	-- ALTER ANY SCHEMA
	-- VIEW DEFINITION
	-- CONTROL


SELECT
    dp.name                  AS UserName,
    dp.type_desc             AS PrincipalType,
    perm.state_desc          AS PermissionState,
    perm.permission_name     AS PermissionName
FROM sys.database_permissions perm
JOIN sys.database_principals dp
    ON perm.grantee_principal_id = dp.principal_id
WHERE perm.class = 0
ORDER BY dp.name, perm.permission_name;


-----------------------------------------------------------------------------------------


	-- 2. Schema-level permissions

	-- Shows permissions on schemas.

	-- Examples:

	-- SELECT
	-- INSERT
	-- UPDATE
	-- DELETE
	-- EXECUTE
	-- ALTER
	-- CONTROL


SELECT
    dp.name                      AS UserName,
    s.name                       AS SchemaName,
    perm.permission_name,
    perm.state_desc
FROM sys.database_permissions perm
JOIN sys.database_principals dp
    ON perm.grantee_principal_id = dp.principal_id
JOIN sys.schemas s
    ON perm.major_id = s.schema_id
WHERE perm.class = 3
ORDER BY dp.name, s.name, perm.permission_name;




-----------------------------------------------------------------------------------------

	-- 3. Table/View-level permissions

	-- Most useful audit query.

	-- Shows:

	-- read
	-- write
	-- delete
	-- alter
	-- references
	-- control
	-- etc.
	
	
	
SELECT
    dp.name                          AS UserName,
    s.name                           AS SchemaName,
    o.name                           AS ObjectName,
    o.type_desc                      AS ObjectType,
    perm.permission_name,
    perm.state_desc
FROM sys.database_permissions perm
JOIN sys.database_principals dp
    ON perm.grantee_principal_id = dp.principal_id
JOIN sys.objects o
    ON perm.major_id = o.object_id
JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE perm.class = 1
AND o.type IN ('U', 'V')
ORDER BY dp.name, s.name, o.name, perm.permission_name;


	-- Object types:

	-- U = table
	-- V = view


-----------------------------------------------------------------------------------------


	-- 4. Stored procedure/function EXECUTE permissions
	
	
SELECT
	dp.name                      AS UserName,
	s.name                       AS SchemaName,
	o.name                       AS ObjectName,
	o.type_desc                  AS ObjectType,
	perm.permission_name,
	perm.state_desc
FROM sys.database_permissions perm
JOIN sys.database_principals dp
	ON perm.grantee_principal_id = dp.principal_id
JOIN sys.objects o
	ON perm.major_id = o.object_id
JOIN sys.schemas s
	ON o.schema_id = s.schema_id
WHERE perm.class = 1
AND o.type IN ('P', 'FN', 'TF', 'IF')
ORDER BY dp.name, s.name, o.name;



	-- Types:

	-- P = stored procedure
	-- FN = scalar function
	-- TF = table-valued function
	-- IF = inline TVF
	
	

-----------------------------------------------------------------------------------------

	-- 5. Role memberships (VERY important)

	-- Permissions are usually inherited from roles, not granted directly.

SELECT
    member.name AS UserName,
    rolep.name  AS RoleName
FROM sys.database_role_members drm
JOIN sys.database_principals rolep
    ON drm.role_principal_id = rolep.principal_id
JOIN sys.database_principals member
    ON drm.member_principal_id = member.principal_id
ORDER BY member.name, rolep.name;

	-- Common roles:

	-- db_owner
	-- db_datareader
	-- db_datawriter
	-- db_ddladmin


-----------------------------------------------------------------------------------------

	-- 6. Effective "read/write/execute" summary per object

	-- This is usually what people actually want.

SELECT
    dp.name AS UserName,
    s.name  AS SchemaName,
    o.name  AS ObjectName,

    MAX(CASE WHEN perm.permission_name = 'SELECT'  THEN 1 ELSE 0 END) AS CanRead,
    MAX(CASE WHEN perm.permission_name = 'INSERT'  THEN 1 ELSE 0 END) AS CanInsert,
    MAX(CASE WHEN perm.permission_name = 'UPDATE'  THEN 1 ELSE 0 END) AS CanUpdate,
    MAX(CASE WHEN perm.permission_name = 'DELETE'  THEN 1 ELSE 0 END) AS CanDelete,
    MAX(CASE WHEN perm.permission_name = 'EXECUTE' THEN 1 ELSE 0 END) AS CanExecute,
    MAX(CASE WHEN perm.permission_name = 'ALTER'   THEN 1 ELSE 0 END) AS CanAlter,
    MAX(CASE WHEN perm.permission_name = 'CONTROL' THEN 1 ELSE 0 END) AS CanControl

FROM sys.database_permissions perm
JOIN sys.database_principals dp
    ON perm.grantee_principal_id = dp.principal_id
JOIN sys.objects o
    ON perm.major_id = o.object_id
JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE perm.class = 1
GROUP BY
    dp.name,
    s.name,
    o.name
ORDER BY
    dp.name,
    s.name,
    o.name;


-----------------------------------------------------------------------------------------

	-- 7. Find users that can ALTER/DROP objects

	-- Important for security reviews.

	-- There is no explicit DROP permission in SQL Server.

	-- DROP ability usually comes from:

	-- CONTROL
	-- ALTER
	-- db_ddladmin
	-- db_owner

	-- Query direct permissions:

SELECT
    dp.name,
    perm.permission_name,
    perm.state_desc,
    s.name AS SchemaName,
    o.name AS ObjectName
FROM sys.database_permissions perm
JOIN sys.database_principals dp
    ON perm.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects o
    ON perm.major_id = o.object_id
LEFT JOIN sys.schemas s
    ON o.schema_id = s.schema_id
WHERE perm.permission_name IN ('ALTER', 'CONTROL')
ORDER BY dp.name;


-----------------------------------------------------------------------------------------

	-- 8. Users that effectively have broad read/write access

	-- This catches common built-in roles.

SELECT
    member.name AS UserName,
    rolep.name  AS RoleName
FROM sys.database_role_members drm
JOIN sys.database_principals rolep
    ON drm.role_principal_id = rolep.principal_id
JOIN sys.database_principals member
    ON drm.member_principal_id = member.principal_id
WHERE rolep.name IN
(
    'db_owner',
    'db_datareader',
    'db_datawriter',
    'db_ddladmin'
)
ORDER BY member.name;


---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
	-- Important caveats

	-- These queries show:

	-- direct grants
	-- direct denies

	-- But effective permissions can also come from:

	-- nested roles
	-- ownership chaining
	-- sysadmin server role
	-- impersonation
	-- certificate signing
	-- schema ownership

	-- So for a true security audit, metadata queries alone are not enough.
	-- For precise verification:

EXECUTE AS USER = 'SomeUser';
SELECT HAS_PERMS_BY_NAME(
    'dbo.SomeTable',
    'OBJECT',
    'SELECT'
);
REVERT;


