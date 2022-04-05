use Date::Parse;
use POSIX qw(strftime);

$imageList = `oc get is/liberty-rest-app -o jsonpath='{range .status.tags[*]}{.tag}{" "}{.items[*].created}{"\\n"}'`;

@imageArray = split(/\n/, $imageList);

foreach $image (@imageArray) {
    print("===============================================\n");
    print $image."\n";
    @tagDate = split(/ /, $image);
    @dates = reverse(@tagDate);
    $tag = pop(@dates);
    
    print("----------------------------------------------\n");
    $recentDate = "";
    foreach $date (@dates) {
        print($date."\n");
        $dateFormat = str2time($date);
        print($dateFormat."\n");
        if ($dateFormat > $recentDate) {
            $recentDate = $dateFormat;
            print "new recent date : ".$dateFormat."\n";
        }
    }  
    $imageStreamHash{$recentDate} = $tag;
}

foreach my $key (sort(keys %imageStreamHash) ){
    print($imageStreamHash{"$key"}."\t".$key,"\n");
    print localtime();
    $datestring = strftime "%a %b %e %H:%M:%S %Y", localtime();
    print $datestring."\n";
}

