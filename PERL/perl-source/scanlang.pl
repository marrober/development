#
#********************************************************************************
#** Module        : scanlang.pl
#** Originator    : Mark Roberts
#** Creation Date : 9th December, 1998
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
#  This PERL script is used to scan the language definition files for any
#  character outside the range 32 to 126 (decimal).
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
print "This script will report any language string where the English and any\n";
print "other language match. This indicates language strings that have not yet\n";
print "been translated. It also gives the line number and position of any character\n";
print "that is not in the standard ASCII character range of 30 to 126.\n";
print "Characters outside the range in the language text definition files should\n";
print "be replaced with an appropriate \dxxx specifier where xxx is the\n";
print "COURIER character code.\n\n\n";

$FileToCheck = $ARGV[0];

$FileToCheck =~ s|/D=||;
$Invalid = 0;
$InString = 0;
$OverLength = 0;

push @LanguageNames, "French";
push @LanguageNames, "German";
push @LanguageNames, "Spanish";

$LineCounter = 1;

open FILEHANDLE, $FileToCheck;

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

        $LineCounter++;
        $CharacterCounter = 0;
    }
    elsif (ord($DataFromFile) == 10)
    {
        # New line character.

        $LineCounter++;
        $CharacterCounter = 0;
    }
    else
    {
        $CharacterCounter++;

        if((ord($DataFromFile) < 32) | (ord($DataFromFile) > 126))
        {
            print "[Invalid character] Line : ".$LineCounter." character ".$CharacterCounter."\n";
            $Invalid = 1;
        }
        if (($InString == 1) && (ord($DataFromFile) != 34))
        {
            # A character to be counted.

            $StringToCheck = $StringToCheck.$DataFromFile;
        }

        if(ord($DataFromFile) == 34)
        {
            if ($InString == 0)
            {
                # The start of a string to check.
                $InString = 1;
            }
            else
            {
                $InString = 0;
                #
                # Check the collected string.
                $StringHoldingCopy = $StringToCheck;
                $StringToCheck =~ s/\\d.../D/g;
                $StringToCheck =~ s/\\x../X/g;
                if (length($StringToCheck) > 16)
                {
                    $OverLength = 1;
                    print "[Overlength String] Line : ".$LineCounter." ".$StringHoldingCopy." : ".length($StringToCheck)." characters long\n";
                }
                $StringToCheck = "";
            }
        }
    }
    if ((ord($DataFromFile) == 13) || (ord($DataFromFile) == 10))
    {
        # There is now a line to be processed.

        @SplitLine = split(/\,/, $FileLineBuffer);

        if ($#SplitLine >= 5)
        {
            $_ = $SplitLine[1];

            $_ =~ s/ *//;
            $_ =~ s/\"//g;

            for ($LanguageIncrement = 2; $LanguageIncrement <= 4;$LanguageIncrement++)
            {
                $SplitLine[$LanguageIncrement] =~ s/ *//;
                $SplitLine[$LanguageIncrement] =~ s/\"//g;

                if (m/$SplitLine[$LanguageIncrement]/)
                {
                    # Match.

                    print "[String Match     ] Line : ".$LineCounter." English & ".$LanguageNames[$LanguageIncrement - 2]."  \t".$_."\n";
                }
            }
        }
        $FileLineBuffer = "";
    }
}

close FILEHANDLE;

if ($Invalid == 0)
{
    print "No invalid characters found in the file.\n";
}
if ($OverLength == 0)
{
    print "No overlength strings found in the file.\n";
}

exit(0);

