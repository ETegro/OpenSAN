/*
	LuCI - Lua Configuration Interface

	Copyright 2008 Steven Barth <steven@midlink.org>
	Copyright 2008-2010 Jo-Philipp Wich <xm@subsignal.org>

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
*/

var cbi_d = [];
var cbi_t = [];
var cbi_c = [];

var cbi_validators = {

	'integer': function(v)
	{
		return (v.match(/^-?[0-9]+$/) != null);
	},

	'uinteger': function(v)
	{
		return (cbi_validators.integer(v) && (v >= 0));
	},

	'float': function(v)
	{
		return !isNaN(parseFloat(v));
	},

	'ufloat': function(v)
	{
		return (cbi_validators['float'](v) && (v >= 0));
	},

	'ipaddr': function(v)
	{
		return cbi_validators.ip4addr(v) || cbi_validators.ip6addr(v);
	},

	'neg_ipaddr': function(v)
	{
		return cbi_validators.ip4addr(v.replace(/^\s*!/, "")) || cbi_validators.ip6addr(v.replace(/^\s*!/, ""));
	},

	'ip4addr': function(v)
	{
		if( v.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)(\/(\d+))?$/) )
		{
			return (RegExp.$1 >= 0) && (RegExp.$1 <= 255) &&
			       (RegExp.$2 >= 0) && (RegExp.$2 <= 255) &&
			       (RegExp.$3 >= 0) && (RegExp.$3 <= 255) &&
			       (RegExp.$4 >= 0) && (RegExp.$4 <= 255) &&
			       (!RegExp.$5 || ((RegExp.$6 >= 0) && (RegExp.$6 <= 32)))
			;
		}

		return false;
	},

	'neg_ip4addr': function(v)
	{
		return cbi_validators.ip4addr(v.replace(/^\s*!/, ""));
	},

	'ip6addr': function(v)
	{
		if( v.match(/^([a-fA-F0-9:.]+)(\/(\d+))?$/) )
		{
			if( !RegExp.$2 || ((RegExp.$3 >= 0) && (RegExp.$3 <= 128)) )
			{
				var addr = RegExp.$1;

				if( addr == '::' )
				{
					return true;
				}

				if( addr.indexOf('.') > 0 )
				{
					var off = addr.lastIndexOf(':');

					if( !(off && cbi_validators.ip4addr(addr.substr(off+1))) )
						return false;

					addr = addr.substr(0, off) + ':0:0';
				}

				if( addr.indexOf('::') >= 0 )
				{
					var colons = 0;
					var fill = '0';

					for( var i = 1; i < (addr.length-1); i++ )
						if( addr.charAt(i) == ':' )
							colons++;

					if( colons > 7 )
						return false;

					for( var i = 0; i < (7 - colons); i++ )
						fill += ':0';

					if (addr.match(/^(.*?)::(.*?)$/))
						addr = (RegExp.$1 ? RegExp.$1 + ':' : '') + fill +
						       (RegExp.$2 ? ':' + RegExp.$2 : '');
				}

				return (addr.match(/^(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}$/) != null);
			}
		}

		return false;
	},

	'port': function(v)
	{
		return cbi_validators.integer(v) && (v >= 0) && (v <= 65535);
	},

	'portrange': function(v)
	{
		if( v.match(/^(\d+)-(\d+)$/) )
		{
			var p1 = RegExp.$1;
			var p2 = RegExp.$2;

			return cbi_validators.port(p1) &&
			       cbi_validators.port(p2) &&
			       (parseInt(p1) <= parseInt(p2))
			;
		}
		else
		{
			return cbi_validators.port(v);
		}
	},

	'macaddr': function(v)
	{
		return (v.match(/^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$/) != null);
	},

	'host': function(v)
	{
		return cbi_validators.hostname(v) || cbi_validators.ipaddr(v);
	},

	'hostname': function(v)
	{	if ( v.length <= 253 )
			return (v.match(/^[a-zA-Z0-9][a-zA-Z0-9\-.]*[a-zA-Z0-9]$/) != null);
	},

	'wpakey': function(v)
	{
		if( v.length == 64 )
			return (v.match(/^[a-fA-F0-9]{64}$/) != null);
		else
			return (v.length >= 8) && (v.length <= 63);
	},

	'wepkey': function(v)
	{
		if( v.substr(0,2) == 's:' )
			v = v.substr(2);

		if( (v.length == 10) || (v.length == 26) )
			return (v.match(/^[a-fA-F0-9]{10,26}$/) != null);
		else
			return (v.length == 5) || (v.length == 13);
	},

	'uciname': function(v)
	{
		return (v.match(/^[a-zA-Z0-9_]+$/) != null);
	},

	'range': function(v, args)
	{
		var min = parseInt(args[0]);
		var max = parseInt(args[1]);
		var val = parseInt(v);

		if (!isNaN(min) && !isNaN(max) && !isNaN(val))
			return ((val >= min) && (val <= max));

		return false;
	}
};


