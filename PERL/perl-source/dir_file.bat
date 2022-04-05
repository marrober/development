@echo off
Rem ------------------------------------------------------------------------------
REM ------ BATCH FILE   : dir_file.bat
REM ------ Authors Name : Mark Roberts
REM ------ Date         : 21 February, 1997.
REM ------ Description  : This batch file is to overcome the problem that the 
REM                       Visual Basic 'dir' function will not list read-only files.
REM                       This batch file will list all files.
dir %1\*.* /b /A-D > %2
