Midnight Home      Support Home      K Home     
 
Vantive Cases   Technotes   Sales   All   Defects & Cases   Old Cases   Case Report   Help    



[Previous Doc] [Next Doc] 

--------------------------------------------------------------------------------
Portal attachment folder for this case (exists only if there are attachments) 
Vantive CaseID: 370872 - $entity getting changed somehow?
This report ran (California Time): 2000-01-13 08:15:39

Reported By: Mr. Peter Vogel
Email: pvogel@iready.com
Phone: +1 (408)-330-4580

Summary:
________________ 
Priority _______ 3 - Medium
State __________ Researching
Queue __________ ClearQuest-NA
Initiated By ___ E-mail
Date Entered ___ 2000-01-11 16:03:07
Date Closed ____ 
Date Modified __ 2000-01-13 08:10:59
Reason Closed __ 
Defect Id ______ 
Company Name ___ Iready
Site ___________ Iready

Assigned To ____ Brian Pinkney
Assigned login _ bpinkney
Assigned email _ bpinkney@rational.com
Closed By ______ 
Closed By login_ 


Product Group __ CRM
Product Name ___ ClearQuest
Product Version_ 
Product Build __ 
Case Type ______ 
Platform _______ Intel x86
Application ____ 
OS Name ________ Unknown
OS Version _____ 
External # _____ 
Symptom ________ 
Keywords _______ 
Database _______ Vantive



--------------------------------------------------------------------------------

Number of Notes = 3

--------------------------------------------------------------------------------

Case Note 3
Action: Email-in
Visibility: External
Company: Iready
By: Peter Vogel
+1 (408)-330-4580 x
Email: pvogel@iready.com
Date Entered: 2000-01-12 18:18:33
Entered By: PortalUser

Subject: (p1 of 1) RE: New CaseID: v0370872 -- $entity getting changed som

Subject: (p1 of 1) RE: New CaseID: v0370872 -- $entity getting changed somehow?
From: pavogel@pacbell.net
To: p_support_na@rational.com
Cc: 
Date Sent: 01/12/2000 6:11:43 PM (PST)
Date Received: 01/12/2000 6:18:39 PM (PST)

This is still a problem, but I thought I'd let you know about a
workaround I built last night that seems to at least let me make
progress.

I defined a BASE type action with an Initialization script that
does this:
 $session->SetNameValue("MyEntity", $entity->GetDisplayName());

(Note, as a side issue that the documentation for NameValue handling
in PERL is completely wrong, the Perl interface has SetNameValue and
GetNameValue, not a NameValue interface as documented, although it would
be trivial to implement a NameValue routine that works as the documentation
implies, I found the correct call by searching CQPerlExt.pm)

Then, in the Validation scripts, I restore my entity by doing this:

my $entityid = $session->GetNameValue("MyEntity");
my $entity = $session->GetEntity("Defect", $entityid);

Seems to work relatively well, the actual solution is a bit more
complex so that the store/restore doesn't happen for submit actions,
etc.

Just thought you'd like to know.

Also, by using $entity->GetDefName() I verified that the problem is,
in fact, that the $entity is getting set to the $entity created by
the actions taken by the user (i.e. an Assignment entity or a different
Defect entity).

