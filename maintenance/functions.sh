#!/bin/bash

#Load in settings
. settings.conf

function sync_repo_osci {
  release=$1
  kojitag=$2
  outdir=$3
  binrepo="$REPOTOPDIR/$kojitag/$BINARYDIR/"
  srcrepo="$REPOTOPDIR/$kojitag/$SRPMDIR/"
  mkdir -p $outdir
  cd $outdir
  mkdir -p SRPMS x86_64 noarch
  make_yum_conf "$binrepo" "$srcrepo"
  reposync -c "$YUMCONF" --repo "$(get_repo_name "$binrepo")" --norepopath -p .
  reposync -c "$YUMCONF" --source --repo "$(get_repo_name "$srcrepo")" --norepopath -p .
  #get_puppet27
  mv *.x86_64.rpm x86_64
  mv *.noarch.rpm noarch
  mv *.src.rpm SRPMS
  createrepo .
}
function get_puppet27 {
  puppetver="2.7.19-1.el6"
  kojitag="puppet27"
  mkdir -p noarch/ SRPMS/
  wget "$REPOTOPDIR/$kojitag/$BINARYDIR/puppet-$puppetver.noarch.rpm" -O noarch/puppet-$puppetver.noarch.rpm
  wget "$REPOTOPDIR/$kojitag/$BINARYDIR/puppet-server-$puppetver.noarch.rpm" -O noarch/puppet-server-$puppetver.noarch.rpm
  wget "$REPOTOPDIR/$kojitag/$SRPMDIR/puppet-$puppetver.src.rpm" -O noarch/puppet-$puppetver.src.rpm
} 

function copy_to_public_mirror {
#Release here should be epel-fuel-folsom-2.x
  #Strip tailing slash
  path=$1
  release=${1%/}
  rsync -vazPL "$path" "$EXT_REPO/$1"
}
function make_yum_conf {
#Parameters: repo urls
  
  cat > $YUMCONF << EOF
[main]
cachedir=/var/cache/yum
keepcache=1
debuglevel=2
logfile=/var/log/yum.log
exactarch=1
obsoletes=1

EOF
  for url in $@; do
    #Strip tailing slash
    url=${url%/}
    if ! grep -q "http" <<< "$url"; then
      echo "$url is not a valid url."
      exit 1
    fi
    #Strip non alphanumeric so it can be a yum repo name
    reponame=$(get_repo_name "$url")

    cat >> $YUMCONF << EOF
[$reponame]
name=$reponame
baseurl=$url
gpgcheck=0
enabled=1

EOF
  done
}
function get_repo_name {
#prints string with only alphanumeric characters
  echo -en "$1" | sed 's/[^[:alnum:]]//g'
}
function cleanup {
  rm -rf $TMPDIR
}

