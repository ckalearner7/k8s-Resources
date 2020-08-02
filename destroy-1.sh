#! /bin/sh
# This script will modify the kube-apiserver file
if [ -d ~/.save/ ]; then
  echo "dir exists"
else
  echo "create dir"
  mkdir ~/.save
  echo "directory created"
fi
suffix=`date +"%m-%d-%Y%T"`
echo $suffix

ORIG_FILENAME=kube-apiserver.yaml
cp -p /etc/kubernetes/manifests/$ORIG_FILENAME ~/.save/$ORIG_FILENAME.$suffix
cp -p /etc/kubernetes/manifests/$ORIG_FILENAME $ORIG_FILENAME
sed 's/\/etc\/kubernetes\/pki\/ca.crt/\/etc\/kubernetes\/pki\/ca1.crt/' $ORIG_FILENAME > /tmp/a.yaml
cp /tmp/a.yaml /etc/kubernetes/manifests/$ORIG_FILENAME
