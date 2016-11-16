#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=ICONS\gnome_ftp.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Fileversion=1.0.0.9
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <SFTPEx.au3>
#include <InetConstants.au3>

FileInstall("C:\Includes\psftp.exe", @TempDir & "\psftp.exe", 1)
OnAutoItExitRegister("_Exit")

$ver = "1.2.0"

if not FileExists(@TempDir & "\psftp.exe") Then
	msgbox(16, "Error", "Files did not extract")
	Exit
EndIf

TraySetToolTip("FTP Watch v" & $ver & @CRLF & "Starting up...")
Global $ftp, $conn, $aFiles, $savePath, $remotePath, $address, $username, $password, $port

; ### CONFIG ###
$savePath = "\\fileserver\saved_docs\"
$remotePath = "/files/"
$address = '127.0.0.1'
$username = 'ftp_user'
$password = 'ftp_pass'
$port = 22
$logging = True
; ### ### ### ###

TraySetToolTip("FTP Watch v" & $ver & @CRLF & "Running: Connecting...")

ConsoleWrite("Connecting..." & @CRLF)
$ftp = _SFTP_Open(@TempDir & "\psftp.exe")

$conn = _SFTP_Connect($ftp, $address, $username, $password, $port)
_SFTP_DirSetCurrent($conn, $remotePath)

while 1
	TraySetToolTip("FTP Watch v" & $ver & @CRLF & "Running: Getting File List")
	ConsoleWrite("Getting File List..." & @CRLF)

	$aFiles = _SFTP_ListToArray($conn, "", 2)

	for $i = 1 to $aFiles[0]
		TraySetToolTip("FTP Watch v" & $ver & @CRLF & "Running: Downloading Files" & @CRLF & $i & " / " & $aFiles[0])
		ConsoleWrite("Downloading: [" & $i & "] " & $aFiles[$i] & @CRLF)
		$size = _SFTP_FileGetSize($conn, $aFiles[$i])
		sleep(1500)
		$sizeAfter = _SFTP_FileGetSize($conn, $aFiles[$i])
		if $size = $sizeAfter Then
			ConsoleWrite($i & ': ' & $aFiles[$i] & " (" & round($size/1024,2) & "kb)" & @CRLF)
			if $size > 10 Then ; If a valid file
				if FileExists($savePath & $aFiles[$i]) Then
					if FileGetSize($savePath & $aFiles[$i]) < 5 Then FileMove($savePath & $aFiles[$i], $savePath & $aFiles[$i] & "x", 0)
				EndIf
				ConsoleWrite("Starting Download...")
				_SFTP_FileGet($conn, $aFiles[$i], $savePath & $aFiles[$i])
				ConsoleWrite("Finished!" & @CRLF)

				if FileExists($savePath & $aFiles[$i]) and FileGetSize($savePath & $aFiles[$i]) > 5 Then
					_SFTP_FileDelete($conn, $aFiles[$i])
					if $logging Then
						$file = FileOpen(@ScriptDir & "\sftp_log.txt", 1)
						FileWrite($file, @MON & "/" & @MDAY & "/" & @YEAR & " " & @HOUR & ":" & @MIN & " Success: " & $aFiles[$i] & @CRLF)
						FileClose($file)
					EndIf
				Else
					if $logging Then
						$file = FileOpen(@ScriptDir & "\sftp_log.txt", 1)
						FileWrite($file, @MON & "/" & @MDAY & "/" & @YEAR & " " & @HOUR & ":" & @MIN & " FAILED: " & $aFiles[$i] & @CRLF)
						FileClose($file)
					EndIf
				EndIf
				if not @error then ConsoleWrite("Deleted!" & @CRLF)
			EndIf
		EndIf
		sleep(1500)
		ConsoleWrite("Next!" & @CRLF)
	Next
	TraySetToolTip("FTP Watch v" & $ver & @CRLF & "Sleeping")
	ConsoleWrite("Sleeping" & @CRLF)
	sleep(600000) ; 10 minutes
WEnd

Func _Exit()
	_SFTP_Close($ftp)
	msgbox(64, "FTP Watch", "Connection Closed")
	Exit
EndFunc