--== لطفا نام دیتابیس و تاریخ تغییرات را وارد نمایید
--== دقت شود تاریخی که وارد می کنید تغییرات بعد از آن تاریخ بررسی می شوند
--===================================================================================================================================================
USE FundRiskAssessment
GO
DECLARE @ChangeDatetime DATETIME2(3) = '2025-11-01';




--===================================================================================================================================================
DROP TABLE IF EXISTS #ChangeDateTime;
SELECT @ChangeDatetime AS ChangeDatetime INTO #ChangeDateTime;
--======================================================================================================================================================
--== ایجاد فانکشنی که می بایست نام اسکیما را خروجی دهد ===========================================================================================
--======================================================================================================================================================
DROP FUNCTION IF EXISTS [dbo].[fnSchemaName];
GO
CREATE FUNCTION [dbo].[fnSchemaName] (
    @Name VARCHAR(50)
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @i TINYINT = 1;
    DECLARE @FirstChar AS BIT = 1;
    DECLARE @Result AS VARCHAR(50) = '';
    WHILE LEN(SUBSTRING(@Name, @i, 1)) = 1
    BEGIN
        IF SUBSTRING(@Name, @i, 1) = '.'
            SET @FirstChar = 1;
        ELSE IF @FirstChar = 1
        BEGIN
            SET @Result = @Result + UPPER(SUBSTRING(@Name, @i, 1));
            SET @FirstChar = 0;
        END;
        ELSE
        BEGIN
            SET @Result = @Result + LOWER(SUBSTRING(@Name, @i, 1));
        END;
        SET @i = @i + 1;
    END;
    RETURN @Result;
END;
GO

DECLARE @ChangeDatetime DATETIME2(3) = (SELECT ChangeDatetime FROM #ChangeDateTime);
--===================================
--به این جهت اضافه شده تا توضیحات فیلدها هم درنظر گرفته شود
WITH Column_Desc AS 
(
	SELECT QUOTENAME(SCHEMA_NAME(tbl.schema_id),']')+'.'+QUOTENAME(tbl.name,']') TableName ,col.name ColName ,ex.value
	FROM sys.extended_properties ex
	JOIN sys.columns col ON col.object_id = ex.major_id AND col.column_id=ex.minor_id
	JOIN sys.tables tbl on tbl.object_id = ex.major_id
)
--======================================================================================================================================================
--== اصلاح نام کلیدهای خارجی که فقط یک ارجاع به جدول رفرنس دارند =================================================================================
--======================================================================================================================================================
SELECT 'Wrong Naming-Script'                                                                          Problem
      ,'Foreign Key'                                                                                  [ObjectType]
      ,'EXEC SP_RENAME ''[' + SCHEMA_NAME(o.schema_id) + '].[' + f.name + ']'' , ''' + 'FK_'
       + dbo.fnSchemaName(SCHEMA_NAME(o.schema_id)) + '_' + OBJECT_NAME(f.parent_object_id) + '_'
       + dbo.fnSchemaName(SCHEMA_NAME(oo.schema_id)) + '_' + OBJECT_NAME(referenced_object_id) + '''' AS [Script/DescriptionOfProblem]
      ,f.name                                                                                         CurrentName
      ,'FK_' + dbo.fnSchemaName(SCHEMA_NAME(o.schema_id)) + '_' + OBJECT_NAME(f.parent_object_id) + '_'
       + dbo.fnSchemaName(SCHEMA_NAME(oo.schema_id)) + '_' + OBJECT_NAME(referenced_object_id)        CorrectName
      ,CONCAT('[', SCHEMA_NAME(o.schema_id), '].[' + o.name, ']')                                     ObjectName
      ,f.create_date
      ,f.modify_date
FROM sys.foreign_keys f
LEFT JOIN sys.objects o ON f.parent_object_id = o.object_id
LEFT JOIN sys.objects oo ON f.referenced_object_id = oo.object_id
WHERE SCHEMA_NAME(f.schema_id) + OBJECT_NAME(f.parent_object_id) + OBJECT_NAME(referenced_object_id) NOT IN
      (SELECT SCHEMA_NAME(schema_id) + OBJECT_NAME(parent_object_id) + OBJECT_NAME(referenced_object_id)
       FROM sys.foreign_keys t
       GROUP BY SCHEMA_NAME(schema_id) + OBJECT_NAME(parent_object_id) + OBJECT_NAME(referenced_object_id)
       HAVING COUNT(*) > 1)

	   	  AND f.name NOT LIKE 'FK_' + dbo.fnSchemaName(SCHEMA_NAME(o.schema_id)) + '_' + OBJECT_NAME(f.parent_object_id) + '_'
                + dbo.fnSchemaName(SCHEMA_NAME(oo.schema_id)) + '_' + OBJECT_NAME(referenced_object_id)+'%'
  AND ( f.create_date >= @ChangeDatetime
     OR f.modify_date >= @ChangeDatetime)
--======================================================================================================================================================
UNION
--======================================================================================================================================================
--== اصلاح نام کلیدهای خارجی که چند ارجاع به جدول رفرنس دارند =====================================================================================
--======================================================================================================================================================
SELECT 'Wrong Naming-Script'                                                                                           Problem
      ,'Foreign Key - Multi Reference'                                                                                 [ObjectType]
      ,'EXEC SP_RENAME ''[' + SCHEMA_NAME(f.schema_id) + '].[' + f.name + ']'' , ''' + 'FK_'
       + dbo.fnSchemaName(SCHEMA_NAME(o.schema_id)) + '_' + OBJECT_NAME(f.parent_object_id) + '_'
       + dbo.fnSchemaName(SCHEMA_NAME(oo.schema_id)) + '_' + OBJECT_NAME(f.referenced_object_id) + '_' + c.name + '''' UpdateScript
      ,f.name                                                                                                          CurrentName
      ,'FK_' + dbo.fnSchemaName(SCHEMA_NAME(o.schema_id)) + '_' + OBJECT_NAME(f.parent_object_id) + '_'
       + dbo.fnSchemaName(SCHEMA_NAME(oo.schema_id)) + '_' + OBJECT_NAME(f.referenced_object_id) + '_' + c.name        CorrectName
      ,CONCAT('[', SCHEMA_NAME(o.schema_id), '].[' + o.name, ']')                                                      ObjectName
      ,f.create_date
      ,f.modify_date
FROM sys.foreign_keys              f
INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = f.object_id
INNER JOIN sys.columns             c ON c.object_id = f.parent_object_id
                                    AND c.column_id = fkc.parent_column_id
LEFT JOIN sys.objects              o ON f.parent_object_id = o.object_id
LEFT JOIN sys.objects              oo ON f.referenced_object_id = oo.object_id
WHERE SCHEMA_NAME(f.schema_id) + OBJECT_NAME(f.parent_object_id) + OBJECT_NAME(f.referenced_object_id)IN
      (SELECT SCHEMA_NAME(schema_id) + OBJECT_NAME(parent_object_id) + OBJECT_NAME(referenced_object_id)
       FROM sys.foreign_keys
       GROUP BY SCHEMA_NAME(schema_id) + OBJECT_NAME(parent_object_id) + OBJECT_NAME(referenced_object_id)
       HAVING COUNT(*) > 1)
	AND f.name NOT LIKE 'FK_' + dbo.fnSchemaName(SCHEMA_NAME(o.schema_id)) + '_' + OBJECT_NAME(f.parent_object_id) + '_'
                + dbo.fnSchemaName(SCHEMA_NAME(oo.schema_id)) + '_' + OBJECT_NAME(f.referenced_object_id)+'%'
  AND ( f.create_date >= @ChangeDatetime
     OR f.modify_date >= @ChangeDatetime)
--ORDER BY  SCHEMA_NAME(f.schema_id) + OBJECT_NAME(f.parent_object_id) + OBJECT_NAME(f.referenced_object_id)  
--======================================================================================================================================================
UNION
--======================================================================================================================================================
--== Correct Default Constraint Name ===================================================================================================================
--======================================================================================================================================================
SELECT 'Wrong Naming-Script'                                                                                           Problem
      ,'Default Constraint'                                                                                            [ObjectType]
      ,'EXEC SP_RENAME ''[' + SCHEMA_NAME(dc.schema_id) + '].' + dc.name + ''' , ''' + 'DF_'
       + dbo.fnSchemaName(SCHEMA_NAME(dc.schema_id)) + '_' + OBJECT_NAME(parent_object_id) + '(' + c.name + ')' + '''' UpdateScript
      ,dc.name                                                                                                         CurrentName
      ,'DF_' + dbo.fnSchemaName(SCHEMA_NAME(dc.schema_id)) + '_' + OBJECT_NAME(parent_object_id) + '(' + c.name + ')'  CorrectName
      ,CONCAT('[', SCHEMA_NAME(dc.schema_id), '].[' + OBJECT_NAME(dc.parent_object_id), ']')                           ObjectName
      ,dc.create_date
      ,dc.modify_date
FROM sys.default_constraints dc
INNER JOIN sys.columns       c ON c.object_id = parent_object_id
                              AND c.column_id = dc.parent_column_id
WHERE dc.name NOT LIKE 'DF_' + dbo.fnSchemaName(SCHEMA_NAME(dc.schema_id)) + '_' + OBJECT_NAME(parent_object_id) +
	'('+ c.name +'%'+ ')'
  AND ( dc.create_date >= @ChangeDatetime
     OR dc.modify_date >= @ChangeDatetime)
--======================================================================================================================================================
UNION
--======================================================================================================================================================
--== Correct Check Constraint Name ===================================================================================================================
--======================================================================================================================================================
SELECT 'Wrong Naming-Script'                                                                                           Problem
      ,'Check Constraint'                                                                                              [ObjectType]
      ,'EXEC SP_RENAME ''[' + SCHEMA_NAME(cc.schema_id) + '].' + cc.name + ''' , ''' + 'CK_'
       + dbo.fnSchemaName(SCHEMA_NAME(cc.schema_id)) + '_' + OBJECT_NAME(parent_object_id) + '(' + c.name + ')' + '''' UpdateScript
      ,cc.name                                                                                                         CurrentName
      ,'CK_' + dbo.fnSchemaName(SCHEMA_NAME(cc.schema_id)) + '_' + OBJECT_NAME(parent_object_id) + '(' + c.name + ')'  CorrectName
      ,CONCAT('[', SCHEMA_NAME(cc.schema_id), '].[' + OBJECT_NAME(parent_object_id), ']')                              ObjectName
      ,cc.create_date
      ,cc.modify_date
FROM sys.check_constraints cc
INNER JOIN sys.columns     c ON c.object_id = parent_object_id
                            AND c.column_id = cc.parent_column_id
WHERE cc.name NOT LIKE 'CK_' + dbo.fnSchemaName(SCHEMA_NAME(cc.schema_id)) + '_' + OBJECT_NAME(parent_object_id) + 
	'('+ c.name +'%' +')'
  AND ( cc.create_date >= @ChangeDatetime
     OR cc.modify_date >= @ChangeDatetime)
--======================================================================================================================================================
UNION
--==== نیست Id جداولی که نام کلید اصلی آنها =============================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                                                                Problem
      ,'Primary Key - Column'                                                                        [ObjectType]
      ,'Primary Key Name is not ''Id'' , if you cant change it, please add Decription for the column'
      ,c.name
      ,'Id'
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', OBJECT_NAME(i.object_id), ']')                     ObjectName
      ,t.create_date                                                                                 table_create_date
      ,t.modify_date                                                                                 table_modify_date
FROM sys.indexes             i
INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id
                               AND ic.index_id = i.index_id
INNER JOIN sys.syscolumns    c ON c.id = i.object_id
                              AND c.colid = ic.column_id
INNER JOIN sys.tables        t ON t.object_id = i.object_id
LEFT JOIN Column_Desc ON [Column_Desc].TableName=CONCAT('[', SCHEMA_NAME(schema_id), '].[', OBJECT_NAME(i.object_id), ']') 
		AND [Column_Desc].ColName=c.name
WHERE i.is_primary_key = 1
  AND Column_Desc.value IS NULL
  AND c.name <> 'id'
  AND ( t.create_date >= @ChangeDatetime
     OR t.modify_date >= @ChangeDatetime)
--======================================================================================================================================================
UNION
--==== اسکریپت اصلاح نام کلیدهای اصلی اشتباه ============================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming-Script'                                            Problem
      ,'Primary Key - Index'                                            [ObjectType]
      ,'EXEC sp_rename ''[' + SCHEMA_NAME(schema_id) + '].[' + i.name + ']'',''PK_'
       + dbo.fnSchemaName(SCHEMA_NAME(schema_id)) + '_' + t.name + '''' ScriptRename
      ,i.name                                                           'Current_PkName'
      ,'PK_' + dbo.fnSchemaName(SCHEMA_NAME(schema_id)) + '_' + t.name  'Correct_PkName'
      ,CONCAT('[', SCHEMA_NAME(t.schema_id), '].[', t.name, ']')        ObjectName
      ,t.create_date                                                    table_create_date
      ,t.modify_date                                                    table_modify_date
FROM sys.indexes      i
INNER JOIN sys.tables t ON t.object_id = i.object_id
WHERE i.is_primary_key = 1
  AND i.name NOT LIKE 'PK_' + dbo.fnSchemaName(SCHEMA_NAME(schema_id)) + '_' + t.name+'%'
  AND ( t.create_date >= @ChangeDatetime
     OR t.modify_date >= @ChangeDatetime)
--==========================================================================================================================================================
UNION
--== اسکریپت اصلاح نام ایندکس ها به غیر از کلید اصلی ===================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming-Script'                                     Problem
      ,'Index'
      ,'EXEC sp_rename ''[' + SCHEMA_NAME(schema_id) + '].[' + t.name + '].[' + i.name + ']'',''' + ic.CorrectIndexName
       + ''',N''index'''                                         ScriptRename
      ,i.name                                                    CurrentName
      ,ic.CorrectIndexName
      ,CONCAT('[', SCHEMA_NAME(t.schema_id), '].[', t.name, ']') ObjectName
      ,t.create_date                                             table_create_date
      ,t.modify_date                                             table_modify_date
FROM sys.indexes                        i
INNER JOIN sys.tables                   t ON t.object_id = i.object_id
INNER JOIN (SELECT i.object_id
                  ,i.index_id
                  ,CASE
                   WHEN i.has_filter = 1 THEN CASE WHEN i.is_unique = 1 THEN 'FUIX_' ELSE 'FIX_' END
                   ELSE CASE WHEN i.is_unique = 1 THEN 'UIX_' ELSE 'IX_' END
                   END + dbo.fnSchemaName(SCHEMA_NAME(schema_id)) + '_' + OBJECT_NAME(i.object_id) + '('
                   + STUFF((SELECT ',' + c.name + ''
                            FROM sys.index_columns ii
                            INNER JOIN sys.columns c ON c.column_id = ii.column_id
                                                    AND c.object_id = ii.object_id
                            WHERE ii.object_id = i.object_id
                              AND ii.index_id = i.index_id
                              AND ii.is_included_column = 0
                            ORDER BY ii.index_column_id
                           FOR XML PATH(''))
                          ,1
                          ,1
                          ,'') + ')' CorrectIndexName
            FROM sys.indexes      i
            INNER JOIN sys.tables t ON t.object_id = i.object_id
            WHERE i.type <> 0
              AND OBJECTPROPERTY(i.object_id, 'IsMSShipped') = 0
              AND i.is_primary_key = 0) ic ON ic.object_id = i.object_id
                                          AND ic.index_id = i.index_id
                                          AND ( t.create_date >= @ChangeDatetime
                                             OR t.modify_date >= @ChangeDatetime)
WHERE i.name NOT LIKE ic.CorrectIndexName +'%'
--==========================================================================================================================================================
UNION
--== ویوو با نامگذاری اشتباه ==============================================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                                   Problem
      ,'View'
      ,'the name of View can not consist "_" and should Start with "vw"'
      ,name                                                             CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']')            ObjectName
      ,create_date
      ,modify_date
FROM sys.views
WHERE ( name LIKE '%[_]%'
     OR name NOT LIKE 'vw%')
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)
--==========================================================================================================================================================
UNION
--== پراسیجر با نامگذاری اشتباه ==============================================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                                        Problem
      ,'Procedure'
      ,'the name of Procedure can not consist "_" and should Start with "Sp"'
      ,name                                                                  CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']')                 ObjectName
      ,create_date
      ,modify_date
