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
# Helper package to read the client secrets json file

package ClientSecret ;

use strict ;
use warnings ;
use JSON qw( decode_json ) ;

sub new {
	my $class = shift ;
	my $fp = shift ; # Full Path to json secret file or undef
                     # If undef, then each parameter needs
                     # to be specified manually in params
	my ( %params ) = @_ ; # undef or overwrite all default
                          # json attributes
	my $this = {
		clientID => 'installed/client_id',
		projectId => 'installed/project_id',
		authUri => 'installed/auth_uri',
		tokenUri => 'installed/token_uri',
		authProviderX509CertUrl => 'installed/auth_provider_x509_cert_url',
		clientSecret => 'installed/client_secret',
		redirectUris => 'installed/redirect_uris'
	} ;
	if ( %params ) {
		@{$this}{keys %params} = @params{keys %params} ;
	}
	bless $this, $class ;
	if ( defined $fp ) {
		if ( $this->readJson( $fp ) ) {
			return $this ;
		}
	}
	return 0 ;
}

sub readJson {
	my $this = shift ;
	my $fp = shift ;
	my $fh ;
	if ( !open $fh, "<", $fp ) {
		warn "Could not open $fp\n" ;
		return 0 ;
	}
	my $json = '' ;
	while( <$fh> ) {
		chomp ;
		$json = $json . $_ ;
	}
	close $fh ;
	my $decoded_json = decode_json( $json ) ;
	foreach ( keys %{$this} ) {
		my @nodes = split /\//, $this->{ $_ } ;
		$this->{ $_ } = $decoded_json->{ shift @nodes } ;
		while ( @nodes ) {
			$this->{ $_ } = $this->{ $_ }->{ shift @nodes } ;
		}
	}
	return ( defined $this->{ clientID } && defined $this->{ clientSecret } ) ;
}

1 ;