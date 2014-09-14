## Installation (Windows)

MCL requires to be started from an elevated command prompt. This is because MCL uses symbolic links which are very common on *nix systems and Windows/NTFS supports them since Vista but for some reasons you can only use them via `mklink` CLI utility and only with elevated permissions *shrug*.

To open an elevated command prompt press your windows key, type in "cmd" and rightclick the entry in the results. In the context menu choose "run as administrator". Alternatively to rightclicking you can press `Ctrl+Shift+Enter`.

## Bundled setup

@todo

The bundled installer will, in the following order,
  - **install GnuTar** (archiving utility)
  - **install Git** (code versioning to get and update MCL)
  - **install Ruby** 2.0 incl. devkit (Ruby programming language)
  - **install bundler** Ruby gem to manage project dependencies
  - **install MCL**
    - pull git repository
    - install bundle
    - add MCL and utilities to path variable
    - copy default config
    - optionally bootstraps a new minecraft server

There is no uninstaller! To remove MCL just delete the folder (typically C:/minecraft/mcl). GnuTar, Ruby and git have their own individual uninstaller.

To start MCL after installation open up an elevated command prompt and type "mcld start". This will start MCL in the background so that you can close the command prompt afterwards.

Doesn't work? [=> Troubleshooting](https://github.com/2called-chaos/mcl/wiki/Troubleshooting)


## Manual installation

### 1. Installing dependencies

1. [Download RubyInstaller _AND_ the development kit](http://rubyinstaller.org/downloads/) and install both (make sure to check _"add ruby to PATH"_).

2. [Download Git](http://git-scm.com/download/win) and install it (make sure to choose _"Use Git from the Windows Command Prompt"_)

3. [Download GnuTar](http://gnuwin32.sourceforge.net/downlinks/tar-bin.php) and install it.

4. Open up a elevated CMD window (press win, enter "cmd", right click the entry and choose "run as administrator")

5. Type in: `gem install bundler`


### 2. Installing MCL

1. Download or clone the whole thing to a convenient location:
    <pre>
      cd c:\minecraft
      git clone https://github.com/2called-chaos/mcl.git</pre>
3. Optional but recommended: Add the bin directory to your PATH variable:
    <pre>
      setx path "%path%;c:\minecraft\mcl\bin"</pre>
   **Close and reopen** the elevated command prompt for this change to take effect.
4. Install the bundle
    <pre>
      cd c:/minecraft/mcl && bundle install --without mysql --deployment</pre>
   **NOTE:** If you want to use MySQL (not recommended) replace `mysql` with `sqlite`
5. Copy and edit the example configuration to fit your needs and server settings (don't indent with tabs!).
    <pre>
      cp config\default.example.yml config\default.yml
      start config\default.yml</pre>
6. Done! Run `mcld run` (to test) or `mcld start` to start the MCL daemon in the background. Doesn't work? [=> Troubleshooting](https://github.com/2called-chaos/mcl/wiki/Troubleshooting)
7. Type `!uadmin` into chat to give yourself root permissions. This only works if your nickname or UUID is listed in the config directory.

##### Hint: Bootstrap
If you want to start with a new server, MCL can bootstrap it for you. Create a file called `bootstrap` (no ending) inside your server folder containing the minecraft version you want to use. MCL will then download the minecraft server for you automatically. Example:
```
mkdir C:\minecraft\my_minecraft_server
echo 1.8 > C:\minecraft\my_minecraft_server\bootstrap
mcld start
```
