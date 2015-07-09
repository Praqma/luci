# Creates a data container with specified data
# 1: Name of data container to create
# 2: Data directory, this directory is included in the container
# 3: Path in container for the data. This is also declared as a volume
function createDataContainer() {
    local containerName=$1
    local data=$2
    local volumePath=$3
    local workdir=$(mktemp -d)
    local imageTag=luci-data-$RANDOM
    
    cat > $workdir/Dockerfile <<-EOF
FROM scratch
VOLUME $volumePath
CMD ['true']
ADD $data $volumePath
EOF
    tar -czP $data -C $workdir Dockerfile | docker build -t $imageTag -
    rm -r $workdir
    docker create --name=$containerName $imageTag
}

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