FROM sys.procedures
WHERE ( name LIKE '%[_]%'
     OR name NOT LIKE 'sp%')
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)
UNION
--== فانکشن با نامگذاری اشتباه ==============================================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                                       Problem
      ,'Function'
      ,'the name of Function can not consist "_" and should Start with "Fn"'
      ,name                                                                 CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']')                ObjectName
      ,create_date
      ,modify_date
FROM sys.objects
WHERE type IN
     ('FN', 'IF', 'TF')
  AND ( name LIKE '%[_]%'
     OR name NOT LIKE 'Fn%')
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)

UNION
--== طولانی بودن نام =======================================================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                          Problem
      ,'LongLength'
      ,'the length of the name should lesser than 50 character'
      ,name                                                    CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']')   ObjectName
      ,create_date
      ,modify_date
FROM sys.objects
WHERE type IN
     ('FN', 'IF', 'TF', 'U', 'P')
  AND LEN(name) > 50
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)
UNION
--== استفاده از عدد در نام ===============================================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                        Problem
      ,'DigitInName'
      ,'do not use number in naming'
      ,name                                                  CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']') ObjectName
      ,create_date
      ,modify_date
FROM sys.objects
WHERE name LIKE '%[0-9]%'
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)
UNION
--== آبجکت هایی که اولین کاراکتر آنها حرف الفبا انگلیسی نیست ======================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                        Problem
      ,'FirstCharacter'
      ,'the first character of the name should be a to z'
      ,name                                                  CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']') ObjectName
      ,create_date
      ,modify_date
