#
#********************************************************************************
#** Module        : makereallang.pl
#** Originator    : Mark Roberts
#** Creation Date : 8th January, 1999
#**
#** Code Review Reference : <the code review form number>
#**
#** (c) 1998 ALSTOM T&D P&C Ltd.
#** (c) 1998 ALSTOM T&D P&C SA.
#********************************************************************************
#

#------------------------------------------------------------------------------
#  DOCUMENTATION
#
#  This PERL script converts all escape sequences to real characters to give a
#  correct representation of the strings.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  INCLUDE FILES
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  CONSTANTS
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
#  SCRIPT CODE
#------------------------------------------------------------------------------

# Print header information.
#
print "This script will conver the escape sequences to ASCII representations\n";
print "of the characters to give a true picture of what the strings look like.\n";
print "NOTE : The output of this script should not be used as the source for\n";
print "the production of files to be downloaded to a product.\n";

$FileToConvert = $ARGV[0];
$OutputFile = $ARGV[1];

$_ = $ARGV[0];

if (m|\/\?|)
{
    print "Arguments to the script are : \n";
    print "\t\t /D=<input file name>\n";
    print "\t\t /O=<output file name>\n";
}

$FileToConvert =~ s|/D=||;
$OutputFile =~ s|/O=|>|;

open FILEHANDLE, $FileToConvert;
open OUTPUTFILE, $OutputFile;

while (eof(FILEHANDLE) == 0)
{
    read FILEHANDLE, $DataFromFile, 1;

    if ((ord($DataFromFile) != 13) && (ord($DataFromFile) != 10))
    {
        $FileLineBuffer = $FileLineBuffer.$DataFromFile;
    }
    if (ord($DataFromFile) == 13)
    {
        # New line character.

        read FILEHANDLE, $DataFromFile, 1;
    }
    if ((ord($DataFromFile) == 13) || (ord($DataFromFile) == 10))
    {
        $FileLineBuffer =~ s/\\d143/\xDF/g;
        $FileLineBuffer =~ s/\\d127/\xC0/g;
        $FileLineBuffer =~ s/\\d128/\xC1/g;
        $FileLineBuffer =~ s/\\d129/\xC4/g;
        $FileLineBuffer =~ s/\\d130/\xC7/g;
        $FileLineBuffer =~ s/\\d131/\xC8/g;
        $FileLineBuffer =~ s/\\d132/\xC9/g;
        $FileLineBuffer =~ s/\\d133/\xCA/g;
        $FileLineBuffer =~ s/\\d134/\xCB/g;
        $FileLineBuffer =~ s/\\d135/\xCE/g;
        $FileLineBuffer =~ s/\\d136/\xCF/g;
        $FileLineBuffer =~ s/\\d137/\xD1/g;
        $FileLineBuffer =~ s/\\d138/\xD4/g;
        $FileLineBuffer =~ s/\\d139/\xD6/g;
        $FileLineBuffer =~ s/\\d140/\xD9/g;
        $FileLineBuffer =~ s/\\d141/\xDB/g;
        $FileLineBuffer =~ s/\\d142/\xDC/g;
        $FileLineBuffer =~ s/\\d143/\xDF/g;
        $FileLineBuffer =~ s/\\d144/\xE0/g;
        $FileLineBuffer =~ s/\\d145/\xE1/g;
        $FileLineBuffer =~ s/\\d146/\xE4/g;
        $FileLineBuffer =~ s/\\d147/\xE7/g;
        $FileLineBuffer =~ s/\\d148/\xE8/g;
        $FileLineBuffer =~ s/\\d149/\xE9/g;
        $FileLineBuffer =~ s/\\d150/\xEA/g;
        $FileLineBuffer =~ s/\\d151/\xEB/g;
        $FileLineBuffer =~ s/\\d152/\xEE/g;
        $FileLineBuffer =~ s/\\d153/\xEF/g;
        $FileLineBuffer =~ s/\\d154/\xF1/g;
        $FileLineBuffer =~ s/\\d155/\xF4/g;
        $FileLineBuffer =~ s/\\d156/\xF6/g;
        $FileLineBuffer =~ s/\\d157/\xF9/g;
        $FileLineBuffer =~ s/\\d158/\xFB/g;
        $FileLineBuffer =~ s/\\d159/\xFC/g;
        $FileLineBuffer =~ s/\\d160/\xCD/g;
        $FileLineBuffer =~ s/\\d161/\xD3/g;
        $FileLineBuffer =~ s/\\d162/\xED/g;
        $FileLineBuffer =~ s/\\d163/\xF3/g;

 		print OUTPUTFILE $FileLineBuffer."\n";
	 	$FileLineBuffer = "";
    }
}

close OUTPUTFILE;
close FILEHANDLE;

exit(0);

