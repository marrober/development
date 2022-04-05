#
#********************************************************************************
#** Module        : modbus_auto.pl
#** Originator    : Mark Roberts
#** Creation Date : 25th January, 1999
#**
#** Code Review Reference : <the code review form number>
#**
#** (c) 1999 ALSTOM T&D P&C Ltd.
#** (c) 1999 ALSTOM T&D P&C SA.
#********************************************************************************
#

#--------------------------------------------------------------------------------
#  DOCUMENTATION
#
#  This PERL script is used to extract data from a Microsoft Excel Spreadsheet
#  to a text file that can be used by the ModBus Master Station for Automatic
#  testing.
#  Arguments : /Type: {settings|commands|data|all}
#              /D:Constant = n (decimal)
#              /InFile=<input excel spreadsheet>
#              /OutFile=<output text file to be used by ModMast>
#              /Excluded=address1, address2, address3,address4-address10 etc..
#              /GD = <Start Address>-<End Address> The start and end address of
#                    the defined group in the spreadsheet given by /I.
#              /GC = <Addr1>-<Addr2>,.... Comma separated pairs of dash separated
#                    addresses that define other group address ranges for which
#                    copies of the data should be produced.
#              /M:x Where x = the model number {1 - 4}
#
#--------------------------------------------------------------------------------

#--------------------------------------------------------------------------------
#  REQUIRED PACKAGES
#--------------------------------------------------------------------------------

use OLE;

#--------------------------------------------------------------------------------
#  SUBROUTINE DEFINITIONS
#--------------------------------------------------------------------------------

sub GetSimpleValue;

#--------------------------------------------------------------------------------
#  CONSTANTS
#--------------------------------------------------------------------------------

$MinMaxStep{0} = "Min";
$MinMaxStep{1} = "Max";
$MinMaxStep{2} = "Step";

#-------------------------------------------------------------------------------
#  Main function
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Process command line options.
#-------------------------------------------------------------------------------

