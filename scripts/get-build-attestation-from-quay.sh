## Partially done.....

payload=$(cosign download attestation $1 | jq .payload)

decodedpayload=$(echo -n $payload | base64 -d )

echo $decodedpayload