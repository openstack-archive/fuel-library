if [ "z`umm status`" = "zumm" ] ; then
    cat /etc/issue.mm
    [ "$#" != "0" ] && echo "$@"
fi
