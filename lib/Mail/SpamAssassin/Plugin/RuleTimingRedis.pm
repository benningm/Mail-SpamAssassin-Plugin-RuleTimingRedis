package Mail::SpamAssassin::Plugin::RuleTimingRedis;

use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::Logger;
use strict;
use warnings;

# ABSTRACT: collect SA rule timings in redis

=head1 DESCRIPTION

RuleTimingRedis is a plugin for spamassassin which gathers and stores performance
data of processed spamassassin rules in a redis server.

=head1 CONFIGURATION

To load the plugin put an loadplugin line into init.pre:

  loadplugin Mail::SpamAssassin::Plugin::RuleTimingRedis

If the RuleTimingRedis.pm is not in perls @INC you need to specify the path:

  loadplugin Mail::SpamAssassin::Plugin::RuleTimingRedis <path-to>/RuleTimingRedis.pm

If your redis server is not listening on 127.0.0.1:6379 configure the address in local.cf:

  timing_redis_server 192.168.0.10:6379

Then restart amavisd.

After the first mail was processed the keys for the processed rules should appear in redis:

  $ redis-cli
  redis 127.0.0.1:6379> KEYS 'sa-timing.*'
     1) "sa-timing.__DRUGS_SLEEP3.count"
     2) "sa-timing.__MAIL_LINK.count"
     3) "sa-timing.__CGATE_RCVD.count"
  ...


=head1 PARAMETERS

The plugin has the following configuration options:

=over

=item timing_redis_server (default: '127.0.0.1:6379')

Address and port of the redis server.

=item timing_redis_prefix (default: 'sa-timing.')

Prefix to used for the keys in redis.

=item timing_redis_precision (default: 1000000)

Since redis uses integers the floating point value is multiplied
by this factor before storing in redis.

=item timing_redis_debug (default: 0)

Turn on/off debug on the Redis connection.

=back

=cut

use Time::HiRes qw(time);

use vars qw(@ISA);
@ISA = qw(Mail::SpamAssassin::Plugin);

use Redis;

sub new {
    my $class = shift;
    my $mailsaobject = shift;

    $class = ref($class) || $class;
    my $self = $class->SUPER::new($mailsaobject);
    bless ($self, $class);

    $mailsaobject->{conf}->{parser}->register_commands( [
        {
            setting => 'timing_redis_server',
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            default => '127.0.0.1:6379',
        }, {
            setting => 'timing_redis_prefix',
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
            default => 'sa-timing.',
        }, {
            setting => 'timing_redis_precision',
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_NUMERIC,
            default => 1000000, # microseconds (millionths of a second)
        }, {
            setting => 'timing_redis_debug',
            type => $Mail::SpamAssassin::Conf::CONF_TYPE_BOOL,
            default => 0,
        },
    ] );

    return( $self );
}

sub _get_redis {
    my $self = shift;

    if( ! defined $self->{'_redis'} ) {
        eval {
            $self->{'_redis'} = Redis->new(
                'server' => $self->{main}->{conf}->{'timing_redis_server'},
                'debug' => $self->{main}->{conf}->{'timing_redis_debug'},
            );
        };
        if( $@ ) {
            die('could not connect to redis: '.$@);
        }
    }
    return $self->{'_redis'};
}

sub start_rules {
    my ($self, $options) = @_;
    $options->{permsgstatus}->{'rule_timing_start'} = Time::HiRes::time();
    return;
}

sub ran_rule {
    my $time = Time::HiRes::time();
    my ($self, $options) = @_;

    my $permsg = $options->{permsgstatus};
    my $name = $options->{rulename};
    my $prefix = $self->{main}->{conf}->{'timing_redis_prefix'};
    my $precision = $self->{main}->{conf}->{'timing_redis_precision'};

    my $duration = int(($time - $permsg->{'rule_timing_start'}) * $precision);
    $permsg->{'rule_timing_start'} = $time;

    my $redis = $self->_get_redis;

    $redis->incrby($prefix.$name.'.time', $duration);
    $redis->incr($prefix.$name.'.count');

    return;
}


sub finish {
	my $self = shift;
	if( defined $self->{'redis'} ) {
		$self->{'redis'}->quit;
	}
	return;
}

1;
