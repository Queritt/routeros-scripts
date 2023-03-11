# PPPAutoAccess
# 0.1
# 2022/03
:local Main do={
:local hostName "pk";
  :if ([/ppp active find comment~"TM"] = "") do={
    :if ([/ip firewall filter find comment="allow pptp from anywhere" disabled=yes]) do={
      /ip firewall filter enable [find comment="allow pptp from anywhere"];
      /log warning "Active TM not found. PPP access enabled!";
    }
  } else={
    foreach k in=[/ppp active find comment~"TM"] do={
      if ([/ppp active get $k caller-id] != [/ip firewall address-list get [find comment=$hostName] address]) do={
        :local oldAddress [/ip firewall address-list get [find comment=$hostName] address];
        /ip firewall address-list set [find comment=$hostName] address=[/ppp active get $k caller-id];
        /ip firewall filter disable [find comment="allow pptp from anywhere"];
        :local newAddress [/ppp active get $k caller-id];
        # [[:parse [/system script get TG source]] Text=("External IP Changed The new address: "."$NewAddress")];
        /log warning "$hostName changed $oldAddress to $newAddress. PPP access disabled.";
        :return null;
      } 
      :if ([/ip firewall filter find comment="allow pptp from anywhere" disabled=no]) do={
        /ip firewall filter disable [find comment="allow pptp from anywhere"];
        /log warning "Active TM found. PPP access disabled.";
      }
      :return null
      }
  }
}

$Main
