## DoH failover
## 0.41 / 7.x
## Changed func Ping
## 2023/02/04
:global dnsSrvStatus1;
:global dnsSrvStatus2;
:global dnsSrvStatus3;
:local dnsSrv1 "1.1.1.1";
:local dnsSrv2 "dns.google";

:global Ping do={
    ## Value required: $1(address); count; [interface]
    :local res 0;
    :local val " address=$1 count=1 as-value";
    :if ([:len $interface] != 0) do={:set val ($val." interface=$interface");};
    :for i from=1 to=$count do={:if ([[:parse "/ping $val"]]->"status" = null) do={:set res ($res + 1);};};
    :return $res;
}

# Over PPP-OUT
# :local pingInf "l2tp-out2";
# This inicializes the DNSServFlags variables, in case this is the 1st time the script has ran
:if ( [:typeof $dnsSrvStatus1] = "nothing" ) do={
    :set dnsSrvStatus1 false;
    :set dnsSrvStatus2 false;
    :set dnsSrvStatus3 false;
}
# Check ISP
## yandex.ru, OpenDNS, GoogleDNS, mail.ru
:local pingHost {87.250.250.242; 208.67.222.222; 8.8.8.8; 94.100.180.200};
:local ispPing 0;
# Over PPP-OUT
# :foreach host in=$pingHost do={ :local res [/ping $host interface=$pingInf count=1]; :set ispPing ($ispPing + $res); };
:foreach host in=$pingHost do={ :local res [$Ping $host count=1]; :set ispPing ($ispPing + $res); };
if ( $ispPing > 0 ) do={
    # Ping DoH Server-1
    # Over PPP-OUT
    # if ( [/ping $dnsSrv1 interface=$pingInf count=3] > 0 ) do={
    if ( [/ping $dnsSrv1 count=3] > 0 ) do={
        if (!$dnsSrvStatus1) do={
            /ip dns set use-doh-server="https://$dnsSrv1/dns-query";
            :set dnsSrvStatus1 true;
            :set dnsSrvStatus2 false;
            :set dnsSrvStatus3 false;
            /log warning "DoH first UP";
        }
    } else={
        # Ping DoH Server-2
        # Over PPP-OUT
        # if ( [/ping $dnsSrv2 interface=$pingInf count=3] > 0 ) do={
        if ( [/ping $dnsSrv2 count=3] > 0 ) do={
            if (!$dnsSrvStatus2) do={
                /ip dns set use-doh-server="https://$dnsSrv2/dns-query";
                :set dnsSrvStatus1 false;
                :set dnsSrvStatus2 true;
                :set dnsSrvStatus3 false;
                /log info "DoH first DOWN";
            }
        } else={
            if (!$dnsSrvStatus3) do={
                /ip dns set use-doh-server="";
                :set dnsSrvStatus1 false;
                :set dnsSrvStatus2 false;
                :set dnsSrvStatus3 true;
                /log warning "DoH DOWN";
            }
        }   
    }
}
