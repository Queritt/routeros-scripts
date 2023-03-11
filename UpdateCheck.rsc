## UpdateCheck
## 0.10
## 2023/02/24
:if ([:len [/log find message ~"New RouterOS is available"]] = 0) do={
    :local updSrv "upgrade.mikrotik.com";
    :local dnsUpdateStatus false;
    :if ( ([:len [/ip dns static find name="$updSrv"]] != 0) \
        && ![/ip dns static get [find name="$updSrv"] disabled] ) do={      
        /ip dns static disable [find name="$updSrv"];
        :set dnsUpdateStatus true;
    }
    :if (([/system package update check-for-updates as-value]->"status") = "New version is available") do={
        :local deviceOsVerInst [/system package update get installed-version];
        :local deviceOsVerAvail [/system package update get latest-version];
        /log warning ("New RouterOS is available: $deviceOsVerAvail (Installed-version: $deviceOsVerInst).");
    }    
    :if ($dnsUpdateStatus) do={/ip dns static enable [find name="$updSrv"];}
}
