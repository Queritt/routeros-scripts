## AntizapretSwitcher
## 0.10
## 2023/03/23

:local SendMsg do={
    :local nameID [/system identity get name;];
    :if ([:len $1] != 0) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help (" Antizapret option: "."%0A". \
        " > enable; disable"."%0A". \
        " > status")
    :return $help;
}

:local action $0;
:local serverName "antizapret";
:local schName "AntizapretWatcher";

:if ([:len [/interface ovpn-client find comment=$serverName]] = 0) do={$SendMsg (" Antizapret: client \"$serverName\" not found."); return []};

:if ([:len [/system scheduler find name=$schName]] = 0) do={$SendMsg (" Antizapret: schedule \"$schName\" not found."); return []};

:if ($action = "help" || $action = "Help") do={$SendMsg [$Help]; :return [];};

:if ($action = "enable") do={
    :if [/interface ovpn-client find comment=$serverName disabled] do={
        [/interface ovpn-client enable [find comment=$serverName]];
        :delay 5s;
        /system scheduler enable $schName;
        $SendMsg (" Antizapret: client enabled.");
    } else={$SendMsg (" Antizapret: client already enabled.")};
    :return [];
};

:if ($action = "disable") do={
    :if [/interface ovpn-client find comment=$serverName disabled=no] do={
        /system scheduler disable $schName;
        [/interface ovpn-client disable [find comment=$serverName]];
        $SendMsg (" Antizapret: client disabled.");
    } else={$SendMsg (" Antizapret: client already disabled.")};
    :return [];
};

:if ($action = "status") do={
    $SendMsg (" Antizapret: client ".[/interface ovpn-client monitor [find comment=$serverName] once as-value]->"status");
    :return [];
};
$SendMsg [$Help];
