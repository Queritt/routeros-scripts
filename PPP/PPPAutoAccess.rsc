# PPPAutoAccess with HoneyPot
# 0.2
# 2022/11/03
:local hostName "pk";
:local oldAddress [/ip firewall address-list get [find comment=$hostName] address];
:local newAddress;
:if ( [/ppp active find comment="WM"] != "") do={
    :set newAddress [/ppp active get [find comment="WM"] caller-id];
} else={
	:set newAddress [/ppp secret get [find comment="WM"] last-caller-id];
}
:if ($oldAddress != $newAddress) do={
	/ip firewall address-list set [find comment=$hostName] address=$newAddress;
	/log warning "$hostName changed \"$oldAddress\" to \"$newAddress\".";	
}
