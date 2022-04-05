#use Win32::NetAdmin;
#use Win32::AdminMisc;
use Win32::OLE;
use Win32::NetAdmin;
use Win32::AdminMisc;
Win32::NetAdmin::GetDomainController("","",$name) || die "problem getting DC: $!\n";
@users = ();
Win32::NetAdmin::GetUsers($name, Win32::NetAdmin::FILTER_NORMAL_ACCOUNT, \@users);
$adsession = Win32::OLE->new('CLEARQUEST.ADMINSESSION');
$adsession->Logon("admin", "","");
%cqspecial = (admin=>1,mailuser=>1,cqweb=>1);
%known_alias = (jtest=>1,editor=>1,editor1=>1,labtest=>1);
map {$users{$_->{Name}} = $_; } Win32::OLE::in($adsession->{Users});
@cqdbs = Win32::OLE::in($adsession->{Databases});
foreach my $username (@users) {
    next if $username =~ /\$$/;
    next if $username =~ /^admin$/;
    $username =~ tr/[A-Z]/[a-z]/;
	
	print $username."\n";

#    $visited{$username}++;
#    Win32::AdminMisc::UserGetMiscAttributes("", $username, \%attribs);

#    my $disabled  = ($attribs{USER_FLAGS} & UF_ACCOUNTDISABLE);
#    my $comment = $attribs{USER_COMMENT};
#    $disabled=1 if ($disabled or 
#		    $comment =~ /^ALIAS:/ or 
#		    $known_alias{$username});
#    $disabled=0 if ($cqspecial{$username});
#    my $user = $users{$username};
#    if (!$disabled && !defined($user)) {
#	print "need to add $username: $comment\n";
#  	$user = $adsession->CreateUser($username);
#  	$user->{Active} = 1;
#  	$user->{AppBuilder} = 0;
#  	$user->{Email} = "$username\@rational.com";
#  	$user->{Fullname} = $attribs{USER_FULL_NAME};
#  	$user->{MiscInfo} = $comment;
#  	$user->{SuperUser} = 0;
#  	$user->{UserMaintainer} = 0;
#  	$user->{Password} = $username;
#  	foreach my $db (@cqdbs) {
#  	    $user->SubscribeDatabase($db);
#  	}
#  	print "added $username\n";
#    } elsif (defined($user)) {
#	my $was_active = $user->{Active};
#	$user->{Active} = ($disabled) ? 0 : 1;
#	$str = ($user->{Active}) ? "Activated" : "Deactivated";
#	print "$str $username\n" if ($user->{Active} != $was_active);
# 	$user->{Email} = "$username\@corp.iready.com";
#  	$user->{Fullname} = $attribs{USER_FULL_NAME};
#  	$user->{MiscInfo} = $comment;
#    }
}
map {
    unless ($visited{$_}) {
	print "no NT account for $_\n" if $users{$_}->{Active};
	$users{$_}->{Active}=0 unless $cqspecial{$_};
    }
} keys %users;

