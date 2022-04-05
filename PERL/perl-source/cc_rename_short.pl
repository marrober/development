#----------------------------------------------------------------------------
#- PERL script to rename a ClearCase element using the Cleartool mv command.
#- This is a short script with no error checking.
#-
#-  Creator : Mark Roberts, Technical Consultant, Rational Software.
#-  Creation date : 21st May, 1999.

$OldName = $ARGV[0];
$NewName = $ARGV[1];


`cleartool co -nc .`;
`cleartool mv -nc $OldName $NewName`;
`cleartool ci -nc .`;


