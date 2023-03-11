# ispFailover 
# BGP edition
# ver 0.60
# modified 2023/01/05
:global ispInf ether1;
:global lteInf lte1;
:global ispFailCnt;
:global ispFail;
:global lteId;
:local lteInfOk [/interface find name=lte1];
:local pingCount 1;
# yandex.ru, cloudflare, GoogleDNS, mail.ru
:local pingHost {87.250.250.242; 1.1.1.1; 8.8.8.8; 94.100.180.200};
:local pingHostWake 8.8.8.8; 
:local ispInetOk false;
:local lteInetOk false;
:local ispPing 0;
:local ltePing 0;
:local failTreshold 3;
:local lteGateDist;

:local SwitchToISP do={
    :global lteId;
    #/ ip firewall connection remove [find];
    # /ip route set [find comment="LTE"] distance=4;
    /ip route set $lteId distance=4;
    /queue tree disable [find comment="LTE"];
    /queue tree enable [find comment="ISP-100"];
    /ip firewall raw disable [find comment="WEB-LTE"]; 
    /interface disable l2tp-out1;
    /interface disable l2tp-out2;
    # /interface disable l2tp-out5;
    :delay 2s;
    /interface enable l2tp-out1;
    /interface enable l2tp-out2;
    # /interface enable l2tp-out5;
    :delay 2s
    /log warning "ISP UP | Switched to main internet connection";
}

:local SwitchToLTE do={
    :global lteId;
    :delay 1s; 
    # /ip route set [find comment="LTE"] distance=1;
    /ip route set $lteId distance=1;
    /queue tree disable [find comment="ISP-100"];
    /queue tree enable [find comment="LTE"];
    #/ ip firewall connection remove [find];
    /ip firewall raw enable [find comment="WEB-LTE"]; 
    /interface disable [find name="l2tp-out1"];
    /interface disable [find name="l2tp-out2"];
    # /interface disable [find name="l2tp-out5"];
    :delay 2s;
    /interface enable [find name="l2tp-out1"];
    /interface enable [find name="l2tp-out2"];
    # /interface enable [find name="l2tp-out5"];
    :delay 2s;
    /log warning "ISP DOWN | Switched to reserve internet connection";
}

# This inicializes the PingFailCount variables, in case this is the 1st time the script has ran
:if ( [:typeof $ispFailCnt] = "nothing" ) do={ :set ispFailCnt 0; :set ispFail false; }
# BGP 
:if ([:typeof $lteId] = "nothing") do={
    :local bgpStatus false;
    :if ( ![/routing bgp peer get [find comment="antifilter.download"] disabled] ) do={ 
        /routing bgp peer disable [find comment="antifilter.download"]; 
        :set $bgpStatus true;
        :delay 5s;
    } 
    :set lteId [/ip route find comment="LTE"];
    :if ($bgpStatus) do={ /routing bgp peer enable [find comment="antifilter.download"]; }
}
# :set lteGateDist [/ip route get [find comment="LTE"] distance];
:set lteGateDist [/ip route get $lteId distance];
:put "lteGateDist=$lteGateDist";
# Check ISP ping
:foreach k in=$pingHost do={
    :local res [/ping $k count=$pingCount interface=$ispInf];
    :set ispPing ($ispPing + $res);
}
:set ispInetOk ($ispPing >= 3);
:put "ispInetOk=$ispInetOk";
if ($ispInetOk) do={
    :if ($ispFailCnt > 0) do={
        :set ispFailCnt ($ispFailCnt - 1);
        :put "ispFailCnt k=$ispFailCnt";
        :if ( ($ispFailCnt = ($failTreshold - 1)) && ($lteGateDist = 1) ) do={
            :if ( ! $ispFail ) do={
                $SwitchToISP; 
            } else={
                # /ip route set [find comment="LTE"] distance=4;
                /ip route set $lteId distance=4;
                :set ispFail false;
                /log warning "ISP UP";
            }
        }
    }
    # In case when the router power is interrupted
    :if ( ($ispFailCnt = 0) && ($lteGateDist = 1) ) do={
        $SwitchToISP; 
    }
} else={ 
    if ( $ispFailCnt < ($failTreshold + 2) ) do={
        :set ispFailCnt ($ispFailCnt + 1);
        :put "ispFailCnt k=$ispFailCnt";
        :if ($ispFailCnt = $failTreshold) do={
            :if ( $lteInfOk ) do={
                /ping $pingHostWake count=$pingCount interface=$lteInf;
                delay 3s;
                foreach k in=$pingHost do={
                    :local res [/ping $k count=$pingCount interface=$lteInf];
                    :set ltePing ($ltePing + $res);
                }
                :set lteInetOk ($ltePing >= 3)
                :put "lteInetOk=$lteInetOk";
                :if ($lteInetOk && ($lteGateDist = 4)) do={
                    $SwitchToLTE;
                }
            } else={
                # /ip route set [find comment="LTE"] distance=1;
                /ip route set $lteId distance=1;
                /log warning "ISP DOWN";
                :set ispFail true;
            }
        }
    } 
    if ( ($ispFailCnt > $failTreshold) && ($lteGateDist = 4) ) do={
        :if ( $lteInfOk ) do={
            /ping $pingHostWake count=$pingCount interface=$lteInf;
            :delay 3s;
            :foreach k in=$pingHost do={
                :local res [/ping $k count=$pingCount interface=$lteInf]
                :set ltePing ($ltePing + $res);
            }
            :set lteInetOk ($ltePing >= 3);
            :put "lteInetOk=$lteInetOk";
            if ($lteInetOk) do={
                $SwitchToLTE;
            }
        }   
    }
}
