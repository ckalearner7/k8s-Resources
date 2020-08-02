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

ORIG_DEST=~/.kube
ORIG_FILENAME=config

ls -l $ORIG_DEST/$ORIG_FILENAME

#Make a backup of the kube-apiserver file in the ~/.save directory
cp -p $ORIG_DEST/$ORIG_FILENAME ~/.save/$ORIG_FILENAME.$suffix

#Make a local copy to run sed against
cp -p $ORIG_DEST/$ORIG_FILENAME $ORIG_FILENAME

#Run sed against the local copy
sed 's/6443/7443/' $ORIG_FILENAME > /tmp/$ORIG_FILENAME

#Delete the local copy since I dont need it anymore
rm $ORIG_FILENAME

# copy the mucked up file to the actual location
cp /tmp/$ORIG_FILENAME $ORIG_DEST/$ORIG_FILENAME
