# Why?
This switchboard plug depends on light-locker, which is a bummer if you suffer from [elementary/greeter#401](https://github.com/elementary/greeter/issues/401) and decided to replace it with something else (like xscreensaver). This fork removes the "Locking" page entirely from the plug, letting you use your own tool for configuring your screen locker

Below the original README.md contents (with modified screenshot):

## Switchboard Security & Privacy Plug
[![Translation status](https://l10n.elementary.io/widgets/switchboard/-/switchboard-plug-security-privacy/svg-badge.svg)](https://l10n.elementary.io/engage/switchboard/?utm_source=widget)

![screenshot](data/screenshot-plug-modified.png?raw=true)

### Building, Testing, and Installation

You'll need the following dependencies:
* libgranite-dev
* libpolkit-gobject-1-dev
* libswitchboard-2.0-dev
* libzeitgeist-2.0-dev
* meson >= 0.46.1
* policykit-1
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
