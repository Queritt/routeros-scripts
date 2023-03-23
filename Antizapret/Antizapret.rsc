## Antizapret
## 0.10
## 2023/03/23

:local SendMsg do={
    :local nameID [/system identity get name;];
    :if ([:len $1] != 0) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help (" Antizapret option: "."%0A". \
        " > add"."%0A". \
        " > status")
    :return $help;
}

:local action $0;
:local address $1;
:local serverName "antizapret";
:local resolveHost "ya.ru";
:local allowedList {192.168.82.0/24; 192.168.85.0/24; 192.168.86.0/24; 192.168.88.0/24; 192.168.89.0/24};
:local allowedAddress false;
:local dynamicAddress [:pick [/ip dns get dynamic-servers] 0];
:local currentAddress;
:local res;

:if ($action = "help" || $action = "Help") do={$SendMsg [$Help]; :return [];};

:if ($action = "add") do={
    ## Running
    :if (![/interface ovpn-client get [find comment=$serverName] running]) do={$SendMsg (" Antizapret: client not running."); :return [];};
    ## Resolving
    :do {:set res [:typeof [/resolve $resolveHost server=$dynamicAddress]]} on-error={:put "";};
    :if ($res != "ip") do={$SendMsg (" Antizapret: host not resolving."); :return [];};
    ## IP 
    :if ([:typeof [:toip $address]] != "ip") do={$SendMsg (" Antizapret $action error: \"$address\" wrong or empty."); :return [];};
    ## Allowed
    :foreach n in=$allowedList do={:if ($address in $n) do={:set allowedAddress true};}
    :if (!$allowedAddress) do={$SendMsg (" Antizapret $action error: \"$address\" not allowed."); :return [];};
    ## NAT address
    :foreach n in=[/ip firewall nat find comment=$serverName] do={
        :set currentAddress [/ip firewall nat get $n to-addresses];
        :if ($currentAddress != $dynamicAddress) do={/ip firewall nat set $n to-addresses=$dynamicAddress};
    }
    :do {
        [:parse ("ip firewall address-list $action address=$address list=$serverName timeout=00:10:00 comment=\"Antizapret-script\"")];
        $SendMsg (" Antizapret: " . "\"$address\"" . " successfully " . "$action" . "ed to list.");
    } on-error={$SendMsg (" Antizapret $action error: \"$address\" already exists.");}  
    :return []; 
}

:if ($action = "status") do={
    $SendMsg (" Antizapret: client ".[/interface ovpn-client monitor [find comment=$serverName] once as-value]->"status"); :return [];
};
$SendMsg [$Help];
