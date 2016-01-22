#!/usr/bin/perl -w

=head1 NAME

Munin plugin snmp__poewrconnect_stackbone is written to monitor the Stack Port traffic on a stack of Dell 6248 switches.  Some information on the SNMP MIBs supplied by Dell at http://en.community.dell.com/support-forums/network-switches/f/866/t/19651968

=head1 AUTHOR

Danny Howard <dannyman@toldme.com>

This plugin was created on the behalf of Quantifind, Inc.  http://www.quantifind.com

=head1 LICENSE

BSD

=head1 MAGIC MARKERS

  #%# family=snmpauto
  #%# capabilities=snmpconf

=head1 EXAMPLE MIB

$ snmpwalk -v 2c -c yourCommunityString your.switch.ip .1.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1
.. switch unit numbers ..
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.2.256 = Gauge32: 1
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.2.257 = Gauge32: 1
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.2.258 = Gauge32: 1
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.2.259 = Gauge32: 1
.. stack port names ..
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.3.256 = STRING: "xg1"
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.3.257 = STRING: "xg2"
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.3.258 = STRING: "xg3"
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.3.259 = STRING: "xg4"
.. stack port data rate Mb/s (gauge) .. (Tx + Rx)
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.8.256 = Counter32: 763
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.8.257 = Counter32: 463
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.8.258 = Counter32: 0
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.8.259 = Counter32: 0
.. 12Gb stack cards should max out at 12000? ..
.. total errors (counter) ..
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.10.256 = Counter32: 0
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.10.257 = Counter32: 0
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.10.258 = Counter32: 0
iso.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1.10.259 = Counter32: 0

TODO: I'm not doing anything with errors here, or trying to pull port
metadata from elsewhere in the SNMP hierarchy ...

NOTE: I tried to make it like other graphs where if you click on the
multigraph you'll get to a page of seperate multigraphs. If I uncomment
the "cut" code, below, graphs don't render at all. With the cut code
commented out, I at least get the multigraph.

=cut

use strict;
use Munin::Plugin::SNMP;

if (defined $ARGV[0] and $ARGV[0] eq "snmpconf") {
        print "require 1.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1\n";
        exit 0;
}

my $session = Munin::Plugin::SNMP->session(-translate =>
                                           [ -timeticks => 0x0 ]);

my $h = $session->get_hash (
	-baseoid	=> ".1.3.6.1.4.1.674.10895.5000.2.6132.1.1.13.7.2.1",
	-cols		=> {
		2	=>  'stackUnit',
		3	=>  'portName',
		8	=>  'portDataRate',
		10	=>	'portTotalErrors',
	}
);

if (!defined $h) {
	printf "ERROR: %s\n", $session->error();
	$session->close();
	my $host;
	my $port;
	my $version;
	my $tail;
	($host, $port, $version, $tail) = Munin::Plugin::SNMP->config_session();
	print "host: $host\nport: $port\nversion: $version\ntail: $tail\n";
	exit 1;
}

my @graph_order_array;
foreach my $k ( keys %{$h} ) {
	my $stackUnit	  =	$h->{$k}->{'stackUnit'};
	my $portName	  =	$h->{$k}->{'portName'};
	$portName = sprintf("%02d:%s", $stackUnit, $portName);
	push(@graph_order_array, "$portName");
}
my $graph_order = '';
for ( sort @graph_order_array ) {
	$graph_order .= "$_ ";
}

if (defined $ARGV[0] and $ARGV[0] eq "config") {
    my ($host) = Munin::Plugin::SNMP->config_session();
	print "host_name $host\n" unless $host eq 'localhost';
	print "
multigraph data_rate
graph_title Stack Port Data Rate
graph_args --lower-limit 0
graph_vlabel Gb/s
graph_category network
graph_scale no
graph_info Data transmission rate on switch backbone connections.
graph_order $graph_order

";

    foreach my $k ( keys %{$h} ) {
		my $stackUnit	  =	$h->{$k}->{'stackUnit'};
		my $portName	  =	$h->{$k}->{'portName'};
		my $portDataRate  =	$h->{$k}->{'portDataRate'};
		$portName = sprintf("%02d:%s", $stackUnit, $portName);

		if ( $portDataRate ) {
			print "$portName.label $portName\n";
			print "$portName.min 0\n";
			print "$portName.draw LINE1\n";
			print "$portName.type GAUGE\n";
		}
    }

# cut 1
#    foreach my $k ( keys %{$h} ) {
#		my $stackUnit	  =	$h->{$k}->{'stackUnit'};
#		my $portName	  =	$h->{$k}->{'portName'};
#		my $portDataRate  =	$h->{$k}->{'portDataRate'};
#		$portName = sprintf("%02d:%s", $stackUnit, $portName);
#
#		if ( $portDataRate ) {
#	print "
#multigraph data_rate.$portName
#graph_title Data Rate for Stack Port $portName
#graph_args --lower-limit 0
#graph_vlabel Gb/s
#graph_category network
#graph_scale no
#graph_info Data transmission rate on switch backbone connections.
#
#stack_port.label $portName
#stack_port.min 0
#stack_port.draw LINE1
#stack_port.type GAUGE
#";
#		}
#
#	}
# cut 1

    exit 0;
}

print "multigraph data_rate\n";
foreach my $k ( keys %{$h} ) {
	my $stackUnit	  =	$h->{$k}->{'stackUnit'};
	my $portName	  =	$h->{$k}->{'portName'};
	my $portDataRate  =	$h->{$k}->{'portDataRate'};
	$portName = sprintf("%02d:%s", $stackUnit, $portName);

	if ( $portDataRate ) {
		$portDataRate = $portDataRate * .001; # Mb -> Gb
		print "$portName.value $portDataRate\n";
	}
}

# cut 2
#foreach my $k ( keys %{$h} ) {
#	my $stackUnit	  =	$h->{$k}->{'stackUnit'};
#	my $portName	  =	$h->{$k}->{'portName'};
#	my $portDataRate  =	$h->{$k}->{'portDataRate'};
#	$portName = sprintf("%02d:%s", $stackUnit, $portName);
#
#	if ( $portDataRate ) {
#		$portDataRate = $portDataRate * .001; # Mb -> Gb
#		print "\nmultigraph data_rate.$portName\n";
#		print "stack_port.value $portDataRate\n";
#	}
#}
# cut 2
