#!/usr/bin/perl
#
# LearnWords main window
#
# Pavel Savinov // savinovpa@gmail.com // http://www.pavelsavinov.info
#
package LearnWords;

use Exporter;
our @EXPORT_OK = qw(main);
# Tk library import
use Tk;
use Tk::Table;
use LearnWordsSubs;

sub main() {

	# create main app window with all necessary controls
	my $main = MainWindow->new( -title => 'LearnWords' );
	my $frame = $main->Frame();

	#central frame with "lists" of words, using Tk::Table widget

	my $table =
	  $frame->Table( -rows => 25, -columns => 2, -scrollbars => 0)
	  ->grid( -columnspan => 2, -row => 2, -column => 1 );
	  
	#top frame with buttons
	my $topFrame =
	  $frame->Frame()
	  ->grid( -column => 1, -row => 1, -columnspan => 2, -sticky => 'n' );
	$topFrame->Button(
		-text    => 'Add new word',
		-command => sub { LearnWordsSubs::addWord($table) }
	)->pack( -side => 'left', -padx => 2, -pady => 5 );
	$topFrame->Button(
		-text    => 'Delete word',
		-command => sub { LearnWordsSubs::deleteWord($table) }
	)->pack( -side => 'left', -padx => 2 );
	$topFrame->Button(
		-text    => 'Edit word',
		-command => sub { LearnWordsSubs::editWord($table) }
	)->pack( -side => 'left', -padx => 2 );
	$topFrame->Button(
		-text    => 'About',
		-command => sub { LearnWordsSubs::showAbout($main) }
	)->pack( -side => 'left', -padx => 2 );
	$topFrame->Button( -text => 'Exit', -command => sub { exit } )
	  ->pack( -side => 'left', -padx => 2 );

	#bottom frame with page selection buttons
	my $bottomFramePage =
	  $frame->Frame( -pady => 3 )
	  ->grid( -column => 2, -row => 3, -sticky => 'e' );
	$bottomFramePage->Button(
		-text    => 'Previous page',
		-command => sub { LearnWordsSubs::prevPage($table) }
	)->grid( -row => 1, -column => 1, -padx => 2 );
	$bottomFramePage->Button(
		-text    => 'Next page',
		-command => sub { LearnWordsSubs::nextPage($table) }
	)->grid( -row => 1, -column => 2, -padx => 2 );

	#bottom frame with visibility switching buttons
	my $bottomFrameSwitch =
	  $frame->Frame( -pady => 3 )
	  ->grid( -column => 1, -row => 3, -sticky => 'w' );
	$bottomFrameSwitch->Button(
		-text    => 'Left',
		-command => sub { LearnWordsSubs::showHide($table,'left') }
	)->grid( -row => 1, -column => 1, -padx => 2 );
	$bottomFrameSwitch->Button(
		-text    => 'Right',
		-command => sub { LearnWordsSubs::showHide($table,'right') }
	)->grid( -row => 1, -column => 2, -padx => 2 );
	$bottomFrameSwitch->Button(
		-text    => 'Both',
		-command => sub { LearnWordsSubs::showHide($table,'both') }
	)->grid( -row => 1, -column => 3, -padx => 2 );

	#packing main frame and resizing restriction
	$frame->pack();
	$main->resizable( 'no', 'no' );

	#load dictionary and user settings
	LearnWordsSubs::loadData($table);

	MainLoop;
}

LearnWords::main();
