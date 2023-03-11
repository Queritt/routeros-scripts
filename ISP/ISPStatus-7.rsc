## ISP Status
## 0.50 / 7.x
## 2023/02/04
## Add first step on fails
:global ispInf ether1
:global lteInf lte1
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
:local pingISPGate IP;
:local pingLTEGate 192.168.8.1;
:local pingGateCnt 3
:local pingHostCnt 1

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

## Ping ISP
## ISP-gate ping Step-1 
:if ([/ping $pingISPGate count=$pingGateCnt interface=$ispInf] = 0) do={
    :delay 5s;
    ## ISP-gate ping Step-2 
    :if ([/ping $pingISPGate count=$pingGateCnt interface=$ispInf] = 0) do={
        /log warning "ISP-Gate DOWN (Status)";
    };
} else={
    ## ISP ping Step-1 
    :if ([$HostPing host=$pingHost count=$pingHostCnt interface=$ispInf] = 0) do={
        :delay 5s;
         ## ISP ping Step-2 
        :if ([$HostPing host=$pingHost count=$pingHostCnt interface=$ispInf] = 0) do={  
            /log warning "ISP DOWN (Status)";
        };
    };
}
## Ping LTE 
## LTE-gate ping Step-1 
:if ([/ping $pingLTEGate count=$pingGateCnt interface=$lteInf] = 0) do={
    :delay 5s;
    ## LTE-gate ping Step-2 
    :if ([/ping $pingLTEGate count=$pingGateCnt interface=$lteInf] = 0) do={
        /system routerboard usb power-reset duration=3s;
        /log warning "LTE-Gate DOWN (Status)";
    };
} else={
    ## LTE ping Step-1 
    :if ([$HostPing host=$pingHost count=$pingHostCnt interface=$lteInf] = 0) do={
        :delay 5s;
        ## LTE ping Step-2 
        :if ([$HostPing host=$pingHost count=$pingHostCnt interface=$lteInf] = 0) do={
            /log warning "LTE DOWN (Status)";
        };
    };
}
