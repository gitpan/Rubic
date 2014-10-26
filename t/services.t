use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use File::Path qw( remove_tree make_path );

{
  use Mojolicious::Lite;

  $ENV{UBIC_DEFAULT_USER} = getpwuid $<;
  $ENV{UBIC_DIR} = 't/ubic';
  $ENV{UBIC_SERVICE_DIR} = 't/ubic/service';

  plugin Ubic => {
    route => app->routes->route('/dummy'),
    json => { foo => 'bar' },
  };
}

my $t = Test::Mojo->new;

{
  remove_tree 't/ubic';
  $t->get_ok('/dummy/services')->json_is('/services', {})->json_is('/foo', 'bar');
  $t->get_ok('/dummy/services/foo')->status_is(404)->json_is('/error', 'Not found');
}

{
  make_path 't/ubic/service/foo';
  make_path 't/ubic/lock';
  make_path 't/ubic/tmp';
  open my $SERVICE, '>', 't/ubic/service/foo/test123' or die $!;
  print $SERVICE "use parent 'Ubic::Service'; sub status { 'running' } bless {}\n";
  close $SERVICE;

  $t->get_ok('/dummy/services')
    ->json_is('/services/foo/services/test123/status', 'running')
    ->json_is('/foo', 'bar')
    ;

  $t->get_ok('/dummy/services?flat=1')
    ->json_is('/services/foo.test123/status', 'running')
    ->json_is('/foo', 'bar')
    ;
}

remove_tree 't/ubic';
done_testing;