FROM sys.objects
WHERE LEFT(name, 1) NOT
BETWEEN 'A' AND 'Z'
  AND SCHEMA_NAME(schema_id) <> 'sys'
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)
UNION
--== وجود فاصله در نام آبجکت ======================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                        Problem
      ,'SpaceInNaming'
      ,'the name can not consist BlankSpace'
      ,name                                                  CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']') ObjectName
      ,create_date
      ,modify_date
FROM sys.objects
WHERE name LIKE '% %'
  AND SCHEMA_NAME(schema_id) <> 'sys'
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)
UNION
--== در نام جداول tbl وجود  ======================================================================================================
--===========================================================================================================================================================
SELECT 'Wrong Naming'                                        Problem
      ,'tableNaming'
      ,'the name can not consist tbl'
      ,name                                                  CurrentName
      ,''
      ,CONCAT('[', SCHEMA_NAME(schema_id), '].[', name, ']') ObjectName
      ,create_date
      ,modify_date
FROM sys.tables
WHERE ( name LIKE 'tbl%'
     OR name LIKE '%tbl')
  AND ( create_date >= @ChangeDatetime
     OR modify_date >= @ChangeDatetime)
ORDER BY Problem DESC
        ,ObjectType;
--== در پروسیجر Set Nocount عدم استفاده از   ======================================================================================================
--===========================================================================================================================================================
SELECT 'Nothing "SET NOCOUNT ON"'                            Problem
      ,'Procedure'                                           ObjectType
      ,'USE "SET NOCOUNT ON" in procudure body'              DescriptionOfProblem
      ,CONCAT('[', ROUTINE_SCHEMA, '].[', ROUTINE_NAME, ']') ObjectName
      ,CREATED                                               AS create_date
      ,LAST_ALTERED                                          AS modify_date
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_DEFINITION NOT LIKE '%nocount%'
  AND ( CREATED >= @ChangeDatetime
     OR LAST_ALTERED >= @ChangeDatetime)
