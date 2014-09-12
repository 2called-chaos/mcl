## Installation (UNIX/OS X/Linux)

This guide helps you setting up MCL via command line on a *nix system.


### 1. Installing dependencies (Debian/Ubuntu)

I recommend to install ruby via chruby. If you want to use rvm or system ruby adapt the steps accordingly.
Do this first step as root.

```
# install packages (most are required to build ruby)
aptitude update
aptitude install curl git build-essential sqlite3 libsqlite3-dev autoconf bison libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev

# install chruby (this is a install script of mine)
curl -O https://gist.githubusercontent.com/2called-chaos/e06bf6322525d37a5bf7/raw/_setup_chruby.sh
chmod u+x _setup_chruby.sh
./_setup_chruby.sh
rm _setup_chruby.sh

# install ruby
ruby-build 2.0.0-p481 /opt/rubies/2.0.0-p481

# use this ruby as default
echo "chruby 2.0.0-p481" >> /etc/profile.d/chruby.sh
source /etc/profile.d/chruby.sh

# install bundler gem
gem install bundler
```


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
6. Done! Run `mcld run` (to test) or `mcld start` to start the MCL daemon in the background. Doesn't work? [=> Troubleshooting](https://github.com/2called-chaos/mcl/wiki/Troubleshooting)
7. Type `!uadmin` into chat to give yourself root permissions. This only works if your nickname or UUID is listed in the config directory.

##### Hint: Bootstrap
If you want to start with a new server, MCL can bootstrap it for you. Create a file called `bootstrap` (no ending) inside your server folder containing the minecraft version you want to use. MCL will then download the minecraft server for you automatically. Example:
```
mkdir my_server
echo "1.8" > my_server/bootstrap
mcld start
```
If you are doing this on a fresh server installation remember that you need java (e.g.: `aptitude install openjdk-7-jre`).
