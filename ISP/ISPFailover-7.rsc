# ISPFailover 
# ver 0.81 / 7.x
# Add global value for ping host
# modified 2023/01/23
# Run every 20s
:global ispInf ether1;
:global lteInf lte1;
:global ispFailCnt;
:global ispFail;
:global lteId;
:local lteInfOk [/interface find name=lte1];
:local pingCount 1;
# :local pingHostWake 8.8.8.8; 
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
:local ispInetOk false;
:local lteInetOk false;
:local ispPing 0;
:local ltePing 0;
:local failTreshold 3;
:local lteGateDist;

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

:local SwitchToISP do={
    :global lteId;
    /ip route set $lteId distance=4;
    :foreach i in=[/ip firewall connection find protocol~"tcp"] do={ /ip firewall connection remove $i };
    :foreach i in=[/ip firewall connection find protocol~"udp"] do={ /ip firewall connection remove $i };
    /queue tree disable [find comment="LTE"];
    /queue tree enable [find comment="ISP-100"];
    /ip firewall raw disable [find comment="WEB-LTE"]; 
    /interface disable l2tp-out1;
    /interface disable l2tp-out2;
    # /interface disable l2tp-out3;
    :delay 2s;
    /interface enable l2tp-out1;
    /interface enable l2tp-out2;
    # /interface enable l2tp-out3;
    :delay 2s
    /log warning "ISP UP | Switched to main internet connection";
}

:local SwitchToLTE do={
    :global lteId;
    :delay 1s; 
    /ip route set $lteId distance=1;
    :foreach i in=[/ip firewall connection find protocol~"tcp"] do={ /ip firewall connection remove $i };
    :foreach i in=[/ip firewall connection find protocol~"udp"] do={ /ip firewall connection remove $i };
    /queue tree disable [find comment="ISP-100"];
    /queue tree enable [find comment="LTE"];
    /ip firewall raw enable [find comment="WEB-LTE"]; 
    /interface disable [find name="l2tp-out1"];
    /interface disable [find name="l2tp-out2"];
    # /interface disable [find name="l2tp-out3"];
    :delay 2s;
    /interface enable [find name="l2tp-out1"];
    /interface enable [find name="l2tp-out2"];
    # /interface enable [find name="l2tp-out3"];
    :delay 2s;
    /log warning "ISP DOWN | Switched to reserve internet connection";
}

# This inicializes the PingFailCount variables, in case this is the 1st time the script has ran
:if ( [:typeof $ispFailCnt] = "nothing" ) do={ :set ispFailCnt 0; :set ispFail false; }
# BGP 
:if ([:typeof $lteId] = "nothing") do={
    :local bgpStatus false;
    :if ( ![/routing bgp connection get [find comment="antifilter.download"] disabled] ) do={ 
        /routing bgp connection disable [find comment="antifilter.download"]; 
        :set $bgpStatus true;
        :delay 5s;
    } 
    :set lteId [/ip route find comment="LTE"];
    :if ($bgpStatus) do={ /routing bgp connection enable [find comment="antifilter.download"]; }
}
:set lteGateDist [/ip route get $lteId distance];
:put "lteGateDist=$lteGateDist";
# Check ISP ping
:foreach k in=$pingHost do={
    :local res [$Ping [$Resolve $k] count=$pingCount interface=$ispInf];
    :set ispPing ($ispPing + $res);
}
:set ispInetOk ($ispPing > 0);
:put "ispInetOk=$ispInetOk";
if ($ispInetOk) do={
    :if ($ispFailCnt > 0) do={
        :set ispFailCnt ($ispFailCnt - 1);
        :put "ispFailCnt k=$ispFailCnt";
        :if ( ($ispFailCnt = ($failTreshold - 1)) && ($lteGateDist = 1) ) do={
            :if ( ! $ispFail ) do={
                $SwitchToISP; 
            } else={
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
                # /ping $pingHostWake count=$pingCount interface=$lteInf;
                # delay 3s;
                foreach k in=$pingHost do={
                    :local res [$Ping [$Resolve $k] count=$pingCount interface=$lteInf];
                    :set ltePing ($ltePing + $res);
                }
                :set lteInetOk ($ltePing > 0)
                :put "lteInetOk=$lteInetOk";
                :if ($lteInetOk && ($lteGateDist = 4)) do={
                    $SwitchToLTE;
                }
            } else={
                /ip route set $lteId distance=1;
                /log warning "ISP DOWN";
                :set ispFail true;
            }
        }
    } 
    if ( ($ispFailCnt > $failTreshold) && ($lteGateDist = 4) ) do={
        :if ( $lteInfOk ) do={
            # /ping $pingHostWake count=$pingCount interface=$lteInf;
            # :delay 3s;
            :foreach k in=$pingHost do={
                :local res [$Ping [$Resolve $k] count=$pingCount interface=$lteInf]
                :set ltePing ($ltePing + $res);
            }
            :set lteInetOk ($ltePing > 0);
            :put "lteInetOk=$lteInetOk";
            if ($lteInetOk) do={
                $SwitchToLTE;
            }
        }   
    }
}
