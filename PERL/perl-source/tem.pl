#
#********************************************************************************
#** Module        : tem.pl
#** Originator    : Mark Roberts
#** Creation Date : 11th August, 1998
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
#  This PERL script is used to produce language text files in the general
#  format of Courier data files. The input to the file is the compressed
#  language text file produced by the script /50300PL/DEV/util/SRC/langsplit.pl
#
#  ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  INCLUDE FILES
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  CONSTANTS
#-------------------------------------------------------------------------------
$Title = "TEM PERL SCRIPT\n";
$HelpText = $Title." Command line argument information :\n".
                   "  /F=FileSource {ALSTOM | USER} \n".
                   "  /M=Model Number \n".
                   "  /C=Comment { DEFAULT_ALSTOM | FILE /D = filename}\n".
                   "  /I=Input file (Produced by langsplit.pl)\n".
                   "  /O=Output file.\n\n\n";

$FileHeader = "APP: Courier\n".
              "TYPE: LanguageText\n".
              "FORMAT: 1.0\n";

#-------------------------------------------------------------------------------
#  PUBLIC VARIABLES
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  SUBROUTINES
#-------------------------------------------------------------------------------
    sub ReadDefinitionFile;

#-------------------------------------------------------------------------------
#  Main function
#-------------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # Process command line arguments.
    #---------------------------------------------------------------------------

    for($Counter = 0; $Counter <= $#ARGV; $Counter++)
    {
        $_ = $ARGV[$Counter];

        if (m|/F|)
        {
            $FileSource = $ARGV[$Counter];
            $FileSource =~ s|/F=||;
        }
        elsif (m|/M|)
        {
            $ModelNumber = $ARGV[$Counter];
            $ModelNumber =~ s|/M=||;
        }
        elsif (m|/C|)
        {
            $Comment = $ARGV[$Counter];
            $Comment =~ s|/C=||;

        }
        elsif (m|/D|)
        {
            $CommentFile = $ARGV[$Counter];
            $CommentFile =~ s|/D=||;
        }
        elsif (m|/I|)
        {
            $InputFile = $ARGV[$Counter];
            $InputFile =~ s|/I=||;
        }
        elsif (m|/O|)
        {
            $OutputFile = $ARGV[$Counter];
            $OutputFile =~ s|/O=||;
        }
        elsif (m|/?|)
        {
            # Display help
            print $HelpText;
            exit(0);
        }
        else
        {
            print "ARGUMENT ERROR \n";
        }
    }

    #--------------------------------------------------------------------------
    # Add to the header.
    #--------------------------------------------------------------------------

    $FileHeader .= "FILESOURCE: ".$FileSource."\n";
    $FileHeader .= "MODEL: ".$ModelNumber."\n\n";

    # If the default description is to be used add it and the date to the
    # header.

    $_ = $Comment;

    if (m/DEFAULT_ALSTOM/)
    {
        $FileHeader .= "This is a ALSTOM P&C originated language text file.\n";
        $FileHeader .= "Date : ";

        ($Sec, $Min, $Hour, $MDay, $Mon, $Year, $WDay, $YDay, $ISDst) = gmtime(time);

        if ($MDay < 10) { $FileHeader .= "0"; }
        $FileHeader .= $MDay."/";
        if ($Mon < 9) { $FileHeader .= "0"; }
        $FileHeader .= ($Mon + 1)."/".$Year."\x1A";
    }

    #--------------------------------------------------------------------------
    # If necessary open the comment file and read the contents.
    #--------------------------------------------------------------------------

    $_ = $Comment;
    if (m/FILE/)
    {
        open InputFileHandle, $CommentFile;

        while(eof(InputFileHandle) == 0)
        {
            read InputFileHandle, $DataFromFile, 255;
            $FileHeader .= $DataFromFile;
        }

        close InputFileHandle;

        split //, $FileHeader;
        $_ = @_[@_ - 1];

        if (m/\n/)
        {
            @_[@_ - 1] = "\x1A";
            $FileHeader = join(/:/, @_);
        }
        else
        {
            $FileHeader .="\x1A";
        }
    }

    #--------------------------------------------------------------------------
    # Open the input file and read the content. Every 16th character insert a
    # <CR><LF> pair except after the last character which should be a ^Z.
    #--------------------------------------------------------------------------

    open InputFileHandle, $InputFile;

    $CharacterCounter = 0;

    while (eof(InputFileHandle) == 0)
    {
        read InputFileHandle, $DataFromFile, 1;
        $CharacterCounter += 1;

        $FileBody .= $DataFromFile;

        if ($CharacterCounter == 16)
        {
            $FileBody .= "\n";
            $CharacterCounter = 0;
        }
    }
    close InputFileHandle;

    #--------------------------------------------------------------------------
    # Produce the output file.
    #--------------------------------------------------------------------------

    $OutputFile = ">".$OutputFile;

    open OutputFileHandle, $OutputFile;

    print OutputFileHandle $FileHeader.$FileBody;

    close OutputFileHandle;

    exit(0);

#
#********************************************************************************
#** END OF FILE
#********************************************************************************
#

