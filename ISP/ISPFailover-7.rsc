## ISPFailover 
## ver 0.93 / 7.x
## Changed func Ping, HostPing
## modified 2023/03/14
## Disable connection or l2tp reset in SwitchToISP
## Run every 93s
:global ispInf ether1;
:global lteInf lte1;
:global lteId;
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
:local lteInfOk [/interface find name=$lteInf];
:local pingCount 1;
:local lteGateDist;

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

:global Ping do={
    ## Value required: $1(address); count; [interface]
    :local res 0;
    :local val " address=$1 count=1 as-value";
    :if ([:len $interface] != 0) do={:set val ($val." interface=$interface");};
    :for i from=1 to=$count do={:if ([[:parse "/ping $val"]]->"status" = null) do={:set res ($res + 1);};};
    :return $res;
}

:global HostPing do={
    ## Value required: host; count; [interface]
    :global Ping; :global Resolve; :local res 0;
    :foreach k in=$host do={:set res ($res + [$Ping [$Resolve $k] count=$count interface=$interface]);};
    :return $res;
}

:local SwitchToISP do={
    :global lteId;
    /ip route set $lteId distance=4;
    # /ip firewall connection remove [find];
    /queue tree disable [find comment="LTE"];
    /queue tree enable [find comment="ISP-100"];
    /ip firewall raw disable [find comment="WEB-LTE"]; 
    # /interface disable l2tp-out1;
    # /interface disable l2tp-out2;
    ## /interface disable l2tp-out3;
    # :delay 2s;
    # /interface enable l2tp-out1;
    # /interface enable l2tp-out2;
    ## /interface enable l2tp-out3;
    :delay 2s;
    /log warning "ISP UP";
}

:local SwitchToLTE do={
    :global lteId;
    :delay 1s; 
    /ip route set $lteId distance=1;
    /ip firewall connection remove [find];
    /queue tree disable [find comment="ISP-100"];
    /queue tree enable [find comment="LTE"];
    /ip firewall raw enable [find comment="WEB-LTE"]; 
    /interface disable [find name="l2tp-out1"];
    /interface disable [find name="l2tp-out2"];
    ## /interface disable [find name="l2tp-out3"];
    :delay 2s;
    /interface enable [find name="l2tp-out1"];
    /interface enable [find name="l2tp-out2"];
    ## /interface enable [find name="l2tp-out3"];
    :delay 2s;
    /log warning "ISP DOWN";
}

## BGP 
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
## Main interface ping Step-1
:if ([$HostPing host=$pingHost count=$pingCount interface=$ispInf] > 0) do={
    :if ($lteGateDist = 1) do={$SwitchToISP;}
} else={ 
    :if (($lteGateDist = 4) && $lteInfOk) do={
        :delay 5s;
        ## Main interface ping Step-2
        :if ([$HostPing host=$pingHost count=$pingCount interface=$ispInf] > 0) do={:return []};
        ## Reserv interface ping
        :if ([$HostPing host=$pingHost count=$pingCount interface=$lteInf] > 0) do={$SwitchToLTE;} 
    }
}
