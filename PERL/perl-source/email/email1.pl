# Email sender script.
#
use Net::SMTP;

my $smtp = Net::SMTP->new("ibmgb-mrober01",
                           Port => "30",
                           Timeout => 60, Debug => 1,);
print " ---- 1\n";
#print $smtp->auth("mark", "mark")."\n";
print " ---- 2\n";
$smtp->mail("mark\@mark.com");
$smtp->recipient("bruce\@mark.com");
$smtp->data("Subject: Hello bruce\r\nHi, this is for Bruce\r\n.");
print " ---- 3n";
$smtp->quit();



