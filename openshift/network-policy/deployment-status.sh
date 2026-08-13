#!/bin/bash

# Ensure required variables are set
if [ -z "$ROX_API_TOKEN" ] || [ -z "$ACS_CENTRAL_URL" ]; then
    echo "Error: ROX_API_TOKEN and ACS_CENTRAL_URL must be set."
    exit 1
fi

# Fetch unique deployment names
deployments=$(curl -s -X GET -k -H "authorization: Bearer $ROX_API_TOKEN" "$ACS_CENTRAL_URL/v1/deployments" | jq '.deployments[].name' | awk '{gsub(/"/, ""); print}')

# Loop through each deployment name
echo "$deployments" | while read -r deploymentName; do
    # Skip empty lines if any
    [ -z "$deploymentName" ] && continue

    # Fetch the deployment ID from the deployment name and remove quotes
    deploymentID=$(curl -s -X GET -k -H "authorization: Bearer $ROX_API_TOKEN" "$ACS_CENTRAL_URL/v1/deployments" | jq --arg deploymentName "$deploymentName" '.deployments[] | select(.name == $deploymentName).id' | awk '{print substr($0, 2, length($0)-2)}')

    # Skip if no ID was found for the deployment name
    [ -z "$deploymentID" ] && echo "Deployment: $deploymentName | Error: ID not found" && continue

    # Fetch the locked status using the deployment ID
    locked_status=$(curl -s -X GET -k \
        -H "authorization: Bearer $ROX_API_TOKEN" \
        -H "Content-Type: application/json" \
        "$ACS_CENTRAL_URL/v1/networkbaseline/$deploymentID" | jq '.locked')

    # Present the result alongside the deployment name
    echo "Deployment: $deploymentName | Locked: $locked_status"
done

