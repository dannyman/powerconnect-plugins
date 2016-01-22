powerconnect-plugins
===================

Munin Plugin for Dell 6248 Stacking Links

# Munin

For Munin: RTFM
* http://munin-monitoring.org/wiki/munin-node-configure
* http://munin.readthedocs.org/en/latest/tutorial/snmp.html

Quick and Dirty:

Assuming the hostname of your switch is is **sw0** and you've configured SNMP appropriately, you can perform the following commands on the munin node you have designated for SNMP.

```
git clone https://github.com/dannyman/powerconnect-plugins.git
sudo cp powerconnect-plugins/munin/snmp__powerconnect.pl /usr/share/munin/plugins/snmp__powerconnect
sudo munin-node-configure --shell --snmp sw0
```

That should print out, for example:

```
ln -s /usr/share/munin/plugins/snmp__powerconnect /etc/munin/plugins/snmp_my-pdu_powerconnect
```

So, you can:

```
sudo munin-node-configure --shell --snmp my-pdu | sudo sh
sudo service munin-node restart
```

You could then test things out with a sample run:
```
$ 0-15:15 djh@intweb2 ~$ sudo munin-run
snmp_sw0.quantifind.com_powerconnect_stackbone 
multigraph data_rate
03:xg1.value 0.233
02:xg2.value 0.231
03:xg2.value 0.117
02:xg1.value 0.042
06:xg1.value 0.117
01:xg1.value 0.066
04:xg1.value 0.164
04:xg2.value 0.08
06:xg2.value 0.138
01:xg2.value 0.043
```

On your Munin Master node, add the node to your **/etc/munin/munin.conf** file.  This is explained at http://munin-monitoring.org/wiki/Using_SNMP_plugins.
