#!/usr/bin/perl
#
# LearnWords subs
#
# Pavel Savinov // savinovpa@gmail.com // http://www.pavelsavinov.info
#
package LearnWordsSubs;

#dependencies
use Exporter;
use JSON;
use Switch;
use Tk::DialogBox;

#exports
our @EXPORT_OK = qw(
  loadData
  addWord
  deleteWord
  editWord
  showAbout
  nextPage
  prevPage
  showHide
  getCurrentPage
  setCurrentPage
);

#package variables
our $pageNumber  = 0;
our $total       = 0;
our $selectedRow = -1;

#table row selection routine
sub setSelectedRow {

	$table       = shift;
	$selectedRow = shift;
	$bckgc       = $table->cget('-background');

	if ( $selectedRow != -1 ) {
		for ( my $x = 0 ; $x < 20 ; $x++ ) {
			my $wl = $table->get( $x, 0 );
			my $wr = $table->get( $x, 1 );
			if ( $wl && $wr ) {

				#reset base colors for all rows except hidden
				if ( $wr->cget('-foreground') ne $bckgc ) {
					$wr->configure( -foreground => 'dark olive green' );
				}
				if ( $wl->cget('-foreground') ne $bckgc ) {
					$wl->configure( -foreground => 'navy' );
				}

			}

		}

		#set selected row color to red, only if not hidden
		if ( $table->get( $selectedRow, 1 )->cget('-foreground') ne $bckgc ) {
			$table->get( $selectedRow, 1 )->configure( -foreground => 'red' );
		}
		if ( $table->get( $selectedRow, 0 )->cget('-foreground') ne $bckgc ) {
			$table->get( $selectedRow, 0 )->configure( -foreground => 'red' );
		}
	}

}

#getters and setters for global variables
sub getSelectedRow {
	return $selectedRow;
}

sub setTotal {
	$total = shift;
}

sub getTotal {
	return $total;
}

sub setCurrentPage {
	$pageNumber = shift;
}

sub getCurrentPage {
	return $pageNumber;
}

#load words database
sub loadData {

	#basic words database file
	$filename = "data/dictionary.json";

	if ( -e $filename ) {

		#reading json base file
		my $jsonText = do {
			open( my $jsonHandler, "<:encoding(UTF-8)", $filename );
			local $/;
			<$jsonHandler>;
		};

		#parsing words base
		my $base = JSON->new()->utf8->decode($jsonText);

		my $table = shift;
		$table->clear;

		my $count      = 0;
		my @words      = @{ $base->{'words'} };
		my $baseLength = @words;
		setTotal($baseLength);
		my $startIdx =
		  getCurrentPage() * 20 < $baseLength ? getCurrentPage() * 20 : 0;
		my $endIdx =
		    ( getCurrentPage() + 1 ) * 20 < $baseLength
		  ? ( getCurrentPage() + 1 ) * 20
		  : 20;

		@words = splice @words, $startIdx, $endIdx;

		#generating page from all the words
		for my $item (@words) {
			my $labelFrom = $table->Label(
				-width      => 32,
				-text       => $item->{'wordFrom'},
				-foreground => 'navy',
				-pady       => 3
			);
			my $labelTo = $table->Label(
				-width      => 32,
				-text       => $item->{'wordTo'},
				-foreground => 'dark olive green',
				-pady       => 3
			);
			my $row = $count;

			#bind select event processing
			$labelFrom->bind(
				'<ButtonRelease-1>' => (
					sub {
						setSelectedRow( $table, $row );
					}
				)
			);
			$labelTo->bind(
				'<ButtonRelease-1>' => (
					sub {
						setSelectedRow( $table, $row );
					}
				)
			);

			#add words to the table
			$table->put( $count, 0, $labelFrom );
			$table->put( $count, 1, $labelTo );
			$count++;
		}

		#fulfill the table with empty rows if base contains less than 20
		if ( $count < 20 ) {
			for ( $i = 20 ; $i > $count ; $i-- ) {
				$table->put( $i, 0, '' );
				$table->put( $i, 1, '' );
			}
		}
	}
	else {

		#database file does not exists :(
		die 'Cannot open data/dictionary.json!';
	}

}

