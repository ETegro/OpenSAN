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

function toggleFade( fade_element ) {
	if ( fade_element.is( ':hidden' ) ) {
		fade_element.fadeIn( 'fast' );
	} else {
		fade_element.fadeOut( 'fast' );
	}
}

function toggleFadeSingleElement( fadeObject ) {
	var click_element = $( fadeObject.click_selector ),
	    fade_element = $( fadeObject.fade_selector );
	click_element.click( function() {
		toggleFade( fade_element );
	} );
}

function toggleFadeParentElement( fadeObject ) {
	var click_element = $( fadeObject.click_selector );
	click_element.click( function() {
		if ( fadeObject.next ) {
			var fade_element = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' ).next( 'tr' );
		} else {
			var fade_element = $( this ).parent( 'div' ).parent( 'td' ).parent( 'tr' ).next( 'tr' );
		}
		toggleFade( fade_element );
		return false;
	} );
}

function toggle_access_pattern_creation() {
	var object = { click_selector : '#access_patterns',
	               fade_selector : '#div_access_pattern_new' };
	toggleFadeSingleElement( object );
}

function toggle_drives_information() {
	var object = { click_selector : 'form a[ id ^= "physical_info-" ]' }
	toggleFadeParentElement( object );
}

function toggle_snapshot_creation() {
	var object = { click_selector : 'form input[ name ^= "snapshot_creation-" ]' };
	toggleFadeParentElement( object );
}

function toggle_resize_snapshot() {
	var object = { click_selector : 'form input[ name ^= "snapshot_resize_button-" ]' };
	toggleFadeParentElement( object );
}

function toggle_edit_access_patterns() {
	var object = { click_selector : 'form input[ name ^= "access_pattern_edit-" ]' };
	toggleFadeParentElement( object );
}

function toggle_logical_volume_creation() {
	var object = { click_selector : 'form input[ name ^= "logical_volume_creation-" ]' };
	object.next = {};
	toggleFadeParentElement( object );
}

function toggle_resize_logical_volume() {
	var object = { click_selector : 'form input[ name ^= "logical_volume_resize_button-" ]' };
	object.next = {};
	toggleFadeParentElement( object );
}

function hide_all_to_hide_elements() {
	$( '[ class *= "to_hide" ]' ).hide();
}

function pulsate_bind_access_patterns() {
	$( 'form input[ name ^= "san.logical_volume_select" ]' ).click( function() {
		$( '.icon-bind' ).show( 'pulsate' );
	} );
}

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
					     '4' : 3,
					     '5' : 3,
					     '6' : 4,
					     '10' : 4 }
				   };

		raidlevels.each( function() {
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
}

function setup_hypnorobo() {
	$( '#hypnorobo_show' ).click( function() {
		$( '#hypnorobo' ).show();
		setInterval( function() { $( '#hypnorobo' ).html( $.map( '32 32 32 32 79 32 112 32 101 32 110 32 83 32 65 32 78 32 10 32 32 32 32 32 32 32 92 95 95 95 95 47 32 32 32 32 32 10 32 32 32 32 32 32 32 47 32 32 32 32 92 32 32 32 32 32 10 32 32 32 32 32 32 47 32 79 32 32 111 32 92 32 32 32 32 10 32 34 111 39 32 40 41 32 92 95 95 47 32 40 41 32 32 32 10 32 32 32 92 47 32 92 95 95 95 95 95 95 47 32 92 32 32 10 32 32 32 32 32 32 32 124 95 124 124 95 124 32 32 32 79 32 10'.split(' '), function( n, i ) { return String.fromCharCode( n ) } ).join('') ) }, 250 );
		setInterval( function() { $( '#hypnorobo' ).html( $.map( '32 32 32 32 79 32 32 32 101 32 32 32 83 32 32 32 78 32 10 32 32 32 32 32 32 32 92 95 95 95 95 47 32 32 32 32 32 10 32 32 32 32 32 32 32 47 32 32 32 32 92 32 32 32 32 32 10 32 32 111 32 32 32 47 32 79 32 32 111 32 92 32 32 32 32 10 32 34 45 39 32 40 41 32 92 95 95 47 32 40 41 32 32 32 10 32 32 32 92 47 32 92 95 95 95 85 95 95 47 32 92 32 32 10 32 32 32 32 32 32 32 124 95 124 124 95 124 32 32 32 79 32 10'.split(' '), function( n, i ) { return String.fromCharCode( n ) } ).join('') ) }, 500 );
		setInterval( function() { $( '#hypnorobo' ).html( $.map( '32 32 32 32 32 32 112 32 32 32 110 32 32 32 65 32 32 32 10 32 32 32 32 32 32 32 92 95 95 95 95 47 32 32 32 32 32 10 32 32 111 32 32 32 32 47 32 32 32 32 92 32 32 32 32 32 10 32 32 32 32 32 32 47 32 111 32 32 79 32 92 32 32 32 32 10 32 34 45 39 32 40 41 32 92 95 95 47 32 40 41 32 32 32 10 32 32 32 92 47 32 92 95 95 117 95 95 95 47 32 92 32 32 10 32 32 32 32 32 32 32 124 95 124 124 95 124 32 32 32 79 32 10'.split(' '), function( n, i ) { return String.fromCharCode( n ) } ).join('') ) }, 750 );
		setInterval( function() { $( '#hypnorobo' ).html( $.map( '32 32 32 32 79 32 32 32 101 32 32 32 83 32 32 32 78 32 10 32 32 32 32 32 32 32 92 95 95 95 95 47 32 32 32 32 32 10 32 32 32 32 32 32 32 47 32 32 32 32 92 32 32 32 32 32 10 32 32 111 32 32 32 47 32 111 32 32 79 32 92 32 32 32 32 10 32 34 95 39 32 40 41 32 92 95 95 47 32 40 41 32 32 32 10 32 32 32 92 47 32 92 95 95 95 95 95 95 47 32 92 32 32 10 32 32 32 32 32 32 32 124 95 124 124 95 124 32 32 32 79 32 10'.split(' '), function( n, i ) { return String.fromCharCode( n ) } ).join('') ) }, 1000 );
		return false;
	} );
	$( '#hypnorobo' ).hide();
}

toggle_access_pattern_creation();
toggle_drives_information();
toggle_snapshot_creation();
toggle_resize_snapshot();
toggle_edit_access_patterns();
toggle_logical_volume_creation();
toggle_resize_logical_volume();
hide_all_to_hide_elements();
pulsate_bind_access_patterns();
toggle_create_raid_form();
setup_hypnorobo();

} );
