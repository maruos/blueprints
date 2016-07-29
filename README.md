# Maru OS Container Blueprints

[![Build Status](https://travis-ci.org/maruos/maruos-blueprints.svg?branch=master)](https://travis-ci.org/maruos/maruos-blueprints)

Builds container images for Maru OS based on a set of "blueprints".

### Blueprints

Image building logic is separated into standalone blueprint plugins.

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

### Contributing

See the [main Maru OS repository](https://github.com/maruos/maruos) for more
info.

### Licensing

This repository is licensed under the Apache License, Version 2.0. See
[LICENSE](LICENSE) for the details.
