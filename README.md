# Switchboard Security & Privacy Plug
[![Translation status](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-security-privacy/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-security-privacy/?utm_source=widget)

## Building, Testing, and Installation

You'll need the following dependencies:
* cmake
* libgranite-dev
* libswitchboard-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make all test` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install`, then execute with `switchboard`

    sudo make install
    switchboard
