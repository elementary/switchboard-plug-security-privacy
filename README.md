# Security & Privacy Settings
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-security-privacy/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot-history.png?raw=true)

## Building, Testing, and Installation

You'll need the following dependencies:
* libgranite-7-dev
* libpolkit-gobject-1-dev
* libswitchboard-3-dev
* libzeitgeist-2.0-dev
* meson >= 0.46.1
* policykit-1
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    ninja install
