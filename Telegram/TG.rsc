# modified 2022/05/31

:local botID    "botXXXXXXXXXXXXX";
:local myChatID "-XXXXXXXX";
:local emailList {"user@mail.ru"}
:local outMsg $Text;
:local outMsgEmail $EmailText;
:if ([:len $outMsgEmail] = 0) do={ :set outMsgEmail $Text; };
:local urlString ("https://api.telegram.org/$botID/sendmessage\?chat_id=$myChatID&text=$outMsg");

## Sending email
:local EmailSend do={
    foreach mail in=$2 do={
        :if ([:len $1] <= 35) do={
            /tool e-mail send to=$mail subject="$1";
        } else={
            /tool e-mail send to=$mail subject=([:pick $1 0 32]."...") body="$1";
        }
    } 
}

## Main
:do { 
    /tool fetch url=$urlString as-value output=user; 
} on-error={$EmailSend $outMsgEmail $emailList}

# Run Text >>> [[:parse [/system script get TG source]] Text="TEXT"]
# Run Val >>> [[:parse [/system script get TG source]] Text=$VAL]
# Run Text+Val >>> [[:parse [/system script get TG source]] Text=("TEXT"."$VAL")]

