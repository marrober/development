#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_remove_cr.pl
#------ Authors Name : Mark Roberts
#------ Date         : 23 June, 1997.
#------ Description  : This script runs as a checkin trigger on any file. If the
#                      filename extension is .c or.h then the file passed as an
#                      argument to the program strip_cr.exe stored in
#                      \\eng-ntserver-6\atria\bin\extra. The arguments to the
#                      program are the name of the file to be converted and the
#                      name of a temporary file to hold the converted file.
#
# Variable declaration.
#
$FileForConversionFile = $ENV{'CLEARCASE_PN'};
#
#
$ReversedName = reverse($FileForConversionFile);
#
split(/\./, $ReversedName);
$Extension = reverse(@_[0]);
#
$_ = $FileForConversionFile;
#
if (((m/[.]h/) && (length($Extension) == 1)) || ((m/[.]c/) && (length($Extension) == 1)) || ((m/[.]dfn/) && (length($Extension) == 3)))
{
#
#       The file is to be converted.
#
#       Generate the name of the temp file.
#
    $TempFileName = $FileForConversionFile."\$\$";
#
#       Generate the conversion command line.
#
    $ConversionCommand = "\\\\eng-ntserver-6\\atria\\bin\\extra\\strip_cr.exe ".$FileForConversionFile." ".$TempFileName;
#
#       Execute the conversion command.
#
   `$ConversionCommand`;
#
#       Check the return value of the function - only allow the checkin operation
#       if the return value from strip_cr.exe was 0.
#
    if ($` == 0)
    {
#
#           Before closing the trigger script the file must be overwritten with its
#           converted version.
#
#           Check the existence of the converted file.
#
        if (-e $TempFileName)
        {
#
#               The file exists so the conversion can continue.
#               Delete the original file.
#
            $DeleteCommand = "del ".$FileForConversionFile;
#
#               Execute the delete command.
#
            `$DeleteCommand`;
#
#               Copy the converted file to the place of the original file.
#
            $CopyCommand = "copy ".$TempFileName." ".$FileForConversionFile;
#
#               Execute the copy command.
#
            `$CopyCommand`;
#
#               Remove the rad-only attribute from the temp file and delete it.
#
            $RemoveAttributeCommand = "attrib -r ".$TempFileName;
            $DeleteTempFileCommand = "del ".$TempFileName;
#
#               Execute the remove attribute and delete commands.
#
            `$RemoveAttributeCommand`;
            `$DeleteTempFileCommand`;
#
#               Close the trigger with an exit code of 0 to allow the checkin to
#               proceed.
#
            exit(0);
        }
        else
        {
#
#               An error has occured and the temp file has not been generated.
#
            exit(1);
        }
    }
    else
    {
#
#           A non zero exit code will cause the checkin operation to fail.
        exit(1);
    }
}
