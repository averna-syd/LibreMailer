#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use Cwd qw( realpath );
use Dancer ':script';

my $appdir = realpath( "$FindBin::Bin/..");

Dancer::Config::setting( 'appdir', $appdir );
config->{environment} = 'production';
Dancer::Config::load();

use LibreMailer::Worker;

my $worker = LibreMailer::Worker->new();

$worker->clean_lists;
$worker->process_campaigns;
$worker->process_bounces;
