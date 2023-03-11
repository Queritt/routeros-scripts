# modified 2022/05/27

:global TG do={
    :local botID    "botXXXXXXXXXXXXX";
    :local myChatID "-XXXXXXXX";
    :local outMsg $1;
    :local urlString ("https://api.telegram.org/$botID/sendmessage\?chat_id=$myChatID&text=$outMsg");
    /tool fetch url=$urlString as-value output=user;
}

# Run Text >>> /sys script run TG; :global TG; $TG "TEXT"
# Run Val >>> /sys script run TG; :global TG; $TG $Val
# Run Text+Val >>> /sys script run TG; :global TG; $TG ("Text: "."$Val")
