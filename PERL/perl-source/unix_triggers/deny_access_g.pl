$message =  "The operation ".$ENV{'CLEARCASE_OP_KIND'}." is not allowed for user ".$ENV{'CLEARCASE_USER'}." in this VOB.";
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

