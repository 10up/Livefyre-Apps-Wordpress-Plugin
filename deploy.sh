#! /bin/bash
# A modification of Dean Clatworthy's deploy script as found here: https://github.com/deanc/wordpress-plugin-git-svn
# The difference is that this script lives in the plugin's git repo & doesn't require an existing SVN repo.

# Let's begin...
echo ".........................................."
echo 
echo "Preparing to deploy wordpress plugin"
echo 
echo ".........................................."
echo 

# main config
PLUGINSLUG="livefyre-apps"
CURRENTDIR=`pwd`
MAINFILE="livefyre-apps.php" # this should be the name of your main php file in the wordpress plugin

# svn config
SVNPATH="TMP_$PLUGINSLUG" # path to a temp SVN repo. No trailing slash required and don't add trunk.
SVNURL="http://plugins.svn.wordpress.org/livefyre-apps" # Remote SVN repo on wordpress.org, with no trailing slash
SVNTRUNK=$SVNURL"/trunk/"
SVNTAGS=$SVNURL"/tags"
SVNUSER="Livefyre" # your svn username
SVNPASSWORD=$LF_WP_ORG_PASSWORD

GITREPO="https://github.com/Livefyre/Livefyre-Apps-Wordpress-Plugin.git" # git repo

# Check if subversion is installed before getting all worked up
if ! which svn >/dev/null; then
	echo "You'll need to install subversion before proceeding. Exiting....";
	exit 1;
fi

# Check version in readme.txt is the same as plugin file after translating both to unix line breaks to work around grep's failure to identify mac line breaks
README_VERSION=`grep "^Stable tag:" readme.txt | awk -F' ' '{print $NF}'`
echo "readme.txt version: $README_VERSION"
MAINFILE_VERSION=`grep "^Version:" $MAINFILE | awk -F' ' '{print $NF}'`
echo "$MAINFILE version: $MAINFILE_VERSION"
if [ "$README_VERSION" != "$MAINFILE_VERSION" ]; then echo "Version in readme.txt & $MAINFILE don't match. Exiting...."; exit 1; fi
echo "Versions match in readme.txt and $MAINFILE. Let's proceed..."
TAG=$MAINFILE_VERSION
SVNDEST="branches/$TAG/trunk"

# For sanity reasons
echo ".........................................."
echo 
echo "Parameters:"
echo "Plugin slug: $PLUGINSLUG"
echo "Current directory: $CURRENTDIR"
echo "Main plugin file: $MAINFILE"
echo "Path to svn temp dir: $SVNPATH"
echo "svn url: $SVNURL"
echo "svn username: $SVNUSER"
echo "svn password: $SVNPASSWORD"
echo "svn destination: $SVNDEST"
echo
echo ".........................................."
echo 

if git show-ref --tags --quiet --verify -- "refs/tags/$README_VERSION"
	then 
		echo "Version $README_VERSION already exists as git tag. Should be Exiting...."; 
	else
		echo "Git version does not exist. Let's proceed..."
		echo "Tagging new version in git"
		git tag -a "$README_VERSION" -m "Tagging version $README_VERSION"
		echo "Pushing latest commit to origin, with tags"
		git push origin master --tags
fi

echo "Creating local copy of SVN repo ..."
mkdir $SVNPATH
svn co $SVNURL $SVNPATH


mkdir $SVNPATH/branches/$TAG
mkdir $SVNPATH/$SVNDEST

echo "Exporting the HEAD of master from git to the trunk of SVN"
git clone --depth 1 $GITREPO $SVNPATH/$SVNDEST

echo "Moving back up to $CURRENTDIR"
cd $CURRENTDIR

echo "Ignoring github specific files and deployment script"
rm -rf $SVNPATH/$SVNDEST/{deploy.sh,install.sh,livefyre-wpvip-page.txt,makefile,README.md,.git,.gitignore}

echo "Adding local contents to remote branch"
svn add $SVNPATH/$SVNDEST/

echo "Checking in added changes"
svn ci --username=$SVNUSER --password=$SVNPASSWORD $SVNPATH -m "Committing $SVNDEST" 

echo "Moving version branch to trunk"
echo svn move --username=$SVNUSER --password=$SVNPASSWORD $SVNURL/$SVNDEST/ $SVNTRUNK -m "Moving $SVNDEST/ to /trunk"

echo "SVN Tag & Commit"
echo svn copy --username=$SVNUSER --password=$SVNPASSWORD $SVNTRUNK $SVNTAGS/$TAG -m "Pushing /trunk into /tags/$TAG"

# rm -rf $SVNPATH
echo "*** FIN ***"