function cbi_d_add(field, dep, next) {
	var obj = document.getElementById(field);
	if (obj) {
		var entry
		for (var i=0; i<cbi_d.length; i++) {
			if (cbi_d[i].id == field) {
				entry = cbi_d[i];
				break;
			}
		}
		if (!entry) {
			entry = {
				"node": obj,
				"id": field,
				"parent": obj.parentNode.id,
				"next": next,
				"deps": []
			};
			cbi_d.unshift(entry);
		}
		entry.deps.push(dep)
	}
}

function cbi_d_checkvalue(target, ref) {
	var t = document.getElementById(target);
	var value;

	if (!t) {
		var tl = document.getElementsByName(target);

		if( tl.length > 0 && tl[0].type == 'radio' )
			for( var i = 0; i < tl.length; i++ )
				if( tl[i].checked ) {
					value = tl[i].value;
					break;
				}

		value = value ? value : "";
	} else if (!t.value) {
		value = "";
	} else {
		value = t.value;

		if (t.type == "checkbox") {
			value = t.checked ? value : "";
		}
	}

	return (value == ref)
}

function cbi_d_check(deps) {
	var reverse;
	var def = false;
	for (var i=0; i<deps.length; i++) {
		var istat = true;
		reverse = false;
		for (var j in deps[i]) {
			if (j == "!reverse") {
				reverse = true;
			} else if (j == "!default") {
				def = true;
				istat = false;
			} else {
				istat = (istat && cbi_d_checkvalue(j, deps[i][j]))
			}
		}
		if (istat) {
			return !reverse;
		}
	}
	return def;
}

function cbi_d_update() {
	var state = false;
	for (var i=0; i<cbi_d.length; i++) {
		var entry = cbi_d[i];
		var next  = document.getElementById(entry.next)
		var node  = document.getElementById(entry.id)
		var parent = document.getElementById(entry.parent)

		if (node && node.parentNode && !cbi_d_check(entry.deps)) {
			node.parentNode.removeChild(node);
			state = true;
			if( entry.parent )
				cbi_c[entry.parent]--;
		} else if ((!node || !node.parentNode) && cbi_d_check(entry.deps)) {
			if (!next) {
				parent.appendChild(entry.node);
			} else {
				next.parentNode.insertBefore(entry.node, next);
			}
			state = true;
			if( entry.parent )
				cbi_c[entry.parent]++;
		}
	}

	if (entry && entry.parent) {
		cbi_t_update();
	}

	if (state) {
		cbi_d_update();
	}
}

function cbi_bind(obj, type, callback, mode) {
	if (!obj.addEventListener) {
		obj.attachEvent('on' + type,
			function(){
				var e = window.event;

				if (!e.target && e.srcElement)
					e.target = e.srcElement;

				return !!callback(e);
			}
		);
	} else {
		obj.addEventListener(type, callback, !!mode);
	}
	return obj;
}

function cbi_combobox(id, values, def, man) {
	var selid = "cbi.combobox." + id;
	if (document.getElementById(selid)) {
		return
	}

	var obj = document.getElementById(id)
	var sel = document.createElement("select");
		sel.id = selid;
		sel.className = 'cbi-input-select';

	if (obj.nextSibling) {
		obj.parentNode.insertBefore(sel, obj.nextSibling);
	} else {
		obj.parentNode.appendChild(sel);
	}

	var dt = obj.getAttribute('cbi_datatype');
	var op = obj.getAttribute('cbi_optional');

	if (dt)
		cbi_validate_field(sel, op == 'true', dt);

	if (!values[obj.value]) {
		if (obj.value == "") {
			var optdef = document.createElement("option");
			optdef.value = "";
			optdef.appendChild(document.createTextNode(def));
			sel.appendChild(optdef);
		} else {
			var opt = document.createElement("option");
			opt.value = obj.value;
			opt.selected = "selected";
			opt.appendChild(document.createTextNode(obj.value));
			sel.appendChild(opt);
		}
	}

	for (var i in values) {
		var opt = document.createElement("option");
		opt.value = i;

		if (obj.value == i) {
			opt.selected = "selected";
		}

		opt.appendChild(document.createTextNode(values[i]));
		sel.appendChild(opt);
	}

	var optman = document.createElement("option");
	optman.value = "";
	optman.appendChild(document.createTextNode(man));
	sel.appendChild(optman);

	obj.style.display = "none";

	cbi_bind(sel, "change", function() {
		if (sel.selectedIndex == sel.options.length - 1) {
			obj.style.display = "inline";
			sel.parentNode.removeChild(sel);
			obj.focus();
		} else {
			obj.value = sel.options[sel.selectedIndex].value;
		}

		try {
			cbi_d_update();
		} catch (e) {
			//Do nothing
		}
	})
}

