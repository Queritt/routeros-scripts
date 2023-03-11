## ISPFailover 
## ver 0.90 / 7.x
## Removed fail counter
## modified 2023/02/02
## Run every 60s
:global ispInf ether1;
:global lteInf lte1;
:global lteId;
:local lteInfOk [/interface find name=$lteInf];
:local pingCount 1;
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
:local ispInetOk false;
:local lteInetOk false;
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

:global HostPing do={
    :global Ping;
    :global Resolve;
    :local counter 0;
    :foreach k in=$pingHost do={
        :local res [$Ping [$Resolve $k] count=$pingCount interface=$pingInf];
        :set counter ($counter + $res);
    }
    :return $counter;
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
    ## /interface disable l2tp-out3;
    :delay 2s;
    /interface enable l2tp-out1;
    /interface enable l2tp-out2;
    ## /interface enable l2tp-out3;
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
    ## /interface disable [find name="l2tp-out3"];
    :delay 2s;
    /interface enable [find name="l2tp-out1"];
    /interface enable [find name="l2tp-out2"];
    ## /interface enable [find name="l2tp-out3"];
    :delay 2s;
    /log warning "ISP DOWN | Switched to reserve internet connection";
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
:put "lteGateDist=$lteGateDist";
## Main interface ping Step-1
:set ispInetOk ([$HostPing pingHost=$pingHost pingCount=$pingCount pingInf=$ispInf] > 0);
:put "ispInetOk=$ispInetOk";
##
if ($ispInetOk) do={
    :if ($lteGateDist = 1) do={$SwitchToISP;}
} else={ 
    :if (($lteGateDist = 4) && $lteInfOk) do={
        :delay 5;
        ## Main interface ping Step-2
        :set ispInetOk ([$HostPing pingHost=$pingHost pingCount=$pingCount pingInf=$ispInf] > 0);
        :if ($ispInetOk) do={:return []};
        ## Reserv interface ping Step-1
        :set lteInetOk ([$HostPing pingHost=$pingHost pingCount=$pingCount pingInf=$lteInf] > 0);
        :put "lteInetOk=$lteInetOk";
        :if ($lteInetOk) do={$SwitchToLTE;} 
    }
}