ORDER BY modify_date;

--SELECT * 
--FROM INFORMATION_SCHEMA.ROUTINES 
--WHERE ROUTINE_NAME = 'SPGetLiveDecision'

--=== Objects without Description
--=============================================================================================================================================
SELECT 'No Description'                                                                       Problem
      ,CASE
       WHEN s.type = 'U' THEN 'Table'
       WHEN s.type = 'V' THEN 'View'
       WHEN s.type = 'P' THEN 'Procedure'
       WHEN s.type IN
          ('FN', 'TF', 'IF') THEN 'Function'
       WHEN s.type = 'SO' THEN 'Sequence'
       END                                                                                    ObjectType
      ,'the Objects (Tables, Procedures, Views, Functions, Sequence) should have Description' AS DescriptionOfProblem
      ,CONCAT('[' + SCHEMA_NAME(s.schema_id), '].[', s.name, ']')                             ObjectName
      ,s.create_date
      ,s.modify_date
FROM sys.extended_properties e
RIGHT JOIN sys.objects       s ON s.object_id = e.major_id
                              AND (e.name LIKE '%Desc%')
                              AND e.minor_id = 0
WHERE s.type IN
     ('U', 'FN', 'TF', 'IF', 'p', 'V', 'SO')
  AND e.major_id IS NULL
  AND s.name NOT LIKE '%diagram%'
  AND s.name <> 'fnSchemaName'
  AND s.create_date >= @ChangeDatetime
