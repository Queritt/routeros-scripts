# DoH failover
# 0.20
# 2022/10/03
:global dnsSrvStatus1;
:global dnsSrvStatus2;
:global dnsSrvStatus3;
:local dnsSrv1 "1.1.1.1";
:local dnsSrv2 "dns.google";
:local dnsSrv3 {1.1.1.1; 8.8.8.8; 8.8.4.4; 94.140.14.140; 4.2.2.1; 77.88.8.8};
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
:foreach host in=$pingHost do={ :local res [/ping $host count=1]; :set ispPing ($ispPing + $res); };
if ( $ispPing > 0 ) do={
    # Ping DoH Server-1
    if ( [/ping $dnsSrv1 count=3] > 0 ) do={
        if (!$dnsSrvStatus1) do={
            /ip dns set use-doh-server="https://$dnsSrv1/dns-query" verify-doh-cert=yes;
            /ip dns set servers="";
            :set dnsSrvStatus1 true;
            :set dnsSrvStatus2 false;
            :set dnsSrvStatus3 false;
            /log info "DoH first UP";
        }
    } else={
        # Ping DoH Server-2
        if ( [/ping $dnsSrv2 count=3] > 0 ) do={
            if (!$dnsSrvStatus2) do={
                /ip dns set use-doh-server="https://$dnsSrv2/dns-query" verify-doh-cert=yes;
                /ip dns set servers="";
                :set dnsSrvStatus1 false;
                :set dnsSrvStatus2 true;
                :set dnsSrvStatus3 false;
                /log info "DoH first DOWN | second enabled";
            }
        } else={
            if (!$dnsSrvStatus3) do={
                /ip dns set servers="$dnsSrv3";
                /ip dns set verify-doh-cert=no;
                /ip dns set use-doh-server="";
                :set dnsSrvStatus1 false;
                :set dnsSrvStatus2 false;
                :set dnsSrvStatus3 true;
                /log warning "DoH first and second DOWN | Reserv enabled";
            }
        }   
    }
}
