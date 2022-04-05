$BranchType = @ARGV[0];
$Display = @ARGV[1];

$FindElementsWithBranchCmd = "cleartool find . -element brtype(".$BranchType.") -print";
@ElementsWithBranchArray = `$FindElementsWithBranchCmd`;

foreach $Element (@ElementsWithBranchArray) {
	$Element =~ s/@@//g;
	$Element =~ s/\n//g;
	
	$FindVerionsofElementwithBranchCmd = "cleartool find ".$Element." -version brtype(".$BranchType.") -print";
	@VersionsofElementWithBranch = `$FindVerionsofElementwithBranchCmd`;
	
	$LatestVersionOnBranch = @VersionsofElementWithBranch[$#VersionsofElementWithBranch];
	$LatestVersionOnBranch =~ s/\n//g;

	$BranchOnFile = substr($LatestVersionOnBranch, 0, index($LatestVersionOnBranch, $BranchType) + length($BranchType));
	
	$DescOnBranchOnElement = "cleartool desc ".$BranchOnFile;
	$DescOnBranchOnElementResult = `$DescOnBranchOnElement`;
	
	@DescOnBranchOnElementResultArray = split("\n", $DescOnBranchOnElementResult);
	
	foreach $Line (@DescOnBranchOnElementResultArray) {
		if (index($Line, "branched from version") > 0) {
			$BranchedFromVersion = substr($Line, index($Line, "branched from version") + length("branched from version: "));

			if ($Display eq "-V") {
				print "For element ".$LatestVersionOnBranch." --- ".$BranchType." branch taken from version ".$BranchedFromVersion."\n";
			} else {
				print $LatestVersionOnBranch."\t";
			}
			
			$VersionBranchedFrom = substr($BranchedFromVersion, rindex($BranchedFromVersion, "\\") + 1);
			$BranchHeaderPoint = substr($BranchedFromVersion, 1, rindex($BranchedFromVersion, "\\") - 1);
			
			if (index($BranchHeaderPoint, "\\") > 0) {
				$BranchHeaderPoint = substr($BranchHeaderPoint, rindex($BranchHeaderPoint, "\\") + 1);
			}
		
			$FindVersionsOnHeaderBranch = "cleartool find ".$Element." -version brtype(".$BranchHeaderPoint.") -print";
			@VersionsofElementOnHeaderBranch = `$FindVersionsOnHeaderBranch`;
			
			$LatestVersionOnHeaderBranch = @VersionsofElementOnHeaderBranch[$#VersionsofElementOnHeaderBranch];
			$LatestVersionNumberOnHeaderBranch = substr($LatestVersionOnHeaderBranch, rindex($LatestVersionOnHeaderBranch, "\\") + 1);
			$LatestFQVersionNumberOnHeaderBranch = substr($LatestVersionOnHeaderBranch, rindex($LatestVersionOnHeaderBranch, "@") + 1);
			
			if ($LatestVersionNumberOnHeaderBranch > $VersionBranchedFrom) {
				if ($Display eq "-V") {
					print "Work has been done on branch ".$BranchHeaderPoint." after ".$BranchType." was created on the element.\n";
				} else {
					print "branch from : ".$BranchedFromVersion."\t Latest Version : ".$LatestFQVersionNumberOnHeaderBranch;
				}
			}
			else {
				if ($Display eq "-V") {
					print "No work has been done on the ".$BranchHeaderPoint." since ".$BranchType." was created on the element.\n";
				} 
				elsif ($Display eq "-S") {
					print "\n";
				} else {
					print "branch from : ".$BranchedFromVersion."\t Latest Version : ".$LatestFQVersionNumberOnHeaderBranch;
				}
			}
		}
	}
}