# Perl package to calculate a checksum
# Copyright (C) by Josef Drexler
# Distributed under the same license terms as Perl itself.

package CRC32;

use base qw(Exporter);

our @EXPORT = qw(&crc32);

my $crc_poly = 0xedb88320;
my @crc_table = map {
	my $crc = $_;
	$crc = ($crc >> 1) ^ ($crc & 1) * $crc_poly for 0..7;
	$crc
} 0..255;

sub crc32
{
  map {
	my $crc = ~0;
	$crc = ($crc >> 8 & 0xffffff) ^ $crc_table[ $crc & 255 ^ ord ]
		for split //, $_;
	~$crc & 0xffffffff;
  } @_;
}
