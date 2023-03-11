## ISP Status
## 0.42 / 7.x
## 2023/02/04
## Changed func Ping
:global ispInf ether1
:global lteInf lte1
:local pingHostCnt 1
:local pingGateCnt 3
# yandex.ru, OpenDNS, GoogleDNS, mail.ru
# :local pingHost {87.250.250.242; 208.67.222.222; 8.8.8.8; 94.100.180.200};
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
# :local pingHostWake 8.8.8.8; 
:local pingISPGate IP;
:local pingLTEGate 192.168.8.1;
:local ispInetOk false;
:local ispGateOk false;
:local lteInetOk false;
:local lteGateOk false;
:local ispPing 0;
:local ltePing 0;
:local ispGatePing 0;
:local lteGatePing 0;

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

:global Ping do={
    ## Value required: $1(address); count; [interface]
    :local res 0;
    :local val " address=$1 count=1 as-value";
    :if ([:len $interface] != 0) do={:set val ($val." interface=$interface");};
    :for i from=1 to=$count do={:if ([[:parse "/ping $val"]]->"status" = null) do={:set res ($res + 1);};};
    :return $res;
}

#--Ping Gates
:set ispGatePing [/ping $pingISPGate count=$pingGateCnt interface=$ispInf];
:set lteGatePing [/ping $pingLTEGate count=$pingGateCnt interface=$lteInf];
:set ispGateOk ($ispGatePing > 0);
:set lteGateOk ($lteGatePing > 0);
:put "ispGateOk=$ispGateOk";
:put "lteGateOk=$lteGateOk";
#--Ping ISP 
if (!$ispGateOk) do={
    /log warning "ISP-Gate DOWN (Status)";
} else={
    foreach k in=$pingHost do={
        :local res [$Ping [$Resolve $k] count=$pingHostCnt interface=$ispInf];
        :set ispPing ($ispPing + $res);
    }
    :set ispInetOk ($ispPing > 0);
    :put "ispInetOk=$ispInetOk";
    if (!$ispInetOk) do={
        /log warning "ISP DOWN (Status)";
    }
}
#--Ping LTE 
if (!$lteGateOk) do={
    /system routerboard usb power-reset duration=3s;
    /log warning "LTE-Gate DOWN (Status)";
} else={
    # foreach k in=$pingHostWake do={
    #     /ping $k count=3 interface=$lteInf;
    # }
    # :delay 3s;
    foreach k in=$pingHost do={
        :local res [$Ping [$Resolve $k] count=$pingHostCnt interface=$lteInf];
        :set ltePing ($ltePing + $res);
    }
    :set lteInetOk ($ltePing > 0);
    :put "lteInetOk=$lteInetOk";
    if (!$lteInetOk) do={
        /log warning "LTE DOWN (Status)";
    }
}
