# TODO List

- Check if the project is `public` - for some reason, billing is enabled on *GitHub/Codespace*.
- The location of the config file should be relative to the `kernel-config` directory.
- Add the 'build-kmod-rpm' script to the Git repository.
- Translate `TODO`, `README`, `BUGS` to English.
- Create `docs/` in English.

+ Add `TODO.md` to the repository.

+ All comments in the code and information displayed on the screen/log should be in English.

+ Test the scripts' functionality when run via the `build-kmods` symlink. It's important that this symlink can be run from different starting locations.

+ The `build-kmods` symlink, when run without a config argument, should default to using the config specified in the script's configuration, for example.

## Features

- Create scripts to run *Docker* on the *Codespace* side. But consider if it makes sense to use *Codespace* at all.