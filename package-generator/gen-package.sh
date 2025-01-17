#! /bin/bash

# Kullanım örneği: sudo ./canan.sh -p cem -v 1.0 -b "a(=1.0), b(=2)"

# $ sudo ./paket_uret.sh -p a -v 1.0.0.600 -b "a-lib(=1.0.0.322)"
# paket adi: a
# paket surum no: 1.0.0.600
# bagimli paketler: a-lib(=1.0.0.322)
# Paket dizini mevcut degil olusturulacak...
# a/DEBIAN dizini oluşturuldu.
# dpkg-deb: building package 'a' in './dists/trusty/main/binary-amd64/a_1.0.0.600.deb'.

usage="$(basename "$0") paket_adı sürüm_numarası bağımlı_olduğu_paket_adı

Argümanlar:
    -h  bu yardım metnini gösterir
    -p  paket adını
    -v  paketin sürüm numarasını
    -b  paketin bağımlı olduğu paket bilgilerini

Örneğin:
    $(basename "$0") -p paket_a -v 1.0 -b \"paket_b(>=1.0.1) paket_c(=2.0) paket_d\"
"

while getopts h:p:v:b: flag; do
  case "$flag" in
    h) echo "$usage"
       exit
       ;;
    p) echo "paket adi: $OPTARG" >&2
       paket_adi=${OPTARG}
       ;;
    v) echo "paket surum no: $OPTARG" >&2
       paket_surum_no=${OPTARG}
       ;;
    b) echo "bagimli paketler: $OPTARG" >&2
       bagimli_paketler=${OPTARG}
       ;;
    *) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done

paket_olusturma_dizini="paketler"

if [ ! -d $paket_olusturma_dizini/${paket_adi}/DEBIAN ]
then
  echo "Paket dizini mevcut degil olusturulacak..."
  mkdir -m 775 -p "${paket_olusturma_dizini}/${paket_adi}/DEBIAN"  
  # chmod -R 775 ./$paket_olusturma_dizini/$paket_adi/DEBIAN

  if [ $? -eq 0 ]; then
    echo "${paket_adi}/DEBIAN dizini oluşturuldu."
  else
    echo "Dizin olusturulamadi!"
    exit 1
  fi
fi

# DEBIAN tanım dosyası olusturulacak
cat << EOF > ./$paket_olusturma_dizini/$paket_adi/DEBIAN/control
Package: $paket_adi
Version: $paket_surum_no
Architecture: amd64
Maintainer: a
Depends: $bagimli_paketler
Conflicts:
Section: web
Priority: standard
Description: retrieves files from the web
EOF


if [ $? -ne 0 ]; then
  echo "./$paket_olusturma_dizini/$paket_adi/DEBIAN/control dosyasi olusturulamadi!"
  exit 1
fi

repo_paket_dizini="/data/dists/focal/main/binary-amd64"

if [ ! -d "$repo_paket_dizini" ]
then
    echo "Paketin yuklenecegi ve docker repo'nun tarayacagi dizin ($repo_paket_dizini) mevcut degil, cikilacak!"
    exit 1
fi

dpkg-deb  -b  ./$paket_olusturma_dizini/$paket_adi  $repo_paket_dizini/${paket_adi}_${paket_surum_no}.deb
