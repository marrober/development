#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_grab_views.pl
#------ Authors Name : Mark Roberts
#------ Date         : 26 January, 1998.
#------ Description  : 
#
#

$GetViewListCommand = "cleartool lsview -s";
$GetViewListResult = `$GetViewListCommand`;

print $GetViewListResult."\n";
