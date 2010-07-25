package hackday2010::Controller::Speak;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use WordNet::QueryData;
use WWW::Curl::Easy;
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
  my $speech = $c->request->param("speech");
  if (!$speech) {
    
    $c->forward('View::TT');
    $c->detach;
  }
  chomp($speech);
  
  my @lines = split(/\.|\?|\!/m,$speech);
  my $groupcount = 0;
  my $linecount = 0;
  my $finaloutput = [];
  my $repsys = {};
  my $output = [];
  for (my $i=0;$i<@lines;$i++) {
    # start for checking next lines starting with And
    my $aheadcheck = 1;
    my $line = $lines[$i];
    
    my $aheadcount = 0;
    while ($aheadcheck) {
      my $nextline = $lines[$i+$aheadcount+1];
      my @nextwords = split(' ',$nextline);
      if ($nextwords[0] =~ m#and#i) {
	$line = $line + ' ' + $nextline;
	$aheadcount++;
		
      } else {
	$aheadcheck = 0;
      }
	    
    }
    $i = $i + $aheadcount;
    # end of checking for next lines starting with And
    $c->stash->{text} = $line;
    $output->[$linecount] = {};
    $output->[$linecount]->{text} = $line;
    $c->forward('pre');

    $output->[$linecount]->{pre} = $c->stash->{pre};
    $c->forward('embed');
    $output->[$linecount]->{embed} = $c->stash->{embed};
    $c->forward('milton');

    $output->[$linecount]->{milton} = $c->stash->{milton};

    # Meta if there is no milton model
    if (!$output->[$linecount]->{milton} ) {
    $output->[$linecount]->{meta}=1;
    }

    $c->log->debug("Meta is " + $c->stash->{meta});
	

    $c->forward('meta');
    if ( !$output->[$linecount]->{meta}) {
	    
      $output->[$linecount]->{meta} = $c->stash->{meta};
    }
	

    #	$c->forward('repsys');
    #	$output->[$linecount]->{repsys} = $c->stash->{repsys};
    #	$c->forward('pre');
    #	$output->[$linecount]->{modop} = $c->stash->{modop};

    # Add to Group Meta and Group Milton
    $finaloutput->[$groupcount]->{meta} += $output->[$linecount]->{meta};
    $finaloutput->[$groupcount]->{milton} += $output->[$linecount]->{milton};
    $linecount++;		
    if ($linecount >= 5 ||  $i==@lines-1) {
		    
      #Check if we can reset group
      if ($finaloutput->[$groupcount]->{meta} != $finaloutput->[$groupcount]->{milton} ||  $i==@lines-1) {
	# Calculate Score
	my $linekey = 0;
	$finaloutput->[$groupcount]->{score} = 0;
	
	foreach ( @{$output}) {

	  #pre supposition
	  if ($finaloutput->[$groupcount]->{milton} > $finaloutput->[$groupcount]->{meta}  ) {
	    if ($output->[$linekey]->{pre} > 0) {
	      $finaloutput->[$groupcount]->{score} += 1*$output->[$linekey]->{pre};
	    } else {

	      $finaloutput->[$groupcount]->{score} += -1*$output->[$linekey]->{pre};
	    }
	  } else {
	    if ($output->[$linekey]->{pre} <= 0 || !$output->[$linekey]->{pre}) {
	     # $finaloutput->[$groupcount]->{score} += 1;

	    } else {

	      $finaloutput->[$groupcount]->{score} -= 1;
	    }
	  }
	
	  #Embedded Commands
	  if ($finaloutput->[$groupcount]->{milton} > $finaloutput->[$groupcount]->{meta}  ) {
	    if ($output->[$linekey]->{embed} > 0) {
	      $finaloutput->[$groupcount]->{score} += 1*$output->[$linekey]->{embed};
	    } else {
	      $finaloutput->[$groupcount]->{score} += -1*$output->[$linekey]->{embed};

	    }
	  } else {
	    if ($output->[$linekey]->{embed} || !$output->[$linekey]->{embed}) {
	     # $finaloutput->[$groupcount]->{score} += 1;

	    } else {
	      $finaloutput->[$groupcount]->{score} -= 1;
	    }
	  }
	  $linekey++;
	}

	# Append the information to the group
	$finaloutput->[$groupcount]->{lines} = $output;
	$output = [];
	$groupcount++;
	$linecount = 0;

      }
    }
  }
  
  
  $c->log->info(Dumper($finaloutput));
    
  $c->stash->{results} = $finaloutput;
  $c->stash->{template} = "speak/results.tt";
  $c->forward('View::TT');
    
}





our $text = "We have endured the shock of watching so many innocent lives ended in acts of unimaginable horror.";

