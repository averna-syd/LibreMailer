use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'LibreMailer',
    AUTHOR              => q{Sarah Fuller <sarah@averna.id.au>},
    VERSION_FROM        => 'lib/LibreMailer.pm',
    ABSTRACT            => 'Email Marketing App',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3126,
        'Template' => 0,
        'Try::Tiny' => 0,
        'strictures' => 0,
        'DateTime' => 0,
        'DateTime::Format::MySQL' => 0,
        'Email::Valid' => 0,
        'JSON' => 0,
        'JSON::Any' => 0,
        'Dancer::Template::TemplateToolkit' => 0,
        'Dancer::Session::Cookie' => 0,
        'Dancer::Plugin::REST' => 0,
        'Dancer::Plugin::Passphrase' => 0,
        'Dancer::Plugin::Database' => 0,
        'Dancer::Plugin::FlashMessage' => 0,
        'Data::Dumper' => 0,
        'DBD::mysql' => 0,
        'Plack::Runner' => 0,
        'Plack::Handler::Starman' => 0,
        'Parallel::ForkManager' => 0,
        'HTML::LinkExtractor' => 0,
        'Email::Stuff' => 0,
        'Email::Send' => 0,
        'Email::Valid' => 0,
        'Mail::POP3Client' => 0,
        'IO::Socket::SSL' => 0,
        'Mail::DeliveryStatus::BounceParser' => 0,
        'Text::CSV' => 0,
        'Dancer::Plugin::SimpleCRUD' => 0,
        'Dancer::Plugin::Auth::Extensible' => 0,
        'Moo' => 0,
        'MIME::Base64::URLSafe' => 0,
        'Crypt::CBC' => 0,
        'Crypt::Blowfish' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LibreMailer-*' },
);
