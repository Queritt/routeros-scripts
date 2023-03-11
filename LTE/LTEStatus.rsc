# LTE status
# 0.10
# 2022/11/5
:local lte ether2;
:local pingCountHost 2;
:local pingCountGate 3;
# yandex.ru, Cloudflare, GoogleDNS, mail.ru
:local pingHost {87.250.250.242; 1.1.1.1; 8.8.8.8; 94.100.180.200};
:local pingHostWake 8.8.8.8;
:local pingLTEGate 192.168.8.1;
:local lteInetOk false;
:local lteGateOk false;
:local ltePing 0;
:local lteGatePing 0;
# Ping Gate
:local res [/ping $pingLTEGate count=$pingCountGate interface=$lte];
:set lteGatePing ($lteGatePing + $res);
:set lteGateOk ($lteGatePing >= 1);
:put "lteGateOk=$lteGateOk";
# Ping LTE 
:if ($lteGateOk) do={
  /ping $pingHostWake count=3 interface=$lte;
  :delay 3s;
  foreach k in=$pingHost do={
    :local res [/ping $k count=$pingCountHost interface=$lte];
    :set ltePing ($ltePing + $res);
  }
  :set lteInetOk ($ltePing >= 5);
  :put "lteInetOk=$lteInetOk";
  if (!$lteInetOk) do={
    /log warning "LTE DOWN (status)";
  }
}