sub text :Local {

  my($self,$c) = @_;
  #	my $text = "We have endured the shock of and watching so many innocent lives ended in acts of unimaginable horror.";
  #my $text = "What we couldn't be sure of then -- and what the terrorists never expected -- was that America would emerge stronger, with a renewed spirit of pride and patriotism.";
  my $text = "The moment the second plane hit the second building -- when we knew it was a terrorist attack -- many felt that our lives would never be the same least many sometime once september times three.";
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
	#$c->forward('/speak/text');
	my $text = $c->stash->{text};
	$c->forward('/search/get_pos',[$text]);
	my $taggedstring = $c->stash->{getpos};
	my $precount = 0;
	while($taggedstring =~ m#<jjr>(.*?)</jjr>#igms){
		$precount++;
	}

	my @textwhat = split(/what/i,$text);
	if($textwhat[1]){
	foreach my $textw (@textwhat){
		$c->forward('/search/get_pos',[$textw]);
		my $taggedstring = $c->stash->{getpos};
		while($taggedstring =~ m#<jj>(.*?)</jj>#igms){
			$precount++;
		}
		
	}}
	my @texthow = split(/how/i,$text);
	if($texthow[1]){
	foreach my $textw (@texthow){
		$c->forward('/search/get_pos',[$textw]);
		my $taggedstring = $c->stash->{getpos};
		while($taggedstring =~ m#<rb>(.*?)</rb>#igms){
			$precount++;
		}
		
	}}
	my @texttry = split(/try/i,$text);
	if(@texttry > 1){
		$precount++;
	}
	#$c->res->body('<pre>aaaaaaaaa'.Dumper($precount).'</pre>');
	$c->stash->{pre} = $precount;
}

