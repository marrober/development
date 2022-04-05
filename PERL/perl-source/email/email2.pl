# Email sender script.
#
use MIME::Base64 qw(encode_base64);
use MIME::Entity;

   open(FILE, "c:\\temp\\qetxt.ini") or die "$!";
   while (read(FILE, $buf, 60*57)) {
       print encode_base64($buf);
   }

my $msg = MIME::Entity->build(From    => "mark@mark.com",
                              To      => "bruce@mark.com",
                              Cc      => "",
                              Subject => "Subject Line",
                              Type    => 'multipart/mixed',
                              'X-Version' =>
                              's.m.o.t. v1.2, '.
                              'Tk 804.26, Perl 5.8.2');



