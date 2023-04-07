## StartupFail
## 0.31
## Correct out message
## 2023/04/07
:local nameID [/system identity get name;];
:local logGet [:toarray [ /log find ($topics ~"error");]];
:local logCnt [:len $logGet];
:local msgTxt ("/$nameID:"."%0A"." StartupFail: error log found: "."%0A");
:if ($logCnt > 0) do={
    :while ( [/ping 1.1.1.1 count=3] = 0 ) do={:delay 30;};
    :foreach i in=$logGet do={:set msgTxt ("$msgTxt"." >".[ /log get $i message; ]."%0A");}
    [[:parse [/system script get TG source]] Text=$msgTxt];
}