=head2 embed
1. conjunction (and) + simple present verb
=cut
sub embed :Local :Args{
	my($self,$c) = @_;
#	$c->forward('/speak/text');
	my $text = $c->stash->{text};
	my @textand = split('and',$text);
	my $presentverb;
	if($textand[1]){

		$c->forward('/search/get_pos',[$textand[1]]);
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
#	$c->res->body(Dumper($c->stash->{embed}));
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
#	$c->forward('/speak/text');
	my $text = $c->stash->{text};
	$c->forward('/search/get_pos',[$text]);
	my $taggedstring = $c->stash->{getpos};
	my $normcount = 0;
	my $return;
	while($taggedstring =~ m#<nn*>(.*?)</nn*>#igms){
#		my $wn = WordNet::QueryData->new(dir=>'/home/niranjan/WordNet-3.0/dict/',verbose=>0,noload=>0);
#		#my $wnrs = [$wn->querySense('learning#n#1','domt')];
#		my $wnrs = [$wn->listAllWords('learning')];
		
my $url="http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20html%20where%20url%3D%22http%3A%2F%2Fwordnetweb.princeton.edu%2Fperl%2Fwebwn%3Fs%3D$1%22%20and%20xpath%3D%27%2F%2Fa[%40class%3D%22pos%22]%20%27%20and%20content%20%3D%20%27%28v%29%27&format=json&callback=";

		$c->forward('/search/get_jason_data',[$url]);
		my $json = $c->stash->{jsondata};
		if($json->{results}){

			my $googleurl = "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=\"ongoing%20decision\"";
			$c->forward('/search/get_jason_data',[$googleurl]);
			my $googlejson = $c->stash->{jsondata};
			my $resultcount = $googlejson->{responseData}->{cursor}->{estimatedResultCount};
			if($resultcount > 2000){
				$normcount++;
#				$c->res->body($1.'<pre>'.Dumper($resultcount).'</pre>');
#				$c->detach;
			}
		}
	}
	$return->{norm} = $normcount;

	my $gernalization = ['always','everyone','anyone','someone','everything','never','ever'];

	my @textnorm = split(/\W/,$text);
	my $gencount=0;
	foreach my $textn (@textnorm){
		$textn = lc($textn);
		foreach my $gen (@$gernalization){
			if($textn eq $gen){
				$gencount++;	
			}
		}
	}
	$return->{gen} = $gencount;

	my $refindex = ['more','most','like','as'];
	my $refindexcount = 0;
	foreach my $textn (@textnorm){
		$textn = lc($textn);
		foreach my $ref (@$refindex){
			if($textn eq $ref){
				$refindexcount++;	
			}
		}
	}
	$return->{refindex} = $refindexcount;
	
	my $timeindex = ['sometime','once','days','weeks','moment','anytime','times','presently'];	
	my $timeindexcount = 0;
	my $textncount=0;
	foreach my $textn (@textnorm){
		my $textn = lc($textn);
		foreach my $ti (@$timeindex){
			if($textn eq $ti){
#				$c->res->body(Dumper($textnorm[$textncount-1]));
				$c->forward('/search/get_pos',[$textnorm[$textncount-1]]);
				my $taggedstring = $c->stash->{getpos};
				$taggedstring =~ m#<cd*>(.*?)</cd*>#ims;
				if(!$1){
					$timeindexcount++;	
				}
			}
		}
		$textncount++;
	}
	$return->{timeindex} = $timeindexcount;
	my $total = $gencount+$refindexcount+$timeindexcount;
	$c->stash->{milton} = $total;
	$c->stash->{meta} = 0;
	if($total == 0){
		$c->stash->{meta} = 1;
#		$c->forward('meta');
	}
	
}

=head2 meta
1. ++meta when milton is absent
2. specific time
=cut
sub meta :Local {
	my($self,$c,@args) = @_;
#	$c->forward('/speak/text');
	my $text = $c->stash->{text};
	my @textnorm = split(/\W/,$text);
	#$c->forward('/search/get_pos',[$text]);
	#my $taggedstring = $c->stash->{getpos};


	my $timeindex = ['month','months','day','days','week','weeks','year','years','january','february','march','april','may','june','july','august','september','october','november','december'];	
	my $timeindexcount = 0;
	my $textncount=0;
	foreach my $textn (@textnorm){
		my $textn = lc($textn);
		foreach my $ti (@$timeindex){
			if($textn eq $ti){
#				$c->res->body(Dumper($textnorm[$textncount-1]));
				$c->forward('/search/get_pos',[$textnorm[$textncount-1]]);
				my $taggedstring = $c->stash->{getpos};
				$taggedstring =~ m#<cd*>(.*?)</cd*>#ims;
				if($1){
					$timeindexcount++;	
				}
			}
		}
		$textncount++;
	}
	$c->stash->{meta} = $timeindexcount;
#	$c->res->body(Dumper($c->stash->{meta}));
#	$c->detach;

}

sub execute_curl_post : Local : Args(2){
        my($self,$c,@args)=@_;
        my $URL=$args[0];
        my $postdata=$args[1];
        my $curl = new WWW::Curl::Easy;

        $curl->setopt(CURLOPT_HEADER,0);
        $curl->setopt(CURLOPT_URL, $URL);
        $curl->setopt(CURLOPT_POST,1);
        $curl->setopt(CURLOPT_POSTFIELDS, $postdata);
        my $response_body;


        open (my $fileb, ">", \$response_body);
        $curl->setopt(CURLOPT_WRITEDATA,$fileb);

        # Starts the actual request
        my $retcode = $curl->perform;

    # Looking at the results...
    if ($retcode == 0) {
                        #print("Transfer went ok\n");
                        my $response_code = $curl->getinfo(CURLINFO_HTTP_CODE);
                        # judge result and next action based on $response_code
                        return $response_body;
#                print("Received response: $response_body\n");
        } else {
                return 'error';
#                print("An error happened: ".$curl->strerror($retcode)." ($retcode)\n");
        }
}


=head2 repsys
1. verb or adverb is related to the see
2. verb or adverb is related to hear
3. verb or adverb is related to feel
4. absence of any of above is auditor/digital
=cut
sub repsys :Local :Args {
	my($self,$c,@args) = @_;
	#$c->forward('/speak/text');
	my $text = $c->stash->{text};
	$c->forward('/search/get_pos',[$text]);
	my $taggedstring = $c->stash->{getpos};
	my $normcount = 0;
	my $return;
	while($taggedstring =~ m#<rb*>(.*?)</rb*>#igms){
		$c->forward('/search/find_similarity',[$1]);
		my $hash = $c->stash->{find_simlarity};
	#	$c->res->body(Dumper($hash));	
	#$c->detach;
	}
	while($taggedstring =~ m#<vb*>(.*?)</vb*>#igms){
		$c->forward('/search/find_similarity',[$1]);
		my $hash = $c->stash->{find_simlarity};
	}
}

=head2 modop
1. strong - when,do,are,am,i'm,will,just followed by a verb
2. weak -should,would,may,can followed by a verb
3. negative - but
=cut
sub modop :Local :Args {
	my($self,$c,@args) = @_;
	#$c->forward('/speak/text');
	my $text = $c->stash->{text};
	my @textnorm = split(/\W/,$text);
	my $medop = ['should','would','may','can'];
	my $strongop = ['when','do','are','am',"m",'will'];
	my $return;
	my $textncount=0;
	foreach my $textn (@textnorm){
		$textn = lc($textn);
		if($textn eq 'but'){
			$return->{neg_modop}++;
		}
		foreach my $medo (@$medop){
			if($textn eq $medo){
				$c->forward('/search/get_pos',[$textnorm[$textncount+1]]);
				my $taggedstring = $c->stash->{getpos};
				$taggedstring =~ m#<vb*>(.*?)</vb*>#ims;
				if($1){
					$return->{med_modop}++;	
				}
			}
		}
		foreach my $strongo (@$strongop){
			if($textn eq $strongo){
				$c->forward('/search/get_pos',[$textnorm[$textncount+1]]);
				my $taggedstring = $c->stash->{getpos};
				$taggedstring =~ m#<vb*>(.*?)</vb*>#ims;
				if($1){
					$return->{strong_modop}++;	
				}
			}
		}
		$textncount++;
	}
#	$c->res->body(Dumper($return));
#	$c->detach;
	$c->stash->{modop} = $return;
}
=head1 AUTHOR

niranjan,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#__PACKAGE__->meta->make_immutable;

1;
