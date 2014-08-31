package LibreMailer::DateTime;

use Moo;
use Dancer qw(:syntax !before !after);
use DateTime;
use DateTime::Format::MySQL;
use Data::Dumper;

our $VERSION = '0.1';

has timezone => ( is => 'ro', default => sub { config->{timezone} } );

sub current_datetime
{
    # Load current DateTime
    my $self = shift;
    my $dt   = DateTime->now;

    $dt->set_time_zone( $self->timezone );

    return $dt;
}

sub sql_current_datetime
{
    # Load current DateTime in SQL datetime
    my $self = shift;
    my $dt   = DateTime->now;

    $dt->set_time_zone( $self->timezone );

    return DateTime::Format::MySQL->format_datetime( $dt );
}

sub convert_sqlt_to_dt
{
    # Convert SQL datetime to DateTime
    my $self = shift;
    my $dt   = shift;

    return DateTime::Format::MySQL->parse_datetime( $dt );
}

sub convert_dt_to_sqlt
{
    # Convert DateTime to SQL datetime
    my $self = shift;
    my $dt   = shift;

    $dt->set_time_zone( $self->timezone );

    return DateTime::Format::MySQL->format_datetime( $dt );
}

sub check_schedule
{
    # Convert DateTime to SQL datetime
    my $self        = shift;
    my $schedule_dt = $self->convert_sqlt_to_dt( shift );
    my $current_dt  = DateTime->now;

    $current_dt->set_time_zone( $self->timezone );

    my $compare     = DateTime->compare( $current_dt, $schedule_dt ); 

    return ( $compare >= 0 ) ? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

LibreMailer::DateTime

=head1 DESCRIPTION

date stuff cos I'm lazy

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

