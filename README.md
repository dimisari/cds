# cd on steroids

# Usage
```console
foo@bar:~$ cds


docs -> /home/foo/Documents

down -> /home/foo/Downloads

share -> /home/foo/.local/share


foo@bar:~$ cds down
foo@bar:~/Downloads$ cds share
foo@bar:~/.local/share$ cds docs
foo@bar:~/Documents$ cds help

To list nicknames
$ cds

To add the nickname <nickname> for the working directory
$ cds add <nickname>

To delete the nickname <nickname>
$ cds del <nickname>

```

# Dependencies
## ghc
```
sudo apt install ghc
```

# Installation
```
make install
```

# Deletion
```
make uninstall
```
