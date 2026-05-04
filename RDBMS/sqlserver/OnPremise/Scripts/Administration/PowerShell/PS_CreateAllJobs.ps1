# Date: 2014-09-01
# Description:	PS script to generate all SQL Server Agent jobs on the given instance. The script accepts an input file of server names.
# Example Execution: .\Create_SQLAgentJobSripts.ps1 .\ServerNameList.txt

param([String]$ServerListPath)

#Load the input file into an Object array
$ServerNameList = get-content -path $ServerListPath

#Load the SQL Server SMO Assembly
#SMO = SQL Manager Object
#http://msdn.microsoft.com/en-us/library/ms162233.aspx
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

#Create a new SqlConnection object
$objSQLConnection = New-Object System.Data.SqlClient.SqlConnection

#For each server in the array do the following..
foreach($ServerName in $ServerNameList)
{
	Try
	{
		$objSQLConnection.ConnectionString = "Server=$ServerName;Integrated Security=SSPI;"
    		Write-Host "Trying to connect to SQL Server instance on $ServerName..." -NoNewline
    		$objSQLConnection.Open() | Out-Null
    		Write-Host "Success."
		$objSQLConnection.Close()
	}
	Catch
	{
		Write-Host -BackgroundColor Red -ForegroundColor White "Fail"
		$errText =  $Error[0].ToString()
    		if ($errText.Contains("network-related"))
		{Write-Host "Connection Error. Check server name, port, firewall."}

		Write-Host $errText
		continue
	}

	Write-Host "Starting to Create Jobs Script.....please wait!!"
	
	#IF the output folder does not exist then create it
	$OutputFolder = ".\$ServerName"
	$DoesFolderExist = Test-Path $OutputFolder
	$null = if (!$DoesFolderExist){MKDIR "$OutputFolder"}

	#Create a new SMO instance for this $ServerName
	$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $ServerName

	#Script out each SQL Server Agent Job for the server
	$srv.JobServer.Jobs | foreach {$_.Script() + "GO`r`n"} | out-file ".\$OutputFolder\jobs.sql"

	#Use the command below to output each SQL Agent Job to a separate file. Remember to comment out the line above.
        #Removed backslash character, typically seen in Replication Agent jobs, to avoid invalid filepath issue
	#$srv.JobServer.Jobs | foreach-object -process {out-file -filepath $(".\$OutputFolder\" + $($_.Name -replace '\\', '') + ".sql") -inputobject $_.Script() }
	
	Write-Host "The script was successfully created on $OutputFolder\jobs.sql" 
	Write-Host "Finishing to Create Jobs Script"
	Sleep -s 10
}