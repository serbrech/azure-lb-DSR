# DSR behing azure load balancer.

## setup

`ncat` is better than `nc` :

`sudo apt-get update && sudo apt-get install nmap -y`

## listen: 
`ncat -l -k -p 6443 -c hostname &`

## query
`ncat -vvv 10.100.63.254 6443`

## arp config

`cat /etc/sysctl.conf`

```
> net.ipv4.conf.all.arp_ignore=1
> net.ipv4.conf.eth0.arp_ignore=1
> net.ipv4.conf.all.arp_announce=2
> net.ipv4.conf.eth0.arp_announce=2
```

## ifconfig  

`sudo ifconfig lo:1 10.100.63.254 netmask 255.255.224.0 -arp up`

```
lo:1: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 10.100.63.254  netmask 255.255.224.0
        loop  txqueuelen 1000  (Local Loopback)
```