Thanks,
-Peter
> -----Original Message-----
> From: Rational Support (North America)
> [mailto:p_support_na@Rational.Com]
> Sent: Tuesday, January 11, 2000 4:03 PM
> To: 'Peter Vogel'
> Subject: New CaseID: v0370872 -- $entity getting changed somehow?
>
>
> New CaseID: v0370872
>
> Dear Customer,
>
> Thank you for using our products. A new case has been created
> in our call-tracking system from your e-mail:
>
> Subject: $entity getting changed somehow?
> Date:    1/11/00 4:00:51 PM
>
> Hi,
>
> I am seeing the following problem (Native UI):
>
> 1) User initiates a "Modify" action on a Defect record
> 2) During the course of the "Modify" action, the user clicks
> a button on the
> form
>     that creates an "Assignment" record with appropriate data
> and does the
> following
>     code: $entit
> ...End of Excerpt
>
> Your case has been assigned CaseID: v0370872. A member
> of our Technical Support staff will respond as soon as possible.
>
> If you want to add information to an existing case or inquire
> about the status of a case, you can send e-mail to one of the
> addresses listed at the end of this message and include the
> string "CaseID: v0370872" in the subject of your e-mail.
>
> For answers to frequently asked questions please visit our
> Technical Support web pages:
>
>         http://www.rational.com/support/
>
> For further information, urgent matters or any other assistance,
> contact one of our Technical Support centres:
>
> Region       Tel. #          E-mail                      Hours
> --------------------------------------------------------------
> ----------
> Asia/Pacific +61-2-9419 0111 support@apac.rational.com
> 8:00-18:00 AEST
>
> Europe,      +31-20-4546 200 support@europe.rational.com
> 9:00-17:30 MET
>   Middle-East,
>   Africa
>
> The Americas
>   East Coast +1-781-676 2450 support@rational.com
> 9:00-18:00 EST
>   West Coast +1-408-863 4000 support@rational.com
> 8:00-18:00 PST
>   Toll Free  +1-800-433 5444

--------------------------------------------------------------------------------

Case Note 2
Action: Call-in
Visibility: Internal
Company: Iready
By: Peter Vogel
+1 (408)-330-4580 x
Email: pvogel@iready.com
Date Entered: 2000-01-11 17:31:57
Entered By: bpinkney

Subject: 

Called in, his case was just assigned, no ETA.  PERL knowledge in CQ is weak 
(if it exists at all)  Asked him to send his schema.  Set his expectations low.

--------------------------------------------------------------------------------

Case Note 1
Action: Email-in
Visibility: External
Company: Iready
By: Peter Vogel
+1 (408)-330-4580 x
Email: pvogel@iready.com
Date Entered: 2000-01-11 16:03:08
Entered By: PortalUser

Subject: (p1 of 1) $entity getting changed somehow?

From: pvogel@iready.com
To: support@rational.com, jhassing@rational.com
Cc: 
Date Sent: 1/11/00 4:00:51 PM (PST)
Date Received: 1/11/00 4:02:46 PM (PST)

Hi,

I am seeing the following problem (Native UI):

1) User initiates a "Modify" action on a Defect record
2) During the course of the "Modify" action, the user clicks a button on the
form
   that creates an "Assignment" record with appropriate data and does the
following
   code: $entity->AddFieldValue("Assignments", $Asg) where $Asg is the
validate()d and
   commit()ed Assignment record.  OutputDebugMessage on entry and exit from
the 
   NewAsg record script indicates that $entity is the Defect record on
entry and on exit from
   the script.

3) However, when the user attempts to "Apply" the modifcations, the validate
script fails indicating
   that the "Project" field does not exist in the EntityDef.  Use of
OutputDebugMessage suggests
   that $entity has somehow been changed to a different entity, probably
the Assignment record that
   was created.

This does not appear to happen when "simple" modifications are made, and the
same code for creating
an assignment is used in the "validate" hook of the "submit" action.

The NewAsg script:
sub Defect_NewAsg {
   my($eventObject) = @_;
   my $result;
   # param is a CQEventObject
   my $session = $entity->GetSession();
        my $what = $entity->GetDisplayName();
        $session->OutputDebugMessage("Start NewAsg, what=$what\r\n");
        my $who = $session->GetUserLoginName();
        my $to = $entity->GetFieldValue("NewAsgTo")->GetValue();
        my $comment = $entity->GetFieldValue("NewAsgComment")->GetValue();
        my $Asg =  MakeAsg($session, $who, $to, $comment);
        $entity->AddFieldValue("Assignments", $Asg->GetDisplayName());
        my $what = $entity->GetDisplayName();
        $session->OutputDebugMessage("Done with NewAsg, what=$what\r\n");

   return $result;
}

