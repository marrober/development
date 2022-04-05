#!/bin/sh
# run_me.sh
#    runs Innotech's search server with a configuration file in
#    /tmp/netresults
# run_me.sh tempdir
#    will run the server with a configuration file in
#    tempdir/netresults

# Find the Java interpreter
if [ $JRE"X" = "X" ]
then
    if [ \( ! `which jre`"X" = "X" \) -a \( ! -d `which jre` \) -a -x `which jre` ]
    then
	JRE=`which jre`
    elif [ \( ! `which java`"X" = "X" \) -a \( ! -d `which java` \) -a -x `which java` ]
    then
	JRE=`which java`
    else
	echo "There is no Java interpreter in your executable search path.  Please"
	echo "make sure you have an interpreter (such as \"jre\" or \"java\") installed."
	echo "Then make sure that the executable is in your path, or set the JRE"
	echo "environment variable to point to it."
	exit 1
    fi
elif [ ! -x $JRE ]
then
    echo "You have set the JRE environment variable, but the file it points to"
    echo "is not an executable.  Please unset the variable, or verify that it"
    echo "points to your executable Java interpreter."
    exit 1
fi

if [ ! \( $1"X" = "X" -o -d "$1" \) ]
then
    echo "Usage:"
    echo "$0"
    echo "   will run the server with a configuration file in"
    echo "   /tmp/netresults"
    echo "$0 tempdir"
    echo "   will run the server with a configuration file in"
    echo "   tempdir/netresults"
    exit 2
fi

# The first parameter, if specified, should be the temporary
# directory.

if [ $1"X" = "X" ]
then
    tempdir="/tmp"
else
    tempdir=$1
fi

# If the NetResults directory has been created, we check for the
# HTTP-based configuration file.

if [ -d $tempdir"/netresults" ]
then

    # If the HTTP-based configuration file doesn't exist, create it.

    if [ ! -f $tempdir"/netresults/http-nr.cfg" -a -f $tempdir"/netresults/Server.cfg" ]
    then
	sed "s/^\(NO_RESULT_URL.*STRING \)[^ ]*/\1http:\/\/localhost:6016\/noResults.html/; s/^\(TEMP_HTML_URL.*STRING \)[^ ]*/\1http:\/\/localhost:6016\//" < $tempdir"/netresults/Server.cfg" > $tempdir"/netresults/http-nr.cfg"

	# Run the server with the HTTP config file.

	cd netresults
	$JRE -cp . -mx16m -ms8m itm.nr.serve.NRServer +prop=$tempdir"/netresults/http-nr.cfg"

    else
	# Run the server with the default file.

	cd netresults
	$JRE -cp . -mx16m -ms8m itm.nr.serve.NRServer	
    fi

else
    # Run the server with the default file.

    cd netresults
    $JRE -cp . -mx16m -ms8m itm.nr.serve.NRServer
fi

