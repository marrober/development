#------------------------------------------------------------------------------
#------ PERL SCRIPT  : tr_show_env.pl
#------ Authors Name : Mark Roberts
#------ Date         : 6th April, 1999.
#------ Description  : This trigger script simply displays all ClearCase
#                      related environment variables for the element with which
#                      it is associated, and the command that caused it to fire.
#                      The return value is always 0 so the command will always
#                      execute when it is associated with a pre-op event.
#                      The trigger is associated with the file :
#                      \Test\trigger_test\show_env_post.txt as a post op trigger
#                      \Test\trigger_test\show_env_pre.txt as a pre op trigger.
#
# Locate the hyperlink (if present).
#
	$FindHyperLinkCommand = "cleartool find ".$ENV{'CLEARCASE_PN'}." -element {hltype(SwToDoc)} -print";
	$FindHyperlinkResult = `$FindHyperLinkCommand`;

	if (length($FindHyperlinkResult) > 0)
	{
		# The hyperlink is present.

		$DescribeCommand = "cleartool desc ".$ENV{'CLEARCASE_PN'}."@@";
		$DescribeResult = `$DescribeCommand`;

		@SplitResult = split(/[\n]/, $DescribeResult);

		foreach $Line (@SplitResult)
		{
			$_ = $Line;

			if (m/SwToDoc/)
			{
				@SplitLine = split(/->/, $Line);
				$SplitLine[1] =~ s/^ //;
			}
		}


		print "This element has a hyperlink to the element : ".$SplitLine[1]."\n";


	}





    exit(1);

