# LTE status
# 0.30 / 7.x
# 2023/01/17

:global lteInf lte1;
:global lteStatus;
:local lteInfOk [/interface find name=lte1];
:local lteInetOk false;
:local ltePing 0;
#--yandex.ru, google.com, mail.ru
:local pingHost {87.250.250.242; 64.233.164.101; 94.100.180.200};

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

:if ( [:typeof $lteStatus] = "nothing" ) do={ :set lteStatus false; };
:if ( $lteInfOk ) do={
    :foreach k in=$pingHost do={
        :local res [$Ping $k count=1 interface=$lteInf]
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
