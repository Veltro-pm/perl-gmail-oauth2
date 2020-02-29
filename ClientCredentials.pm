#!/usr/bin/perl
# Copyright (c) 2018 Veltro. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# This package is provided "as is" and without any express or implied
# warranties, including, without limitation, the implied warranties of
# merchantability and fitness for a particular purpose
#
# Description:
# Helper package to store the client credentials
# in a JSON file (both refresh token and access token)
# and to be able to determine if the refresh token is
# available and the access token is still valid. 

package ClientCredentials ;

use strict ;
use warnings ;
use JSON qw( decode_json encode_json -convert_blessed_universally ) ;

sub new {
	my $class = shift ;
	my $fp = shift ; # Full Path to JSON credentials file
	                 # (or the file that needs to be created)
	my $this = {
		_filePath => $fp,
		accessToken => undef,
		expiresIn => undef,
		time => undef,
		refreshToken => undef,
		tokenType => undef
	} ;
	bless $this, $class ;
	if ( defined $fp ) {
		if ( -f $fp ) {
			$this->readJson( $fp ) ;
			if ( $this->expired ) {
				$this->{ accessToken } = undef ;
				$this->{ expiresIn } = undef ;
				$this->{ time } = undef ;
				$this->{ tokenType } = undef ;
			}
		}
	}
	return $this ;
}

sub refreshTokenNeeded {
	my $this = shift ;
	return 1 unless ( defined $this->{ refreshToken } ) ;
	return 0 ;
}

sub expired {
	my $this = shift ;
	return 1 unless ( defined $this->{ accessToken } && defined $this->{ expiresIn } && defined $this->{ time } ) ;
	return time > ( $this->{ time } + $this->{ expiresIn } - 300 ) ? 1 : 0 ;
}

sub setRefreshToken {
	my $this = shift ;
	my $refreshToken = shift ;
	$this->{ refreshToken } = $refreshToken ;
	$this->{ accessToken } = undef ;
	$this->{ expiresIn } = undef ;
	$this->{ time } = undef ;
	$this->{ tokenType } = undef ;
	$this->writeJson() ;
}

sub setAccessToken {
	my $this = shift ;
	my $accessToken = shift ;
	my $expiresIn = shift ;
	my $tokenType = shift ;
	my $time = time ;
	$this->{ accessToken } = $accessToken ;
	$this->{ expiresIn } = $expiresIn ;
	$this->{ time } = $time ;
	$this->{ tokenType } = $tokenType ;
	$this->writeJson() ;
}

sub readJson {
	my $this = shift ;
	my $fp = shift ;
	my $fh ;
	if ( !open $fh, "<", $fp ) {
		warn "Could not open $fp\n" ;
		return ;
	} ;
	my $json = '' ;
	while( <$fh> ) {
		chomp ;
		$json = $json . $_ ;
	}
	close $fh ;
	my $decoded_json = decode_json( $json ) ;
	foreach ( keys %{$this} ) {
		if( $_ =~ /^[^_].*/ ) {
			$this->{ $_ } = $decoded_json->{ $_ } ;
		}
	}
}

sub writeJson {
	my $this = shift ;
	my $json = JSON->new->allow_nonref->convert_blessed ;
	my $encoded_json = $json->encode( $this ) ;
	my $fh ;
	if ( !open $fh, ">", $this->{ _filePath } ) {
		warn "Write failed to $this->{ _filePath }\n" ;
		return ;
	} ;
	print $fh $encoded_json ;
	close $fh ;
}

1 ;