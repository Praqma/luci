#!/bin/sh

#define parameters which are passed in.
shellCmd=$1

#define the job.
cat  << EOF
<project>
<actions/>
<description/>
<keepDependencies>false</keepDependencies>
<properties>
<com.sonyericsson.jenkins.plugins.bfa.model.ScannerJobProperty plugin="build-failure-analyzer@1.12.1">
<doNotScan>false</doNotScan>
</com.sonyericsson.jenkins.plugins.bfa.model.ScannerJobProperty>
<com.synopsys.arc.jenkins.plugins.ownership.jobs.JobOwnerJobProperty plugin="ownership@0.6">
<ownership>
<ownershipEnabled>true</ownershipEnabled>
<primaryOwnerId>heh</primaryOwnerId>
<coownersIds class="sorted-set"/>
</ownership>
</com.synopsys.arc.jenkins.plugins.ownership.jobs.JobOwnerJobProperty>
<hudson.plugins.disk__usage.DiskUsageProperty plugin="disk-usage@0.25"/>
<org.jvnet.hudson.plugins.shelveproject.ShelveProjectProperty plugin="shelve-project-plugin@1.5"/>
</properties>
<scm class="hudson.scm.NullSCM"/>
<canRoam>true</canRoam>
<disabled>false</disabled>
<blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
<blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
<jdk>(Default)</jdk>
<triggers/>
<concurrentBuild>false</concurrentBuild>
<builders>
<hudson.tasks.Shell>
<command>$shellCmd</command>
</hudson.tasks.Shell>
</builders>
<publishers/>
<buildWrappers/>
</project>
EOF
