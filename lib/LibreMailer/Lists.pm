package LibreMailer::Lists;

use Dancer ':syntax';
use Dancer::Plugin::Database;
use Dancer::Plugin::SimpleCRUD;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::Passphrase;
use Dancer::Session::Cookie;
use Dancer::Plugin::REST;
use Dancer::Plugin::FlashMessage;
use Dancer::FileUtils qw(dirname path read_file_content);
use Email::Valid;
use Text::CSV;
use Data::Dumper;

simple_crud(
    record_title => 'List',
    prefix => '/lists',
    db_table => 'lists',
    labels => {
        name => 'List Name',
        description => 'List Description',
    },
    input_types => {  # overriding form input type for some columns
        name           => 'text',
    },
    required   => [ qw( name description ) ],
    key_column => 'id', # id is default anyway
    editable_columns => [ qw( name description ) ],
    display_columns  => [ qw( name description ) ],
    deleteable => 1,
    editable => 1,
    sortable => 1,
    paginate => 100,
    template => 'lists.tt',
    query_auto_focus => 1,
    downloadable => 1,
    custom_columns => {
        '' => {
            raw_column => "name",
            transform  => sub {
                my $name = shift;
                my $db   = database;
                my $list = $db->quick_select( 'lists', { name => $name } );

                return "<a href='/contacts?searchfield=list_id&searchtype=c&q=$list->{id}&o=&d=&searchsubmit=Search'>View Contacts</a>";
            },
        },
    },
);

get '/lists/upload' => sub
{
    # Display upload page
    my $db    = database;
    my @lists = $db->quick_select( 'lists', { } );

    return template 'upload', { lists => \@lists };
};

post '/lists/upload' => sub 
{
    # Accepts CSV files and attempts to add their contents into a contact list.
    my $params = params;
    my $db     = database;
    my $udir   = Dancer::FileUtils::path( setting('appdir'), 'uploads' );
    my $upload = upload('file');
    my $file   = "$udir/$params->{file}";

    if ( ! $upload->{filename} )
    {
        flash error        => "File not found.";
        session denied_msg => 'Looks like you have tried to upload a file without first adding the file.';

        return redirect '/denied';
    }

    if ( $upload->{headers}->{'Content-Type'} !~ m{text/csv}i )
    {
        unlink $upload->{tempname};
        flash error        => "File not CSV format.";
        session denied_msg => 'Looks like you have tried to upload a file that was not a CSV file. The uploader only accecpts CSV files.';

        return redirect '/denied';
    }

    while ( -e $file )
    {
        $file = "$udir/$params->{file}" . '.' . ( int( rand( 1099999 - 1024 ) ) + 1024 );
    }

    $upload->copy_to( $file );

    my @rows;
    my $csv = Text::CSV->new ( { binary => 1 } ) || return file_error( "Cannot use CSV: ".Text::CSV->error_diag () );

    open my $fh, "<:encoding(utf8)", $file || return file_error( 'Can not read CSV file.' );

        while ( my $row = $csv->getline( $fh ) ) 
        {
            push @rows, $row;
        }

        $csv->eof or $csv->error_diag();

    close $fh;

    unlink $upload->{tempname};
    unlink $file;

    my $fields = $rows[0];
    my @names  = ( 'email', 'firstname', 'lastname', 'format', 'confirmation', 'status' );
    my $data   = {};
    my $count  = 0;

    for ( my $i=0; $i <= @{ $fields }; $i++ )
    {
        next if ( ! $fields->[ $i ] );
        grep { if ( $names[ $_ ] =~ m{^$fields->[ $i ]$}i ) { $data->{ $names[ $_ ] } = $i } } 0 .. $#names;
    }

    if ( $data->{email} && $data->{firstname} && $data->{lastname} && $params->{list_id} =~ m{^\d+$} )
    {
        for my $row ( @rows[1 .. $#rows] )
        {
            $db->quick_insert( 'contacts', { list_id => $params->{list_id}, email => $row->[ $data->{email} ], firstname => $row->[ $data->{firstname} ], lastname => $row->[ $data->{lastname} ] } ); 

            if ( $data->{format} && $row->[ $data->{format} ] =~ m{^(HTML|Text)$} )
            {
                $db->quick_update( 'contacts', { list_id => $params->{list_id}, email => $row->[ $data->{email} ] }, { format => $row->[ $data->{format} ] } );
            }

            if ( $data->{confirmation} && $row->[ $data->{confirmation} ] =~ m{^(Confirmed|Unconfirmed)$} )
            {
                $db->quick_update( 'contacts', { list_id => $params->{list_id}, email => $row->[ $data->{email} ] }, { confirmation => $row->[ $data->{confirmation} ] } );
            }

            if ( $data->{status} && $row->[ $data->{status} ] =~ m{^(Active|Unsubscribed|Bounced)$} )
            {
                $db->quick_update( 'contacts', { list_id => $params->{list_id}, email => $row->[ $data->{email} ] }, { status => $row->[ $data->{status} ] } );
            }

            $count++;
        }
    }
    else
    {
        flash error        => "Could not find the required fields in CSV file.";
        session denied_msg => 'The CSV file did not have the required fields: "email", "firstname", "lastname".';

        return redirect '/denied';
    }

    my $list = $db->quick_select( 'lists', { id => $params->{list_id} } );

    flash success => "Successfully added $count contacts to list $list->{name} <a href='/contacts?searchfield=list_id&searchtype=c&q=$list->{id}&o=&d=&searchsubmit=Search'>View Contacts</a>";

    return redirect '/lists/upload';
};

sub file_error
{
    # Standed CSV "OPPS!" error message.
    my $error = shift;

    flash error        => "File upload error.";
    session denied_msg => 'Looks like you have tried to upload a file that was not a CSV file. The uploader only accecpts CSV files.';

    return redirect '/denied';
}

true;

__END__

=pod

=head1 NAME

LibreMailer::Lists

=head1 DESCRIPTION

list management

=head1 AUTHOR

Sarah Fuller, C<< <sarah at averna.id.au> >>

=head1 LICENSE AND COPYRIGHT

This file is part of LibreMailer

LibreMailer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

LibreMailer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with LibreMailer.  If not, see <http://www.gnu.org/licenses/>.

=cut
