--DSProdSSIS01
USE SSISDB
Go

DECLARE @Prj VARCHAR(50), @Version INT, @Folder VARCHAR(50) ;

SET @Prj='ConformingDimensions'


SELECT	DISTINCT @Folder =f.name
FROM	 	catalog.projects as p
INNER JOIN	catalog.folders as f
ON f.folder_id = p.folder_id
WHERE P.name = @Prj


/*
--Following code can be used to know the versions and particular version (object_version_lsn) could be used to restore project to that version.

select o.object_version_lsn, * 
from catalog.object_versions o (nolock)
inner JOin catalog.projects p (NOLOCK)
ON o.object_id=p.project_id
inner join catalog.folders f (NOLOCK)
ON p.folder_id=f.folder_id
where object_name=@Prj
order by o.created_time desc

*/
	
SELECT  @Version =  a.object_version_lsn 
FROM
(
	SELECT o.object_version_lsn ,
			rowid = ROW_NUMBER() OVER (ORDER BY o.created_time desc)
	FROM catalog.object_versions o (nolock)
	inner JOin catalog.projects p (NOLOCK)
	ON o.object_id=p.project_id
	inner join catalog.folders f (NOLOCK)
	ON p.folder_id=f.folder_id
	where object_name=@Prj
) a
WHERE a.rowid =2 


EXEC catalog.restore_project 
		@folder_name = @Folder
    ,	@project_name = @Prj
    ,	@object_version_lsn = @Version

DECLARE @Prj VARCHAR(50), @Version INT, @Folder VARCHAR(50) ;

SET @Prj='EDMHMFWeeklyLoad'


SELECT	DISTINCT @Folder =f.name
FROM	 	catalog.projects as p
INNER JOIN	catalog.folders as f
ON f.folder_id = p.folder_id
WHERE P.name = @Prj


/*
--Following code can be used to know the versions and particular version (object_version_lsn) could be used to restore project to that version.

select o.object_version_lsn, * 
from catalog.object_versions o (nolock)
inner JOin catalog.projects p (NOLOCK)
ON o.object_id=p.project_id
inner join catalog.folders f (NOLOCK)
ON p.folder_id=f.folder_id
where object_name=@Prj
order by o.created_time desc

*/
	
SELECT  @Version =  a.object_version_lsn 
FROM
(
	SELECT o.object_version_lsn ,
			rowid = ROW_NUMBER() OVER (ORDER BY o.created_time desc)
	FROM catalog.object_versions o (nolock)
	inner JOin catalog.projects p (NOLOCK)
	ON o.object_id=p.project_id
	inner join catalog.folders f (NOLOCK)
	ON p.folder_id=f.folder_id
	where object_name=@Prj
) a
WHERE a.rowid =2 


EXEC catalog.restore_project 
		@folder_name = @Folder
    ,	@project_name = @Prj
    ,	@object_version_lsn = @Version

