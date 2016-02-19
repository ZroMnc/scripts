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
SHOPJSON=""
POSTBODY=""
AUTH_SHOP_HDR=""
CETECEAN="https://cetacean.greendale.zalan.do/api/customers/"
TUSK="https://tusk.greendale.zalan.do/api/tokens/"

#TEST VALUE
#CUSTOMER_NUMBER="c7e0580b-78dd-45a6-bc0d-26ed4017c7c0"
#EMAIL="han.solo@millennium-falcon.rebels"
#EMAIL2="han.solo@retirement.rebels"
#FIRSTNAME="Han"
#LASTNAME="Solo"
#PASSWORD="c7e0580b-78dd-45a6-bc0d-26ed4017c7c0"
PASSWORD="8kZXrXUeE-QDMKo_eSw9"
#PASSWORD="\$08\$LVSZJlKDSMfTOxcq3zQfAeJ7gvRASUZ0FjQmgcLPat7g27zG3hAtS"
EMAIL="christian.kunert@zalando.de"

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

get_customer_client_header () {
    CLIENT_ID=$( json_decode "$SHOPJSON" "client_id" )
    CLIENT_SECRET=$( json_decode "$SHOPJSON" "client_secret" )
    AUTH_SHOP_HDR=$( echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64 | tr -d ' \n' )
}

get_credentials () {
    printf "[+] Getting AWS Credentials to download OAuth Foo\n"
    mai login production
    printf "[+] Downloading user.json and client.json from S3\n"
    aws s3api get-object --bucket  zalando-stups-mint-356702503974-eu-west-1 --key marauder/user.json user.json
    aws s3api get-object --bucket  zalando-stups-mint-356702503974-eu-west-1 --key marauder/client.json client.json
    aws s3api get-object --bucket  shop-client-618c02d8-b8b5-469d-96fc-0ede5b004e3d --key shop/shop-client.json shop-client.json
    APPJSON=$(cat user.json)
    CLIENTJSON=$(cat client.json)
    SHOPJSON=$(cat shop-client.json)
}

create_customer () {
    printf "[+] Creating Customer\n"
    data="{\"customer_number\":\"${CUSTOMER_NUMBER}\",\"email\":\"${EMAIL}\",\"first_name\": \"${FIRSTNAME}\",\"last_name\": \"${LASTNAME}\",\"encrypted_password\": \"${PASSWORD}\"}"
    echo $data | jq .
    response=$(curl -k -s -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTH_TOKEN" --data "$data" "$CETECEAN" )
    echo $response | jq .
}

update_customer () {
    printf "[+] Update Customer\n"
    data="{\"email\":\"${EMAIL2}\"}"
    echo $data | jq .
    response=$(curl -X PATCH -k -s -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTH_TOKEN" --data "$data" "$CETECEAN/$CUSTOMER_NUMBER/" )
    echo $response | jq .
}

login_customer_email_tusk () {
    printf "[+] Login Customer via Tusk with $EMAIL\n"
    data="{ \"username\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"scopes\": [\"uid\", \"openid\", \"mail\"]}"
    echo $data | jq .
    response=$(curl -s -k -X POST -H "Content-Type: application/json" -H "If-None-Match: *" -H "Accept: application/shop.token+json" -H "Authorization: Basic $AUTH_SHOP_HDR" --data "$data" "$TUSK")
    echo $response  | jq .
}

login_customer_email_am () {
    printf "[+] Login Customer via OpenAM with $EMAIL\n"
    data="grant_type=password&username=$EMAIL&password=$PASSWORD&scope=uid%20openid%20mail"
    echo $data
    response=$(curl -s -k -X POST -H "Host: auth.zalando.com" -H "Authorization: Basic $AUTH__SHOP_HDR" --data "$data" "https://aws-am.greendale.zalan.do/z/oauth2/access_token?realm=customers")
    echo $response | jq .
}

login_customer_updated_email () {
    printf "[+] Login Customer with $EMAIL2\n"
    data="{ \"username\":\"${EMAIL2}\",\"password\":\"${PASSWORD}\",\"scopes\": [\"uid\", \"openid\", \"mail\"]}"
    echo $data | jq .
    response=$(curl -s  -k -X POST -H "Content-Type: application/json" -H "If-None-Match: *" -H "Accept: application/shop.token+json" -H "Authorization: Basic $AUTH_SHOP_HDR" --data "$data" "$TUSK")
    echo $response  | jq .
}

remove_customer () {
    printf "[+] Deleting Customer\n"
    response=$(curl -k -s -X DELETE -H "Content-Type: application/json" -H "Authorization: Bearer $OAUTH_TOKEN" "$CETECEAN$CUSTOMER_NUMBER" )
    echo $response
}

main () {
# Add A customer_login directly to openam vs. tusk
    get_credentials
    get_service_token
#    get_customer_client_header
#    create_customer
    login_customer_email_tusk
    login_customer_email_am
#    update_customer
#    login_customer_updated_email
#    remove_customer
    printf "[+] Done\n"
}

main
