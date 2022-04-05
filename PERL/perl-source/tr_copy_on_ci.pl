# Trigger creation command :
# cleartool mktrtype -element -all -postop checkin -nc -exec "perl \\view\default\Data\perl-source\tr_copy_on_ci.pl" CopyOnCi

$FileName = $ENV{'CLEARCASE_PN'};
$ElementType = $ENV{'CLEARCASE_ELTYPE'};
$CopyTargetDir = "c:\\temp\\";

if ($ElementType ne "directory") {
	$CopyCmd = "copy ".$FileName." ".$CopyTargetDir;
	`$CopyCmd`;
}

