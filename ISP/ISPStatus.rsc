# ISP Status
# 0.2
# 2022/10/23
:global ispInf ether1
:global lteInf lte1
:local pingHostCnt 2
:local pingGateCnt 3
# yandex.ru, OpenDNS, GoogleDNS, mail.ru
:local pingHost {87.250.250.242; 208.67.222.222; 8.8.8.8; 94.100.180.200};
:local pingHostWake 8.8.8.8; 
:local pingISPGate ISPGATE;
:local pingLTEGate 192.168.8.1;
:local ispInetOk false;
:local ispGateOk false;
:local lteInetOk false;
:local lteGateOk false;
:local ispPing 0;
:local ltePing 0;
:local ispGatePing 0;
:local lteGatePing 0;
#--Ping Gates
:set ispGatePing [/ping $pingISPGate count=$pingGateCnt interface=$ispInf];
:set lteGatePing [/ping $pingLTEGate count=$pingGateCnt interface=$lteInf];
:set ispGateOk ($ispGatePing >= 1);
:set lteGateOk ($lteGatePing >= 1);
:put "ispGateOk=$ispGateOk";
:put "lteGateOk=$lteGateOk";
#--Ping ISP 
if (!$ispGateOk) do={
  	/log warning "ISP-Gate DOWN (Status)";
} else={
  	foreach k in=$pingHost do={
    	:local res [/ping $k count=$pingHostCnt interface=$ispInf];
    	:set ispPing ($ispPing + $res);
  	}
  	:set ispInetOk ($ispPing >= 5);
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
  	foreach k in=$pingHostWake do={
    	/ping $k count=3 interface=$lteInf;
  	}
  	:delay 3s;
  	foreach k in=$pingHost do={
    	:local res [/ping $k count=$pingHostCnt interface=$lteInf];
    	:set ltePing ($ltePing + $res);
  	}
  	:set lteInetOk ($ltePing >= 5);
  	:put "lteInetOk=$lteInetOk";
  	if (!$lteInetOk) do={
    	/log warning "LTE DOWN (Status)";
  	}
}
