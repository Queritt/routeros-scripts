# Guest
# ver 0.3
# modified 2023/01/15

#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}

#---Function of showing information about available commands
:local Help do={
    :local help ("Guest options: "."%0A". \
        " > print [pass; limit]"."%0A". \
        " > set:"."%0A". \
        "     pass [gen; manual]"."%0A". \
        "     limit [1-90]");
    :return $help;
}

:local Print do={
    :local action $1;
    :if ($action = "pass") do={
        :local guestPass [/interface wireless security-profiles get Guest wpa2-pre-shared-key];
        :return ("Guest-Wireless pass: ". $guestPass);
    }
    :if ($action = "limit") do={
        :local guestLimit ([/interface wireless access-list get [find comment="wlan1-Guest"] ap-tx-limit] / 1000000);
        :return ("Guest-Wireless limit: ".$guestLimit."M.");
    }
    :return ("Guest print option is not recognized.");
}

:local Set do={
    :local action $1;
    :local option $2;
    :if ($action = "pass") do={
        :if ($option = "gen") do={
            :local newPass [[:parse [/system script get Password source]] 8 1];
            /interface wireless security-profiles set Guest wpa2-pre-shared-key=$newPass;
            :return ("Guest-Wireless new pass: ". $newPass);
        } else={
            :if ([:len $option] > 7) do={
                /interface wireless security-profiles set Guest wpa2-pre-shared-key=$option;
                :return ("Guest-Wireless new pass: ". $option);
            } else={ :return ("\"$option\"" . " less than 8 characters. Try againg..."); };
        }
    }
    :if ($action = "limit") do={
        :do {
            :if ($option = null || $option > 90 || $option = 0) do={:set option 10M} else={ :set option ($option . "M"); };
            :foreach i in=[/interface wireless access-list find (comment ~"Guest")] do={
                /interface wireless access-list set $i ap-tx-limit=$option;
            }; 
            :return ("Guest-Wireless download limit changed to " . "\"$option\".");
        } on-error={ :return ("Guest-Wireless limit error: " . "\"$option\"" . " not correct! Try again..."); }
    }
    :return ("Guest set option is not recognized.");
}

#---MAIN---#
#---Printing current password
:if ($0 = "print") do={ $SendMsg [$Print $1]; :return []; };
#---Setting download limit
:if ($0 = "set") do={ $SendMsg [$Set $1 $2]; :return []; };
#---Help
$SendMsg [$Help];
