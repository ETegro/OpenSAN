$.noConflict();
jQuery(document).ready( function($) {

// Hide all elements with class "to_hide*".
$( '[ class ^= "to_hide" ]' ).hide();

// Hide all on click button "Hide all".
$( 'input[ name = "hide_all" ]' ).click( function() {
	$( '[ class ^= "to_hide" ]' ).fadeOut();
} );

// Show all on click button "Show all".
$( 'input[ name = "show_all" ]' ).click( function() {
	$( '[ class ^= "to_hide" ]' ).fadeIn();
} );

// Hide/show form for "Create RAID".

var physicals_select = $( 'form input:checkbox[ name = "san.physical_id" ]' );

$( physicals_select ).click( function() {
	if ( $( this ).is( ':checked' ) ) {
		$( '#div_raid_create' ).fadeIn( 'fast' );
	} else {
		if ( $( physicals_select ).is( ':checked' ) ) {
			//
		} else {
			$( '#div_raid_create' ).fadeOut( 'fast' );
		}
	}

	// RAID validator
	var num = $( 'form input:checkbox[ name = "san.physical_id" ]:checked:' ).length;
//	var num = drives_array.length;
	var raidlevels = $( '#div_raid_create input:radio[ name = "san.raid_level" ]' );
	var restrictions = { min : { 'passthrough' : 1,
				     'linear' : 1,
				     '0' : 2,
				     '1' : 2,
				     '5' : 3,
				     '6' : 4,
				     '10' : 4 },
			     max : { 'passthrough' : 1 }
			   };

	$( raidlevels ).each( function() {
		var radio = $( this );
		var min = restrictions.min[ radio.val() ] || 0;
		var max = restrictions.max[ radio.val() ] || 1000;
		if ( num >= min && num <= max ) {
			$( this ).removeAttr( 'disabled' );
		} else {
			$( this ).attr( 'disabled', 'disabled' );
		}
	} );
} );

// Hide/show information of physicals and logicals.
$( 'form a[ id *= "ical_info-" ]' ).click( function() {
	var parent_selector = $( this ).parent( 'td' ).parent( 'tr' ).next( 'tr' );
	if ( $( parent_selector ).is( ':hidden' ) ) {
		$( parent_selector ).fadeIn( 'fast' );
	} else {
		$( parent_selector ).fadeOut( 'fast' );
	}
} );

});
