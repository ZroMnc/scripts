#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#VARS
ENVIRONMENT=${1:-}
HOST=''
#HOST_DEV='https://dev-aws-am.greendale-staging.zalan.do'
HOST_DEV='https://dev-aws-am-ff.greendale-staging.zalan.do'
HOST_LOCAL='https://dev-iamamall.greendale.zalando.net'
#HOST_TEST='https://test-aws-am.greendale-staging.zalan.do'
HOST_TEST='https://test-aws-am-ff.greendale-staging.zalan.do'

if [ "$ENVIRONMENT" == 'dev' ]; then
    HOST=$HOST_DEV
    printf "[+] Using =>  $HOST \n"
fi
if [ "$ENVIRONMENT" == 'local' ]; then
    HOST=$HOST_LOCAL
    printf "[+] Using =>  $HOST \n"
fi
if [ "$ENVIRONMENT" == 'test' ]; then
    HOST=$HOST_TEST
    printf "[+] Using =>  $HOST \n"
fi
if [ -z "$ENVIRONMENT" ]; then
    print "[!] Error Missing Environment [test], [dev] or [local]"
    exit 0
fi


AUTH_HDR_SERVICE=$( echo -n 'testclient:iam@zal123' | base64 )
#AUTH_HDR_SERVICE=$( echo -n 'centiro-faf5cf35-c977-427c-922e-31262e3b1b1a:8a9f962f-b53b-48bb-ae09-d010d2d6a985' | base64 )
#AUTH_HDR_SERVICE=$( echo -n 'centiro-faf5cf35-c977-427c-922e-31262e3b1b1a:8a9f962f5' | base64 )
SERVICE_USER="testservice"
SERVICE_PASS="iamdev@zal123"
#SERVICE_USER="0fc215db-addf-4cbb-9b04-54f7724db3ed"
#SERVICE_PASS="dzYDSTzk42lrlklr34k9k2lkl2k3"

AUTH_HDR_TENANT=$( echo -n 'testclient:iam@tenant123' | base64 )
TENANT_USER="tenant-usr"
TENANT_PASS="iam@tenant123"

#AUTH_HDR_CUS=$( echo -n 'greendale_5e61b4ed-198b-4b99-bf4c-fab2f0c44197:29d732c6-cbf9-4196-a8e5-4adaeb4f9ff8' | base64 )
#AUTH_HDR_CUS=$( echo -n 'greendale-dev-testclient-5e61b4ed-198b-4b99-bf4c-fab2f0c44197:F)yR]9JTvGb).(LTQP)$H"^*B6J]j:' | base64 )
AUTH_HDR_CUS=$( echo -n 'testclient:iam@zal123' | base64 )
#AUTH_HDR_CUS=$( echo -n 'iamtestclient:iam@zal123' | base64 )

#CUS_PASS="8kZXrXUeE-QDMKo_eSw9"
#CUS_USER="christian.kunert@zalando.de"
CUS_USER="test@customer.com"
CUS_PASS="iamdev@zal123"

SERVICE=$(curl -s -k -X POST --header "Authorization: Basic $AUTH_HDR_SERVICE" --data "grant_type=password&username=$SERVICE_USER&password=$SERVICE_PASS&scope=openid uid cn" "$HOST/z/oauth2/access_token?realm=/services")
TENANT=$(curl -s -k -X POST --header "Authorization: Basic $AUTH_HDR_TENANT" --data "grant_type=password&username=$TENANT_USER&password=$TENANT_PASS" "$HOST/z/oauth2/access_token?realm=/tenants")
CUS=$(curl -s -k -X POST --header "Authorization: Basic $AUTH_HDR_CUS" --data "grant_type=password&username=$CUS_USER&password=$CUS_PASS&scope=uid mail openid sn givenName" "$HOST/z/oauth2/access_token?realm=/customers")
CUS_MOBILE=$(curl -s -k -X POST --header "Authorization: Basic $AUTH_HDR_CUS" --data "grant_type=password&username=$CUS_USER&password=$CUS_PASS" "$HOST/z/oauth2/access_token?realm=/customers-mobile")
printf "[+]\tService Realm\n\t[-]-Result:\t$SERVICE\n"
printf "[+]\tTenant Realm\n\t[-]-Result:\t$TENANT\n"
printf "[+]\tCustomer Realm\n\t[-]-Result:\t$CUS\n"
printf "[+]\tCustomer Mobile Realm\n\t[-]-Result:\t$CUS_MOBILE\n"
