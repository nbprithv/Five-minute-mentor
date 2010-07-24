package hackday2010::Controller::Speak;
use Moose;
use namespace::autoclean;
use Data::Dumper;
BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

hackday2010::Controller::Speak - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    #my $acronnyms = get_acronyms();
    #$c->response->body(Dumper($acronnyms));
    #$c->detach;
    $c->response->body('Matched hackday2010::Controller::Speak in Speak.');
}
our $text = "We have endured the shock of watching so many innocent lives ended in acts of unimaginable horror.";
sub text :Local {

	my($self,$c) = @_;
#	my $text = "We have endured the shock of and watching so many innocent lives ended in acts of unimaginable horror.";
my $text = "What we couldn't be sure of then -- and what the terrorists never expected -- was that America would emerge stronger, with a renewed spirit of pride and patriotism.";
	$c->stash->{text} = $text;
	return $text;
}

=head2 pre
1. comparison
2. what + adj
3. how + adv
4. try
=cut
sub pre :Local :Args{
	my($self,$c) = @_;
	$c->forward('/speak/text');
	my $text = $c->stash->{text};
	$c->forward('/search/get_pos',[$text]);
	my $taggedstring = $c->stash->{getpos};
	my $precount = 0;
	while($taggedstring =~ m#<jjr>(.*?)</jjr>#igms){
		$precount++;
	}

	my @textwhat = split(/what/i,$text);
	foreach my $textw (@textwhat){
		$c->forward('/search/get_pos',[$textw]);
		my $taggedstring = $c->stash->{getpos};
		while($taggedstring =~ m#<jj>(.*?)</jj>#igms){
			$precount++;
		}
		
	}
	my @texthow = split(/how/i,$text);
	foreach my $textw (@texthow){
		$c->forward('/search/get_pos',[$textw]);
		my $taggedstring = $c->stash->{getpos};
		while($taggedstring =~ m#<rb>(.*?)</rb>#igms){
			$precount++;
		}
		
	}
	my @texttry = split(/try/i,$text);
	if(@texttry > 1){
		$precount++;
	}
#	$c->res->body('<pre>aaaaaaaaa'.Dumper($precount).'</pre>');

	$c->stash->{pre} = $precount;
}

=head2 embed
1. conjunction (and) + simple present verb
=cut
sub embed :Local :Args{
	my($self,$c) = @_;
	$c->forward('/speak/text');
	my $text = $c->stash->{text};
	my @textand = split('and',$text);
	if(@textand>0){

		$c->forward('/search/get_pos',[$text]);
		my $taggedstring = $c->stash->{getpos};
		my $presentverb=0;
		while($taggedstring =~ m#<vbp*>(.*?)</vbp*>#igms){
			$presentverb++;
		}
		$c->stash->{embed} = $presentverb;
	#	$c->res->body('<pre>aaaaaaaaa'.Dumper($presentverb).'</pre>');
#		$c->stash->{embed} = 
	}
	else{
		$c->stash->{embed} = 0;
	}

	#$c->forward('/search/parse_search',[$text]);
#	my $to = $c->stash->{to};
#	my $verb = $c->stash->{verb};
#	my $noun = $c->stash->{noun};
#	$c->detach;
}

=head2 milton
1. nominalization - event_word or noun + verb of noun should exist + "an ongoing noun" should not make sense
2. generalization - universal quantifier (always,everyone,anyone,someone,everything,never,always...)
3. lack of referential index - (many,most,most,like...)
4. lack of time index (sometime,once,[months,days,weeks,moment,anytime,times,presently] without a number before it) 
=cut
sub milton :Local{
	my($self,$c,@args) = @_;
	
}

=head2 meta
1. ++meta when milton is absent
2. specific time
=cut
sub meta {
}

=head2 repsys
1. verb or adverb is related to the see
2. verb or adverb is related to hear
3. verb or adverb is related to feel
4. absence of any of above is auditor/digital
=cut
sub repsys {
}

=head2 modop
1. strong - when,do,are,am,i'm,will,just followed by a verb
2. weak -should,would,may,can followed by a verb
3. negative - but
=cut
sub modop {
}
=head1 AUTHOR

niranjan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#__PACKAGE__->meta->make_immutable;

1;
