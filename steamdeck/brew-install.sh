#!/usr/bin/env bash

# Intall homebrew on Steam Deck
# Ref: https://gist.github.com/uyjulian/105397c59e95f79f488297bb08c39146

# 1. Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Add it to .bash_profile
echo 'if [ $(basename $(printf "%s" "$(ps -p $(ps -p $$ -o ppid=) -o cmd=)" | cut --delimiter " " --fields 1)) = konsole ] ; then '$'\n''eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'$'\n''fi'$'\n' >> ~/.bash_profile

# 3. Add new profile in Konsole
# - In Konsole's menu bar, go to Settings -> Manage Profile
# - Press "New"
# - Check "Default Profile"
# - Set "Command" to /bin/bash -l
# - Click OK twice

# 4. Add brew to current context
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# 5. Add glibc
curl -L https://raw.githubusercontent.com/Homebrew/homebrew-core/f46b316a63932bb75a863f7981a2149147591ff8/Formula/glibc.rb | sed -e 's/depends_on BrewedGlibcNotOlderRequirement//' > ./glibc.rb
brew install ./glibc.rb
brew unlink glibc
find /home/linuxbrew/.linuxbrew/opt/glibc -iname \*.o -delete
find /home/linuxbrew/.linuxbrew/opt/glibc -iname \*.a -delete
find /home/linuxbrew/.linuxbrew/opt/glibc -iname \*.so -delete
find /home/linuxbrew/.linuxbrew/opt/glibc/lib -iname \*.so.\* -delete
brew link glibc

# 6.Add GCC
brew install gcc

