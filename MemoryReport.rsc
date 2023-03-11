# Memory Reporter
# 0.1
# 2022/10/05
:global memoryFree;
:local sendMsgInterval 12;
:local memThreshold 20;
:local date [/system clock get date];
:local time [/system clock get time];
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
:local tmpMem ( [/system resource get free-memory] / 1048576 );
:local tmpStr (" > " . [:pick $date 0 6] . " " . [:pick $time 0 5] . " - $tmpMem Mb" . "%0A");
:if ( [:len $memoryFree] = 0) do={ 
    :set memoryFree {("Memory free:" . "%0A" . $tmpStr)};
} else={
    :set memoryFree ($memoryFree, $tmpStr);
}
:if ( [:len $memoryFree] >= $sendMsgInterval +1 ) do={
    :local tmpMemoryFree [:tostr $memoryFree];
    :local newString "";
        :for i from=0 to=([:len $tmpMemoryFree] -1) step=1 do={
            :local actualchar [:pick $tmpMemoryFree $i];
            :if ($actualchar = ";") do={ :set actualchar "" };
            :set newString ($newString.$actualchar);
        }  
    $SendMsg $newString;
    :set memoryFree {("Memory free:" . "%0A")};
}
:if ( $tmpMem < $memThreshold ) do={
    $SendMsg ("Memory warning! Free: $tmpMem Mb / Threshold: $memThreshold Mb.");
}
