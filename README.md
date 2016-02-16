# Opencast Build

`ocb` is a build tool to speed up development of the [Karaf](http://karaf.apache.org) based version of Opencast 
Matterhorn.

## Requirements

The only requirement to build and run the tool is [Elixir](http://elixir-lang.org), version 1.2 and above.

### Mac OS X 

    $ brew update
    $ brew install elixir

## Install

Clone the repo

    $ git clone https://github.com/cedriessen/ocb.git

Build the tool with

    $ mix deps.get
    $ mix escript.build

Then put it on your path. 

    $ export $PATH:/path/to/ocb

## Use

Get a comprehensive help with

    $ ocb -h
    

Happy development!
    




