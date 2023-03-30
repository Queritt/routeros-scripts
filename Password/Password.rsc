# Password generator
# ver 0.3
# modified 2022/09/06
:local lenPass;
:local countPass;
:local passList "";
# :local passList ("Password: " . "%0A");
#--
:local Help do={
    :local help ("Password options: "."%0A". \
        " > print [numbers 8-24; amount 1-25]"."%0A". \
        " > [numbers 8-24]");
    [[:parse [/system script get TG source]] Text=$help];
}
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
:if ( $0 = null || $0 = "help" || $0 = "Help" ) do={ $Help; return []; };
:if ( $0 = "print") do={ :set lenPass $1; :set countPass $2; } else={ :set lenPass $0; :set countPass $1; }
:if ( $countPass = null || $countPass > 25) do={:set countPass 1; };
:if ( [:ping address="www.random.org" count=3] = 0 ) do={ $SendMsg ("\"www.random.org\" is not available. Try again..."); :return []; };
:if ($lenPass < 8) do={ :set lenPass 8};
:if ($lenPass > 24) do={ :set lenPass 24};
:do {
    :for i from=1 to=($countPass) do={
        :local new ([/tool fetch url="https://www.random.org/passwords/\?num=1&len=$lenPass&format=plain&rnd=new" output=user as-value]->"data")
        :set $new ( [:pick $new 3 ([:len $new] - 1)] . [:pick $new 0 3] );
        :set $passList ("$passList" . "$new" . "%0A");
    }
    # :if ( $0 = "print") do={ $SendMsg ("Password: " . "%0A" . "$passList"); } else={ :if ($countPass = 1) do={ :return $passList; } };

    :if ( $0 = "print") do={ $SendMsg ("Password: " . "%0A" . "$passList"); } else={ :if ($countPass = 1) do={ :return [:pick $passList 0 [:find $passList "%"]]; } };
} on-error={ $SendMsg ("Password: Something went wrong. Try again...") };