function cbi_combobox_init(id, values, def, man) {
	var obj = document.getElementById(id);
	cbi_bind(obj, "blur", function() {
		cbi_combobox(id, values, def, man)
	});
	cbi_combobox(id, values, def, man);
}

function cbi_filebrowser(id, url, defpath) {
	var field   = document.getElementById(id);
	var browser = window.open(
		url + ( field.value || defpath || '' ) + '?field=' + id,
		"luci_filebrowser", "width=300,height=400,left=100,top=200,scrollbars=yes"
	);

	browser.focus();
}

function cbi_browser_init(id, respath, url, defpath)
{
	function cbi_browser_btnclick(e) {
		cbi_filebrowser(id, url, defpath);
		return false;
	}

	var field = document.getElementById(id);

	var btn = document.createElement('img');
	btn.className = 'cbi-image-button';
	btn.src = respath + '/cbi/folder.gif';
	field.parentNode.insertBefore(btn, field.nextSibling);

	cbi_bind(btn, 'click', cbi_browser_btnclick);
}

function cbi_dynlist_init(name, respath)
{
	function cbi_dynlist_renumber(e)
	{
		/* in a perfect world, we could just getElementsByName() - but not if
		 * MSIE is involved... */
		var inputs = [ ]; // = document.getElementsByName(name);
		for (var i = 0; i < e.parentNode.childNodes.length; i++)
			if (e.parentNode.childNodes[i].name == name)
				inputs.push(e.parentNode.childNodes[i]);

		for (var i = 0; i < inputs.length; i++)
		{
			inputs[i].id = name + '.' + (i + 1);
			inputs[i].nextSibling.src = respath + (
				(i+1) < inputs.length ? '/cbi/remove.gif' : '/cbi/add.gif'
			);
		}

		e.focus();
	}

	function cbi_dynlist_keypress(ev)
	{
		ev = ev ? ev : window.event;

		var se = ev.target ? ev.target : ev.srcElement;

		if (se.nodeType == 3)
			se = se.parentNode;

		switch (ev.keyCode)
		{
			/* backspace, delete */
			case 8:
			case 46:
				if (se.value.length == 0)
				{
					if (ev.preventDefault)
						ev.preventDefault();

					return false;
				}

				return true;

			/* enter, arrow up, arrow down */
			case 13:
			case 38:
			case 40:
				if (ev.preventDefault)
					ev.preventDefault();

				return false;
		}

		return true;
	}

	function cbi_dynlist_keydown(ev)
	{
		ev = ev ? ev : window.event;

		var se = ev.target ? ev.target : ev.srcElement;

		if (se.nodeType == 3)
			se = se.parentNode;

		var prev = se.previousSibling;
		while (prev && prev.name != name)
			prev = prev.previousSibling;

		var next = se.nextSibling;
		while (next && next.name != name)
			next = next.nextSibling;

		switch (ev.keyCode)
		{
			/* backspace, delete */
			case 8:
			case 46:
				var jump = (ev.keyCode == 8)
					? (prev || next) : (next || prev);

				if (se.value.length == 0 && jump)
				{
					se.parentNode.removeChild(se.nextSibling.nextSibling);
					se.parentNode.removeChild(se.nextSibling);
					se.parentNode.removeChild(se);

					cbi_dynlist_renumber(jump);

					if (ev.preventDefault)
						ev.preventDefault();

					/* IE Quirk, needs double focus somehow */
					jump.focus();

					return false;
				}

				break;

			/* enter */
			case 13:
				var n = document.createElement('input');
					n.name       = se.name;
					n.type       = se.type;

				var b = document.createElement('img');

				cbi_bind(n, 'keydown',  cbi_dynlist_keydown);
				cbi_bind(n, 'keypress', cbi_dynlist_keypress);
				cbi_bind(b, 'click',    cbi_dynlist_btnclick);

				if (next)
				{
					se.parentNode.insertBefore(n, next);
					se.parentNode.insertBefore(b, next);
					se.parentNode.insertBefore(document.createElement('br'), next);
				}
				else
				{
					se.parentNode.appendChild(n);
					se.parentNode.appendChild(b);
					se.parentNode.appendChild(document.createElement('br'));
				}

				var dt = se.getAttribute('cbi_datatype');
				var op = se.getAttribute('cbi_optional') == 'true';

				if (dt)
					cbi_validate_field(n, op, dt);

				cbi_dynlist_renumber(n);
				break;

			/* arrow up */
			case 38:
				if (prev)
					prev.focus();

				break;

			/* arrow down */
			case 40:
				if (next)
					next.focus();

				break;
		}

		return true;
	}

	function cbi_dynlist_btnclick(ev)
	{
		ev = ev ? ev : window.event;

		var se = ev.target ? ev.target : ev.srcElement;

		if (se.src.indexOf('remove') > -1)
		{
			se.previousSibling.value = '';

			cbi_dynlist_keydown({
				target:  se.previousSibling,
				keyCode: 8
			});
		}
		else
		{
			cbi_dynlist_keydown({
				target:  se.previousSibling,
				keyCode: 13
			});
		}

		return false;
	}

	var inputs = document.getElementsByName(name);
	for( var i = 0; i < inputs.length; i++ )
	{
		var btn = document.createElement('img');
			btn.className = 'cbi-image-button';
			btn.src = respath + (
				(i+1) < inputs.length ? '/cbi/remove.gif' : '/cbi/add.gif'
			);

		inputs[i].parentNode.insertBefore(btn, inputs[i].nextSibling);

		cbi_bind(inputs[i], 'keydown',  cbi_dynlist_keydown);
		cbi_bind(inputs[i], 'keypress', cbi_dynlist_keypress);
		cbi_bind(btn,       'click',    cbi_dynlist_btnclick);
	}
}

