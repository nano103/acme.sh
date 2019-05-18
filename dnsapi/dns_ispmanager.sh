#!/bin/bash

#Here is a sample custom api script.
#This file name is "dns_myapi.sh"
#So, here must be a method   dns_myapi_add()
#Which will be called by acme.sh to add the txt record to your api system.
#returns 0 means success, otherwise error.
#
#Author: Neilpang
#Report Bugs here: https://github.com/Neilpang/acme.sh
#
########  Public functions #####################

#ISPMANAGERAPI_BASE="https://delta.netbreeze.net:1500/ispmgr?authinfo=username:password"

#Usage: dns_ispmanager_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_ispmanager_add() {
  fulldomain=$1
  txtvalue=$2
  
  ISPMANAGERAPI_BASE="${ISPMANAGERAPI_BASE:-$(_readaccountconf_mutable ISPMANAGERAPI_BASE)}"
  if [ -z "$ISPMANAGERAPI_BASE" ]; then
    ISPMANAGERAPI_BASE=""
    _err "You don't specify ISPMANAGER API base."
    _err "Please create you key and try again."
    return 1
  fi

  #save the credentials to the account conf file.
  _saveaccountconf_mutable ISPMANAGERAPI_BASE  "$ISPMANAGERAPI_BASE"  
  
  _ispmanager_init
  
  #_info "Using ispmanager"
  #_debug fulldomain "$fulldomain"
  #_debug txtvalue "$txtvalue"
  
  _ispmanager_get "out=xml&func=domain.sublist.edit&sok=yes&plid=$_domain&name=$_sub_domain&sdtype=TXT&addr=$txtvalue"
}

#Usage: fulldomain txtvalue
#Remove the txt record after validation.
dns_ispmanager_rm() {
  fulldomain=$1
  txtvalue=$2
  
  _ispmanager_init
  
  #_info "Using ispmanager"
  #_debug fulldomain "$fulldomain"
  #_debug txtvalue "$txtvalue"
  
  _ispmanager_get "out=xml&func=domain.sublist.delete&plid=$_domain&elid=$_sub_domain%20TXT%20%20$txtvalue"
}

####################  Private functions below ##################################
#_acme-challenge.www.domain.com
#returns
# _sub_domain=_acme-challenge.www
# _domain=domain.com
_get_root() {

  l_domain=$1

  if ! _ispmanager_get "func=domain&out=xml"; then
    return 1
  fi

  domains=$(echo "$response" | sed -n '/dispname/{s/.*<dispname>//;s/<\/dispname.*//;p;}')
  SAVEIFS=$IFS
  IFS=$'\n'
  for dm in $domains ; do
    if _endswith "$l_domain" "$dm" >/dev/null; then
      _domain="$dm"
      l_dlen=${#_domain}
      #length of domain
      l_dlen=$(_math "$l_dlen" + 2)
      #and dot and first char number is 1
      _sub_domain=$(echo "$l_domain" | rev | cut -c $l_dlen- | rev)
      IFS=$SAVEIFS
      return 0
    fi
  done
  IFS=$SAVEIFS
return 1
}

_ispmanager_get() {
  ep="$1"
  l_url="$ISPMANAGERAPI_BASE&$ep" 
  #_debug2 "url" "$l_url"

  response="$(_get "$l_url")"

  if [ "$?" != "0" ]; then
    _err "error $ep"
    return 1
  fi
  #_debug2 response "$response"
  return 0
}

_ispmanager_init() {
  #_debug "First detect the root zone"
  if ! _get_root "$fulldomain"; then
    _err "invalid domain"
    return 1
  fi
  _debug _sub_domain "$_sub_domain"
  _debug _domain "$_domain"
}
