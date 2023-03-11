# Guest
# ver 0.2
# modified 2023/01/15
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
#---Function of showing information about available commands
:local Help do={
    :local help ("Guest options: "."%0A". \
        " > print | print limit"."%0A". \
        " > limit [1-90]"."%0A". \
        " > gen");
    :return $help;
}
:local Print do={
    :local action $1;
    :if ($action = "limit") do={
        :local guestLimit ([/interface wireless access-list get [find comment="wlan1-Guest"] ap-tx-limit] / 1000000);
        :return ("Guest-Wireless limit: ".$guestLimit."M.");
    }
    :local guestPass [/interface wireless security-profiles get Guest wpa2-pre-shared-key];
    :return ("Guest-Wireless pass: ". $guestPass);
}
:local Limit do={
    :local limit $1;
    :do {
        :if ($limit = null || $limit > 90 || $limit = 0) do={:set limit 10M} else={ :set limit ($limit . "M"); };
        :foreach i in=[/interface wireless access-list find (comment ~"Guest")] do={
            /interface wireless access-list set $i ap-tx-limit=$limit;
        }; 
        :return ("Guest-Wireless download limit changed to " . "\"$limit\".");
    } on-error={ :return ("Guest-Wireless limit error: " . "\"$limit\"" . " not correct! Try again..."); }
}
:local Gen do={
    :local newPass [[:parse [/system script get Password source]] 8 1];
    :if ([:len $newPass ] > 7) do={
        /interface wireless security-profiles set Guest wpa2-pre-shared-key=$newPass;
        :return ("Guest-Wireless new pass: ". $newPass);
    } else={ :return ($newPass . " less than 8 characters. Try againg..."); };
}
#---MAIN---#
#---Printing current password
:if ($0 = "print") do={ $SendMsg [$Print $1]; :return []; };
#---Changing download limit
:if ($0 = "limit") do={ $SendMsg [$Limit $1]; :return []; };
#---Generating a new password
:if ($0 = "gen") do={ $SendMsg [$Gen]; :return []; };
#---Help
$SendMsg [$Help];