//Hijacks the CBI form to send via XHR (requires Prototype)
function cbi_hijack_forms(layer, win, fail, load) {
	var forms = layer.getElementsByTagName('form');
	for (var i=0; i<forms.length; i++) {
		$(forms[i]).observe('submit', function(event) {
			// Prevent the form from also submitting the regular way
			event.stop();

			// Submit via XHR
			event.element().request({
				onSuccess: win,
				onFailure: fail
			});

			if (load) {
				load();
			}
		});
	}
}


function cbi_t_add(section, tab) {
	var t = document.getElementById('tab.' + section + '.' + tab);
	var c = document.getElementById('container.' + section + '.' + tab);

	if( t && c ) {
		cbi_t[section] = (cbi_t[section] || [ ]);
		cbi_t[section][tab] = { 'tab': t, 'container': c, 'cid': c.id };
	}
}

function cbi_t_switch(section, tab) {
	if( cbi_t[section] && cbi_t[section][tab] ) {
		var o = cbi_t[section][tab];
		var h = document.getElementById('tab.' + section);
		for( var tid in cbi_t[section] ) {
			var o2 = cbi_t[section][tid];
			if( o.tab.id != o2.tab.id ) {
				o2.tab.className = o2.tab.className.replace(/(^| )cbi-tab( |$)/, " cbi-tab-disabled ");
				o2.container.style.display = 'none';
			}
			else {
				if(h) h.value = tab;
				o2.tab.className = o2.tab.className.replace(/(^| )cbi-tab-disabled( |$)/, " cbi-tab ");
				o2.container.style.display = 'block';
			}
		}
	}
	return false
}

function cbi_t_update() {
	var hl_tabs = [ ];

	for( var sid in cbi_t )
		for( var tid in cbi_t[sid] )
			if( cbi_c[cbi_t[sid][tid].cid] == 0 ) {
				cbi_t[sid][tid].tab.style.display = 'none';
			}
			else if( cbi_t[sid][tid].tab && cbi_t[sid][tid].tab.style.display == 'none' ) {
				cbi_t[sid][tid].tab.style.display = '';

				var t = cbi_t[sid][tid].tab;
				t.className += ' cbi-tab-highlighted';
				hl_tabs.push(t);
			}

	if( hl_tabs.length > 0 )
		window.setTimeout(function() {
			for( var i = 0; i < hl_tabs.length; i++ )
				hl_tabs[i].className = hl_tabs[i].className.replace(/ cbi-tab-highlighted/g, '');
		}, 750);
}


