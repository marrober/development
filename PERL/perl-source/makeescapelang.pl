#
#********************************************************************************
#** Module        : makeescapelang.pl
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
#  This PERL script converts all real characters outside the asCII range into
#  escape chaarcters.
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
print "This script will convert the ASCII characters to escape sequences where\n";
print "required.\n";

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
        $FileLineBuffer =~ s/\xDF/\\d143/g;
        $FileLineBuffer =~ s/\xC0/\\d127/g;
        $FileLineBuffer =~ s/\xC1/\\d128/g;
        $FileLineBuffer =~ s/\xC4/\\d129/g;
        $FileLineBuffer =~ s/\xC7/\\d130/g;
        $FileLineBuffer =~ s/\xC8/\\d131/g;
        $FileLineBuffer =~ s/\xC9/\\d132/g;
        $FileLineBuffer =~ s/\xCA/\\d133/g;
        $FileLineBuffer =~ s/\xCB/\\d134/g;
        $FileLineBuffer =~ s/\xCE/\\d135/g;
        $FileLineBuffer =~ s/\xCF/\\d136/g;
        $FileLineBuffer =~ s/\xD1/\\d137/g;
        $FileLineBuffer =~ s/\xD4/\\d138/g;
        $FileLineBuffer =~ s/\xD6/\\d139/g;
        $FileLineBuffer =~ s/\xD9/\\d140/g;
        $FileLineBuffer =~ s/\xDB/\\d141/g;
        $FileLineBuffer =~ s/\xDC/\\d142/g;
        $FileLineBuffer =~ s/\xDF/\\d143/g;
        $FileLineBuffer =~ s/\xE0/\\d144/g;
        $FileLineBuffer =~ s/\xE1/\\d145/g;
        $FileLineBuffer =~ s/\xE4/\\d146/g;
        $FileLineBuffer =~ s/\xE7/\\d147/g;
        $FileLineBuffer =~ s/\xE8/\\d148/g;
        $FileLineBuffer =~ s/\xE9/\\d149/g;
        $FileLineBuffer =~ s/\xEA/\\d150/g;
        $FileLineBuffer =~ s/\xEB/\\d151/g;
        $FileLineBuffer =~ s/\xEE/\\d152/g;
        $FileLineBuffer =~ s/\xEF/\\d153/g;
        $FileLineBuffer =~ s/\xF1/\\d154/g;
        $FileLineBuffer =~ s/\xF4/\\d155/g;
        $FileLineBuffer =~ s/\xF6/\\d156/g;
        $FileLineBuffer =~ s/\xF9/\\d157/g;
        $FileLineBuffer =~ s/\xFB/\\d158/g;
        $FileLineBuffer =~ s/\xFC/\\d159/g;
        $FileLineBuffer =~ s/\xCD/\\d160/g;
        $FileLineBuffer =~ s/\xD3/\\d161/g;
        $FileLineBuffer =~ s/\xED/\\d162/g;
        $FileLineBuffer =~ s/\xF3/\\d163/g;

 		print OUTPUTFILE $FileLineBuffer."\n";
	 	$FileLineBuffer = "";
    }
}

close OUTPUTFILE;
close FILEHANDLE;

exit(0);

