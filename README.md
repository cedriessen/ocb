# Opencast Build

[![Inline docs](http://inch-ci.org/github/cedriessen/ocb.svg)](http://inch-ci.org/github/cedriessen/ocb)

`ocb` is a build tool to speed up development of the [Karaf](http://karaf.apache.org) based version of Opencast 
Matterhorn.

## Requirements

The only requirement to build and run the tool is [Elixir](http://elixir-lang.org), version 1.2 and above.

### Mac OS X 

    $ brew update
    $ brew install elixir
    
### Other Platforms
    
See Elixir's [installation](http://elixir-lang.org/install.html) instructions how to
install Elixir on other platforms.

## Install

Clone the repo.

    $ git clone https://github.com/cedriessen/ocb.git

Build the tool with

    $ cd ocb
    $ mix deps.get
    $ mix escript.build

Then put it on your path. 

    $ export $PATH:/path/to/ocb
    
### Bash Completion

In order to enable Bash completion for `ocb` you may want to add the following line to you 
`.profile` or `.bash_profile`.
     
     source ocb-complete.sh     
    
## Get Updates

The current version number is shown in the header of the help screen. Get an update with
    
    $ ocb --update

## Use

Get a comprehensive help with

    $ ocb -h
    
## Why?

Because it makes things easier. And also a bit faster.

**Do a full build** 

    $ mvn clean install -DdeployTo=/path/to/build -Pmodules,entwine
    --
    $ ocb -c -a
    
**Build and deploy a certain module**
    
    $ mvn install --project modules/matterhorn-common
    $ mvn install -DdeployTo=/path/to/build -Pmodules,entwine -rf :opencast-karaf-features
    --
    $ ocb modules/matterhorn-common
       
**Do some work, then build and deploy your changes**

Figure out what has been modified since your last deployment... Then do the above. 
     
    $ ocb -m
    
**Resume a failed build of modified modules**

Figure out that three modules have been modified. Start the build. After it failed and you did
the necessary fix, cut and paste the module to resume with from the maven output. If you did just
a partial build do not forget to build and deploy the assembly.
  
    $ mvn install --projects modules/matterhorn-series-service-api,modules/matterhorn-conductor,modules/matterhorn-series-service-impl
    >> Build fails at matterhorn-conductor <<   
    $ mvn install -rf :matterhorn-conductor
    $ mvn install -DdeployTo=/path/to/build -Pmodules,entwine -rf :opencast-karaf-features
    --
    $ ocb -r -m
    
**Save data between deployments**

A deployment, done by maven cleans out the whole `data/` directory. This is somewhat annoying since
all your previously entered test data is gone. So let's start over...

    $ ocb -m
    >> OR <<
    $ ocb -s -a
     
**Save some time with deployments**

A deployment done by maven always requires a complete repackaging and inflating into the `build/` directory.
If you only did a minor change, this is quite an overhead.

Use `ocb -m` to build what has been modified and deploy only these bundles in one go. Your data will
also be kept between restarts of Karaf.
     
**Save some time with common commandline switches**

During development you don't want to run checkstyle and all the tests each time you do a deployment.
Tests are probably better run from the IDE to just test what's necessary.
      
      $ mvn clean install -DskipTests -Dcheckstyle.skip=true
      --
      $ ocb -R      
      $ ocb -C -T -c -a 
     
**Provision your deployment**

Sometimes you need an extra file or two to configure your deployment, say a
special workflow, a catalog definition, you name it. You're perfectly able to
copy these files manually or create a little shell script that you can run
after each deployment. OCB lets you create such a shell script named
`.ocb.provision` which is run automatically after each build if it exists.  
    

_Happy development!_
    