function cbi_validate_form(form, errmsg)
{
	/* if triggered by a section removal or addition, don't validate */
	if( form.cbi_state == 'add-section' || form.cbi_state == 'del-section' )
		return true;

	if( form.cbi_validators )
	{
		for( var i = 0; i < form.cbi_validators.length; i++ )
		{
			var validator = form.cbi_validators[i];
			if( !validator() && errmsg )
			{
				alert(errmsg);
				return false;
			}
		}
	}

	return true;
}

function cbi_validate_reset(form)
{
	window.setTimeout(
		function() { cbi_validate_form(form, null) }, 100
	);

	return true;
}

function cbi_validate_field(cbid, optional, type)
{
	var field = (typeof cbid == "string") ? document.getElementById(cbid) : cbid;
	var vargs;

	if( type.match(/^(\w+)\(([^\(\)]+)\)/) )
	{
		type  = RegExp.$1;
		vargs = RegExp.$2.split(/\s*,\s*/);
	}

	var vldcb = cbi_validators[type];

	if( field && vldcb )
	{
		var validator = function()
		{
			// is not detached
			if( field.form )
			{
				field.className = field.className.replace(/ cbi-input-invalid/g, '');

				// validate value
				var value = (field.options && field.options.selectedIndex > -1)
					? field.options[field.options.selectedIndex].value : field.value;

				if( !(((value.length == 0) && optional) || vldcb(value, vargs)) )
				{
					// invalid
					field.className += ' cbi-input-invalid';
					return false;
				}
			}

			return true;
		};

		if( ! field.form.cbi_validators )
			field.form.cbi_validators = [ ];

		field.form.cbi_validators.push(validator);

		cbi_bind(field, "blur",  validator);
		cbi_bind(field, "keyup", validator);

		if (field.nodeName == 'SELECT')
		{
			cbi_bind(field, "change", validator);
			cbi_bind(field, "click",  validator);
		}

		field.setAttribute("cbi_validate", validator);
		field.setAttribute("cbi_datatype", type);
		field.setAttribute("cbi_optional", (!!optional).toString());

		validator();

		var fcbox = document.getElementById('cbi.combobox.' + field.id);
		if (fcbox)
			cbi_validate_field(fcbox, optional, type);
	}
}

function cbi_row_swap(elem, up, store)
{
	var tr = elem.parentNode;
	while (tr && tr.nodeName.toLowerCase() != 'tr')
		tr = tr.parentNode;

	if (!tr)
		return false;

	var table = tr.parentNode;
	while (table && table.nodeName.toLowerCase() != 'table')
		table = table.parentNode;

	if (!table)
		return false;

	var s = up ? 3 : 2;
	var e = up ? table.rows.length : table.rows.length - 1;

	for (var idx = s; idx < e; idx++)
	{
		if (table.rows[idx] == tr)
		{
			if (up)
				tr.parentNode.insertBefore(table.rows[idx], table.rows[idx-1]);
			else
				tr.parentNode.insertBefore(table.rows[idx+1], table.rows[idx]);

			break;
		}
	}

	var ids = [ ];
	for (idx = 2; idx < table.rows.length; idx++)
	{
		table.rows[idx].className = table.rows[idx].className.replace(
			/cbi-rowstyle-[12]/, 'cbi-rowstyle-' + (1 + (idx % 2))
		);

		if (table.rows[idx].id && table.rows[idx].id.match(/-([^\-]+)$/) )
			ids.push(RegExp.$1);
	}

	var input = document.getElementById(store);
	if (input)
		input.value = ids.join(' ');

	return false;
}

if( ! String.serialize )
	String.serialize = function(o)
	{
		switch(typeof(o))
		{
			case 'object':
				// null
				if( o == null )
				{
					return 'null';
				}

				// array
				else if( o.length )
				{
					var i, s = '';

					for( var i = 0; i < o.length; i++ )
						s += (s ? ', ' : '') + String.serialize(o[i]);

					return '[ ' + s + ' ]';
				}

				// object
				else
				{
					var k, s = '';

					for( k in o )
						s += (s ? ', ' : '') + k + ': ' + String.serialize(o[k]);

					return '{ ' + s + ' }';
				}

				break;

			case 'string':
				// complex string
				if( o.match(/[^a-zA-Z0-9_,.: -]/) )
					return 'decodeURIComponent("' + encodeURIComponent(o) + '")';

				// simple string
				else
					return '"' + o + '"';

				break;

			default:
				return o.toString();
		}
	}


