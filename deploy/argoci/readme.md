
```bash
$ mkdir -p .ssh
$ cd .ssh
$ path=`echo $PWD`
$ ssh-keygen 
#Generating public/private rsa key pair.
#Enter file in which to save the key (/home/user/.ssh/id_rsa): $path

# check git access
$ ssh -T git@github.com -i id_rsa 

# create known host file
$ ssh-keyscan -t rsa github.com > known_hosts

```

