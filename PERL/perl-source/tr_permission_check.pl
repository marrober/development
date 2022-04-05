# ClearCase Trigger Script.
# 
# This script identifies the VOB, the Object and the user.
# It then uses a series of text files of user and group
# information to identify whether or not to allow the 
# command to proceed.
#

$_ = $ENV{'OS'};


if (m/Windows_NT/)
{
	# Windows NT specific.
	
	$UserName = lc($ENV{'CLEARCASE_USER'});
	$VobTag = lc($ENV{'CLEARCASE_VOB_PN'});
	$ObjectName = lc($ENV{'CLEARCASE_PN'});
	$FileLocations = "\\\\gargantua\\cc_store\\vobs_sources\\scripts\\";
}
else
{
	# UNIX specific.

	$UserName = lc($ENV{CLEARCASE_USER});
	$VobTag = lc($ENV{CLEARCASE_VOB_PN});
	$ObjectName = lc($ENV{CLEARCASE_PN});
	$FileLocations = "/net/gargantua/cc_store/vobs_sources/scripts/";	
}

$VobFileName = $FileLocations.$VobTag."_vob.txt";

# print $VobFileName."\n";

open VobFileHandle, $VobFileName;

while (eof(VobFileHandle) == 0)
{
    read VobFileHandle, $DataFromFile, 25;
    $GroupList = join('',$GroupList, lc($DataFromFile));
}

close VobFileHandle;

@GroupArray = split("\n", $GroupList);

foreach $_ (@GroupArray)
{
#	print "Group : ".$_."\n";
	
	if (m/:/)
	{
		# Split the group name from the specific area in the vob that they can write into.
		@Group_Path = split(":", $_);
		$Group = @Group_Path[0];
		$Path = @Group_Path[1];
		$Group =~ s/ //g;
		$Path =~ s/ //g;

		$_ = $ENV{'OS'};

		if (m/Windows_NT/)
		{

		}
		else
		{
			$Path =~ s/\\/\//g;
		}
	}
	else
	{
		$Group = $_;
		$Path = "";
	}

#	print "checking group : ".$Group."\n";
	$GroupFileName = $FileLocations.$Group."_group.txt";

#	print $GroupFileName."\n";

	open GroupFileHandle, $GroupFileName;

	while (eof(GroupFileHandle) == 0)
	{
	    read GroupFileHandle, $DataFromFile, 25;
	    $UserList = join('',$UserList, lc($DataFromFile));
	}

	close GroupFileHandle;

	@UserArray = split("\n", $UserList);

	foreach $_ (@UserArray)
	{
#		print "comparing user : ".$_."\n";
		if (m/$UserName/)
		{
			$_ = $ObjectName;

			if (length($Path) > 0)
			{
#				print "Compare ....\n";
			

#				print $Path."\n";
#				print $_."\n";

				$Index = index($_, $Path);
#				print $Index."\n";
				if ($Index >= 0)
				{
					exit(0);
				}
			}
			else
			{
				exit(0);
			}
		}
	}
}
$message =  "This action is not allowed for user ".$ENV{'CLEARCASE_USER'}." in this VOB.";
error("$message");

########################################################################
# SUBROUTINE ERROR
#
sub error
{
    local ($prompt = @_[0]);

    $_ = $ENV{'OS'};

    if (m/Windows_NT/)
    {
        local ($errorProg="$ENV{ATRIAHOME}/bin/clearprompt");
    }
    else
    {
        local ($errorProg="/usr/atria/bin/clearprompt");
    }
    local ($flags = "proceed -type error -default abort -mask abort");
    system("$errorProg $flags -prompt \"$prompt\"");
    exit 2;
}
exit(-1);