#add word to database
sub addWord {

	my $table = shift;

	#dialog box with buttons
	my $d = $table->DialogBox(
		-title   => "Add new word",
		-buttons => [ "OK", "Cancel" ]
	);

	#words adding frame with 2 labels and 2 edits
	my $df = $d->add( Frame, -width => 300 );
	$df->Label( -text => 'Word:' )
	  ->grid( -row => 0, -column => 0, -pady => 8, -padx => 5, -sticky => 'e' );
	my $wfe = $df->Entry()->grid( -row => 0, -column => 1 );
	$df->Label( -text => 'Translation:' )
	  ->grid( -row => 1, -column => 0, -pady => 8, -padx => 5, -sticky => 'e' );
	my $wte = $df->Entry()->grid( -row => 1, -column => 1 );
	$df->pack();

	#set focus to the first edit box
	$wfe->focus;

	#show window and get the result
	my $result = $d->Show;

	if ( $result eq 'OK' ) {

		$filename = 'data/dictionary.json';

		my $jsonText = do {
			open( my $jsonHandler, '<:encoding(UTF-8)', $filename );
			local $/;
			<$jsonHandler>;
		};

		my $base       = JSON->new()->utf8->decode($jsonText);
		my @words      = @{ $base->{'words'} };
		my $baseLength = @words;
		my $exists     = 0;

		#scan the base to find out if the word already exists
		for my $item (@words) {
			if ( $item->{'wordFrom'} eq $wfe->get() ) {
				$exists++;
				last;
			}
		}

		#word does not exists, create new one
		if ( $exists == 0 ) {
			$word->{'wordFrom'} = $wfe->get();
			$word->{'wordTo'}   = $wte->get();
			$words[$baseLength] = $word;

			$newBase->{'words'} = [@words];

			#save new base to file
			open $baseFile, '>:encoding(UTF-8)', $filename;
			print $baseFile JSON->new()->utf8->encode($newBase);
			close $baseFile;

			loadData($table);
		}
	}
}

sub deleteWord {

	my $table = shift;

	if ( getSelectedRow() != -1 ) {

		#get associated words pair
		$wf = $table->get( getSelectedRow(), 0 )->cget('-text');
		$wt = $table->get( getSelectedRow(), 1 )->cget('-text');
		my $d = $table->DialogBox(
			-title   => "Delete word",
			-buttons => [ "OK", "Cancel" ]
		);

		#build confirmation dialog box
		$d->Label(
			-text =>
			  "Are you sure you want to delete words pair '$wf <-> $wt'?",
			-pady => 10,
			-padx => 5
		)->pack();

		$result = $d->Show;

		#delete, if confirmed
		if ( $result eq 'OK' ) {
			$filename = 'data/dictionary.json';

			my $jsonText = do {
				open( my $jsonHandler, '<:encoding(UTF-8)', $filename );
				local $/;
				<$jsonHandler>;
			};

			my $base  = JSON->new()->utf8->decode($jsonText);
			my @words = @{ $base->{'words'} };

			for ( $k = 0 ; $k < @words ; $k++ ) {
				my $item = $words[$k];

				#word found, splicing array to move it out
				if ( $item->{'wordFrom'} eq $wf ) {
					splice @words, $k, 1;
					last;
				}
			}

			$newBase->{'words'} = [@words];

			open $baseFile, '>:encoding(UTF-8)', $filename;
			print $baseFile JSON->new()->utf8->encode($newBase);
			close $baseFile;

			#reload current page
			loadData($table);

		}
	}

}

