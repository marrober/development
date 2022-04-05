#
#********************************************************************************
#** Module        : langsplit.pl
#** Originator    : Mark Roberts
#** Creation Date : 7th April, 1998
#**
#** Code Review Reference : <the code review form number>
#**
#** (c) 1998 GEC ALSTHOM T&D P&C Ltd.
#** (c) 1998 GEC ALSTHOM T&D P&C SA.
#********************************************************************************
#

#------------------------------------------------------------------------------
#  DOCUMENTATION
#
#  This PERL script is used to convert language text definition files into
#  string tables. See the document /50300PL/doc/dbapp/dblayout.doc  for
#  more information.
#
#  ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  INCLUDE FILES
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  CONSTANTS
#-------------------------------------------------------------------------------
$Title = "LANGSPLIT PERL SCRIPT\n";
$HelpText = $Title." Command line argument information :\n".
                   "  /D=Definition file (.dfn) There may be any number of definition files.\n".
$BSlash = chr(92);
#-------------------------------------------------------------------------------
#  PUBLIC VARIABLES
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  SUBROUTINES
#-------------------------------------------------------------------------------
    sub ReadDefinitionFile;
	sub ProcessText;
#-------------------------------------------------------------------------------
#  Main function
#-------------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # Get the temp environment variable.
    #---------------------------------------------------------------------------

    $LanguagesToProcess = 4;

    $EnvTemp = $ENV{'TEMP'};

    if (length($EnvTemp) == 0)
    {
        $EnvTemp = $ENV{'temp'};
    }
    if (length($EnvTemp) == 0)
    {
        $EnvTemp = $ENV{'TMP'};
    }
    if (length($EnvTemp) == 0)
    {
        $EnvTemp = $ENV{'tmp'};
    }
    if (length($EnvTemp) == 0)
    {
        if (($ENV{'PERL_TRACE'} cmp "1") == 0) { print "section 002\n"; }

        print "\n\n ERROR : Could not find one of the following environment variables\n";
        print "        temp, TEMP, tmp, TMP\n";
        exit(0);
    }

    #---------------------------------------------------------------------------
    # Process command line arguments.
    #---------------------------------------------------------------------------

    for($Counter = 0; $Counter <= $#ARGV; $Counter++)
    {
        $_ = $ARGV[$Counter];

        if (m|/D|)
        {
            ReadDefinitionFile($ARGV[$Counter]);

            $FileName = $ARGV[$Counter];

            $FileName =~ s|/D=||;
        }
        elsif (m|/?|)
        {
            # Display help
            print $HelpText;

        }
        else
        {
            print "ARGUMENT ERROR \n";
        }
    }

    #---------------------------------------------------------------------------
    # Split the definition data into individual lines.
    #---------------------------------------------------------------------------

    @SplitRes = split /\n/, $DefinitionData;

    # For each line split into the components.

    @SplitLines = @SplitRes;

    foreach $SingleLine (@SplitLines)
    {
        $_ = $SingleLine;

        if (m/^#/)
        {
            # Comment line to ignore.
        }
        elsif (m/\/\//)
        {
            # Comment line to ignore.
        }
        else
        {
            # Remove spaces except those in the string text.

            $QuoteFound = 0;

            @SplitRes = split //, $SingleLine;

            $SpaceFreeLine = "";

            if (@SplitRes > 0)
            {
                foreach $char (@SplitRes)
                {
                    $_ = $char;

                    if (m/ /)
                    {
                        if ($QuoteFound == 1)
                        {
                            $SpaceFreeLine = $SpaceFreeLine.$char;
                        }
                    }
                    elsif (m/\"/)
                    {
                        $SpaceFreeLine = $SpaceFreeLine.$char;
                        if ($QuoteFound == 1)
                        {
                            $QuoteFound = 0;
                        }
                        else
                        {
                            $QuoteFound = 1;
                        }
                    }
                    else
                    {
                        $SpaceFreeLine = $SpaceFreeLine.$char;
                    }
                    $Counter++;
                }

                @SplitRes = split /,/, $SpaceFreeLine;

                push @DefineList, $SplitRes[0];

                if (length($SplitRes[0]) > $MaxDefineLength)
                {
                    $MaxDefineLength = length($SplitRes[0]);

                }

                for ($LanguageCounter = 0; $LanguageCounter < 4; $LanguageCounter++)
                {
                    if ($LanguageCounter == 0)
                    {
                        push @LanguageOneList, $SplitRes[1 + $LanguageCounter];
                    }
                    if ($LanguageCounter == 1)
                    {
                        if ($LanguagesToProcess > 1)
                        {
                            push @LanguageTwoList, $SplitRes[1 + $LanguageCounter];
                        }
                     	else
                        {
                     		push @LanguageTwoList, $SplitRes[1];
	                  	}
                    }
                    elsif ($LanguageCounter == 2)
                    {
                        if ($LanguagesToProcess > 2)
                        {
                            push @LanguageThreeList, $SplitRes[1 + $LanguageCounter];
                        }
                     	else
                        {
                     		push @LanguageThreeList, $SplitRes[1];
	                    }                    }
                    if ($LanguageCounter == 3)
                    {
                        if ($LanguagesToProcess > 3)
                        {
                            push @LanguageFourList, $SplitRes[1 + $LanguageCounter];
                        }
                     	else
                        {
                     		push @LanguageFourList, $SplitRes[1];
                        }
	              	}
                }

                push @StringTableNameList, $SplitRes[1 + $LanguagesToProcess];

                if (length($SplitRes[1 + $LanguagesToProcess]) > $MaxStringTableNameLength)
                {
                    $MaxStringTableNameLength = length($SplitRes[1 + $LanguagesToProcess]);
                }
            }
        }
    }

    #---------------------------------------------------------------------------
    # Get the longest item in each list.
    #---------------------------------------------------------------------------

    $LanguageOneListMax = 0;

    foreach $Lang (@LanguageOneList)
    {
        if (length($Lang) > $LanguageOneListMax)
        {
            $LanguageOneListMax = length($Lang);
        }
    }

    $LanguageTwoListMax = 0;

    foreach $Lang (@LanguageTwoList)
    {
        if (length($Lang) > $LanguageTwoListMax)
        {
            $LanguageTwoListMax = length($Lang);
        }
    }

    $LanguageThreeListMax = 0;

    foreach $Lang (@LanguageThreeList)
    {
        if (length($Lang) > $LanguageThreeListMax)
        {
            $LanguageThreeListMax = length($Lang);
        }
    }


    $LanguageFourListMax = 0;

    foreach $Lang (@LanguageFourList)
    {
        if (length($Lang) > $LanguageFourListMax)
        {
            $LanguageFourListMax = length($Lang);
        }
    }

    #---------------------------------------------------------------------------
    # Create a new temp file of the formatted text.
    #---------------------------------------------------------------------------

    $TempFile = ">".$EnvTemp."\\"."formatdef.temp";

    open OutputFile, $TempFile;

    ReadDefinitionFile($ARGV[$Counter]);

    @SplitRes = split /\n/, $DefinitionData;

    # For each line split into the components.

    @SplitLines = @SplitRes;

    foreach $SingleLine (@SplitLines)
    {
        $_ = $SingleLine;

        if (m/^#/)
        {
            print OutputFile $SingleLine."\n";
        }
        elsif (m/\/\//)
        {
            print OutputFile $SingleLine."\n";
        }
        else
        {
            # Remove spaces except those in the string text.

            $QuoteFound = 0;

            @SplitRes = split //, $SingleLine;

            $SpaceFreeLine = "";

            if (@SplitRes > 0)
            {
                foreach $char (@SplitRes)
                {
                    $_ = $char;

                    if (m/ /)
                    {
                        if ($QuoteFound == 1)
                        {
                            $SpaceFreeLine = $SpaceFreeLine.$char;
                        }
                    }
                    elsif (m/\"/)
                    {
                        $SpaceFreeLine = $SpaceFreeLine.$char;
                        if ($QuoteFound == 1)
                        {
                            $QuoteFound = 0;
                        }
                        else
                        {
                            $QuoteFound = 1;
                        }
                    }
                    else
                    {
                        $SpaceFreeLine = $SpaceFreeLine.$char;
                    }
                    $Counter++;
                }

                @SplitRes = split /,/, $SpaceFreeLine;

                # Now the strings are split into individual items.
                # Join the items back together ensuring that there is
                # an appropriate amount of space between each item.


                $NewLine = $SplitRes[0].",";

                $TargetLength = $MaxDefineLength + 1;

                while (length($NewLine) <= $TargetLength)
                {
                    $NewLine = $NewLine." ";
                }

                $NewLine = $NewLine." ".$SplitRes[1].",";

                $TargetLength = $TargetLength + $LanguageOneListMax + 2;

                while (length($NewLine) <= $TargetLength)
                {
                    $NewLine = $NewLine." ";
                }

                $NewLine = $NewLine." ".$SplitRes[2].",";

                $TargetLength = $TargetLength + $LanguageTwoListMax + 2;

                while (length($NewLine) <= $TargetLength)
                {
                    $NewLine = $NewLine." ";
                }

                $NewLine = $NewLine." ".$SplitRes[3].",";

                $TargetLength = $TargetLength + $LanguageThreeListMax + 2;

                while (length($NewLine) <= $TargetLength)
                {
                    $NewLine = $NewLine." ";
                }

                $NewLine = $NewLine." ".$SplitRes[4].",";

                $TargetLength = $TargetLength + $LanguageFourListMax + 2;


                while (length($NewLine) <= $TargetLength)
                {
                    $NewLine = $NewLine." ";
                }

                $NewLine = $NewLine." ".$SplitRes[5]."\n";

                print OutputFile $NewLine;
            }
            else
            {
                print OutputFile $SingleLine."\n";
            }
        }
    }

    close OutputFile;

    $CopyCommand = "copy ".substr($TempFile, 1)." ".$FileName;

    `$CopyCommand`;

    exit(0);


sub ReadDefinitionFile
{
    my $FileName = shift;

    $FileName =~ s|/D=||;

    open InputFileHandle, $FileName;

    while (eof(InputFileHandle) == 0)
    {
        read InputFileHandle, $DataFromFile, 25;
        $DefinitionData = join('',$DefinitionData, $DataFromFile);
    }

    close InputFileHandle;
}

