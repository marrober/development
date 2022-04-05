#------------------------------------------------------------------------------
#------ PERL SCRIPT  : cc_listvob.pl
#------ Authors Name : Mark Roberts
#------ Date         : 27 November, 1996.
#------ Description  : This script simply lists the VOB names and descriptions.
# 
# Variable declaration. 
#
# Print sign on information.
#
print "VOB Name | Description\n";
#
@VobNames = `cleartool lsvob -short`;
#
# Use the ClearTool describe command to list the VOB name and description.
#
foreach $i (@VobNames)
{
# Remove the \n from the end of each line as it is processed.
#
	split(/[\n]/,$i);
	$Vob = @_[0];
#
    $DescribeCommand = "cleartool describe -fmt \"%En%[12]St%0.68c\" -vob ".$Vob;
#
    $DescribeResult = `$DescribeCommand`; 

$Counter = 1;

    if (length($DescribeResult) > 70)
    {
        while ($Counter < 20)
        {
            $End = substr($DescribeResult, ($Counter * -1));
#
            if ((substr($End, 0, 1) cmp " ") == 0)
            {
                $DescribeResult = substr($DescribeResult, 0, length($DescribeResult) - $Counter);
                print $DescribeResult."\n";
                $End =~ s/\n/ /g;
                print "          ".$End."\n";
                goto QuitWhile;
            }
            $Counter++;
        }
QuitWhile:
    }
    else
    {    
        print $DescribeResult;
    }
}


