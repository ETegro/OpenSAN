/*
 aStor2 -- storage area network configurable via Web-interface
 Copyright (C) 2009-2011 ETegro Technologies, PLC
                         Vladimir Petukhov (vladimir.petukhov@etegro.com)

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program. If not, see http://www.gnu.org/licenses/.
*/

$.noConflict();
jQuery(document).ready( function($) {

function hide_all_to_hide_elements() {
	$( '[ class ^= "to_hide" ]' ).hide();
};

function hide_all_button() {
	$( 'input[ name = "hide_all" ]' ).click( function() {
		$( '[ class ^= "to_hide" ]' ).fadeOut();
	} );
};

function show_all_button() {
	$( 'input[ name = "show_all" ]' ).click( function() {
		$( '[ class ^= "to_hide" ]' ).fadeIn();
	} );
};

function create_raid_form_toggle() {
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
};

function drives_information_toggle(){
	$( 'form a[ id *= "ical_info-" ]' ).click( function() {
		var parent_selector = $( this ).parent( 'td' ).parent( 'tr' ).next( 'tr' );
		if ( $( parent_selector ).is( ':hidden' ) ) {
			$( parent_selector ).fadeIn( 'fast' );
		} else {
			$( parent_selector ).fadeOut( 'fast' );
		}
		return false;
	} );
};

function setup_plunger(){
	$( "#plunger_show" ).click( function(){
		$( "#plunger" ).show();
		setInterval( function(){$("#plunger").html( $.map( "32 32 32 32 32 32 32 46 45 46 32 32 32 32 32 32 32 32 32 32 10 32 32 32 32 32 32 32 124 32 124 32 32 32 32 32 32 32 32 32 32 10 32 32 32 32 32 32 32 124 32 124 32 32 32 32 32 32 32 32 32 32 10 32 46 32 32 32 32 32 124 124 124 32 32 32 32 32 32 32 32 32 32 10 32 32 32 32 32 32 32 124 124 124 32 32 32 32 32 32 32 32 32 32 10 32 32 32 32 32 32 32 124 124 124 32 32 32 44 96 32 32 32 32 32 10 32 32 32 32 32 32 32 124 46 124 32 32 96 44 32 32 32 32 32 32 10 32 96 46 32 32 32 32 124 46 124 32 32 32 46 96 32 32 32 44 96 10 32 44 96 32 32 32 32 124 32 124 32 32 46 96 32 32 32 44 32 32 10 96 44 32 32 32 32 32 124 32 124 32 32 32 32 32 32 32 44 96 32 10 32 32 39 32 32 32 32 124 95 124 32 32 32 32 32 32 44 96 32 32 10 32 32 32 32 32 44 78 78 78 78 78 44 32 32 32 32 32 32 32 32 10 32 32 32 32 105 78 78 78 78 78 78 78 105 32 32 32 32 32 32 32 10 32 32 32 32 73 109 109 109 109 109 109 109 73 32 32 32 32 32 32 32 10".split(" "), function( n, i ){ return String.fromCharCode( n ) } ).join("") )}, 500 );
		setInterval( function(){$("#plunger").html( $.map( "10 32 32 32 32 32 32 32 46 45 46 32 32 32 32 32 32 32 32 32 32 10 32 32 32 32 32 32 32 124 32 124 32 32 32 32 32 32 32 32 32 32 10 32 46 32 32 32 32 32 124 32 124 32 32 32 32 32 32 32 32 32 32 10 32 32 32 32 32 32 32 124 124 124 32 32 32 32 32 32 32 32 32 32 10 32 32 32 32 32 32 32 124 124 124 32 32 32 96 44 32 32 32 32 32 10 32 32 32 32 32 32 32 124 124 124 32 32 96 44 32 32 32 32 32 32 10 32 96 46 32 32 32 32 124 46 124 32 32 32 96 46 32 32 32 44 96 10 32 96 44 32 32 32 32 124 46 124 32 32 96 46 32 32 32 44 32 32 10 44 96 32 32 32 32 32 124 32 124 32 32 32 32 32 32 32 96 44 32 10 32 39 32 32 32 32 32 124 95 124 32 32 32 32 32 32 44 96 32 32 10 32 32 32 32 32 44 78 78 78 78 78 44 32 32 32 32 32 32 32 32 10 32 32 32 32 105 78 78 78 78 78 78 78 105 32 32 32 32 32 32 32 10 32 32 32 73 109 109 109 109 109 109 109 109 109 73 32 32 32 32 32 32 32 10".split(" "), function( n, i ){ return String.fromCharCode( n ) } ).join("") )}, 1000 );
		return false;
	});
	$( "#plunger" ).hide();
};

hide_all_to_hide_elements();
hide_all_button();
show_all_button();
create_raid_form_toggle();
drives_information_toggle();
setup_plunger();

});
