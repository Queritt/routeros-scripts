# LTEStatus
# 0.41 / 7.x
# Add global value for ping host; change start lteStatus status as true;
# 2023/01/20

:global lteInf lte1;
:global lteStatus;
:local lteInfOk [/interface find name=lte1];
:local lteInetOk false;
:local ltePing 0;
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

:global Ping do={
    :local pingAddress $1;
    :local pingCount $count;
    :local pingInf $interface;
    :local res 0;
    :for i from=1 to=$pingCount step=1 do={
        :if ( [:len $pingInf] = 0) do={ 
            :if ( [/ping address=$pingAddress count=1 as-value]->"status"=null ) do={:set res ($res + 1);}  
        } else={
            :if ( [/ping address=$pingAddress count=1 interface=$pingInf as-value]->"status"=null ) do={:set res ($res + 1);}   
        }
    }
    :return $res;
}

:if ( [:typeof $lteStatus] = "nothing" ) do={ :set lteStatus true; };
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
            /log warning "LTE | UP";
        }
    } else={
        :if ( $lteStatus ) do={
            :set lteStatus false;
            /system routerboard usb power-reset duration=5s;
            /log warning "LTE DOWN | USB-power reseted"; 
        }
    }
}
