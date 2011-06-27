/*
 aStor2 -- storage area network configurable via Web-interface
 Copyright (C) 2009-2011 ETegro Technologies, PLC
                         Vladimir Petukhov (vladimir.petukhov@etegro.com)

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

$.noConflict();
jQuery( document ).ready( function( $ ) {

function hide_all_to_hide_elements() {
	$( '[ class *= "to_hide" ]' ).hide();
};

function toggle_create_raid_form() {
	var physicals = $( 'form input:checkbox[ name = "san.physical_id" ]' );
	$( physicals ).click( function() {
		if ( $( this ).is( ':checked' ) ) {
			$( '#div_raid_create' ).fadeIn( 'fast' );
		} else {
			if ( !physicals.is( ':checked' ) ) {
				$( '#div_raid_create' ).fadeOut( 'fast' );
			}
		}

		// RAID validator
		var selected_physicals = $( 'form input:checkbox[ name = "san.physical_id" ]:checked' ),
		    num = selected_physicals.length,
		    raidlevels = $( '#div_raid_create input:radio[ name = "san.raid_level" ]' ),
		    restrictions = { max : { 'passthrough' : 1 },
		                     min : { 'passthrough' : 1,
					     'linear' : 1,
					     '0' : 2,
					     '1' : 2,
					     '5' : 3,
					     '6' : 4,
					     '10' : 4 }
				   };

		$( raidlevels ).each( function() {
			var radio = $( this ),
			    min = restrictions.min[ radio.val() ] || 0,
			    max = restrictions.max[ radio.val() ] || 1000;
			if ( num >= min && num <= max ) {
				$( this ).removeAttr( 'disabled' );
			} else {
				$( this ).attr( 'disabled', 'disabled' );
			}
		} );
	} );
};

function toggle_access_pattern_creation() {
	$( '#access_patterns' ).click( function() {
		var parent_selector = $( '#div_access_pattern_new' );
		if ( parent_selector.is( ':hidden' ) ) {
			parent_selector.fadeIn( 'fast' );
		} else {
			parent_selector.fadeOut( 'fast' );
		}
	} );
};

function toggle_drives_information() {
	$( 'form a[ id ^= "physical_info-" ]' ).click( function() {
		var parent_selector = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' );
		if ( parent_selector.is( ':hidden' ) ) {
			parent_selector.fadeIn( 'fast' );
		} else {
			parent_selector.fadeOut( 'fast' );
		}
		return false;
	} );
};

function toggle_logical_volume_creation() {
	$( 'form input[ name ^= "logical_volume_creation-" ]' ).click( function() {
		var parent_selector = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' ).next( 'tr' );
		if ( parent_selector.is( ':hidden' ) ) {
			parent_selector.fadeIn( 'fast' );
		} else {
			parent_selector.fadeOut( 'fast' );
		}
		return false;
	} );
};

function toggle_resize_logical_volume() {
	$( 'form input[ name ^= "logical_volume_resize_button-" ]' ).click( function() {
		var parent_selector = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' ).next( 'tr' );
		if ( parent_selector.is( ':hidden' ) ) {
			parent_selector.fadeIn( 'fast' );
		} else {
			parent_selector.fadeOut( 'fast' );
		}
		return false;
	} );
};

function toggle_snapshot_creation() {
	$( 'form input[ name ^= "snapshot_creation-" ]' ).click( function() {
		var parent_selector = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' );
		if ( parent_selector.is( ':hidden' ) ) {
			parent_selector.fadeIn( 'fast' );
		} else {
			parent_selector.fadeOut( 'fast' );
		}
		return false;
	} );
};

function toggle_resize_snapshot() {
	$( 'form input[ name ^= "snapshot_resize_button-" ]' ).click( function() {
		var parent_selector = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' );
		if ( parent_selector.is( ':hidden' ) ) {
			parent_selector.fadeIn( 'fast' );
		} else {
			parent_selector.fadeOut( 'fast' );
		}
		return false;
	} );
};

function toggle_edit_access_patterns() {
	$( 'form input[ name ^= "access_pattern_edit-" ]' ).click( function() {
		var parent_selector = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' );
		if ( parent_selector.is( ':hidden' ) ) {
			parent_selector.fadeIn( 'fast' );
		} else {
			parent_selector.fadeOut( 'fast' );
		}
		return false;
	} );
};

function pulsate_bind_access_patterns() {
	$( 'form input[ name ^= "san.logical_volume_select" ]' ).click( function() {
		$( '.icon-bind' ).show( 'pulsate' );
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
toggle_access_pattern_creation();
toggle_create_raid_form();
toggle_drives_information();
toggle_logical_volume_creation();
toggle_resize_logical_volume();
toggle_resize_snapshot();
toggle_snapshot_creation();
toggle_edit_access_patterns();
pulsate_bind_access_patterns();
setup_plunger();

} );
