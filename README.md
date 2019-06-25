# LBRY-CAFO

Easily run any version of lbrynet in Docker.

## Install

One-liner to install system-wide:

```
wget https://raw.githubusercontent.com/PlenusPyramis/lbry-cafo/master/lbrycafo.sh \
   -O /tmp/lbry-cafo \
   && sudo install /tmp/lbry-cafo /usr/bin
```

Alternatively, install for just one user:

```
mkdir -p $HOME/bin
wget https://raw.githubusercontent.com/PlenusPyramis/lbry-cafo/master/lbrycafo.sh \
   -O $HOME/bin/lbry-cafo
chmod a+x $HOME/bin/lbry-cafo

# Make sure to add $HOME/bin to your path
# (if it isn't already; check $HOME/.bashrc or equivalent)
export PATH=$HOME/bin
```

For development, instead of installing, alias the script directly from git:

```
GIT_ROOT=$HOME/git/vendor
git clone https://github.com/PlenusPyramis/lbry-cafo.git $GIT_ROOT/plenuspyramis/lbry-cafo

echo "alias lbry-cafo=$GIT_ROOT/plenuspyramis/lbry-cafo/lbrycafo.sh" >> $HOME/.bashrc
source $HOME/.bashrc
```
