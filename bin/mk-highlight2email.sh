#!/bin/sh

if [ -s $MAGIC_EMAIL ]
then
    MAGIC_EMAIL=$1
fi

BOOKMARKLET='var h2e=function (m){ var s=document.title;var b=window.getSelection();location.href="mailto:?subject="+escape(s)+"&body="+escape(b)+"&to="+escape(m); }; h2e("'${MAGIC_EMAIL}'"); void(0);'

echo $BOOKMARKLET
