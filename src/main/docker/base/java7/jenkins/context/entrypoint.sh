#! /bin/bash

while getopts "d:c:j:e:" arg; do
  case $arg in
    d) dataContainer=$OPTARG ;;  # Name of data container that is used by slaves
    c) dockerUrl=$OPTARG ;;      # Url for (non-TLS) docker host to run slaves in                    
    j) jenkinsUrl=$OPTARG ;;     # Url to access jenkins with (from the outside)                     
    e) adminEmail=$OPTARG ;;     # Admin email in jenkins configuration
  esac
done

shift $((OPTIND-1))

# Generate configuragtion files
/luci/bin/generateJenkinsConfigXml.sh $dataContainer $dockerUrl > /usr/share/jenkins/ref/config.xml
/luci/bin/generateJenkinsLocateConfiguration.sh $jenkinsUrl $adminEmail > /usr/share/jenkins/ref/jenkins.model.JenkinsLocationConfiguration.xml

set -e

# Copy files from /usr/share/jenkins/ref into /var/jenkins_home
# So the initial JENKINS-HOME is set with expected content. 
# Don't override, as this is just a reference setup, and use from UI 
# can then change this, upgrade plugins, etc.
copy_reference_file() {
	f=${1%/} 
	echo "$f" >> $COPY_REFERENCE_FILE_LOG
    rel=${f:23}
    dir=$(dirname ${f})
    echo " $f -> $rel" >> $COPY_REFERENCE_FILE_LOG
	if [[ ! -e /var/jenkins_home/${rel} ]] 
	then
		echo "copy $rel to JENKINS_HOME" >> $COPY_REFERENCE_FILE_LOG
		mkdir -p /var/jenkins_home/${dir:23}
		cp -r /usr/share/jenkins/ref/${rel} /var/jenkins_home/${rel};
		# pin plugins on initial copy
		[[ ${rel} == plugins/*.jpi ]] && touch /var/jenkins_home/${rel}.pinned
	fi; 
}
export -f copy_reference_file
echo "--- Copying files at $(date)" >> $COPY_REFERENCE_FILE_LOG
find /usr/share/jenkins/ref/ -type f -exec bash -c 'copy_reference_file {}' \;

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
   exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