if( ! String.format )
	String.format = function()
	{
		if (!arguments || arguments.length < 1 || !RegExp)
			return;

		var html_esc = [/&/g, '&#38;', /"/g, '&#34;', /'/g, '&#39;', /</g, '&#60;', />/g, '&#62;'];
		var quot_esc = [/"/g, '&#34;', /'/g, '&#39;'];

		function esc(s, r) {
			for( var i = 0; i < r.length; i += 2 )
				s = s.replace(r[i], r[i+1]);
			return s;
		}

		var str = arguments[0];
		var out = '';
		var re = /^(([^%]*)%('.|0|\x20)?(-)?(\d+)?(\.\d+)?(%|b|c|d|u|f|o|s|x|X|q|h|j|t|m))/;
		var a = b = [], numSubstitutions = 0, numMatches = 0;

		while( a = re.exec(str) )
		{
			var m = a[1];
			var leftpart = a[2], pPad = a[3], pJustify = a[4], pMinLength = a[5];
			var pPrecision = a[6], pType = a[7];

			numMatches++;

			if (pType == '%')
			{
				subst = '%';
			}
			else
			{
				if (numSubstitutions++ < arguments.length)
				{
					var param = arguments[numSubstitutions];

					var pad = '';
					if (pPad && pPad.substr(0,1) == "'")
						pad = leftpart.substr(1,1);
					else if (pPad)
						pad = pPad;

					var justifyRight = true;
					if (pJustify && pJustify === "-")
						justifyRight = false;

					var minLength = -1;
					if (pMinLength)
						minLength = parseInt(pMinLength);

					var precision = -1;
					if (pPrecision && pType == 'f')
						precision = parseInt(pPrecision.substring(1));

					var subst = param;

					switch(pType)
					{
						case 'b':
							subst = (parseInt(param) || 0).toString(2);
							break;

						case 'c':
							subst = String.fromCharCode(parseInt(param) || 0);
							break;

						case 'd':
							subst = (parseInt(param) || 0);
							break;

						case 'u':
							subst = Math.abs(parseInt(param) || 0);
							break;

						case 'f':
							subst = (precision > -1)
								? ((parseFloat(param) || 0.0)).toFixed(precision)
								: (parseFloat(param) || 0.0);
							break;

						case 'o':
							subst = (parseInt(param) || 0).toString(8);
							break;

						case 's':
							subst = param;
							break;

						case 'x':
							subst = ('' + (parseInt(param) || 0).toString(16)).toLowerCase();
							break;

						case 'X':
							subst = ('' + (parseInt(param) || 0).toString(16)).toUpperCase();
							break;

						case 'h':
							subst = esc(param, html_esc);
							break;

						case 'q':
							subst = esc(param, quot_esc);
							break;

						case 'j':
							subst = String.serialize(param);
							break;

						case 't':
							var td = 0;
							var th = 0;
							var tm = 0;
							var ts = (param || 0);

							if (ts > 60) {
								tm = Math.floor(ts / 60);
								ts = (ts % 60);
							}

							if (tm > 60) {
								th = Math.floor(tm / 60);
								tm = (tm % 60);
							}

							if (th > 24) {
								td = Math.floor(th / 24);
								th = (th % 24);
							}

							subst = (td > 0)
								? String.format('%dd %dh %dm %ds', td, th, tm, ts)
								: String.format('%dh %dm %ds', th, tm, ts);

							break;

						case 'm':
							var mf = pMinLength ? parseInt(pMinLength) : 1000;
							var pr = pPrecision ? Math.floor(10*parseFloat('0'+pPrecision)) : 2;

							var i = 0;
							var val = parseFloat(param || 0);
							var units = [ '', 'K', 'M', 'G', 'T', 'P', 'E' ];

							for (i = 0; (i < units.length) && (val > mf); i++)
								val /= mf;

							subst = val.toFixed(pr) + ' ' + units[i];
							break;
					}
				}
			}

			out += leftpart + subst;
			str = str.substr(m.length);
		}

		return out + str;
	}