UNION
--=== Tinyint Columns without Description
--=============================================================================================================================================
SELECT 'No Description'                                                   Problem
      ,'Column'                                                           ObjectType
      ,'the Columns with TINYINT datatype should have Description'        AS DescriptionOfProblem
      ,CONCAT('[', SCHEMA_NAME(t.schema_id), '].[', t.name, '].', c.name) ObjectName
      ,t.create_date
      ,t.modify_date
FROM sys.columns                       c
INNER JOIN sys.types                   ty ON ty.system_type_id = c.system_type_id
INNER JOIN sys.tables                  t ON t.object_id = c.object_id
LEFT JOIN sys.extended_properties      ep ON ep.major_id = c.object_id
                                         AND ep.minor_id = c.column_id
LEFT JOIN sys.foreign_key_columns      f ON f.parent_object_id = c.object_id
                                        AND f.parent_column_id = c.column_id
LEFT JOIN (SELECT DISTINCT ic.object_id
                          ,ic.column_id
           FROM sys.indexes             i
           INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id
                                          AND ic.index_id = i.index_id
           WHERE i.is_primary_key = 1) i ON i.object_id = c.object_id
                                        AND i.column_id = c.column_id
WHERE ty.name = 'tinyint'
  AND ep.minor_id IS NULL
  AND f.constraint_column_id IS NULL
  AND i.object_id IS NULL
  AND ( t.create_date >= @ChangeDatetime
     OR t.modify_date >= @ChangeDatetime)