if (($#ARGV == 0) && $ARGV[0] =~ (m/CONFIG=/))
{
    # Arguments are in a config file.

    $ConfigFile = $ARGV[0];
    $ConfigFile =~ s/\/CONFIG=//;
    $ConfigFile =~ s/^ *//g;
    $ConfigFile =~ s/ *$//g;

    open CONFIGFILE, $ConfigFile;

    while (eof(CONFIGFILE) == 0)
    {
        read CONFIGFILE, $FileBuffer, 100;
        $JoinedArguments .= $FileBuffer;
    }

    close CONFIGFILE;

    $JoinedArguments =~ s/\n/ /g;
}
else
{
    for ($Counter = 0; $Counter <= $#ARGV; $Counter++)
    {
        $JoinedArguments = $JoinedArguments." ".$ARGV[$Counter];
    }
}

@ARGV = split(/\//, $JoinedArguments);

$TypeFlag = 0;

for ($Counter = 0; $Counter <= $#ARGV; $Counter++)
{
    $_ = $ARGV[$Counter];

    if (m/D:/i)
    {
        $_ =~ s/D://i;
        @SplitArg = split(/=/, $_);
        $SplitArg[0] =~ s/ *//;
        $SplitArg[0] =~ s/ $//;
        $SplitArg[1] =~ s/ //g;
        $Arguments{$SplitArg[0]} = $SplitArg[1];
    }

    if (m/[type] *:/i)
    {
        $_ =~ s/ //g;
        $_ =~ s/type://i;

        if (m/all/i)        { $TypeFlag |= 7; }
        if (m/settings/i)   { $TypeFlag |= 1; }
        if (m/data/i)       { $TypeFlag |= 2; }
        if (m/commands/i)   { $TypeFlag |= 4; }
    }
    if (m/InFile *=/i)
    {
        @SplitArg = split(/=/, $_);
        $InputFileName = $SplitArg[1];
        $InputFileName =~ s/ //g;
    }
    if (m/OutFile *=/i)
    {
        @SplitArg = split(/=/, $_);
        $OutputFileName = $SplitArg[1];
        $OutputFileName =~ s/ //g;
    }
    if (m/Excluded *=/i)
    {
        @SplitArg = split(/=/, $_);
        $SplitArg[1] =~ s/ //g;
        @SplitArg2 = split(/,/, $SplitArg[1]);

        foreach $AddressSpec (@SplitArg2)
        {
            $_ = $AddressSpec;

            if (m/-/)
            {
                # Range specifier.
                @SplitRange = split(/-/, $AddressSpec);

                if (m/[^-0-9]/)
                {
                    # Error invalid character in the exclusion specifier.
                    print "An invalid character was found in the exclusion specifier ".$_."\n";
                    exit(-3);
                }
                elsif ($SplitRange[1] < $SplitRange[0])
                {
                    # Error the range must run from a low to a higher address.
                    print "Range error in address exclusion : ".$SplitRange[1].
                          " is less than ".$SplitRange[0]."\n";
                    exit(-4);
                }
                elsif ($SplitRange[1] == $SplitRange[0])
                {
                    # Error the range must run from a low to a higher address.
                    print "Range error in address exclusion : ".$SplitRange[1].
                          " is equal to ".$SplitRange[0]."\n";
                    exit(-5);
                }
                else
                {
                    foreach $Exc ($SplitRange[0] .. $SplitRange[1])
                    {
                        push @Exclusions, $Exc;
                    }
                }
            }
            else
            {
                if (m/[^0-9]/)
                {
                    # Error invalid character in the exclusion specifier.
                    print "An invalid character was found in the exclusion specifier ".$_."\n";
                    exit(-6);
                }
                else
                {
                    push @Exclusions, $_;
                }
            }
        }
    }
    if (m/GD *=/i)
    {
        @SplitArg = split(/=/, $_);
        $SplitArg[1] =~ s/ //g;
        @SplitArg2 = split(/-/, $SplitArg[1]);
        $DefinedGroupStart = $SplitArg2[0];
        $DefinedGroupEnd   = $SplitArg2[1];
    }
    if (m/GC *=/i)
    {
        @SplitArg = split(/=/, $_);
        $SplitArg[1] =~ s/ //g;
        @SplitArg2 = split(/,/, $SplitArg[1]);

        $GCCounter = 0;

        foreach $AddressSpec (@SplitArg2)
        {
            $_ = $AddressSpec;

            if (m/-/)
            {
                # Range specifier.
                @SplitRange = split(/-/, $AddressSpec);

                if (m/[^-0-9]/)
                {
                    # Error invalid character in the exclusion specifier.
                    print "An invalid character was found in the /GC specifier ".$_."\n";
                    exit(-7);
                }
                elsif ($SplitRange[1] < $SplitRange[0])
                {
                    # Error the range must run from a low to a higher address.
                    print "Range error in address for /GC : ".$SplitRange[1].
                          " is less than ".$SplitRange[0]."\n";
                    exit(-8);
                }
                elsif ($SplitRange[1] == $SplitRange[0])
                {
                    # Error the range must run from a low to a higher address.
                    print "Range error in address for /GC : ".$SplitRange[1].
                          " is equal to ".$SplitRange[0]."\n";
                    exit(-9);
                }
                else
                {
                    $GroupCopy[$GCCounter][0] =$SplitRange[0];
                    $GroupCopy[$GCCounter][1] =$SplitRange[1];
                    $GCCounter++;
                }
            }
            else
            {
                # Error. This argument should contain a range specifier.
                print "Error in the range specifier for argument /GC\n";
                exit(-10);
            }
        }
    }
    if (m/M:/i)
    {
        @SplitArg = split(/:/, $_);
        $SplitArg[1] =~ s/ //g;
        $ModelNumber = $SplitArg[1];
    }
}

#-------------------------------------------------------------------------------
#  Open the excel spreadsheet and get the information into arrays.
#-------------------------------------------------------------------------------

print "\nReading spreadsheet ";

$excel = CreateObject OLE 'Excel.Application'
        or warn "Couldn't create new instance of Excel App!!";
$book = $excel->Workbooks->Open($InputFileName);

$sheet = $book->Worksheets(2);
$lastcol = $sheet->UsedRange->Columns->{Count};
$lastrow = $sheet->UsedRange->Rows->{Count};

$DatabaseRowCounter = 0;

$DisplayCounter = 0;

foreach $Row (1..$lastrow)
{
    $DisplayCounter++;

    if ($DisplayCounter > ($lastrow / 10))
    {
        $DisplayCounter = 0;

        print ".";
    }

    $ModBusStart = "";
    $_ = ($sheet->Cells(int($Row),6))->{Value};

    if((length($_) > 0) && (m/[0-9]+/))
    {
        $ModBusStart = $sheet->Cells(int($Row),6)->{Value};
        $ModBusEnd =   $sheet->Cells(int($Row),7)->{Value};

        if (length($sheet->Cells(int($Row),13)->{Value}) == 0)
        {
            if ((m/^3/))
            {
                $CellType = "Data";
            }
            elsif ((m/^4/))
            {
                $CellType = "Command";
            }
        }
        else
        {
            $CellType = $sheet->Cells(int($Row),13)->{Value};
        }

        $CellGCode = $sheet->Cells(int($Row),9)->{Value};
        $DefaultValue = $sheet->Cells(int($Row),12)->{Value};
        $Min =  $sheet->Cells(int($Row),14)->{Value};
        $Max =  $sheet->Cells(int($Row),15)->{Value};
        $Step = $sheet->Cells(int($Row),16)->{Value};

        # Check the model number to see if this cell is included or whether or not
        # substitutions from the row below are required.
        #
        if (!($sheet->Cells(int($Row),(17 + $ModelNumber))->{Value} =~ (m/ *\* */)))
        {
            $_ = $sheet->Cells(int($Row + 1),6)->{Value};
            $_ =~ s/^ *//g;
            $_ =~ s/ *$//g;

            if (length($_) == 0)
            {
                # No information in the ModBus address field so it is assumed that the
                # information in the line below the 'current line' may contain
                # substitution data.
                #

                if ($sheet->Cells(int($Row + 1),(17 + $ModelNumber))->{Value} =~ (m/ *\* */))
                {
                    # The cell is to be included but some of the information is to be
                    # copied from the row below.
                    # Replace any column data that has text in the row below. Replacements
                    # are only allowed on the default, min, max and step.

                    $_ = $sheet->Cells(int($Row + 1),12)->{Value};

                    $_ =~ s/^ *//g;
                    $_ =~ s/ *$//g;

                    if (length($_) > 0)
                    {
                        $DefaultValue = $_;
                    }

                    $_ = $sheet->Cells(int($Row + 1),14)->{Value};

                    $_ =~ s/^ *//g;
                    $_ =~ s/ *$//g;

                    if (length($_) > 0)
                    {
                        $Min = $_;
                    }

                    $_ = $sheet->Cells(int($Row + 1),15)->{Value};

                    $_ =~ s/^ *//g;
                    $_ =~ s/ *$//g;

                    if (length($_) > 0)
                    {
                        $Max = $_;
                    }

                    $_ = $sheet->Cells(int($Row + 1),16)->{Value};

                    $_ =~ s/^ *//g;
                    $_ =~ s/ *$//g;

                    if (length($_) > 0)
                    {
                        $Step = $_;
                    }
                }
                else
                {
                    $ModBusStart = "";
                }
            }
            else
            {
                $ModBusStart = "";
            }
        }

        if ((length($ModBusStart) > 0) && ($ModBusStart =~ (m/^[0-9]/)))
        {
            $Excluded = 0;

            foreach $Exclusion (@Exclusions)
            {
                if ($ModBusStart == $Exclusion)
                {
                    $Excluded = 1;
                }
            }
            if ($Excluded == 0)
            {
                $Database[$DatabaseRowCounter][0] = $ModBusStart;
                $Database[$DatabaseRowCounter][1] = $ModBusEnd;
                $Database[$DatabaseRowCounter][2] = $CellType;
                $Database[$DatabaseRowCounter][3] = $CellGCode;
                $Database[$DatabaseRowCounter][4] = GetSimpleValue($DefaultValue);
                $Database[$DatabaseRowCounter][5] = GetSimpleValue($Min);
                $Database[$DatabaseRowCounter][6] = GetSimpleValue($Max);
                $Database[$DatabaseRowCounter][7] = GetSimpleValue($Step);
                $DatabaseRowCounter += 1;
            }
        }
    }
}

print " done\n";

#-------------------------------------------------------------------------------
#  Get the data type information from the spreadsheet.
#-------------------------------------------------------------------------------

print "Reading data types ";

$sheet = $book->Worksheets(3);
$lastcol = $sheet->UsedRange->Columns->{Count};
$lastrow = $sheet->UsedRange->Rows->{Count};

$RowCounter = 0;

$DisplayCounter = 0;

$StoredGCode = "";

foreach $Row (1..$lastrow)
{

    $DisplayCounter++;

    if ($DisplayCounter > ($lastrow / 10))
    {
        $DisplayCounter = 0;

        print ".";
    }

    $_ = ($sheet->Cells(int($Row),1))->{Value};

    if (m/.*\-.*/)
    {
        # A dash exists in the G number name. This indicates that a comma separated list
        # of model numbers follows.

        @SplitGCode = split(/-/, $sheet->Cells(int($Row),1)->{Value});
        $_ = $SplitGCode[1];
        @SplitModelNumbers = split(/,/, $_);

        $MatchFound = 0;

        foreach $_ (@SplitModelNumbers)
        {
            if (m/$ModelNumber/)
            {
                # The model number specified as an argument is after the name.

                @SplitGCode = split(/-/, $sheet->Cells(int($Row),1)->{Value});
                $StoredGCode = $SplitGCode[0];
                $MatchFound = 1;
            }
            else
            {
                if ($MatchFound == 0)
                {
                    $StoredGCode = "";
                }
            }
        }
    }
    elsif (m/^G[0-9]+/)
    {
        $StoredGCode = $sheet->Cells(int($Row),1)->{Value};
    }
    else
    {
        if ((length(($sheet->Cells(int($Row),2))->{Value}) > 0) &&
            (length(($sheet->Cells(int($Row),3))->{Value}) > 0) && (length($StoredGCode) > 0))
        {
            $DataTypes[$RowCounter][0] = $StoredGCode;
            $DataTypes[$RowCounter][1] = ($sheet->Cells(int($Row),2))->{Value};
            $DataTypes[$RowCounter][2] = ($sheet->Cells(int($Row),3))->{Value};

            $RowCounter++;
        }
    }
}

$NumberDataTypes = $RowCounter;

$excel->Workbooks->Close($InputFileName);

$excel->Quit();

print " done\n";

#-------------------------------------------------------------------------------
#  Extract the correct default value from the associations of the textual
#  default value and the G type associated with the cell.
#-------------------------------------------------------------------------------

print "Replacing textual defaults with G type associated values ....";

foreach $Row (0 .. ($DatabaseRowCounter - 1))
{
    $_ = $Database[$Row][2];

    if ((m/Setting/) || (m/Command/))
    {
        foreach $TypeIndex (0 .. ($NumberDataTypes - 1))
        {
            $_ = $Database[$Row][3];

            if ((m/$DataTypes[$TypeIndex][0]/) &&
                (length($_) == length($DataTypes[$TypeIndex][0])))
            {
                $_ = $Database[$Row][4];

                if ((m/$DataTypes[$TypeIndex][2]/) &&
                    (length($_) == length($DataTypes[$TypeIndex][2])))
                {
                    $Database[$Row][4] = $DataTypes[$TypeIndex][1];
                }
            }
        }
    }
}

print " done\n";

#-------------------------------------------------------------------------------
# Substitute any default values that have not been replaced by G type
# associations.
#-------------------------------------------------------------------------------

print "Substitute default values defined on command line ....";

foreach $Row (0 .. ($DatabaseRowCounter - 1))
{
    $_ = $Database[$Row][2];

    #print $Row."  looking for settings : ".$_."\n";

    if ((m/Setting/) || (m/command/))
    {
        $_ = $Database[$Row][4];

        if (m/[^-0-9\.]/)
        {
            $OldDef = $_;

            $_ =  $Database[$Row][3];

            if (!(m/^G3$/) && !(m/^G20$/))
            {
                # Characters other than numeric have been found. Check the 'Arguments' associative
                # array for the text.

                $Match = 0;

                $_ = $OldDef;

                $_ =~ s/^ *//g;
                $_ =~ s/ *$//g;

                foreach $Arg (sort keys %Arguments)
                {

                    if ((m/$Arg/) && (length($_) == length($Arg)))
                    {
                        $Database[$Row][4] = $Arguments{$Arg};
                        $Match = 1;
                    }
                }
                if ($Match == 0)
                {
                    # The textual default definition was not found in the arguments
                    # list.
                    print "The default was undefined for ".
                            $_." for the cell at ModBus address ".$Database[$Row][0]."\n";
                    exit(-11);
                }
            }
        }
    }
}

print " done\n";


#-------------------------------------------------------------------------------
# Substitute any 'variable' min, max or step values for supplied arguments.
# Fail if a non numeric string is found that was not supplied as an argument.
#-------------------------------------------------------------------------------

print "Replacing variable min, max, step values defined on command line ....";

foreach $Row (0 .. ($DatabaseRowCounter - 1))
{
    $_ = $Database[$Row][2];

    if (m/setting/i)
    {
        foreach $MMS (5 .. 7)
        {
            $_ = $Database[$Row][$MMS];

            #print "Checking : ".$_."\n";

            if ((length($_) == 0) && ($Database[$Row][3] != "G12"))
            {
                print "The ".$MinMaxStep{$MMS - 5}.
                      " was blank for the cell at ModBus address ".$Database[$Row][0]."\n";
                exit(-1);
            }

            if (m/[^-0-9\.]/)
            {
                # Characters other than numeric have been found. Check the 'Arguments' associative
                # array for the text.

                $Match = 0;

                foreach $Arg (keys %Arguments)
                {
                    if ((m/$Arg/) && (length($_) == length($Arg)))
                    {
                        $Database[$Row][$MMS] = $Arguments{$Arg};
                        $Match = 1;
                    }
                }
                if ($Match == 0)
                {
                    # The textual min, max or step definition was not found in the arguments
                    # list.
                    print "The ".$MinMaxStep{$MMS - 5}." was undefined for ".
                          $_." for the cell at ModBus address ".$Database[$Row][0]."\n";
                    exit(-2);
                }
            }
        }
    }
}

print "done\n";

#-------------------------------------------------------------------------------
# Generate group copies if required.
#-------------------------------------------------------------------------------

print "Generating group copies ....";

$InsertionCounter = 0;

foreach $Group (0 .. ($GCCounter - 1))
{
    foreach $Row (0 .. ($DatabaseRowCounter - 1))
    {
        if (($Database[$Row][0] >= $DefinedGroupStart) &&
            ($Database[$Row][0] <= $DefinedGroupEnd))
        {
            $Database[$DatabaseRowCounter + $InsertionCounter][0] =
                $GroupCopy[$Group][0] + $Database[$Row][0] - $DefinedGroupStart;

            if (length($Database[$Row][1]) > 0)
            {
                $Database[$DatabaseRowCounter + $InsertionCounter][1] =
                    $GroupCopy[$Group][0] + $Database[$Row][1] - $DefinedGroupStart;
            }

            foreach $ColumnCopy (2 .. 7)
            {
                $Database[$DatabaseRowCounter + $InsertionCounter][$ColumnCopy] =
                    $Database[$Row][$ColumnCopy];
            }
            $InsertionCounter++;
        }
    }
}

$DatabaseRowCounter += $InsertionCounter;

print "done\n";

#-------------------------------------------------------------------------------
# Copy the processed database information to the output file.
#-------------------------------------------------------------------------------

print "Write data file ....";

$OutputFileName = ">".$OutputFileName;

open FILEHANDLE, $OutputFileName;

foreach $Row (0 .. ($DatabaseRowCounter - 1))
{
    $_ = $Database[$Row][2];

    if (($TypeFlag == 0) ||
        ((m/setting/i) && ($TypeFlag & 1)) ||
        ((m/data/i) &&    ($TypeFlag & 2)) ||
        ((m/command/i) && ($TypeFlag & 4)))
    {
        foreach $J (0 .. 7)
        {
            print FILEHANDLE $Database[$Row][$J];
            if ($J < 7)
            {
                print FILEHANDLE ",";
            }
        }
        print FILEHANDLE "\n";
    }
}

close(FILEHANDLE);

print "done\n";

#-------------------------------------------------------------------------------
# end of script.
#-------------------------------------------------------------------------------

exit(0);

#-------------------------------------------------------------------------------
# Subroutine : GetSimpleValue
#-------------------------------------------------------------------------------


sub GetSimpleValue
{
# Extract the first numeric only part of the min max step specifier.
#
    my $Var = shift;

    $_ = $Var;

    if (m/^[^-0-9\.]/)
    {
        return($Var);
    }
    else
    {
        @SplitRes = split(/[\*\/\^ ]/, $Var);

        return($SplitRes[0]);
    }
}