The Validate script:
sub Defect_Validation {
   my($actionname, $actiontype) = @_;
   my $result;
   # $actionname as string scalar
   # $actiontype as long scalar
   # $result as string scalar
   # action = Modify
   my $session = $entity->GetSession();
        my $who = $session->GetUserLoginName();
        my $what = $entity->GetDisplayName();
        $session->OutputDebugMessage("In Modify validate: user=$who
what=$what\r\n");
         my $project = $entity->GetFieldValue("Project")->GetValue();
        $session->OutputDebugMessage("In Modify validate: project =
$project\r\n");
        if ($project) {
                my $Project = $session->GetEntity("Project", $project);
               my $owner = $Project->GetFieldValue("Owner")->GetValue();
          $session->OutputDebugMessage("In Modify validate: owner =
$owner\r\n");
               if ($owner && !HasAsgTo($session, $entity, $owner)) {
                       my $Asg = MakeAsg($session,$who,$owner,"Default
assignment to project lead\n");
                       $entity->AddFieldValue("Assignments",
$Asg->GetDisplayName());
               }
        }
        my $owner;
        $owner = $entity->GetFieldValue("EngOwner")->GetValue() if
($entity->GetFieldValue("EngOwnerSet")->GetValue());
        $session->OutputDebugMessage("In Modify validate: EngOwner =
$owner\r\n");

        my $module = $entity->GetFieldValue("Source")->GetValue();
        if ($module) {
                my $Module = $session->GetEntity("SrcModule", $module);
               $owner = $Module->GetFieldValue("EngOwner")->GetValue()
unless ($owner);
               $docowner = $Module->GetFieldValue("DocOwner")->GetValue();
               $entity->SetFieldValue("DocOwner", $docowner) if ($docowner
&& !($entity->GetFieldValue("DocOwnerSet")->GetValue()));
$entity->SetFieldValue("DocOwner", $docowner) if ($docowner &&
!($entity->GetFieldValue("DocOwnerSet")->GetValue()));
               $qaowner = $Module->GetFieldValue("QAOwner")->GetValue();
               $entity->SetFieldValue("QAOwner", $qaowner) if ($qaowner &&
!($entity->GetFieldValue("QAOwnerSet")->GetValue()));
        }
        if ($owner && !HasAsgTo($session, $entity, $owner)) {
                       my $Asg = MakeAsg($session,$who,$owner,"Default
assignment to source module owner\n");
                       $entity->AddFieldValue("Assignments",
$Asg->GetDisplayName());
        }
        $entity->SetFieldValue("EngOwner", $owner) unless
($entity->GetFieldValue("EngOwnerSet")->GetValue());
        $session->OutputDebugMessage("Done with Modify validate\r\n");

   return $result;
}

The relevant output from the DBWin:
258: Firing Pre Click Hook: NewAsgButton not associated with any control..!
258: Start NewAsg, what=TEST00000005
258: Done with NewAsg, what=TEST00000005
258: Using login locking scheme 0; timeout = 15000 ms.
258: Checking for Idle Sessions
258: In Modify validate: user=user what=33554504
258: AdEntity: The "Project" AdField cannot be gotten because it does not
exist.
Location: ClearQuest Core:adentity.cpp:575Execution of a hook failed during
the action Modify.  It was the ACTION_VALIDATION hook attached to the Defect
"TEST00000005".  The reason for the failure was:
AdEntity: The "Project" AdField cannot be gotten because it does not exist.
Location: ClearQuest Core:adentity.cpp:575 at C:\Program
Files\Rational\common\lib/CQPerlExt.pm line 1074.        

Notice the value of "what" on entry to Modify validate!

Please help!

Thanks,
-Peter
Peter A. Vogel
Release Engineering Manager
iReady Corporation
http://www.iready.com; http://www.iready.net

--------------------------------------------------------------------------------

Number of Audit Trail entries = 5
5. SW_CASE.SWSTATUS changed by PortalUser on 2000-01-12 18:18:33 from Waiting on customer to Researching 
4. SW_CASE.SWSTATUS changed by bpinkney on 2000-01-12 11:49:38 from New to Waiting on customer 
3. SW_CASE.RSMODIFIEDBY changed by bpinkney on 2000-01-11 17:32:55 from 631704 to 613104 
2. SW_CASE.RSMODIFIEDBY changed by dajones on 2000-01-11 16:42:49 from 403113 to 631704 
1. SW_CASE.SWASSIGNEDTO changed by dajones on 2000-01-11 16:42:49 from 390223 to 613104 


--------------------------------------------------------------------------------

[Previous Doc] [Next Doc] 
  
Vantive Cases   Technotes   Sales   All   Defects & Cases   Old Cases   Case Report   Help    



Questions or comments regarding Technical Support? support@Rational.Com 
Copyright © 1999 by Rational Software Corporation. INTERNAL USE ONLY.      
  
Midnight Home      Support Home      K Home     
 
Vantive Cases   Technotes   Sales   All   Defects & Cases   Old Cases   Case Report   Help    



[Previous Doc] [Next Doc] 

--------------------------------------------------------------------------------
Portal attachment folder for this case (exists only if there are attachments) 
Vantive CaseID: 363326 - Perl Scripts - Trouble with CreateObject Command.
This report ran (California Time): 2000-01-10 23:22:24

Reported By: Mr. George Andrews
Email: gandrews@rational.com


Summary:
________________ 
Priority _______ 3 - Medium
State __________ Closed
Queue __________ ClearQuest-NA
Initiated By ___ Phone
Date Entered ___ 1999-12-29 10:42:25
Date Closed ____ 2000-01-06 07:05:17
Date Modified __ 2000-01-06 07:05:23
Reason Closed __ Answered
Defect Id ______ 
Company Name ___ RATIONAL SOFTWARE CORP.
Site ___________ RATIONAL SOFTWARE CORP.

Assigned To ____ Betsy MacDonald
Assigned login _ bmac
Assigned email _ bmacdona@rational.com
Closed By ______ Betsy MacDonald
Closed By login_ bmac


Product Group __ CRM
Product Name ___ ClearQuest
Product Version_ 2.0
Product Build __ 
Case Type ______ 
Platform _______ 
Application ____ 
OS Name ________ 
OS Version _____ 
External # _____ 
Symptom ________ 
Keywords _______ 
Database _______ Vantive



--------------------------------------------------------------------------------

Number of Notes = 7

--------------------------------------------------------------------------------

Case Note 7
Action: Research
Visibility: Internal
Company: RATIONAL SOFTWARE CORP.
By: George Andrews
Email: gandrews@rational.com
Date Entered: 2000-01-06 07:05:01
Entered By: bmac

Subject: This is what mike came up with.

Hi Tanya, Betsy,
In the product meeting today I mentioned a Perl hook, so here it is.  You
might be able to learn from it or use it for reference, maybe even use parts
of it as an example, but the hook has limited application on it's own.
This is a ChoiceList hook, designed after the VB example in our hooks
database (which probably has the same limitations by the way).  It queries
the subscribed users, and adds the active ones to the choicelist.  The
limitation it has is that users subscribed implicitly to all databases are
not returned by GetSubscribedUsers, so to really get all the subscribed
users, you really need to test all users individually for SubsctibedToAllDbs
and combine those with those returned from GetSubscribedUsers (which returns
the list of users subscribed explicitly).
Anyway, the script is a great example for general Perl syntax, declaring
variables and arrays, conditional and looping structures, and particularly
valuable for showing the correct way to create a session object
(adminsession specifically) and adding choices to a choicelist, both of
which are substantially different than in VB.
Hope this helps.
Mike.


sub Owner_ChoiceList {
   my($fieldname) = @_;
   my @choices;
   # $fieldname as string scalar
   # @choices as string array
   # entityDef is ChangeRequest

       # Retrieve the login names of all the users
       # subscribing to the current database
       # who are also active users.
       #
       # This hook uses the default admin login information.
       # That information may need changing
       #
       my $session;
       my $currentDBDesc;
       my $currentDBName;
       my $adminSession;
       my $adminDB;
       my $subscribedUsers;
       my $userRecord;
       my $userCount;
       my $count;
       my $aUser;
       my $admUser = "admin";        # Administrator's username
       my $admPW = "";                # Administrator's password

       # get current session identifier
       $session = $entity->GetSession;

       # get Database description object
       $currentDBDesc = $session->GetSessionDatabase();

       # get current DB name for later use
       $currentDBName = $currentDBDesc->GetDatabaseName();

       # You might expect creating an Admin session to look like one of the
following
       #        $adminSession = 
$session->CreateObject("ClearQuest.AdminSession");
       #        $adminSession = 
$session->CreateObject("ClearQuest->AdminSession");

       # but in Perl, the approach is fundamentally different
       $adminSession = CQAdminSession::Build();

       # login
       $adminSession->Logon($admUser, $admPW, "");

       # get the user db object
       $adminDB = $adminSession->GetDatabase($currentDBName);

       # get explicitly subscribed users
       $subscribedUsers = $adminDB->GetSubscribedUsers();

       # get number of user records in the Users object
       $userCount =  $subscribedUsers->Count();
       $session->OutputDebugMessage("\nNumUsers:\n$userCount\n");

       # Loop over zero-based list of user records
       for ($count = 0; $count <= $userCount - 1; $count++)

               $userRecord = $subscribedUsers->Item($count);
                  if ($userRecord->GetActive()) {                              
                                                                 # Select only 
active users
                                       $aUser =  $userRecord->GetName();
                                       $session->OutputDebugMessage("\nActive 
User:\t$aUser\n");
                               # Add login names of active users to the 
choices array
                                       push(@choices, $aUser);
                                       }
       }

       # Alphabetize listing
       @choices = sort(@choices);
       $session->OutputDebugMessage("\nChoice list:\n@choices");

       return @choices;
}

--------------------------------------------------------------------------------

Case Note 6
Action: Email-internal
Visibility: Internal
Company: RATIONAL SOFTWARE CORP.
By: George Andrews
Email: gandrews@rational.com
Date Entered: 2000-01-04 12:57:43
Entered By: PortalUser

Subject: (p1 of 1) CaseID: v0363326 -- CQ: Calling Perl global script...

From: jveilleu@rational.com
To: bmacdona@rational.com, support@rational.com, ts_cq@rational.com
Cc: support@rational.com
Date Sent: 01/04/2000 12:57:22 PM (PST)
Date Received: 01/04/2000 12:57:43 PM (PST)

Betsy --

At 10:41 AM 1/4/00 , MacDonald, Betsy wrote:
>
>I'm glad that you asked those questions joe and its good to see that you
>haven't entirely disappeared ;)

Soon.

>First, the path does look mangled but it is accurate to the screen shot. I
>referenced the wrong case id above. Its actually  363326.
>
>Second, I put the script into my schema and was able to validate the syntax.
>However, I'm ashamed to say that I couldn't figure out how to call the
>script from the hook. In the midst of struggling with that, the tech rep
>sent an e-mail saying that he was getting some help from Mike Exum and they
>were able to work around the CreateObject error but they were still not
>getting the correct choices list. 

I'd be interested to know how they got around it; was it something
environmental or something in the code?

>Any ideas on what the hook code would look like to call this global script?

You call a global script by putting code into another script (an action or
field script) that calls the global script by using its function name.

For example if your global script is called "foo()" and it returns a
character value, you'd put some code into your action or field-level hook
like:

 var xx;
 set xx = foo();

Oops. That's VBScript syntax. Well, Perl's similar but my Perl is so rusty
I couldn't even reliably rattle-off the syntax for a program to call a
subroutine. It's something really simple (similar to the above) but I'd
have to go dig in my Perl books a bit to find the answer.

Let me look in some old Perl code I wrote.... ah, here we have it. Looks
like you define the subroutine using syntx like:

sub foo {
 # Body of the function goes here...
 # Last expression evaluated becomes the return value.
}

...and then you call it by including it in an expression and preceeding its
name with an ampersand; something like:

 local(xx);
 xx = &foo();

...actually I'm a little vague on whether those parentheses are necessary
if the function doesn't take any parameters, but whatever.... it's close...

Sorry I can't be more explicit/clear. Actually diving into Perl is going to
be something I'm going to do in earnest once I can shake free of a couple
of residual Support responsibilities (upgrading the Training and a couple
of cases I still own). If you're still having trouble with this by this
time next week I should be able to help you out a lot better.

>thanks,
>bets
>
>
>-----Original Message-----
>From: Joe Veilleux [mailto:jveilleu@Rational.Com]
>Sent: Tuesday, January 04, 2000 10:28 AM
>To: MacDonald, Betsy; 'ts_cq@rational.com'
>Cc: support@Rational.Com
>Subject: Re: Case ID: 361950
>
>
>
>Betsy --
>
>Are you 100% sure the message was transcribed accurately? The @INC path is
>supposed to contain a list of directory names to look in to resolve
>"included" files at runtime. The path as listed there looks kind-of mangled
>and I'm confused as to whether this is perhaps the actual problem or
>whether it's just a typing error.
>
>Did you try this global hook on your own system? What does it do?
>
>At 02:45 PM 12/29/99 , MacDonald, Betsy wrote:
>>
>>Hi All,
>>The perl script code below is failing with the following error:
>>"Execution of a hook failed during the action Submit. ... The reason for
>the
>>failure was:
>>Can't locate auto/CQSession/CreateObjec.al in @INC(@INC contain: C:\Program
>>Files\Rational\ClearQuest 2.0\C:\Program
>>Files\Rational\common\lib/MSWin32-x86 C:\Program Files\Rational\common\lib
>>C:\Program Files\Rational\connon\site\5.00502\lib C:\Program
>>
>>The hook code compiles with no errors. Any ideas would be appreciated.
>>
>># Start of Global Script SetActiveUserList
>>
>>sub SetActiveUserList  {
>># Retrieve the login names of all the users
>># subscribing to the current database 
>># who are also active users.
>>#
>># This hook uses the default admin login information.
>># That information may need changing
>>#
>>        my @choices;
>>        my $session;
>>        my $currentDB;
>>        my $currentDBName;
>>        my $adminSession;
>>        my $currentDBoad;
>>        my @subscribedUsers;
>>        my $userRecord;
>>        my $user;
>>        my $admPW = "";                # Administrator's password
>>
>>        $session = $entity->GetSession;                                # 
current
>>session
>>        $currentDB = $session->GetSessionDatabase();                # Database
>>description object
>>        $currentDBName = $currentDB->GetDatabaseName;                   # 
Current DB
>>name for later use
>>        $adminSession = $session->CreateObject("ClearQuest.AdminSession");
>># Create an AdminSession
>>        $adminSession->Logon("admin", $admPW, "");                        #
>>AdminSession login
>>        $currentDBoad = $adminSession->GetDatabase($currentDBName);        #
>>Second DB object for the admin session
>>        @subscribedUsers = $currentDBoad->GetSubscribedUsers();               
#
>>Get the 'collection' of user objects
>>
>>        foreach $userRecord (@subscribedUsers) {                # 
>>                if ($userRecord->active) {                        # Check the
>>Active property of each user record
>>                        push(@choices, $userRecord->GetName());        # Add 
the
>>active users to the choice list
>>                }
>>        }
>>
>>        @choices = sort(@choices);                                #
>>Alphabetize listing
>>
>>        $session->OutputDebugMessage("\nChoice list:\n@choices"); 
>>
>>        return  @choices
>>}
>># End of Global Script SetActiveUserList
>>
>>
>>Betsy MacDonald
>>Technical Support Engineer
>>Rational Software
>>1-800-433-5444
>>
>
>Please reply if you need any more assistance.
>
>IMPORTANT: To ensure prompt handling of your request, if you reply
>please send to 'support@rational.com' with "CaseID: vXXXXX" in your
>Subject field.
>
>---------------------------------------------------------------------
>Joe Veilleux
>Technical Support           Tel:   (800) 433-5444
>Rational Software Corp      Fax:   (408) 863-4001
>18880 Homestead Road        Email: support@rational.com
>Cupertino CA 95014          Web:   http://www.rational.com/support
>
>
>Y2K Readiness Alert! All ClearQuest customers please see:
>http://www.rational.com/technotes/crm_html/ClearQuest_html/technote_9681.htm
>l
>

Please reply if you need any more assistance.

IMPORTANT: To ensure prompt handling of your request, if you reply
please send to 'support@rational.com' with "CaseID: vXXXXX" in your
Subject field.

---------------------------------------------------------------------
Joe Veilleux
Technical Support           Tel:   (800) 433-5444
Rational Software Corp      Fax:   (408) 863-4001
18880 Homestead Road        Email: support@rational.com
Cupertino CA 95014          Web:   http://www.rational.com/support


Y2K Readiness Alert! All ClearQuest customers please see:
http://www.rational.com/technotes/crm_html/ClearQuest_html/technote_9681.html

--------------------------------------------------------------------------------

Case Note 5
Action: Email-internal
Visibility: Internal
Company: RATIONAL SOFTWARE CORP.
By: George Andrews
Email: gandrews@rational.com
Date Entered: 1999-12-30 16:09:53
Entered By: PortalUser

Subject: (p1 of 1) RE: CaseID: 363326

From: gandrews@rational.com
To: p_support_na@rational.com
Cc: 
Date Sent: 12/30/99 4:09:45 PM (PST)
Date Received: 12/30/99 4:09:54 PM (PST)

Betsy,

I'm working with a ClearQuest marketing engineer named Mike Exum. We've
worked around the CreateObject error, but we still don't get the correct
choices list. I'll keep you posted.

George

> -----Original Message-----
> From: MacDonald, Betsy [mailto:bmacdona@rational.com]
> Sent: Wednesday, December 29, 1999 3:02 PM
> To: 'gandrews@rational.com'
> Cc: Rational Support (North America)
> Subject: CaseID: 363326
>
>
> Hi George,
> Did you try changing the syntax to "ClearQuest->AdminSession"?  I
> agree that
> the api syntax looks a little suspicious and it wouldn't be the first time
> that the api help was wrong. I put the script and the error message out to
> TS_CQ but i haven't seen any response back yet. Please let me know if you
> get through this before I get an answer.
>
> Regards,
>
> Betsy
>
> Please include the above subject in all correspondences regarding
> this case.
>
> Betsy MacDonald                                 Support: 800-433-5444
> Technical Support                               Email:
> support@rational.com
> ClearQuest                        Rational Software
> http://www.rational.com                      Lexington, MA Office
>                                Unifying Software Teams
>
>
>

--------------------------------------------------------------------------------

Case Note 4
Action: Email-internal
Visibility: Internal
Company: RATIONAL SOFTWARE CORP.
By: George Andrews
Email: gandrews@rational.com
Date Entered: 1999-12-29 17:04:51
Entered By: PortalUser

Subject: (p1 of 1) RE: CaseID: 363326

From: gandrews@rational.com
To: p_support_na@rational.com
Cc: 
Date Sent: 12/29/99 5:04:36 PM (PST)
Date Received: 12/29/99 5:04:47 PM (PST)

Betsy,

I tried that syntax and it didn't work either.

As I see it, the only reason for creating the AdminSession is so we get an
identifier for the current database. We need that identifier to get the
Users object. Is there any way to get that identifier from within the
session the we start out in?

George

> -----Original Message-----
> From: MacDonald, Betsy [mailto:bmacdona@rational.com]
> Sent: Wednesday, December 29, 1999 3:02 PM
> To: 'gandrews@rational.com'
> Cc: Rational Support (North America)
> Subject: CaseID: 363326
>
>
> Hi George,
> Did you try changing the syntax to "ClearQuest->AdminSession"?  I
> agree that
> the api syntax looks a little suspicious and it wouldn't be the first time
> that the api help was wrong. I put the script and the error message out to
> TS_CQ but i haven't seen any response back yet. Please let me know if you
> get through this before I get an answer.
>
> Regards,
>
> Betsy
>
> Please include the above subject in all correspondences regarding
> this case.
>
> Betsy MacDonald                                 Support: 800-433-5444
> Technical Support                               Email:
> support@rational.com
> ClearQuest                        Rational Software
> http://www.rational.com                      Lexington, MA Office
>                                Unifying Software Teams
>
>
>

--------------------------------------------------------------------------------

Case Note 3
Action: Email-internal
Visibility: Internal
Company: RATIONAL SOFTWARE CORP.
By: George Andrews
Email: gandrews@rational.com
Date Entered: 1999-12-29 15:10:19
Entered By: PortalUser

Subject: (p1 of 1) CaseID: 363326

From: bmacdona@rational.com
To: gandrews@rational.com
Cc: p_support_na@rational.com
Date Sent: 12/29/1999 3:02:14 PM (PST)
Date Received: 12/29/1999 3:10:18 PM (PST)

Hi George,
Did you try changing the syntax to "ClearQuest->AdminSession"?  I agree that 
the api syntax looks a little suspicious and it wouldn't be the first time that 
the api help was wrong. I put the script and the error message out to TS_CQ but 
i haven't seen any response back yet. Please let me know if you get through 
this before I get an answer.

Regards,

Betsy        

Please include the above subject in all correspondences regarding this case.

Betsy MacDonald                                 Support: 800-433-5444 
Technical Support                               Email: support@rational.com
ClearQuest                        Rational Software 
http://www.rational.com                      Lexington, MA Office 
                              Unifying Software Teams

--------------------------------------------------------------------------------

Case Note 2
Action: Email-internal
Visibility: Internal
Company: RATIONAL SOFTWARE CORP.
By: George Andrews
Email: gandrews@rational.com
Date Entered: 1999-12-29 11:32:27
Entered By: PortalUser

Subject: (p1 of 1) Case ID: 363326

PORTAL NOTES
Attachments For this Message are located at: 
ftp://portal1.rational.com/v0xxxxxx/v036xxxx/v03633xx/v0363326/
END PORTAL NOTES
From: gandrews@rational.com
To: bmacdona@rational.com
Cc: support@rational.com, gandrews@rational.com
Date Sent: 12/29/1999 11:32:00 AM (PST)
Date Received: 12/29/1999 11:32:23 AM (PST)

Betsy,

I have attached the Perl script and a screen capture of the error message
that it generated.

This may be a separate issue, but here are a couple of things about the
documentation of CreateObject
       There is no description of CreateObject as a method of the session 
object.
I found the syntax description in the introductory chapters, on pages 23 and
33.

       The syntax that should create an AdminSession is:
               $adminSession = 
$session->CreateObject("ClearQuest.AdminSession");
       It contains a quoted sring that uses VBScript notation. For Perl, should
this string be:
               "ClearQuest->AdminSession"

Thanks for your help,
George

--------------------------------------------------------------------------------

Case Note 1
Action: Call-in
Visibility: Internal
Date Entered: 1999-12-29 10:43:27
Entered By: bmac

Subject: 

I've got the API Manual - Page 23 - CurrentSessionObject to create separate 
section.
Tries to execute command - 
Compiles commnad.
Can't locate auto/CQSESSION/CREATEOBJ

at INC contains - path variable 

Having him send error message. will post to ts_cq and he will post to cqinfo.

--------------------------------------------------------------------------------

Number of Audit Trail entries = 6
6. SW_CASE.SWREASONCLOSED changed by bmac on 2000-01-06 07:05:24 from "" to Answered 
5. SW_CASE.SWDATERESOLVED changed by bmac on 2000-01-06 07:05:24 from "" to 2000-01-06 07:05:17 
4. SW_CASE.SWSTATUS changed by bmac on 2000-01-06 07:05:24 from Researching to Closed 
3. SW_CASE.SWSTATUS changed by PortalUser on 2000-01-04 12:57:43 from Waiting on customer to Researching 
2. SW_CASE.SWSTATUS changed by bmac on 2000-01-03 05:47:00 from Researching to Waiting on customer 
1. SW_CASE.SWSTATUS changed by bmac on 1999-12-29 11:35:36 from New to Researching 


--------------------------------------------------------------------------------

[Previous Doc] [Next Doc] 
  
Vantive Cases   Technotes   Sales   All   Defects & Cases   Old Cases   Case Report   Help    



Questions or comments regarding Technical Support? support@Rational.Com 
Copyright © 1999 by Rational Software Corporation. INTERNAL USE ONLY.      
  
