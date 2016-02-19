#!/bin/bash
#set -euo pipefail
#IFS=$'\n\t'

#VARS
TOKEN=""
OAUTH_TOKEN=""
PREVIOUS_OAUTH_TOKEN=""
TOKENINFO="https://auth.zalando.com/oauth2/tokeninfo?access_token"
APPJSON=""
CLIENTJSON=""
service=$1

json_decode () {
    echo -n "$1" | jq -r ."$2"
}

url_encode () {
    echo -n "$1" | perl -pe 's/([^a-zA-Z0-9])/"%".sprintf("%x", ord($1))/ge'
}

get_service_token () {

    APP_PASS=$( json_decode "$APPJSON" "application_password" )
    APP_NAME=$( json_decode "$APPJSON" "application_username" )
    CLIENT_ID=$( json_decode "$CLIENTJSON" "client_id" )
    CLIENT_SECRET=$( json_decode "$CLIENTJSON" "client_secret" )
    AUTH_HDR=$( echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64 | tr -d ' \n' )
    USER_ID=$( url_encode "$APP_NAME" )
    USER_PASS=$( url_encode "$APP_PASS" )

    TOKEN=$(curl -s -X POST --header "Authorization: Basic $AUTH_HDR" --data "grant_type=password&username=$USER_ID&password=$USER_PASS&scope=uid customer.write" "https://auth.zalando.com/oauth2/access_token?realm=/services")
    VAR2=$(echo -n $TOKEN | jq -r '[.access_token // .code]' | tr -d '[]')
    OAUTH_TOKEN=$( echo $VAR2 | tr -d '""' | awk '{gsub(/^ +| +$/,"")} {print $0 }')
    response=$(curl -s -H "Authorization: Bearer $OAUTH_TOKEN" "$TOKENINFO")
    printf "[+] TOKENINFO\n"
    echo $response | jq .

}

get_credentials () {
    printf "[+] Getting AWS Credentials to download OAuth Foo\n"
    mai login production
    printf "[+] Downloading user.json and client.json from S3\n"
    aws s3api get-object --bucket  zalando-stups-mint-356702503974-eu-west-1 --key $service/user.json user.json
    aws s3api get-object --bucket  zalando-stups-mint-356702503974-eu-west-1 --key $service/client.json client.json
    APPJSON=$(cat user.json)
    CLIENTJSON=$(cat client.json)
}

main () {
# Add A customer_login directly to openam vs. tusk
    get_credentials
    get_service_token
    printf "[+] Done\n"
}

main
