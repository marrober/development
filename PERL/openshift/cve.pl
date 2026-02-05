#!/usr/bin/perl
use strict;
use warnings;
use JSON;

my $centralURL = 'https://central-stackrox.apps.ocp4.mr-openshift.co.uk';
my $rox_token = $ENV{'ROX_API_TOKEN'};

my $apiImageEndpoint = '/v1/images';
my $endpointQuery = 'query=CVE:CVE-2024-45337';

my $command = "curl -s -X GET -k -H 'authorization: Bearer $rox_token' '$centralURL$apiImageEndpoint?$endpointQuery'";

my $response = `$command`;

my $json = JSON->new();
my $data = $json->decode($response);

my @images;

if (ref($data) eq 'HASH' && exists $data->{images}) {
    foreach my $image (@{$data->{images}}) {
        push @images, $image->{name};
    }
}

print "Images\n";

foreach my $image (@images) { 
    print $image."\n";
}

## Get the deployments associated with each container image.

print " Deployments associated with the images\n";

my @deploymentImages;

foreach my $image (@images) { 

    my $getDeploymentCommand = "oc get deployment -A  -o json | jq -r '.items[] | .metadata.name as \$dep | .spec.template.spec.containers[].image | \"\\(\$dep) \\(.)\"' | grep $image";

    my $deploymentResponse = `$getDeploymentCommand`;

    print " image : ".$image."\n";
    print "--- ".$deploymentResponse."\n";

    if (length($deploymentResponse) < 10) {
        print "Image no longer in use : ".$image."\n";
    } else {
        my @deploymentParts = split(/ /, $deploymentResponse);
        my %deploymentHash = (deployment => $deploymentParts[0], image => $deploymentParts[1]);

        push @deploymentImages, \%deploymentHash;
    }
}

foreach my $deploymentImages (@deploymentImages) {
    print sprintf("%-50s %s", $deploymentImages->{deployment}, $deploymentImages->{image});
}