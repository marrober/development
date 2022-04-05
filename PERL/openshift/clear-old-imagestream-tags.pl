use Date::Parse;

$imageList = `oc get is/liberty-rest-app -o jsonpath='{range .status.tags[*]}{.tag}{" "}{.items[*].created}{"\\n"}'`;

@imageArray = split(/\n/, $imageList);

foreach $image (@imageArray) {
    print("===============================================\n");
    print $image."\n";
    @tagDate = split(/ /, $image);
    @dates = reverse(@tagDate);
    $tag = pop(@dates);
    
    $deleteTag = false;
    $now = time;
    print "now : ".$now."\n";
    $timeLimit = $now - 24*60*60;
    print "time limit : ".$timeLimit."\n";

    print("----------------------------------------------\n");
    foreach $date (@dates) {
        print($date."\n");
        $dateFormat = str2time($date);
        print($dateFormat."\n");
        if ($dateFormat < $timeLimit) {
            print("Tag is older than 24 hours\n");
            `oc delete tag
        }

    }

    
}

