#----------------------------------------------------------------------------
#- PERL script to rename a ClearCase element using the Cleartool mv command.
#- This script contains a large amount of error checking to ensure the
#- following :
#- 		The element to be renamed does exist as a ClearCase element.
#-		The element to be renamed is not checkedout. (This is not strictly
#-			necessary but is a good idea since it prevents problems with
#- 			the view-private file associated with the checkout.
#-		A file does not already exist with the new name (either a ClearCase
#-			element, or a view-private file).
#-		The parent directory is not already checked out.
#-		The parent directory as checked out successfuly as part of the process.
#-		The rename operation takes place successfully.
#-		The parent directory is successfuly checked back in.
#-
#-  This version of the script is suitable to be called from the explorer
#-  and/or the clearcase details menus. It uses a prompt box to collect the
#-  new name for the element.
#- 	Two prompt boxes are used to collect comments for the checkout of the
#-  parent directory and the actual rename operation.
#- 	This script can be modified to remove such functionality if required.
#-
#-  Creator : Mark Roberts, Technical Consultant, Rational Software.
#-  Creation date : 21st May, 1999.


# Variable declaration.
#
$EnvTemp = $ENV{'TEMP'};
#
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
    print "\n\n ERROR : Could not find one of the following environment variables\n";
    print "        temp, TEMP, tmp, TMP\n";
    exit(0);
}

$Comment = "";

$OldName = $ARGV[0];

$TempTextFile = $EnvTemp."\\temptextfile.tmp";
$GetNewNameCommand = "clearprompt text -outfile ".$TempTextFile." -prompt \"Enter the new name for the element.\"";
`$GetNewNameCommand`;

ReadTempTextFile();

$NewName = $Comment;

if (length($NewName) == 0)
{
	print "New name not given.\n";

	exit(0);
}

# Confirm that the file specified is an object.
#
$CleartoolLsCommand = "cleartool ls ".$OldName;
$CleartoolLsResult = `$CleartoolLsCommand`;

$_ = $CleartoolLsResult;

if (m/@@/)
{
	# Get checkout status of the old object.
	
	$CleartoolLsCoCommand = "cleartool lsco ".$OldName;
	$CleartoolLsCoResult = `$CleartoolLsCoCommand`;
	
	if(length($CleartoolLsCoResult) == 0)
	{
		# The file is not checkedout. 
		
		# Check if the destination filename is already used.
		
		if (-e $NewName)
		{
			# The destination name already exists.
			
			print "The destination name already exists.\n";
		}
		else
		{
			# Check that the parent directory is not already checked out.

			$CleartoolLsCoCommand = "cleartool lsco -directory .";
			$CleartoolLsCoResult = `$CleartoolLsCoCommand`;	
			
			if(length($CleartoolLsCoResult) == 0)
			{
				# The parent directory is not checked out.
				
				# Checkout the parent.

				# Get a comment for the directory checkout first.

    			$GetCommentCommand = "clearprompt text -outfile $TempTextFile -multi_line";
				$GetCommentCommand = $GetCommentCommand." -prompt";
				$GetCommentCommand = $GetCommentCommand." \"Enter a comment to be used for the directory checkout.\"";

				`$GetCommentCommand`;

				ReadTempTextFile();

				$CleartoolCoCommand = "cleartool co -c \"$Comment\" .";
				$CheckoutResult = `$CleartoolCoCommand`;

				$_ = $CheckoutResult;

				if (m/Checked out "." from version/)
				{
					# The checkout was successful.

					# Now, rename the elementm but first get a comment for the rename.

					$TempTextFile = $EnvTemp."\\comment2.tmp";
	    			$GetCommentCommand = "clearprompt text -outfile $TempTextFile -multi_line";
					$GetCommentCommand = $GetCommentCommand." -prompt \"Enter a comment to be used for the element rename.\"";

					`$GetCommentCommand`;

					ReadTempTextFile();

					$CleartoolMvCommand = "cleartool mv -c \"".$Comment."\" ".$OldName." ".$NewName;
					$CleartooMvResult = `$CleartoolMvCommand`;

					# Validate the name change with a cleartool ls on the new name.
			
					$CleartoolLsCommand = "cleartool ls ".$NewName;
					$CleartoolLsResult = `$CleartoolLsCommand`;

					$_ = $CleartoolLsResult;

					if (m/@@/)					
					{
						print "The rename was successful.\n";
					}
					else
					{
						print "The rename failed - please investigate ...\n";
					}
					
					# Checkin the parent directory - use the comment from the checkout.

					$CleartoolCiCommand = "cleartool ci -nc .";
					$CleartoolCiResult = `$CleartoolCiCommand`;

					$_ = $CleartoolCiResult;

					if (!m/Checked in "." version/)
					{
						print "An error has occured and the parent directory was\n";
						print "not successfully checked in. Please investigate ...\n";
					}
				}
				else
				{
					print "ERROR : Unable to checkout the directory\n";
				}

			}
			else
			{
				print "The parent directory is already checked out.\n";

				$CleartoolLsCoCommand = "cleartool lsco -directory -fmt \"Checked out by '%u' on %d with comment : %c \n\" .";
				$CleartoolLsCoResult = `$CleartoolLsCoCommand`;	
				$CleartoolLsCoResult =~ s/comment : /comment : \n/;
				print $CleartoolLsCoResult."\n";
			}	

		
		}
		
	}
	else
	{
		print "The file is currently checkedout. Whilst it is possible\n";
		print "to change the name of a checked out element, this process\n";
		print "involves moving the checkedout view-private file too, and\n";
		print "so it is not recommended. Wait until the file is checked\n";
		print "in and then rename it.\n";
	}
}
else
{
	print "The file to be renamed is not a ClearCase element.\n";
	print "Either the file does not exist, or it is a view-private\n";
	print "file that can be renamed using the standard explorer tool.\n";
}



sub ReadTempTextFile
{
	# Get the result of the last backtick command. 
	# If the return code is 0 then the user pressed OK
	# to dismiss the dialog box.

	if ($? == 0)
	{			
		# Get the comment from the file.

        open(TempTextFileHandle, $TempTextFile);

		$LinesToRead = 0;
		$Comment = "";
		while ($LinesToRead == 0)
		{
			if (eof(TempTextFileHandle) == 1)
			{
    			$LinesToRead = 1;
			}
				else
        	{
            	read(TempTextFileHandle, $CommentBuffer, 1024);
                $Comment = $Comment.$CommentBuffer;
            }
        }
        close(TempTextFileHandle);

		# Remove the file that held the comment.

    	`del $TempTextFile`;
    }

}
	


