# Maru OS Container Blueprints

[![Build Status](https://travis-ci.org/maruos/blueprints.svg?branch=master)](https://travis-ci.org/maruos/blueprints)

Container image builder for Maru OS.

### Blueprints

Image building logic is separated into standalone plugins called blueprints.

To create your own blueprint, all you need to do is:

1. Add a directory under blueprint/. Use this directory to store anything you
   need during the build process.

2. Add a script called plugin.sh to the top-level of your new blueprint
   directory. This will be the entrypoint to your blueprint.

3. Define the function `blueprint_build` in plugin.sh that will run your build
   logic.

4. Define the function `blueprint_cleanup` in plugin.sh that will clean up any
   intermediate build artifacts.

See blueprint/debian as the canonical example for Debian.

### Examples

Build a Debian Jessie armhf container called 'debian' (option defaults):

    $ ./build.sh

Build a Debian Jessie arm64 container called 'jessie64':

    $ ./build.sh -b debian -n jessie64 -- -a arm64

*Tip: You will need root privileges to mount binfmt_misc for bootstrapping
foreign architecture containers.*

### Contributing

See the [main Maru OS repository](https://github.com/maruos/maruos) for more
info.

### Licensing

This repository is licensed under the Apache License, Version 2.0. See
[LICENSE](LICENSE) for the details.
