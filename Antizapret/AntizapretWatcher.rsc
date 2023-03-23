## AntizapretWatcher
## 0.10
## 2023/03/23

:local SendMsg do={
    :local nameID [/system identity get name;];
    :if ([:len $1] != 0) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local serverName "antizapret";
:local schName "AntizapretWatcher";
:local resolveHost "ya.ru";
:local res;

:if ([:len [/interface ovpn-client find comment=$serverName]] != 0 && [/interface ovpn-client find comment=$serverName disabled=no]) do={
    :if (![/interface ovpn-client get [find comment=$serverName] running]) do={
        /system scheduler disable $schName;
        [/interface ovpn-client disable [find comment=$serverName]];
        $SendMsg (" AntizapretWatcher: client not running and has been disabled.");
    } else={
        :do {:set res [:typeof [/resolve $resolveHost server=[:pick [/ip dns get dynamic-servers] 0]]]} on-error={:put "";};
        :if ($res != "ip") do={
            /system scheduler disable $schName;
            [/interface ovpn-client disable [find comment=$serverName]];
            $SendMsg (" AntizapretWatcher: host not resolving and has been disabled.");
        };
    }   
} else={
    $SendMsg (" AntizapretWatcher: client \"$serverName\" not found or disabled."); 
    /system scheduler disable $schName;
}