sub editWord {

	my $table = shift;

	if ( getSelectedRow() != -1 ) {
		$wf = $table->get( getSelectedRow(), 0 )->cget('-text');
		$wt = $table->get( getSelectedRow(), 1 )->cget('-text');

		my $d = $table->DialogBox(
			-title   => "Edit word",
			-buttons => [ "OK", "Cancel" ]
		);
		my $df = $d->add( Frame, -width => 300 );
		$df->Label( -text => 'Word:' )->grid(
			-row    => 0,
			-column => 0,
			-pady   => 8,
			-padx   => 5,
			-sticky => 'e'
		);
		my $wfe = $df->Entry()->grid( -row => 0, -column => 1 );
		$df->Label( -text => 'Translation:' )->grid(
			-row    => 1,
			-column => 0,
			-pady   => 8,
			-padx   => 5,
			-sticky => 'e'
		);
		my $wte = $df->Entry()->grid( -row => 1, -column => 1 );
		$df->pack();

		$wfe->insert( 'end', $wf );
		$wte->insert( 'end', $wt );
		$wfe->focus;

		my $result = $d->Show;

		if ( $result eq 'OK' ) {

			$filename = 'data/dictionary.json';

			my $jsonText = do {
				open( my $jsonHandler, '<:encoding(UTF-8)', $filename );
				local $/;
				<$jsonHandler>;
			};

			my $base       = JSON->new()->utf8->decode($jsonText);
			my @words      = @{ $base->{'words'} };
			my $baseLength = @words;

			for ( $k = 0 ; $k < @words ; $k++ ) {
				my $item = $words[$k];
				if ( $item->{'wordFrom'} eq $wf ) {
					$item->{'wordFrom'} = $wfe->get();
					$item->{'wordTo'}   = $wte->get();
					$words[$k]          = $item;
					last;
				}
			}

			$newBase->{'words'} = [@words];

			open $baseFile, '>:encoding(UTF-8)', $filename;
			print $baseFile JSON->new()->utf8->encode($newBase);
			close $baseFile;

			loadData($table);
		}
	}

}

#simple about box
sub showAbout {

	my $d = shift->DialogBox(
		-title   => "About LearnWords...",
		-buttons => ["OK"]
	);
	my $df = $d->add( Frame, -width => 300 );

	$df->Label( -text => 'LearnWords', -pady => 20, -foreground => 'navy' )
	  ->pack();
	$df->Label(
		-text =>
'Simple Perl/Tk application to learn foreign words day by day. Feel free to contact me to fix bugs/improve functionality.',
		-justify    => 'center',
		-wraplength => 250,
		-font       => [ -size => 8 ]
	)->pack();
	$df->Label(
		-text       => 'http://www.pavelsavinov.info',
		-foreground => 'blue',
		-padx       => 10,
		-pady       => 3
	)->pack();
	$df->Label(
		-text       => 'savinovpa@gmail.com',
		-foreground => 'blue',
		-padx       => 10,
		-pady       => 3
	)->pack();

	$df->pack();

	$d->Show();

}

sub nextPage {

	my $cp =
	  ( getCurrentPage() + 1 ) * 20 < $total
	  ? getCurrentPage() + 1
	  : getCurrentPage();
	setCurrentPage($cp);
	loadData(shift);
}

sub prevPage {

	my $cp = getCurrentPage() - 1 < 0 ? 0 : getCurrentPage() - 1;
	setCurrentPage($cp);
	loadData(shift);
}

sub showHide {

	my $table = shift;

	#switch does not exists in standard Perl, but package Switch provides it
	switch (shift) {
		case 'left' {
			for ( my $x = 0 ; $x < 20 ; $x++ ) {
				my $wl = $table->get( $x, 0 );
				if ($wl) {
					my $cval = $table->get( $x, 0 )->cget('-foreground');
					my $bckg = $table->cget('-background');
					$table->get( $x, 0 )
					  ->configure(
						-foreground => ( $cval eq $bckg ? 'navy' : $bckg ) );
				}
			}
		}

		case 'right' {
			for ( my $x = 0 ; $x < 20 ; $x++ ) {
				my $wr = $table->get( $x, 1 );
				if ($wr) {
					my $cval = $table->get( $x, 1 )->cget('-foreground');
					my $bckg = $table->cget('-background');
					$table->get( $x, 1 )
					  ->configure( -foreground =>
						  ( $cval eq $bckg ? 'dark olive green' : $bckg ) );
				}
			}
		}

		case 'both' {
			for ( my $x = 0 ; $x < 20 ; $x++ ) {
				my $wl = $table->get( $x, 0 );
				if ($wl) {
					my $cval = $wl->cget('-foreground');
					my $bckg = $table->cget('-background');
					$table->get( $x, 1 )
					  ->configure( -foreground =>
						  ( $cval eq $bckg ? 'dark olive green' : $bckg ) );
					$table->get( $x, 0 )
					  ->configure(
						-foreground => ( $cval eq $bckg ? 'navy' : $bckg ) );
				}
			}
		}
	}

	setSelectedRow( $table, getSelectedRow() );

}

