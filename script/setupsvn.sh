#!/bin/bash
# derived from http://www.hostingrails.com/forums/wiki_thread/4
echo
echo "Setup a new SVN repository under ~/svn/<projectname>"
echo "Usage: $0 <projectname>"
echo

if [ $# == 0 ]
then
exit
fi

PROJECT=$1

echo "Creating SVN repository"
mkdir -p ~/svn/$PROJECT
svnadmin create ~/svn/$PROJECT
mkdir ~/tmp/$PROJECT
cd ~/tmp/$PROJECT
mkdir branches
mkdir tags
mkdir trunk
cd trunk

rails .

echo "Creating initial import of temp project into SVN"
svn import ~/tmp/$PROJECT file:///home/$USER/svn/$PROJECT -m "created project"

cd ~
rm -rf ~/tmp/$PROJECT

echo "Checking out a working copy on the server"
mkdir ~/tmp/workingcopy
cd ~/tmp/workingcopy
svn co file:///home/$USER/svn/$PROJECT/trunk $PROJECT

echo "Cleaning up some rails-specific things..."
cd $PROJECT
svn remove log/*
svn commit -m 'no logs directory in version control please'
svn propset svn:ignore "*.log" log/
svn update log/
svn commit -m 'no log files either'