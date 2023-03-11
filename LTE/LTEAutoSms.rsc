# LTE sms sender;
# 0.10
# 2022/09/26
:local lteIP "192.168.8.1";
:local phone "900";
:local sms "perevod";

:if ( [/interface find name="lte1"] ) do={
    :local getBetween do={
        # "CuriousKiwi - mikrotik forum" 
        # This is a basic parser, can be used for XML
        # It takes three parameters:
        # inputString - The main string
        # betweenStart - Text AFTER this point will be returned
        # betweenEnd - Text BEFORE this point will be returned
        :local posStart 0;
        :if ([:len $betweenStart] > 0) do={
        :set posStart [:find $inputString $betweenStart]
            :if ([:len $posStart] = 0) do={
                :set posStart 0
            } else={
                :set posStart ($posStart + [:len $betweenStart])
            }
        }
        :local posEnd 9999;
        :if ([:len $betweenEnd] > 0) do={
        :set posEnd [:find $inputString $betweenEnd];
        :if ([:len $posEnd] = 0) do={ :set posEnd 9999 }
        }
        :local result [:pick $inputString $posStart $posEnd];
        :return $result;
    }
    :do {
    	# get SessionID and Token via LTE modem API
    	:local urlSesTokInfo "http://$lteIP/api/webserver/SesTokInfo";
    	:local api [/tool fetch $urlSesTokInfo output=user as-value]; 
    	:local apiData  ($api->"data");

    	# pars SessionID and Token from API session data 
    	:local apiSessionID [$getBetween inputString=$apiData betweenStart="<SesInfo>" betweenEnd="</SesInfo>"];
    	:local apiToken [$getBetween inputString=$apiData betweenStart="<TokInfo>" betweenEnd="</TokInfo>"];

    	# header and data config
    	:local apiHead "Content-Type:application/x-www-form-urlencoded,Cookie: $apiSessionID,__RequestVerificationToken:$apiToken";
    	:local sendData "<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Index>-1</Index><Phones><Phone>$phone</Phone></Phones><Sca></Sca><Content>$sms</Content><Length>-1</Length><Reserved>1</Reserved><Date>-1</Date></request>";

    	# send SMS via LTE modem API with fetch
    	/tool fetch  http-method=post output=user  \
    	http-header-field=$apiHead \
    	url="http://$lteIP/api/sms/send-sms" \
    	http-data=$sendData;
    	/log warning "LTE sms from \"*NUM\" succesfully sent.";
    } on-error={ /log warning "LTE sms from \"*NUM\" failed!."; }
}
