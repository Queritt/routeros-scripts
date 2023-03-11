# Password generator
# ver 0.1
# modified 2022/08/23
:local lenPass;
#--
:local Help do={
    :local help ("Password options: "."%0A". \
        " > print [numbers 8-24]"."%0A". \
        " > [numbers 8-24]");
    [[:parse [/system script get TG source]] Text=$help];
}
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
:if ( $0 = null || $0 = "help" || $0 = "Help" ) do={ $Help; return []; };
:if ( $0 = "print") do={ :set lenPass $1; } else={ :set lenPass $0; }
:do {
    :if ($lenPass < 8) do={ :set lenPass 8};
    :if ($lenPass > 24) do={ :set lenPass 24};
    :local new ([/tool fetch url="https://www.random.org/passwords/\?num=1&len=$lenPass&format=plain&rnd=new" output=user as-value]->"data")
    :set $new ( [:pick $new 3 ([:len $new] - 1)] . [:pick $new 0 3] );
    :if ( $0 = "print") do={ $SendMsg ("Password: $new"); } else={ :return $new; };
} on-error={ $SendMsg ("Password: Something went wrong. Try again...") };
