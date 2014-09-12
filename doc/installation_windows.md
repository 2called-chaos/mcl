## Installation (Windows)

## Bundled setup

@todo


## Manual installation

### 1. Installing dependencies

1. [Download RubyInstaller _AND_ the development kit](http://rubyinstaller.org/downloads/) and install both (make sure to check _"add ruby to PATH"_).
2. [Download Git](http://git-scm.com/download/win) and install it (make sure to choose _"Use Git from the Windows Command Prompt"_)

2. Open up a elevated CMD window (press win, enter "cmd", right click the entry and choose "run as administrator")

3. Type in: `gem install bundler`


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
6. Done! Run `mcld.cmd run` (to test) or `mcld.cmd start` to start the MCL daemon in the background. Doesn't work? [=> Troubleshooting](https://github.com/2called-chaos/mcl/wiki/Troubleshooting)
7. Type `!uadmin` into chat to give yourself root permissions. This only works if your nickname or UUID is listed in the config directory.

##### Hint: Bootstrap
If you want to start with a new server, MCL can bootstrap it for you. Create a file called `bootstrap` (no ending) inside your server folder containing the minecraft version you want to use. MCL will then download the minecraft server for you automatically. Example:
```
mkdir C:\minecraft\my_minecraft_server
echo 1.8 > C:\minecraft\my_minecraft_server\bootstrap
mcld.cmd start
```
