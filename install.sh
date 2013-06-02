#!/bin/sh

PROGRAM=`echo $0 | sed 's%.*/%%'`
PROGDIR="$(cd `dirname $0`; echo $PWD)"

THE_TDS=swathesis.tds.zip

KPSEWHICH=`command -v kpsewhich`



__usage() {
  printf "Usage: $PROGRAM [OPTIONS]

Install swathesis.

OPTIONS
  --home      install to TEXMFHOME  ($($KPSEWHICH -var-value TEXMFHOME )) (* recommended)
  --local     install to TEXMFLOCAL ($($KPSEWHICH -var-value TEXMFLOCAL))
  --tex       install to TEXMFDIST  ($($KPSEWHICH -var-value TEXMFDIST )) (not recommended)

  --bin-home  install the \`swth' script to $BIN_DEFAULT (*)
  --bin-local install the \`swth' script to /usr/local/bin
  --bin-tex   install the \`swth' script to $(dirname $KPSEWHICH)
  --bin-sys   install the \`swth' script to /usr/bin (not recommended)

  --no-req    do not atempt to install required packages
  --no-bin    do not link the \`swth' script

  --verbose   turn verbose output on
  --help      output this help and exit

* = default

"
}

__find_bin() {
  if [ -d "${HOME}/.bin" ] && echo $PATH | tr : \n | grep -q "${HOME}/.bin"; then
    echo "${HOME}/.bin"
  else
    echo "${HOME}/bin"
  fi
}


__check_dir() {
  DIR="$1"
  if [ ! -d "$DIR" ]; then
    printf "\n$DIR does not exist, create it? [YES|no] "
    read ANS
    case "$ANS" in
      [Nn][Oo]?) : ;;
      *) mkdir -p $DIR ;;
    esac
  fi

  if [ ! -w "$DIR" ]; then
    printf "\n$DIR is not writable, continue as root (sudo)? [NO|yes] "
    read ANS
    case "$ANS" in
      [Yy][Ee][Ss]) E=sudo ;;
      *) exit 2 ;;
    esac
  fi
}

__verbose_info() {
  printf "
Information
-----------
DEST=         $DEST
DEST_DIR=     $DEST_DIR
DEST_DEFAULT= $DEST_DEFAULT
BIN=          $BIN
BIN_DEFAULT=  $BIN_DEFAULT
"
if [ ! -z "$E" ]; then
  echo "using $E as sudo";
fi
if [ "x$REQUIREMENTS" = "xfalse" ]; then
  printf "not "
fi
echo "installing requirements"
if [ "x$NOBIN" = "xtrue" ]; then
  printf "not "
fi
echo "installing binary"
echo "-----------"

}

VERBOSE=false
DEST=
DEST_DEFAULT="$($KPSEWHICH -var-value TEXMFHOME)"
REQUIREMENTS=true
BIN=
BIN_DEFAULT="$(__find_bin)"
NOBIN=false
E=


while test $# -gt 0; do
  case "x$1" in
    x--help|x-h)
      __usage
      exit 0
      ;;
    x--verbose|x-v) VERBOSE=true                ;;
    x--home)        DEST=TEXMFHOME              ;;
    x--local)       DEST=TEXMFLOCAL             ;;
    x--tex)         DEST=TEXMFDIST              ;;
    x--bin-home)    BIN="$BIN_DEFAULT"          ;;
    x--bin-local)   BIN=/usr/local/bin          ;;
    x--bin-tex)     BIN="$(dirname $KPSEWHICH)" ;;
    x--bin-tex)     BIN=/usr/bin                ;;
    x--no-req)      REQUIREMENTS=false          ;;
    x--no-bin)      NOBIN=true                  ;;
    *)
      echo "$PROGRAM: unknown option \`$1', try --help if you need it." >&2
      exit 1
      ;;
  esac
  shift
done


echo "Installing swathesis"
echo "===================="
echo ""
echo ""
if [ "x$VERBOSE" = "xtrue" ]; then
  __verbose_info
fi


if [ -z "$DEST" ]; then
  printf "
Where shall I install swathesis to,
  install to TEXMFHOME  ($($KPSEWHICH -var-value TEXMFHOME )) (recommended)
  install to TEXMFLOCAL ($($KPSEWHICH -var-value TEXMFLOCAL))
  install to TEXMFDIST  ($($KPSEWHICH -var-value TEXMFDIST )) (not recommended)
  or somewhere else?
[TEXMFHOME] "
  read DEST
  if [ -z "$DEST" ]; then DEST=TEXMFHOME; fi
fi
case "$DEST" in
  TEXMF*) DEST_DIR=$("$KPSEWHICH" -var-value "$DEST") ;;
  *)      DEST_DIR="$DIR"                             ;;
esac

__check_dir "$DEST_DIR"

if [ "x%NOBIN" != "xtrue" ]; then
  if [ -z "$BIN" ]; then
    printf "
Where shall I install the \`swth' script to?
  home  install to $BIN_DEFAULT
  local install to /usr/local/bin
  tex   install to $(dirname $KPSEWHICH)
  sys   install to /usr/bin (not recommended)
  or somewhere else?
[home] "
    read ANS
    if [ -z "$ANS" ]; then ANS="$BIN_DEFAULT"; fi
    case "$ANS" in
      home)  BIN="$BIN_DEFAULT"          ;;
      local) BIN=/usr/local/bin          ;;
      tex)   BIN="$(dirname $KPSEWHICH)" ;;
      sys)   BIN=/usr/bin                ;;
      *)     BIN="$ANS"                  ;;
    esac
  fi
  __check_dir "$BIN"
  if [ -f "$BIN"/swth -o -L "$BIN"/swth ]; then
    printf "\`swth' is already present in $BIN.
Shall I ignore that (no linking) or overwrite that file?
[IGNORE|overwrite|abort] "
    read ANS
    case "$ANS" in
      o|over*)  rm "$BIN"/swth ;;
      a|abort*) exit 128       ;;
      *)        NOBIN=true     ;;
    esac
  fi
fi


if [ "x$VERBOSE" = "xtrue" ]; then
  __verbose_info
fi


if [ "x$REQUIREMENTS" != "xfalse" ]; then
  echo "> Installing Requirements"
  _PREQ="$PWD"; cd "$PROGDIR"/requirements
  TDS_DEST="$DEST_DIR" ./get_requirements.sh
  cd "$_PREQ"
fi

if [ ! -f "$PROGDIR/$THE_TDS" ]; then
  echo "> (re)Building TDS package"
  _PTDS="$PWD"; cd "$PROGDIR"
  ./tdsify.sh
  cd "$_PTDS"
fi




echo "> Deploying swathesis into $DEST_DIR"
_P=$PWD
cd "$DEST_DIR"

$E unzip -q "$PROGDIR/$THE_TDS"

cd "$_P"


if [ "x$NOBIN" != "xtrue" ]; then
  echo "> Linking \`swth' into $BIN"
  $E ln -s "$DEST_DIR"/scripts/swathesis/swth.sh "$BIN"/swth
fi

echo "Done"