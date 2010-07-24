package hackday2010::Controller::Search;
use Moose;
#use namespace::autoclean;
use WWW::Mechanize;
use JSON -support_by_pp;
use Data::Dumper;
use Lingua::EN::Tagger;
use WordNet::QueryData;
use WordNet::Similarity::path;
use URI::Escape;
#use CGI::Minimal;


BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

hackday2010::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched hackday2010::Controller::Search in Search.');
}

sub find_similarity :Local {
    my ($self,$c,$word) = @_;
#    my ($word) = shift;
    my @availableverbs = ('listen' , 'read');
    my $wn = WordNet::QueryData->new;
    my $measure = WordNet::Similarity::path->new ($wn);
    my $finalverb;
    my $highestvalue=0;

    foreach my $currentverb (@availableverbs)
      {
        my $value = $measure->getRelatedness("$word#v#1", "$currentverb#v#1");
        if($highestvalue < $value)
          {
            $highestvalue = $value;
            $finalverb = $currentverb;
          }

      }


    #if(value is integer)
    return $finalverb;
  }
sub parse_search :Local :Args { 
    my ($self,$c,$search_string) = @_;
#    my $search_string = shift;
    my $verb;
    my $noun;
    my $to=0;
    my $taggedstring = $c->forward('get_pos',[$search_string]);


    $taggedstring =~ m#<vbs*>(.*?)</vbs*>#ims;
    $verb = $1;
    while($taggedstring =~ m#<nns*>(.*?)</nns*>#imsg)
      { push (@$noun,$1);
      }

    #print $taggedstring;

    if( $taggedstring =~ m#<nns*>(.*)<ins*>(.*)</ins*>.*</nns*>#imsg)
      {
        if($2)
          {
            $to = $2;
          }

      }

    #print $to;
	$c->stash->{to} = $to;
	$c->stash->{verb} = $verb;
	$c->stash->{noun} = $noun;
#    return ($to,$verb,@noun);

}

sub showspeeches :Local :Args {
    my ($self,$c,$speeches) = @_;
      my $speeches = shift;
      print "<ul>";
      foreach my $speech (@{$speeches})
        {
                  print "<li>";
                  my $link = $speech->{href};
                  my $name = $link;
                  $name =~ s#/download/(.*)/.*#$1#igsm;
                  print $name.'<br/>';
                  $link =  "http://archive.org".$link;
                  print '<a href="'.$link.'">Click to Listen</a>';
        }
}

sub get_representational_system :Local :Args{
    my $verb = shift;

    # Make sure you take the list of adj verbs and take the best rp based on priority or count 

    my %rp_types = (

                    video  => ['watch'] ,
                    audio  => ['listen'],
                    text   => ['read']

                   );

    while ((my $rp_type, my $words) = each(%rp_types)) {
      foreach my $word (@{$words}) {
        return $rp_type if($verb eq $word);
      }
    }
}

sub get_pos :Local :Args{
	my($self,$c,$search_string) = @_;
#      my $search_string = shift;
      my $p = new Lingua::EN::Tagger;
      my $tagged_text = $p->add_tags( $search_string );

	$c->stash->{getpos} = $tagged_text;
#      return $tagged_text;

    }



=head1 AUTHOR

niranjan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#__PACKAGE__->meta->make_immutable;

1;
