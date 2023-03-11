# WGAutoAccess
# 0.1
# 2022/10/22

:local Main do={
    :local status false;
    :foreach i in=[/tool netwatch find comment~"TM"] do={
        :if ( [/tool netwatch get $i status] = "up" ) do={ :set status true; }
    }
    :local natComment "WG-pk";
    :local listComment "pk";
    :if (! $status ) do={   
        :if ( [:typeof [/ip firewall nat get [find comment=$natComment] src-address]] != "nil" ) do={
            /ip firewall nat unset [find comment=$natComment] src-address;
            /log warning "Active TM not found. WG access enabled!";
        }
    } else={
        :local oldAddress [/ip firewall address-list get [find comment=$listComment] address];
        :foreach k in=[/tool netwatch find comment~"TM"] do={
            :if ( [/tool netwatch get $k status] = "up" ) do={
                :local peerComment [/tool netwatch get $k comment];
                :local newAddress [/interface wireguard peers get [find comment=$peerComment] current-endpoint-address];
                :if ( $newAddress != $oldAddress ) do={
                    /ip firewall address-list set [find comment=$listComment] address=$newAddress;
                    /ip firewall nat set [find comment=$natComment] src-address=$newAddress;
                    /log warning "Host \"$hostName\" changed $oldAddress to $newAddress. WG access disabled.";
                    :return null;
                } 
                :if ( [:typeof [/ip firewall nat get [find comment=$natComment] src-address]] = "nil" ) do={
                    /ip firewall nat set [find comment=$natComment] src-address=$newAddress;
                    /log warning "Active TM found. WG access disabled.";
                }
                :return null;
            } 
        }
    }
}

$Main
