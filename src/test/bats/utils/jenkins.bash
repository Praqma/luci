# Construct a test project for Jenkins (i.e. a project that can be build by Jenkins)
# The project is contstructed in a data container
# 1: Name of data container
# 2: Path to the project in the data container. This is also a volume
#    and can with -V be accessed from other containers
# 3: project source (under jenkins-projects
# 4: project type (e.g. gradle)
function constructJenkinsTestProjectContainer() {
    # A test project for jenkins is constructed by merging the
    # source for a project with the buildsystem.
    # The
    local containerName=$1
    local projectPath=${2%/}
    local sourceDir="$LUCI_ROOT/src/test/jenkins-projects/$3"
    local buildSystemDir="$LUCI_ROOT/src/test/jenkins-buildsystems/$4"
    local imageName="luci-$2-$1"

    local target=$(mktemp -d)

    cp -r $sourceDir/* $buildSystemDir/* $target

    (cd $target; git init; git add --all; git commit -m"Commit for Luci test project" )
    createDataContainer $containerName $target $projectPath
    rm -r $target
}
