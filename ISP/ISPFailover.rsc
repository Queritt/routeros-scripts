# ISPFailover 
# BGP edition
# ver 0.30
# modified 2022/09/25
:global ISP ether1;
:global LTE lte1;
:local SwitchToISP do={
    /queue tree disable [find comment="LTE"];
    /queue tree enable [find comment="ISP-100"];
    #/queue tree enable [find comment="ISP-300"];
    #/ ip firewall connection remove [find];
    # /ip route set [find comment="LTE"] distance=4;
    /ip route set $LTEID distance=4;
    /ip firewall raw disable [find comment="WEB-LTE"]; 
    /interface disable l2tp-out1;
    /interface disable l2tp-out2;
    # /interface disable l2tp-out3;
    # /interface disable l2tp-out4;
    # /interface disable l2tp-out5;
    :delay 2s;
    /interface enable l2tp-out1;
    /interface enable l2tp-out2;
    # /interface enable l2tp-out3;
    # /interface enable l2tp-out4;
    # /interface enable l2tp-out5;
    :delay 2s
    /log warning "ISP UP | Switched to main internet connection";
}
:local SwitchToLTE do={
    :delay 1s; 
    /queue tree disable [find comment="ISP-100"];
    #/queue tree disable [find comment="ISP-300"];
    /queue tree enable [find comment="LTE"];
    #/ ip firewall connection remove [find];
    /ip firewall raw enable [find comment="WEB-LTE"]; 
    # /ip route set [find comment="LTE"] distance=1;
    /ip route set $LTEID distance=1;
    /interface disable [find name="l2tp-out1"];
    /interface disable [find name="l2tp-out2"];
    # /interface disable [find name="l2tp-out3"];
    # /interface disable [find name="l2tp-out4"];
    # /interface disable [find name="l2tp-out5"];
    :delay 2s;
    /interface enable [find name="l2tp-out1"];
    /interface enable [find name="l2tp-out2"];
    # /interface enable [find name="l2tp-out3"];
    # /interface enable [find name="l2tp-out4"];
    # /interface enable [find name="l2tp-out5"];
    :delay 2s;
    /log warning "ISP DOWN | Switched to reserve internet connection";
}
:local LTEInfOK [/interface find name=lte1];
:local PingCount 1;
# yandex.ru, cloudflare, GoogleDNS, mail.ru
:local PingHosts {87.250.250.242; 1.1.1.1; 8.8.8.8; 94.100.180.200};
:local PingHostWakeup {8.8.8.8}; 
:local host;
:local ISPInetOk false;
:local LTEInetOk false;
:local ISPPings 0;
:local LTEPings 0;
# Please fill how many ping failures are allowed last-packet-before= fail-over happends
:local FailTreshold 3;
# Declare the global variables
:global PingFailCountISP;
:global ISPFail;
# This inicializes the PingFailCount variables, in case this is the 1st time the script has ran
:if ( [:typeof $PingFailCountISP] = "nothing" ) do={ :set PingFailCountISP 0; :set ISPFail 0; }
# Check ISP ping
:foreach host in=$PingHosts do={
    :local res [/ping $host count=$PingCount interface=$ISP];
    :set ISPPings ($ISPPings + $res);
}
:set ISPInetOk ($ISPPings >= 3);
:put "ISPInetOk=$ISPInetOk";
# BGP 
:global ISPID;
:global LTEID;
:if ([:typeof $ISPID] = "nothing") do={
    :local bgpStatus false;
    :if ( ![/routing bgp peer get [find comment="antifilter.download"] disabled] ) do={ 
        /routing bgp peer disable [find comment="antifilter.download"]; 
        :set $bgpStatus true;
        :delay 5s;
    } 
    :set ISPID [/ip route find comment="ISP"];
    :set LTEID [/ip route find comment="LTE"];
    :if ($bgpStatus) do={ /routing bgp peer enable [find comment="antifilter.download"]; }
}
# :local ISPGWDistance [/ip route get [find comment="ISP"] distance];
# :local LTEGWDistance [/ip route get [find comment="LTE"] distance];
:local ISPGWDistance [/ip route get $ISPID distance];
:local LTEGWDistance [/ip route get $LTEID distance];
:put "ISPGWDistance=$ISPGWDistance";
:put "LTEGWDistance=$LTEGWDistance";
if ($ISPInetOk) do={
    :if ($PingFailCountISP > 0) do={
        :set PingFailCountISP ($PingFailCountISP - 1);
        :put "PingFailCountISP k=$PingFailCountISP";
        :if ( ($PingFailCountISP = ($FailTreshold - 1)) && ($ISPGWDistance >= $LTEGWDistance) ) do={
            :if ( $ISPFail = 0 ) do={
                $SwitchToISP; 
            } else={
                # /ip route set [find comment="LTE"] distance=4;
                /ip route set $LTEID distance=4;
                :set ISPFail 0;
                /log warning "ISP UP";
            }
        }
    }
    # In case when the router power is interrupted
    :if ( ($PingFailCountISP = 0) && ($ISPGWDistance >= $LTEGWDistance) ) do={
        $SwitchToISP; 
    }
} else={ 
    if ( $PingFailCountISP < ($FailTreshold + 2) ) do={
        :set PingFailCountISP ($PingFailCountISP + 1);
        :put "PingFailCountISP k=$PingFailCountISP";
        :if ($PingFailCountISP = $FailTreshold) do={
            :if ( $LTEInfOK ) do={
                :foreach host in=$PingHostWakeup do={
                    :local wakeup [/ping $host count=$PingCount interface=$LTE];
                }   
                delay 3s;
                foreach host in=$PingHosts do={
                    :local res [/ping $host count=$PingCount interface=$LTE];
                    :set LTEPings ($LTEPings + $res);
                }
                :set LTEInetOk ($LTEPings >= 3)
                :put "LTEInetOk=$LTEInetOk";
                :if ($LTEInetOk && ($ISPGWDistance <= $LTEGWDistance)) do={
                    $SwitchToLTE;
                }
            } else={
                # /ip route set [find comment="LTE"] distance=1;
                /ip route set $LTEID distance=1;
                /log warning "ISP DOWN";
                :set ISPFail 1;
            }
        }
    } 
    if ( ($PingFailCountISP > $FailTreshold) && ($ISPGWDistance <= $LTEGWDistance) ) do={
        :if ( $LTEInfOK ) do={
            :foreach host in=$PingHostWakeup do={
                :local wakeup [/ping $host count=$PingCount interface=$LTE];
            }   
            :delay 3s;
            :foreach host in=$PingHosts do={
                :local res [/ping $host count=$PingCount interface=$LTE]
                :set LTEPings ($LTEPings + $res);
            }
            :set LTEInetOk ($LTEPings >= 3);
            :put "LTEInetOk=$LTEInetOk";
            if ($LTEInetOk) do={
                $SwitchToLTE;
            }
        }   
    }
}
