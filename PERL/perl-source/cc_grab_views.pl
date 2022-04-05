#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_grab_views.pl
#------ Authors Name : Mark Roberts
#------ Date         : 26 January, 1998.
#------ Description  : 
#
#

$GetViewListCommand = "cleartool lsview -s";
$GetViewListResult = `$GetViewListCommand`;

@ViewList = split(/[\n]/, $GetViewListResult);

foreach $V (@ViewList)
{
	# Get the long listing of information about each view and then collect
	# information accordingly.

	$LongDescription = `cleartool lsview -l $V`;

	@ViewDescription = split(/[\n]/, $LongDescription);

	$Tag = $GlobalPath = $Attributes = "";

	foreach $L (@ViewDescription)
	{

		$_ = $L;

		if (m/Tag:/)
		{
			$Tag = $_;
			$Tag =~ s/Tag://;

			$Tag =~ s/ //g;
	
			
		}
		if (m/Global path:/)
		{
			$GlobalPath = $_;
			$GlobalPath =~ s/Global path://;

			$GlobalPath =~ s/ //g;
	
			
		}
		if (m/View attributes:/)
		{
			$Attributes = $_;
			$Attributes =~ s/View attributes://;

			$Attributes =~ s/ //g;	
		}	
	}

	print "-----------------------------------------------------------\n";
	print "Tag :".$Tag."\n";
	print "Global Path :".$GlobalPath."\n";

	# Get config spec.
	$ConfigSpec = `cleartool catcs -tag $Tag`;
	print $ConfigSpec."\n";

	if (length($Attributes) > 0) 
	{
		print " *** SNAPSHOT VIEW ***\n";
	}


}
