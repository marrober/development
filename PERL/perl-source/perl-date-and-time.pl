@DateTime = gmtime(time);

$DateAndTime = sprintf("%02d", @DateTime[3])."/".sprintf("%02d", (@DateTime[4] + 1))."/".(@DateTime[5] + 1900)." ".sprintf("%02d", (@DateTime[2] + 1)).":".sprintf("%02d", @DateTime[1]).":".sprintf("%02d", @DateTime[0]);
print $DateAndTime."\n";