ORDER BY modify_date DESC
        ,DescriptionOfProblem DESC
        ,ObjectName;

--=== Inappropriate Column Datatype
--=============================================================================================================================================
SELECT 'Wrong Datatype'                                                    AS Problem
      ,CONCAT('[', SCHEMA_NAME(t.schema_id), '].[', t.name, ']')           TableName
      ,c.name                                                              ColumnName
      ,CASE WHEN ty.name = 'decimal' THEN 'decimal(18,0)' ELSE ty.name END CurrentDatatype
      ,CASE
       WHEN ty.name = 'decimal' THEN 'bigint'
       WHEN ty.name = 'datetime' THEN 'datetime2(3)'
       WHEN ty.name = 'text' THEN 'varchar(max)'
       WHEN ty.name = 'ntext' THEN 'nvarchar(max)'
       WHEN ty.name = 'image' THEN 'varbinary(max)'
       END                                                                 AS CorrectDatatype
FROM sys.tables        t
INNER JOIN sys.columns c ON c.object_id = t.object_id
LEFT JOIN sys.types    ty ON c.user_type_id = ty.user_type_id -- WHERE t.object_id = OBJECT_ID('[bof.tse].Trade')
WHERE ( ty.name IN
     ('text', 'ntext', 'image', 'datetime')
     OR ( ty.name = 'decimal'
      AND c.precision = 18
      AND c.scale = 0
      AND c.system_type_id = 106))
  AND ( t.create_date >= @ChangeDatetime
     OR t.modify_date >= @ChangeDatetime)
ORDER BY ty.name;

--=== Tables On Primary FileGroup
--=============================================================================================================================================
IF (SELECT TOP 1 name
    FROM sys.filegroups
    WHERE is_default = 1) <> 'Primary'
BEGIN
    SELECT 'Wrong File Group'                                        AS Problem
          ,fg.name                                                   FileGroup
          ,'No tables should be on the Primary File Group'           AS DescriptionOfProblem
          ,CONCAT('[', SCHEMA_NAME(t.schema_id), '].[', t.name, ']') TableName
          ,i.name                                                    IndexName
          ,i.type_desc
          ,t.create_date
          ,t.modify_date
    FROM sys.indexes                     i
    INNER JOIN sys.tables                t ON t.object_id = i.object_id
    INNER JOIN sys.schemas               s ON s.schema_id = t.schema_id
    INNER JOIN sys.filegroups            fg ON fg.data_space_id = i.data_space_id
    INNER JOIN sys.dm_db_partition_stats p ON p.object_id = i.object_id
                                          AND p.index_id = i.index_id
    WHERE fg.name = 'Primary'
      AND ( t.create_date >= @ChangeDatetime
         OR t.modify_date >= @ChangeDatetime)
    ORDER BY p.used_page_count DESC
            ,i.object_id
            ,i.index_id;
END;


--== حذف فانکشن ===========================================================================================================================================
--===========================================================================================================================================================
GO

DROP FUNCTION [dbo].[fnSchemaName];