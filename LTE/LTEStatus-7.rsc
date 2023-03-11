## LTEStatus
## 0.51 / 7.x
## 2023/02/04
## Changed func Ping
## LTEStatus interval max 59 min in scheduler!

:global lteInf lte1;
:global lteStatus;
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
:global lteFailTreshold;
## set status interval (lteStatusInt) in minutes
:local lteStatusInt 120;
:local lteInfOk [/interface find name=lte1];
:local lteInetOk false;
:local ltePing 0;
:global lteFailCnt;

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

:global Ping do={
    ## Value required: $1(address); count; [interface]
    :local res 0;
    :local val " address=$1 count=1 as-value";
    :if ([:len $interface] != 0) do={:set val ($val." interface=$interface");};
    :for i from=1 to=$count do={:if ([[:parse "/ping $val"]]->"status" = null) do={:set res ($res + 1);};};
    :return $res;
}

:if ( [:typeof $lteStatus] = "nothing" ) do={ 
    :set lteStatus false; :set lteFailCnt 0; 
    :set lteFailTreshold ( $lteStatusInt / [:tonum [:pick [/system scheduler get LTEStatus interval] 3 5]] ); 
};
:if ( $lteInfOk ) do={
    :foreach k in=$pingHost do={
            :local res [$Ping [$Resolve $k] count=1 interface=$lteInf]
            :set ltePing ($ltePing + $res);
    }
    :set lteInetOk ($ltePing > 0);
    :put "lteInetOk=$lteInetOk";
    :if ( $lteInetOk ) do={
        :if ( ! $lteStatus ) do={
            :set lteStatus true;
            :set lteFailCnt 0;
            /log warning "LTE | UP";
        }
    } else={
        :set lteFailCnt ($lteFailCnt + 1);
        :if ( $lteStatus ) do={
            :set lteStatus false;
            /system routerboard usb power-reset duration=5s;
            /log warning "LTE DOWN | USB-power reseted"; 
        } else={
            :if ($lteFailCnt >= $lteFailTreshold) do={
                /system routerboard usb power-reset duration=5s;
                :set lteFailCnt 0;
                /log warning "LTE DOWN (every 2h) | USB-power reseted"; 
            }
        }
    }
}
