# StartupFail
# 0.30
# 2023/01/04
:local nameID [ /system identity get name; ];
:local logGet [ :toarray [ /log find ($topics ~"error"); ]];
:local logCnt [ :len $logGet ];
:local msgTxt ("$nameID"."%0A"."Error log found: "."%0A");
:if ($logCnt > 0) do={
    :while ( [/ping 1.1.1.1 count=3] = 0 ) do={ :delay 30; };
    :foreach i in=$logGet do={
        :set msgTxt ("$msgTxt"." >".[ /log get $i message; ]."%0A");
    }
    [[:parse [/system script get TG source]] Text=$msgTxt];
}
