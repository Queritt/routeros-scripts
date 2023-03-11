## 0.12
## 2022/06/02

:local Access do={
    :do {
        :local accessService $1
        :local accessAddress $2
        :local accessList {"PPP"; "SSH"; "WinBox"}
        :foreach i in=$accessList do={
            :if ($accessService = $i) do={
                :if ([:len $accessAddress] = 0) do={ 
                    /ip firewall address-list add address="0.0.0.0/0" list=($accessService."-Access") timeout=00:00:20 comment="Added from TLGRM"; 
                    /log warning "$accessService access enabled"; 
                    :return [];
                } else={
                    /ip firewall address-list add address=$accessAddress list=($accessService."-Access") timeout=00:02:00 comment="Added from TLGRM";
                    /log warning "$accessService access enabled for: $accessAddress";
                    :return [];
                }     
            }    
        }  
        [[:parse [/system script get TG source]] Text=($accessService." doesn't exist. Try again...")];  
    } on-error { [[:parse [/system script get TG source]] Text="Error: something didn't work when adding access."]; }
}

:local Help do={
    :local help "Access [PPP; SSH; WinBox] [IP]"
    [[:parse [/system script get TG source]] Text=$help];
}

## Main
:local service $0;
:local address $1;
:if ([:len $service] = 0) do={ $Help; } else={ $Access $service $address; }
