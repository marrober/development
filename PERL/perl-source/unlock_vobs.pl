#------------------------------------------------------------------------------
#------ PERL SCRIPT  : lunock_vobs.pl
#------ Authors Name : Mark Roberts
#------ Date         : 6th December, 2000.
#------ Description  : Unlock all vobs after to the backup.
#

$VobList = `cleartool lsvob -s`;

@Vobs = split("\n", $VobList);

foreach $Vob (@Vobs)
{
    $VobLockCommand = "cleartool unlock vob:".$Vob;

    print `$VobLockCommand`;
}


