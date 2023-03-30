# Password generator
# ver 0.4
# modified 2023/01/09
:local lenPass;
:local countPass;
:local symPass;
:local passList "";
# :local nums "0123456789";
# :local lowLetter "abcdefghijklmnopqrstuvwxyz";
# :local bigLetter "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
:local nums "23456789";
:local lowLetter "abcdefghjkmnpqrstuvwxyz";
:local bigLetter "ABCDEFGHIJKMNPQRSTUVWXYZ";
:local passStr ("$nums"."$lowLetter"."$bigLetter");
#--
:local Help do={
    :local help ("Password options: "."%0A". \
        " > print [numbers (6-24); amount (1-24); sym]"."%0A". \
        " > [numbers (6-24)]");
    [[:parse [/system script get TG source]] Text=$help];
}
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
:if ( $0 = null || $0 = "help" || $0 = "Help" ) do={ $Help; return []; };
:if ( $0 = "print") do={ :set lenPass $1; :set countPass $2;} else={ :set lenPass $0; :set countPass $1;}
:if ( $countPass = null || $countPass > 25) do={:set countPass 1; };
:if ($lenPass < 6) do={ :set lenPass 6};
:if ($lenPass > 24) do={ :set lenPass 24};
:do {
    :for i from=1 to=($countPass) do={
        :local new [/rndstr from=($passStr) length=$lenPass];
        :set $passList ("$passList" . "$new" . "%0A");
    }
    :if ( $0 = "print") do={ $SendMsg ("Password: " . "%0A" . "$passList");} else={ :if ($countPass = 1) do={ :return [:pick $passList 0 [:find $passList "%"]]; } };
} on-error={ $SendMsg ("Password: Something went wrong. Try again...") };
