## Installation (UNIX/OS X/Linux)

This guide helps you setting up MCL via command line on a *nix system.


### 1. Installing dependencies (Debian/Ubuntu)

```shell
sudo aptitude update
sudo aptitude install ruby2.0 git
sudo gem install bundler
```
If the ruby version cannot be found look for the most recent version with `sudo aptitude search ruby`.



### 1. Installing dependencies (Mac OS X)

On OS X you need to open the `Terminal.app` which you can find in `Applications/Utilities`. If you are running OS X Mountain Lion (10.8) or higher you already have a usable ruby version installed. To install git I recommend using homebrew. If you don't have homebrew [grab it here](http://brew.sh/#install).

```shell
brew install git
sudo gem install bundler
```


### 2. Installing MCL

Switch to the user which will run the minecraft server (e.g. `su - minecraft_server`)

2. Download or clone the whole thing to a convenient location:
    <pre>
      cd ~
      git clone https://github.com/2called-chaos/mcl.git</pre>
3. Optional but recommended: Add the bin directory to your $PATH variable or create a symlink to the executable:
    <pre>
      echo 'export PATH="$HOME/mcl/bin:$PATH"' >> ~/.profile && source ~/.profile
      OR
      ln -s /home/minecraft_server/mcl/bin/mcld /usr/local/bin/mcld</pre>
4. Install the bundle
    <pre>
      cd ~/mcl && bundle install --without mysql --deployment</pre>
   **NOTE:** If you want to use MySQL (not recommended) replace `mysql` with `sqlite`
5. Copy and edit the example configuration to fit your needs and server settings.
   Please note that there is currently no user support which means all servers need to run under the same user as MCL does.
    <pre>
      cd ~/mcl
      cp config/default.example.yml config/default.yml
      nano config/default.yml</pre>
6. Done! Run `mcld start` to start the MCL daemon. Doesn't work? [=> Troubleshooting](https://github.com/2called-chaos/mcl/wiki/Troubleshooting)
7. Type `!uadmin` into chat to give yourself root permissions. This only works if your nickname or UUID is listed in the config directory.

##### Hint: Bootstrap
If you want to start with a new server, MCL can bootstrap it for you. Create a file called `bootstrap` (no ending) inside your server folder containing the minecraft version you want to use. MCL will then download the minecraft server for you automatically. Example:
```
mkdir my_server
echo "1.8" > my_server/bootstrap
mcld start
```
