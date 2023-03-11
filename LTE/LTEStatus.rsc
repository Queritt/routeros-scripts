# LTE status
# 0.20 
# 2023/01/07

:global lteInf lte1;
:global lteStatus;
:local lteInfOk [/interface find name=lte1];
:local lteInetOk false;
:local ltePing 0;
:local pingCount 2;
# yandex.ru, cloudflare, GoogleDNS, mail.ru
:local pingHost {87.250.250.242; 1.1.1.1; 8.8.8.8; 94.100.180.200};
:if ( [:typeof $lteStatus] = "nothing" ) do={ :set lteStatus false; };

:if ( $lteInfOk ) do={
    :foreach k in=$pingHost do={
        :local res [/ping $k count=$pingCount interface=$lteInf]
        :set ltePing ($ltePing + $res);
    }
    :set lteInetOk ($ltePing >= 5);
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
