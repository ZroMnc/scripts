#!/bin/bash
#
# enables Federation debugging through Debug.jsp

urlencode() {
    var=$1;
    out=$(perl -e '$uri=shift(); $uri =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg; print "$uri\n";' $var);
    echo $out;
}


user=amadmin
pass=$(cat /opt/openam/config/.pass)
uri=https://itr-am01.greendale.zalando.net:443

tokenid=$(curl -s -X POST -H "X-OpenAM-Username: $user" -H "X-OpenAM-Password: $pass" -H 'Content-Type: application/json' -d '{}' -k $uri/z/json/authenticate | jq '.["tokenId"]' | sed -e 's/\"//g')
formtoken=$(curl -k -X POST -d 'category=Federation&level=3' -H "Cookie: ZalandoSSO=$tokenid" $uri/z/Debug.jsp | grep '<input type="hidden" name="formToken" value=' | awk '{ print $4 }' | sed -e 's/value=\"//' | sed -e 's/\"//')
newformtoken=$(urlencode "$formtoken")
# now confirm
curl -k -X POST -d "category=Federation&level=3&do=true&formToken=$newformtoken" -H "Cookie: ZalandoSSO=$tokenid" $uri/z/Debug.jsp
