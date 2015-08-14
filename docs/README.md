# Documentation and design notes


## Use-case


I tell lucibox to `create` my lucibox with name `NAME`, supplying it with a configuration file:

	lucibox create -c luciboxconfig-example.yml NAME

Out comes information (on standard out or markdown file?) about:

* lucibox URL
* login and credentials


* `lucibox start NAME` will start a _stopped_ lucibox
* `lucibox stop NAME` will stop a sarted lucibox
* `lucibox remove NAME` will remove everything including data
* `lucibox refresh NAME` will reread configuration file, and make needed changes to luci to comply with the new configuration. Eg. 10 more build slaves.



## luci box configuraton

Eventually the user needs to supply some information to get a lucibox customized a bit. I could be a web-interface at some point, but for a simple minimum viable product it could as well be a configuration file in YAML format

The point is to look at what information is needed from the user, to customize the lucibox.

It is not just to fire up docker images, docker compose can do that and the user can do that without luci. So instead of requiring already custumized docker images, that fits the users needs, some common adjustments for a continuous delivery build environmnet is made directly available in the luci box configuration.

The `luciboxconfig-example.yml` should be a show-case on how simple luci is to configure, yet powerful to custmize. 

_Ideas_:

* The user doesn't really need to supply, nor know, about all the configuration a docker-compose file needs (linking, ports etc.) but just maybe the docker images needed within the categories supported.
* The user need to supply information abou credentials and where to run the lucibox.
* The user needs to tell which adjustments is needed for the default docker images used (we prefer to use default docker hub images, so users doesn't need to create and maintain their own).
* The configuraton file tries to re-use as much as possible from other docker tools. For example by supporting docker-compose YAML setings, and using docker-machine syntax to specificy the lucibox hosts configuration.

**The `luciboxconfig-example.yml` will explain a lot more details on design and assumptions as comments**.


## Vocabulary


* **service**: a service is a one of the continuous delivery tool stack services, typically maps to one or more docker containers as well. For example `buildserver`, `repository`, `artifactmanagement`, `buildslave`. You implicit get the nginx webserver to front the _appliance_.
* **lucibox**: is our _appliance_, that have all the services running and that I can access on a URL and from there get access to every _service_ running


Some definition also are implict from the configuration file example.


## Features

The following features, autmation and configuration are assumed to be working on the started luci box:

* 'luciboxURL' is a front-page, which have links to all services running
* Each individual service can be accessed on `luciboxURL/servicename`. Eg. `luciboxURL/buildserver`, `luciboxURL/repository` or for the repeatable ones (that are persisted): `luciboxURL/buildslave-1`
* Build slaves are normally dynamically created when needed and discarded after a build, but can be made persistent (some of them) if the is needed in the build process. For example to investigate build slave problems etc.
* Internal hostname works, so I a on the build server, I can refer to a git repository like `http://repository/projectname.git` or `git@repository:Praqma/luci.git` (ssh clone url, compares to `git@github.com:Praqma/luci.git`). The `luciboxURL/repository` would not work, **that is important to avoid problems with staging, test, and prod environments**.
* Services are automatically configured towards each other, this means if for example I chose Artifactory as `artifactmanagement`, and Jenkins as `buildserver` the Jenkins Global Configuration page is already configured with the Artifactory server. This means the best and usefull plugin for Artifactory on Jenkins, chosen by Praqma who have this experience, is also automatically installed on Jenkins. Mail notifications for all systems are configured as well to send to the `lucibox-admins` group.
* The build system is automatically configured so that build slaves can clone the repositories, and push changes back like tags. The same goes for the Artifact management system.
* The build system also automatically comes with our recommended plugins installed, we know what is needed based on experience. User can apply more plugins, or remove them later in the Jenkins configuration. UI. User can supply extra more special plugins needed. Our default list is: Fingerprint Plugin, Job DSL, build-name-setter, Task Scanner Plug-in, Jenkins Mailer Plugin, Build Failure Analyzer, Environment Injector Plugin, Pretested Integration Plugin, Jenkins Git Plugin, HTML Publisher Plugin, JUnit Plugin, Build Pipeline Plugin, Copy Artifact Plugin, Warnings Plugin, Jenkins Parameterized Trigger Plugin, Safe Restart (list comes from the one used in traing in Praqma: http://code.praqma.net/training/pluginusage/).
* The `ssh-post-config` option is for now a praqmatic way of customizing slaves. I really think users should be able to just specify things like `git 2.1.5`, `maven 3.0.1`, `RVM Ruby 2.2` etc.
