## DomainList
## 0.10
## 2023/04/08
:local domains {

"instagram";
"cdninstagram";
"twitter";
"twimg";
"facebook";
"fbcdn";
"fb.com";
"messenger.com";

"news.google.com";
"googleusercontent.com";
"play.google.com";

"themoviedb";
"tmdb";

"rutracker";
"t-ru.org";
"rutor";
"nnmclub.to";

"porn";
"intel";

}

:local listName "WEB-2";
:local listComment "DomainList";

:foreach dn in=$domains do={
    :foreach i in=[/ip dns cache find name~"$dn"] do={ 
        :do { /ip firewall address-list add list=$listName address=[/ip dns cache get $i name] timeout=1w comment=$listComment; :delay 100ms;} on-error={}
    }
    :delay 500ms;
}
