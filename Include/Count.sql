SET NOCOUNT ON
select  COUNT(*) from sys.databases
	WHERE name NOT IN ('model','tempdb')
