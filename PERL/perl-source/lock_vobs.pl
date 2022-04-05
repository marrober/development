#------------------------------------------------------------------------------
#------ PERL SCRIPT  : lock_vobs.pl
#------ Authors Name : Mark Roberts
#------ Date         : 6th December, 2000.
#------ Description  : Lock all vobs prior to the backup.
#

$VobList = `cleartool lsvob -s`;

@Vobs = split("\n", $VobList);

foreach $Vob (@Vobs)
{
    $VobLockCommand = "cleartool lock vob:".$Vob;

    print `$VobLockCommand`;
}


