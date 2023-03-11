# modified 2022/05/27

:local botID    "botXXXXXXXXXXXXX";
:local myChatID "-XXXXXXXX";
:local outMsg $Text;
:local urlString ("https://api.telegram.org/$botID/sendmessage\?chat_id=$myChatID&text=$outMsg");
/tool fetch url=$urlString as-value output=user;

# Run Text >>> [[:parse [/system script get TG source]] Text="TEXT"]
# Run Val >>> [[:parse [/system script get TG source]] Text=$VAL]
# Run Text+Val >>> [[:parse [/system script get TG source]] Text=("TEXT"."$VAL")]
