//The 'V' is for 'VORE' but you can pretend it's for Vue.js if you really want.

////////////////////////////////////////////////////////////////////////////////////////
//Updated by Lira for Rogue Star September 2025 as part of a VChat enhancement package//
////////////////////////////////////////////////////////////////////////////////////////

(function(){
	// On 516 this is fairly pointless because we can use devtools if we want
	if(navigator.userAgent.indexOf("Trident") >= 0){
		let oldLog = console.log;
		console.log = function (message) {
			send_debug(message);
			oldLog.apply(console, arguments);
		};
		let oldError = console.error;
		console.error = function (message) {
			send_debug(message);
			oldError.apply(console, arguments);
		}
		window.onerror = function (message, url, line, col, error) {
		let stacktrace = "";
		if(error && error.stack) {
			stacktrace = error.stack;
		}
			send_debug(message+" ("+url+"@"+line+":"+col+") "+error+"|UA: "+navigator.userAgent+"|Stack: "+stacktrace);
		return true;
		}
	}
})();

// Button Controls that need background-color and text-color set.
var SKIN_BUTTONS = [
	/* Rpane */ "rpane.textb", "rpane.infob", "rpane.wikib", "rpane.forumb", "rpane.rulesb", "rpane.github", "rpane.discord", "rpane.mapb", "rpane.changelog",
	/* Mainwindow */ "mainwindow.saybutton", "mainwindow.mebutton", "mainwindow.hotkey_toggle"

];
// Windows or controls that need background-color set.
var SKIN_ELEMENTS = [
	/* Mainwindow */ "mainwindow", "mainwindow.mainvsplit", "mainwindow.tooltip",
	/* Rpane */ "rpane", "rpane.rpanewindow", "rpane.mediapanel",
];

function switch_ui_mode(options) {
	doWinset(SKIN_BUTTONS.reduce(function(params, ctl) {params[ctl + ".background-color"] = options.buttonBgColor; return params;}, {}));
	doWinset(SKIN_BUTTONS.reduce(function(params, ctl) {params[ctl + ".text-color"] = options.buttonTextColor; return params;}, {}));
	doWinset(SKIN_ELEMENTS.reduce(function(params, ctl) {params[ctl + ".background-color"] = options.windowBgColor; return params;}, {}));
	doWinset("infowindow", {
		"background-color": options.tabBackgroundColor,
		"text-color": options.tabTextColor
	});
	doWinset("infowindow.info", {
		"background-color": options.tabBackgroundColor,
		"text-color": options.tabTextColor,
		"highlight-color": options.highlightColor,
		"tab-text-color": options.tabTextColor,
		"tab-background-color": options.tabBackgroundColor
	});
}

function doWinset(control_id, params) {
	if (typeof params === 'undefined') {
		params = control_id;  // Handle single-argument use case.
		control_id = null;
	}
	let url = "byond://winset?";
	if (control_id) {
		url += ("id=" + control_id + "&");
	}
	url += Object.keys(params).map(function(ctl) {
		return ctl + "=" + encodeURIComponent(params[ctl]);
	}).join("&");
	window.location = url;
}

//Options for vchat
var vchat_opts = {
	msBeforeDropped: 30000, //No ping for this long, and the server must be gone
	cookiePrefix: "vst-", //If you're another server, you can change this if you want.
	alwaysShow: ["vc_looc", "vc_system"], //Categories to always display on every tab
	vchatTabsVer: 1.0 //Version of vchat tabs save 'file'
};

/***********
* If you are changing either tabBackgroundColor in dark or lightmode,
* lease keep this synchronized with code\modules\examine\examine.dm
* I cannot think of a elegant way to ensure it tracks these settings properly.
* As long as LIGHTMODE stays as "none", stuff should not break.
* Thank you!
************/

var DARKMODE_COLORS = {
	buttonBgColor: "#40628a",
	buttonTextColor: "#FFFFFF",
	windowBgColor: "#272727",
	highlightColor: "#009900",
	tabTextColor: "#FFFFFF",
	tabBackgroundColor: "#272727"
};

var LIGHTMODE_COLORS = {
	buttonBgColor: "none",
	buttonTextColor: "#000000",
	windowBgColor: "none",
	highlightColor: "#007700",
	tabTextColor: "#000000",
	tabBackgroundColor: "none"
};

/***********
*
* Setup Methods
*
************/

var domparser = new DOMParser();
var storage_system = undefined;

// LS only works in 515, and 516 adds a proprietary storage system
if(storageAvailable('serverStorage')){ // >= 516
	storage_system = window.serverStorage;
} else if (storageAvailable('localStorage')) { // <= 515
	storage_system = window.localStorage;
} else {
	send_debug("No storage system available, using cookies. Sad!");
}

//State-tracking variables
var vchat_state = {
	ready: false,

	//Userinfo as reported by byond
	byond_ip: null,
	byond_cid: null,
	byond_ckey: null,

	//Ping status
	lastPingReceived: 0,
	latency_sent: 0,

	//Last ID
	lastId: 0
}

/* eslint-disable-next-line no-unused-vars */ // Invoked directly by byond
function start_vchat() {
	//Instantiate Vue.js
	start_vue();

	//Inform byond we're done
	vchat_state.ready = true;
	push_Topic('done_loading');
	push_Topic_showingnum(this.showingnum);
	if(typeof vueapp !== 'undefined' && vueapp && typeof vueapp.request_round_overview === 'function') {
		vueapp.request_round_overview();
	} //RS Add: Pull history on load (Lira, September 2025)

	//I'll do my own winsets
	doWinset("htmloutput", {"is-visible": true});
	doWinset("oldoutput", {"is-visible": false});
	doWinset("chatloadlabel", {"is-visible": false});

	// RS Add: Workaround for client bug in 515.1642, hide using these methods too
	doWinset("htmloutput", {"size": "0x0"}); // 0,0 is 'take up all space'
	doWinset("oldoutput", {"size": "1x1"});
	doWinset("chatloadlabel", {"size": "1x1"});

	doWinset("htmloutput", {"pos": "0,0"});
	doWinset("oldoutput", {"pos": "999,999"});
	doWinset("chatloadlabel", {"pos": "999,999"});
	// RS Add End

	//Commence the pingening
	setInterval(check_ping, vchat_opts.msBeforeDropped);

	//For fun
	send_debug("VChat Loaded!");
	//throw new Error("VChat Loaded!");

}

//Loads vue for chat usage
var vueapp;
function start_vue() {
	/* eslint-disable-next-line no-undef */ // Present in vue.min.js, imported in HTML
	vueapp = new Vue({
		el: '#app',
		data: {
			messages: [], //List o messages from byond
			shown_messages: [], //Used on filtered tabs, but not "Main" because it has 0len categories list, which bypasses filtering for speed
			unshown_messages: 0, //How many messages in archive would be shown but aren't
			archived_messages: [], //Too old to show
			tabs: [ //Our tabs
				{name: "Main", categories: [], immutable: true, active: true}
			],
			unread_messages: {}, //Message categories that haven't been looked at since we got one of them
			editing: false, //If we're in settings edit mode
			paused: false, //Autoscrolling state (manual and automatic)
			manual_paused: false, //RS Add: Manual pause toggle (Lira, September 2025)
			scroll_paused: false, //RS Add: Auto pause when scrolled away from bottom (Lira, September 2025)
			latency: 0, //Not necessarily network latency, since the game server has to align the responses into ticks
			reconnecting: false, //If we've lost our connection
			ext_styles: "", //Styles for chat downloaded files
			is_admin: false,

			//Settings
			inverted: false, //Dark mode
			crushing: 3, //Combine similar messages
			animated: false, //Small CSS animations for new messages
			fontsize: 0.9, //Font size nudging
			lineheight: 130,
			//RS Add Start: Font support (Lira, September 2025)
			fontfamily_default: 'Verdana, Arial, sans-serif',
			fontfamily: 'Verdana, Arial, sans-serif',
			// RS Add End
			showingnum: 50, // RS Edit: Lock active messages to 50 (Lira, September 2025)

				// RS Add Start: New settings for export, history, and font (Lira, September 2025)
				pending_chatlog: null,
				round_selector: {
					visible: false,
					loading: false,
					options: [],
					error: '',
					totalMessages: 0,
					roundTotal: 0,
					currentOption: null
				},
				round_overview: {
					loading: false,
					loaded: false,
					error: '',
					totalMessages: 0,
					currentRoundId: '',
					options: []
				},
				history_viewer: {
					visible: false,
					loading: false,
					error: '',
					messages: [],
					roundId: '',
					roundLabel: '',
					requestedRound: '',
					roundsLoading: false,
					messageCount: 0,
					resolvedRoundId: ''
				},
				archived_dom: null,
				pending_archived: [],
				active_round_id: '',
				last_loaded_round_id: '',
				pending_main_round_id: '',
				fontfamily_options: [
					{ label: 'Verdana (Default)', value: 'Verdana, Arial, sans-serif' },
					{ label: 'Bahnschrift', value: 'Bahnschrift, "Segoe UI", Arial, sans-serif' },
					{ label: 'Calibri', value: 'Calibri, "Segoe UI", Arial, sans-serif' },
					{ label: 'Century Gothic', value: '"Century Gothic", "Segoe UI", Arial, sans-serif' },
					{ label: 'Comic Sans MS', value: '"Comic Sans MS", "Comic Sans", cursive' },
					{ label: 'Consolas', value: 'Consolas, "Courier New", Courier, monospace' },
					{ label: 'Gabriola', value: 'Gabriola, "Segoe Script", "Segoe UI", cursive' },
					{ label: 'Ink Free', value: '"Ink Free", "Comic Sans MS", cursive' },
					{ label: 'Wingdings', value: 'Wingdings, "Segoe UI Symbol", sans-serif' },
					{ label: 'Georgia', value: 'Georgia, "Times New Roman", serif' },
					{ label: 'Impact', value: 'Impact, Haettenschweiler, "Arial Narrow Bold", sans-serif' },
					{ label: 'Palatino Linotype', value: '"Palatino Linotype", "Book Antiqua", Palatino, serif' },
					{ label: 'Segoe Script', value: '"Segoe Script", "Comic Sans MS", cursive' },
					{ label: 'Segoe UI', value: '"Segoe UI", Tahoma, Geneva, Verdana, sans-serif' }
				],
				// RS Add End

			//The table to map game css classes to our vchat categories
			type_table: [
				{
					matches: ".filter_say, .say, .emote, .emote_subtle", //VOREStation Edit
					becomes: "vc_localchat",
					pretty: "Local Chat",
					tooltip: "In-character local messages (say, emote, etc)",
					required: false,
					admin: false
				},
				{
					matches: ".filter_radio, .alert, .syndradio, .centradio, .airadio, .entradio, .comradio, .secradio, .engradio, .medradio, .sciradio, .supradio, .srvradio, .expradio, .radio, .deptradio, .newscaster",
					becomes: "vc_radio",
					pretty: "Radio Comms",
					tooltip: "All departments of radio messages",
					required: false,
					admin: false
				},
				{
					matches: ".filter_notice, .notice:not(.pm), .adminnotice, .info, .sinister, .cult",
					becomes: "vc_info",
					pretty: "Notices",
					tooltip: "Non-urgent messages from the game and items",
					required: false,
					admin: false
				},
				{
					matches: ".filter_warning, .warning:not(.pm), .critical, .userdanger, .italics",
					becomes: "vc_warnings",
					pretty: "Warnings",
					tooltip: "Urgent messages from the game and items",
					required: false,
					admin: false
				},
				{
					matches: ".filter_deadsay, .deadsay",
					becomes: "vc_deadchat",
					pretty: "Deadchat",
					tooltip: "All of deadchat",
					required: false,
					admin: false
				},
				{
					matches: ".filter_pray",
					becomes: "vc_pray",
					pretty: "Pray",
					tooltip: "Prayer messages",
					required: false,
					admin: false
				},
				{
					matches: ".ooc, .filter_ooc",
					becomes: "vc_globalooc",
					pretty: "Global OOC",
					tooltip: "The bluewall of global OOC messages",
					required: false,
					admin: false
				},
				//VOREStation Add Start
				{
					matches: ".nif",
					becomes: "vc_nif",
					pretty: "NIF Messages",
					tooltip: "Messages from the NIF itself and people inside",
					required: false,
					admin: false
				},
				//VOREStation Add End
				{
					matches: ".mentor_channel, .mentor",
					becomes: "vc_mentor",
					pretty: "Mentor messages",
					tooltip: "Mentorchat and mentor pms",
					required: false,
					admin: false
				},
				{
					matches: ".filter_pm, .pm",
					becomes: "vc_adminpm",
					pretty: "Admin PMs",
					tooltip: "Messages to/from admins ('adminhelps')",
					required: false,
					admin: false
				},
				{
					matches: ".filter_ASAY, .admin_channel",
					becomes: "vc_adminchat",
					pretty: "Admin Chat",
					tooltip: "ASAY messages",
					required: false,
					admin: true
				},
				{
					matches: ".filter_MSAY, .mod_channel",
					becomes: "vc_modchat",
					pretty: "Mod Chat",
					tooltip: "MSAY messages",
					required: false,
					admin: true
				},
				{
					matches: ".filter_ESAY, .event_channel",
					becomes: "vc_eventchat",
					pretty: "Event Chat",
					tooltip: "ESAY messages",
					required: false,
					admin: true
				},
				{
					matches: ".filter_combat, .danger",
					becomes: "vc_combat",
					pretty: "Combat Logs",
					tooltip: "Urist McTraitor has stabbed you with a knife!",
					required: false,
					admin: false
				},
				{
					matches: ".filter_adminlogs, .log_message",
					becomes: "vc_adminlogs",
					pretty: "Admin Logs",
					tooltip: "ADMIN LOG: Urist McAdmin has jumped to coordinates X, Y, Z",
					required: false,
					admin: true
				},
				{
					matches: ".filter_attacklogs",
					becomes: "vc_attacklogs",
					pretty: "Attack Logs",
					tooltip: "Urist McTraitor has shot John Doe",
					required: false,
					admin: true
				},
				{
					matches: ".filter_debuglogs",
					becomes: "vc_debuglogs",
					pretty: "Debug Logs",
					tooltip: "DEBUG: SSPlanets subsystem Recover().",
					required: false,
					admin: true
				},
				{
					matches: ".looc",
					becomes: "vc_looc",
					pretty: "Local OOC",
					tooltip: "Local OOC messages, always enabled",
					required: true
				},
				{
					matches: ".rlooc",
					becomes: "vc_rlooc",
					pretty: "Remote LOOC",
					tooltip: "Remote LOOC messages",
					required: false,
					admin: true
				},
				{
					matches: ".boldannounce, .filter_system",
					becomes: "vc_system",
					pretty: "System Messages",
					tooltip: "Messages from your client, always enabled",
					required: true
				},
				{
					matches: ".unsorted",
					becomes: "vc_unsorted",
					pretty: "Unsorted",
					tooltip: "Messages that don't have any filters.",
					required: false,
					admin: false
				}
			],
		},
		mounted: function() {
			//Load our settings
			this.load_settings();

			let xhr = new XMLHttpRequest();
			xhr.open('GET', 'ss13styles.css');
			xhr.onreadystatechange = (function() {
				this.ext_styles = xhr.responseText;
			}).bind(this);
			xhr.send();

			// RS Add: Support archived messages (Lira, September 2025)
			this.$nextTick((function() {
				this.archived_dom = this.$refs.archivedMessages || null;
				this.flush_pending_archived();
				this.update_archived_filter(this.current_categories);
			}).bind(this));

			// RS Add Start: Updated scrolling (Lira, September 2025)
			this._suppress_scroll_update = true;
			this._boundScrollHandler = this.handle_window_scroll.bind(this);
			try {
				window.addEventListener('scroll', this._boundScrollHandler, { passive: true });
			} catch(error) {
				window.addEventListener('scroll', this._boundScrollHandler);
			}
			this.$nextTick((function() {
					this.scroll_to_latest();
					let releaseScrollSuppression = (function() {
						this._suppress_scroll_update = false;
						this.resume_autoscroll();
						this.handle_window_scroll();
					}).bind(this);
					if(typeof window.requestAnimationFrame === 'function') {
						window.requestAnimationFrame(releaseScrollSuppression);
					} else {
						setTimeout(releaseScrollSuppression, 0);
					}
			}).bind(this));
			// RS Add End
		},
		// RS Add: Scrolling Support (Lira, September 2025)
		beforeDestroy: function() {
			if(this._boundScrollHandler) {
				window.removeEventListener('scroll', this._boundScrollHandler);
				this._boundScrollHandler = null;
			}
		},
		updated: function() {
			if(!this.editing && !this.paused) {
				this.scroll_to_latest(); // RS Add: Updated scrolling (Lira, September 2025)
			}
		},
		watch: {
			reconnecting: function(newSetting, oldSetting) {
				if(newSetting == true && oldSetting == false) {
					this.internal_message("Your client has lost connection to the server, or there is severe lag. Your client will reconnect if possible.");
				} else if (newSetting == false && oldSetting == true) {
					this.internal_message("Your client has reconnected to the server.");
				}
			},
			//Save the inverted setting to LS
			inverted: function (newSetting) {
				set_storage("darkmode",newSetting);
				if(newSetting) { //Special treatment for <body> which is outside Vue's scope and has custom css
					document.body.classList.add("inverted");
					switch_ui_mode(DARKMODE_COLORS);
				} else {
					document.body.classList.remove("inverted");
					switch_ui_mode(LIGHTMODE_COLORS);
				}
			},
			crushing: function (newSetting) {
				set_storage("crushing",newSetting);
			},
			animated: function (newSetting) {
				set_storage("animated",newSetting);
			},
			fontsize: function (newSetting, oldSetting) {
				if(isNaN(newSetting)) { //Numbers only
					this.fontsize = oldSetting;
					return;
				}
				if(newSetting < 0.2) {
					this.fontsize = 0.2;
				} else if(newSetting > 5) {
					this.fontsize = 5;
				}
				set_storage("fontsize",newSetting);
			},
			lineheight: function (newSetting, oldSetting) {
				if(!isFinite(newSetting)) { //Integers only
					this.lineheight = oldSetting;
					return;
				}
				if(newSetting < 100) {
					this.lineheight = 100;
				} else if(newSetting > 200) {
					this.lineheight = 200;
				}
				set_storage("lineheight",newSetting);
			},
			// RS Add: Font selection support (Lira, September 2025)
			fontfamily: function(newSetting, oldSetting) {
				if(typeof newSetting !== 'string') {
					let fallback = (typeof oldSetting === 'string' && oldSetting.trim().length) ? oldSetting.trim() : this.fontfamily_default;
					this.fontfamily = fallback;
					set_storage("fontfamily", fallback);
					return;
				}
				let trimmed = newSetting.trim();
				if(!trimmed.length) {
					this.fontfamily = this.fontfamily_default;
					set_storage("fontfamily", this.fontfamily);
					return;
				}
				if(this.fontfamily !== trimmed) {
					this.fontfamily = trimmed;
				}
				let optionExists = this.fontfamily_options.some(function(option) {
					return option && option.value === trimmed;
				});
				if(!optionExists) {
					let label = trimmed.split(',')[0] || '';
					label = label.replace(/['"]/g, '').trim();
					if(!label.length) {
						label = 'Custom';
					}
					this.fontfamily_options.push({ label: label, value: trimmed });
				}
				set_storage("fontfamily", trimmed);
			},
			//RS Edit: Locked to 50 (Lira, September 2025)
			showingnum: function () {
				this.showingnum = 50;
				set_storage("showingnum", this.showingnum);
				push_Topic_showingnum(this.showingnum);
			},
			current_categories: function(newSetting) {
				this.update_archived_filter(newSetting); // RS Add: Show archived messages in categories (Lira, September 2025)
				if(newSetting.length) {
					this.apply_filter(newSetting);
				}
			}
		},
		computed: {
			//Which tab is active?
			active_tab: function() {
				//Had to polyfill this stupid .find since IE doesn't have EC6
				let tab = this.tabs.find( function(tab) {
					return tab.active;
				});
				return tab;
			},
			//What color does the latency pip get?
			ping_classes: function() {
				if(!this.latency) {
					return this.reconnecting ? "red" : "green"; //Standard
				}

				if (this.latency == "?") { return "grey"; } //Waiting for latency test reply
				else if(this.latency < 0 ) {return "red"; }
				else if(this.latency <= 200) { return "green"; }
				else if(this.latency <= 400) { return "yellow"; }
				else { return "grey"; }
			},
			current_categories: function() {
				if(this.active_tab == this.tabs[0]) {
					return []; //Everything, no filtering, special case for speed.
				} else {
					return this.active_tab.categories.concat(vchat_opts.alwaysShow);
				}
			},
			// RS Add: Add filtering to history based on tab (Lira, September 2025)
			filtered_history_messages: function() {
				let messages = Array.isArray(this.history_viewer.messages) ? this.history_viewer.messages : [];
				let categories = this.current_categories;
				if(!Array.isArray(categories) || !categories.length) {
					return messages;
				}

				return messages.filter(function(entry) {
					if(!entry || typeof entry !== 'object') {
						return false;
					}
					let category = typeof entry.category === 'string' && entry.category.length ? entry.category : 'vc_unsorted';
					return categories.indexOf(category) > -1;
				});
			}
		},
		methods: {
			//Load the chat settings
			load_settings: function() {
				this.inverted = get_storage("darkmode", false);
				this.crushing = get_storage("crushing", 3);
				this.animated = get_storage("animated", false);
				this.fontsize = get_storage("fontsize", 0.9);
				this.lineheight = get_storage("lineheight", 130);
				this.fontfamily = get_storage("fontfamily", this.fontfamily_default); // RS Add: Font setting (Lira, September 2025)
				// RS Edit Start: Active messages locked to 50 (Lira, September 2025)
				this.showingnum = 50;
				set_storage("showingnum", this.showingnum);
				// RS Edit End

				if(isNaN(this.crushing)){this.crushing = 3;} //This used to be a bool (03-02-2020)
				if(isNaN(this.fontsize)){this.fontsize = 0.9;} //This used to be a string (03-02-2020)
				// RS Add Start: Font support (Lira, September 2025)
				if(typeof this.fontfamily !== 'string' || !this.fontfamily.trim().length){this.fontfamily = this.fontfamily_default;}
				else {
					this.fontfamily = this.fontfamily.trim();
				}

				let hasFontOption = this.fontfamily_options.some(function(option) {
					return option && option.value === this.fontfamily;
				}, this);
				if(!hasFontOption) {
					let label = this.fontfamily.split(',')[0] || '';
					label = label.replace(/['"]/g, '').trim();
					if(!label.length) {
						label = 'Custom';
					}
					this.fontfamily_options.push({ label: label, value: this.fontfamily });
				}
				// RS Add End

				this.load_tabs();
			},
			load_tabs: function() {
				let loadstring = get_storage("tabs")
				if(!loadstring)
					return;
				let loadfile = JSON.parse(loadstring);
				//Malformed somehow.
				if(!loadfile.version || !loadfile.tabs) {
					this.internal_message("There was a problem loading your tabs. Any new ones you make will be saved, however.");
					return;
				}
				//Version is old? Sorry.
				if(!loadfile.version == vchat_opts.vchatTabsVer) {
					this.internal_message("Your saved tabs are for an older version of VChat and must be recreated, sorry.");
					return;
				}

				this.tabs.push.apply(this.tabs, loadfile.tabs);
			},
			save_tabs: function() {
				let savefile = {
					version: vchat_opts.vchatTabsVer,
					tabs: []
				}

				//The tabs contain a bunch of vue stuff that gets funky when you try to serialize it with stringify, so we 'purify' it
				this.tabs.forEach(function(tab){
					if(tab.immutable)
						return;

					let name = tab.name;

					let categories = [];
					tab.categories.forEach(function(category){categories.push(category);});

					let cleantab = {name: name, categories: categories, immutable: false, active: false}

					savefile.tabs.push(cleantab);
				});

				let savestring = JSON.stringify(savefile);
				set_storage("tabs", savestring);
			},
			//Change to another tab
			switchtab: function(tab) {
				if(tab == this.active_tab) return;
				this.active_tab.active = false;
				tab.active = true;

				tab.categories.forEach( function(cls) {
					this.unread_messages[cls] = 0;
				}, this);

				this.apply_filter(this.current_categories);
				this.update_archived_filter(this.current_categories); // RS Add: Update category archive (Lira, September 2025)
			},
			//Toggle edit mode
			editmode: function() {
				this.editing = !this.editing;
				this.save_tabs();
			},
			//Toggle autoscroll
			pause: function() {
			// RS Add Start: Enhanced pause function (Lira, September 2025)
				if(this.manual_paused) {
					this.manual_paused = false;
					if(this.scroll_paused) {
						this.scroll_paused = false;
					}
					this.update_pause_state();
					if(!this.paused) {
						this.scroll_to_latest();
					}
					return;
				}

				if(this.scroll_paused) {
					this.scroll_paused = false;
					this.update_pause_state();
					if(!this.paused) {
						this.scroll_to_latest();
					}
					return;
				}

				this.manual_paused = true;
				this.update_pause_state();
			},
			update_pause_state: function() {
				let shouldPause = this.manual_paused || this.scroll_paused;
				if(this.paused !== shouldPause) {
					this.paused = shouldPause;
				}
			},
			resume_autoscroll: function() {
				let wasPaused = this.manual_paused || this.scroll_paused || this.paused;
				this.manual_paused = false;
				this.scroll_paused = false;
				this.update_pause_state();
				if(wasPaused || !this.is_near_bottom()) {
					this.scroll_to_latest();
				}
			},
			scroll_to_latest: function() {
				let messagebox = document.getElementById("messagebox");
				let doc = document.documentElement;
				let body = document.body;
				let fallback = 0;
				if(doc && typeof doc.scrollHeight === 'number') {
					fallback = Math.max(fallback, doc.scrollHeight);
				}
				if(body && typeof body.scrollHeight === 'number') {
					fallback = Math.max(fallback, body.scrollHeight);
				}
				window.scrollTo(0, messagebox ? messagebox.scrollHeight : fallback);
			},
			handle_window_scroll: function() {
				if(this._suppress_scroll_update) {
					return;
				}
				if(this.editing) {
					return;
				}
				let atBottom = this.is_near_bottom();
				if(atBottom) {
					if(this.scroll_paused) {
						this.scroll_paused = false;
						this.update_pause_state();
					}
				} else if(!this.scroll_paused) {
					this.scroll_paused = true;
					this.update_pause_state();
				}
			},
			is_near_bottom: function() {
				let doc = document.documentElement;
				let body = document.body;
				let messagebox = document.getElementById("messagebox");
				let scrollTop;
				if(window.pageYOffset !== undefined) {
					scrollTop = window.pageYOffset;
				} else if(doc && typeof doc.scrollTop === 'number') {
					scrollTop = doc.scrollTop;
				} else if(body && typeof body.scrollTop === 'number') {
					scrollTop = body.scrollTop;
				} else {
					scrollTop = 0;
				}
				let viewportHeight = window.innerHeight || (doc && typeof doc.clientHeight === 'number' ? doc.clientHeight : 0);
				if(!viewportHeight && body && typeof body.clientHeight === 'number') {
					viewportHeight = body.clientHeight;
				}
				let scrollHeight = 0;
				if(doc && typeof doc.scrollHeight === 'number') {
					scrollHeight = Math.max(scrollHeight, doc.scrollHeight);
				}
				if(body && typeof body.scrollHeight === 'number') {
					scrollHeight = Math.max(scrollHeight, body.scrollHeight);
				}
				if(messagebox && typeof messagebox.scrollHeight === 'number') {
					scrollHeight = Math.max(scrollHeight, messagebox.scrollHeight);
				}
				return (scrollHeight - (scrollTop + viewportHeight)) <= 12;
			// RS Add End
			},
			//Create a new tab (stupid lack of classes in ES5...)
			newtab: function() {
				this.tabs.push({
					name: "New Tab",
					categories: [],
					immutable: false,
					active: false
				});
				this.switchtab(this.tabs[this.tabs.length - 1]);
			},
			//Rename an existing tab
			renametab: function() {
				if(this.active_tab.immutable) {
					return;
				}
				let tabtorename = this.active_tab;
				let newname = window.prompt("Type the desired tab name:", tabtorename.name);
				if(newname === null || newname === "" || tabtorename === null) {
					return;
				}
				tabtorename.name = newname;
			},
			//Delete the currently active tab
			deltab: function(tab) {
				if(!tab) {
					tab = this.active_tab;
				}
				if(tab.immutable) {
					return;
				}
				this.switchtab(this.tabs[0]);
				this.tabs.splice(this.tabs.indexOf(tab), 1);
			},
			movetab: function(tab, shift) {
				if(!tab || tab.immutable) {
					return;
				}
				let at = this.tabs.indexOf(tab);
				let to = at + shift;
				this.tabs.splice(to, 0, this.tabs.splice(at, 1)[0]);
			},
			tab_unread_count: function(tab) {
				let unreads = 0;
				let thisum = this.unread_messages;
				tab.categories.find( function(cls){
					if(thisum[cls]) {
						unreads += thisum[cls];
					}
				});
				return unreads;
			},
			tab_unread_categories: function(tab) {
				let unreads = false;
				let thisum = this.unread_messages;
				tab.categories.find( function(cls){
					if(thisum[cls]) {
						unreads = true;
						return true;
					}
				});

				return { red: unreads, grey: !unreads};
			},
			// RS Add: Reset and load chat log (Lira, September 2025)
			reset_chat_log: function() {
				this.messages.splice(0);
				this.shown_messages.splice(0);
				this.archived_messages.splice(0);
				this.unshown_messages = 0;
				this.pending_archived = [];
				vchat_state.lastId = 0;
				this.ensure_archived_dom();
				if(this.archived_dom) {
					while(this.archived_dom.firstChild) {
						this.archived_dom.removeChild(this.archived_dom.firstChild);
					}
				}
			},
			attempt_archive: function() {
				let wiggle = 20; //Wiggle room to prevent hysterisis effects. Slice off 20 at a time.
				//Pushing out old messages
				if(this.messages.length > this.showingnum) {//Time to slice off old messages
					let too_old = this.messages.splice(0,wiggle); //We do a few at a time to avoid doing it too often
					Array.prototype.push.apply(this.archived_messages, too_old); //ES6 adds spread operator. I'd use it if I could.
					this.append_archived_messages(too_old); // RS Add: Add archived messages (Lira, September 2025)
				}/*
				//Pulling back old messages
				} else if(this.messages.length < (this.showingnum - wiggle)) { //Sigh, repopulate old messages
					let too_new = this.archived_messages.splice(this.messages.length - (this.showingnum - wiggle));
					Array.prototype.shift.apply(this.messages, too_new);
				}
				*/
			},
			// RS Add Start: Enhanced history support (Lira, September 2025)
			append_archived_messages: function(messages, skipQueue) {
				if(!Array.isArray(messages) || !messages.length)
					return;

				this.ensure_archived_dom();
				if(!this.archived_dom) {
					for(let i = 0; i < messages.length; i++) {
						this.pending_archived.push(messages[i]);
					}
					return;
				}

				for(let i = 0; i < messages.length; i++) {
					let msg = messages[i];
					if(!msg || typeof msg !== 'object')
						continue;

					let wrapper = document.createElement('div');
					wrapper.className = 'archived-message';
					if(wrapper.dataset)
						wrapper.dataset.category = msg.category || '';
					else
						wrapper.setAttribute('data-category', msg.category || '');
					let contentSpan = document.createElement('span');
					contentSpan.innerHTML = typeof msg.content === 'string' ? msg.content : '';
					wrapper.appendChild(contentSpan);

					if(msg.repeats && msg.repeats > 1) {
						let repeat = document.createElement('span');
						repeat.className = 'ui grey circular label';
						repeat.textContent = 'x' + msg.repeats;
						wrapper.appendChild(repeat);
					}

					this.archived_dom.appendChild(wrapper);
				}

				if(!skipQueue)
					this.update_archived_filter(this.current_categories);
			},
			flush_pending_archived: function() {
				if(!this.pending_archived.length)
					return;

				let queued = this.pending_archived.slice();
				this.pending_archived = [];
				this.append_archived_messages(queued, true);
				this.update_archived_filter(this.current_categories);
			},
			ensure_archived_dom: function() {
				if(!this.archived_dom) {
					this.archived_dom = this.$refs.archivedMessages || null;
				}
			},
			update_archived_filter: function(categories) {
				this.ensure_archived_dom();
				if(!this.archived_dom)
					return;

				let activeCategories = Array.isArray(categories) ? categories : this.current_categories;
				let showAll = !(activeCategories && activeCategories.length);
				let children = this.archived_dom.children;
				if(!children)
					return;

				for(let i = 0; i < children.length; i++) {
					let node = children[i];
					if(!node)
						continue;
					let nodeCategory = '';
					if(node.dataset && typeof node.dataset.category === 'string') {
						nodeCategory = node.dataset.category;
					} else if(typeof node.getAttribute === 'function') {
						nodeCategory = node.getAttribute('data-category') || '';
					}
					let shouldShow = showAll || (activeCategories && activeCategories.indexOf(nodeCategory) !== -1);
					node.style.display = shouldShow ? '' : 'none';
				}
			},
			on_round_overview_updated: function(roundId) {
				let normalized = typeof roundId === 'string' ? roundId : '';
				if(!normalized && this.round_overview && Array.isArray(this.round_overview.options)) {
					let currentOption = this.round_overview.options.find(function(option) {
						return option && option.isCurrent;
					});
					if(currentOption && currentOption.id) {
						normalized = currentOption.id;
					}
				}

				if(this.active_round_id !== normalized) {
					this.active_round_id = normalized;
					this.load_current_round_history();
				} else if(!this.messages.length && !this.archived_messages.length) {
					this.load_current_round_history();
				}
			},
			load_current_round_history: function() {
				let target = this.active_round_id || '';
				this.reset_chat_log();
				this.request_main_history(target);
			},
			request_main_history: function(roundId) {
				let target = typeof roundId === 'string' ? roundId : '';
				this.pending_main_round_id = target || (this.round_overview && this.round_overview.currentRoundId) || '';
				try {
					const payload = {
						round_id: target,
						source: 'main'
					};
					push_Topic("request_history&param[data]=" + encodeURIComponent(JSON.stringify(payload)));
				} catch (err) {
					console.error(err);
					this.pending_main_round_id = '';
				}
			},
			load_main_history: function(event) {
				let entries = Array.isArray(event.messages) ? event.messages : [];
				let resolvedRound = this.resolve_event_round(event);
				this.last_loaded_round_id = resolvedRound || '';

				this.reset_chat_log();

				let startIndex = Math.max(entries.length - this.showingnum, 0);
				let archivedBatch = [];
				for(let i = 0; i < entries.length; i++) {
					let entry = entries[i];
					if(!entry || typeof entry !== 'object')
						continue;

					let content = typeof entry.content === 'string' ? entry.content : '';
					let messageObj = {
						time: entry.worldtime || 0,
						category: this.get_category(content),
						content: content,
						repeats: 1
					};
					messageObj.id = ++vchat_state.lastId;

					if(i < startIndex) {
						this.archived_messages.push(messageObj);
						archivedBatch.push(messageObj);
					} else {
						this.messages.push(messageObj);
					}
				}

				if(archivedBatch.length) {
					this.append_archived_messages(archivedBatch, true);
				}

				this.apply_filter(this.current_categories);
				this.resume_autoscroll();
				this.pending_main_round_id = '';
			},
			resolve_event_round: function(event) {
				if(event.use_all_rounds === true || event.use_all_rounds === 'true' || event.use_all_rounds === 1)
					return 'all';
				if(typeof event.round_id === 'string' && event.round_id.length)
					return event.round_id;
				if(typeof event.current_round_id === 'string' && event.current_round_id.length)
					return event.current_round_id;
				return '';
			},
			// RS Add End
			apply_filter: function(cat_array) {
				//Clean up the array
				this.shown_messages.splice(0);
				this.unshown_messages = 0;
				this.update_archived_filter(cat_array); // RS Add: Archived message support (Lira, September 2025)

				//For each message, try to find it's category in the categories we're showing
				this.messages.forEach( function(msg){
					if(cat_array.indexOf(msg.category) > -1) { //Returns the position in the array, and -1 for not found
						this.shown_messages.push(msg);
					}
				}, this);
			},
			//Push a new message into our array
			add_message: function(message) {
				//IE doesn't support the 'class' syntactic sugar so we're left making our own object.
				let newmessage = {
					time: message.time,
					category: "error",
					content: message.message,
					repeats: 1
				};

				//Get a category
				newmessage.category = this.get_category(newmessage.content);

				//Put it in unsorted blocks
				if (newmessage.category == "vc_unsorted") {
					newmessage.content = "<span class='unsorted'>" + newmessage.content + "</span>";
				}

				//Try to crush it with one of the last few
				if(this.crushing) {
					let crushwith = this.messages.slice(-(this.crushing));
					for (let i = crushwith.length - 1; i >= 0; i--) {
						let oldmessage = crushwith[i];
						if(oldmessage.content == newmessage.content) {
							newmessage.repeats += oldmessage.repeats;
							this.messages.splice(this.messages.indexOf(oldmessage), 1);
						}
					}
				}

				newmessage.content = newmessage.content.replace(
					/(\b(https?):\/\/[-A-Z0-9+&@#/%?=~_|!:,.;]*[-A-Z0-9+&@#/%=~_|])/img, //Honestly good luck with this regex ~Gear
					'<a href="$1">$1</a>');

				//Unread indicator and insertion into current tab shown messages if sensible
				if(this.current_categories.length && (this.current_categories.indexOf(newmessage.category) < 0)) { //Not in the current categories
					if (isNaN(this.unread_messages[newmessage.category])) {
						this.unread_messages[newmessage.category] = 0;
					}
					this.unread_messages[newmessage.category] += 1;
				} else if(this.current_categories.length) { //Is in the current categories
					this.shown_messages.push(newmessage);
				}

				//Append to vue's messages
				newmessage.id = ++vchat_state.lastId;
				this.attempt_archive();
				this.messages.push(newmessage);
			},
			//Push an internally generated message into our array
			internal_message: function(message) {
				let newmessage = {
					time: this.messages.length ? this.messages.slice(-1).time+1 : 0,
					category: "vc_system",
					content: "<span class='notice'>[VChat Internal] " + message + "</span>"
				};
				newmessage.id = ++vchat_state.lastId;
				this.messages.push(newmessage);
			},
			// RS Edit: Updated for new features (Lira, September 2025)
			on_mouseup: function(event) {
				// Focus map window on mouseup so hotkeys work.  Exception for if they highlighted text or clicked an input.
				let ele = event.target;
				let textSelected = ('getSelection' in window) && window.getSelection().isCollapsed === false;
				let isFormControl = false;
				let node = ele;
				while(node) {
					let tagName = node.tagName;
					if(tagName === 'INPUT' || tagName === 'TEXTAREA' || tagName === 'SELECT' || tagName === 'OPTION') {
						isFormControl = true;
						break;
					}
					node = node.parentElement;
				}

				if (!textSelected && !isFormControl) {
					focusMapWindow();
					if(navigator.userAgent.indexOf("Trident") >= 0){
						// Okay focusing map window appears to prevent click event from being fired.  So lets do it ourselves.
						event.preventDefault();
						event.target.click();
					}
				}
			},
			click_message: function(event) {
				let ele = event.target;
				if(ele.tagName === "A") {
					event.stopPropagation();
					event.preventDefault ? event.preventDefault() : (event.returnValue = false); //The second one is the weird IE method.

					let href = ele.getAttribute('href'); // Gets actual href without transformation into fully qualified URL

					if (href[0] == '?' || (href.length >= 8 && href.substring(0,8) == "byond://")) {
						window.location = href; //Internal byond link
					} else { //It's an external link
						window.location = "byond://?action=openLink&link="+encodeURIComponent(href);
					}
				}
			},
			//Derive a vchat category based on css classes
			get_category: function(message) {
				if(!vchat_state.ready) {
					push_Topic('not_ready');
					return;
				}

				let doc = domparser.parseFromString(message, 'text/html');
				let evaluating = doc.querySelector('span');

				let category = "vc_unsorted"; //What we use if the classes aren't anything we know.
				if(!evaluating) return category;
				this.type_table.find( function(type) {
					if(evaluating.matches(type.matches)) {
						category = type.becomes;
						return true;
					}
				});

				return category;
			},
			save_chatlog: function() {
				//RS Edit Start: Adjusted for enhanced save system (Lira, September 2025)
				const categories = Array.isArray(this.current_categories) ? this.current_categories.slice() : [];
				const fileprefix = "log";
				const extension = ".html";
				const now = new Date();
				//RS Edit End
				let hours = String(now.getHours());
				if(hours.length < 2) {
					hours = "0" + hours;
				}
				let minutes = String(now.getMinutes());
				if(minutes.length < 2) {
					minutes = "0" + minutes;
				}
				let dayofmonth = String(now.getDate());
				if(dayofmonth.length < 2) {
					dayofmonth = "0" + dayofmonth;
				}
				let month = String(now.getMonth()+1); //0-11
				if(month.length < 2) {
					month = "0" + month;
				}
				let year = String(now.getFullYear());
				let datesegment = " "+year+"-"+month+"-"+dayofmonth+" ("+hours+" "+minutes+")";
				let filename = fileprefix+datesegment+extension;

				this.prepare_chatlog_export(categories, filename); // RS Add: Call export (Lira, September 2025)
			},
			// RS Add Start: Logging support (Lira, September 2025)
			prepare_chatlog_export: function(categories, filename) {
				this.pending_chatlog = {
					categories: Array.isArray(categories) ? categories.slice() : [],
					filename: filename
				};
				this.round_selector.visible = true;
				this.round_selector.loading = true;
				this.round_selector.error = '';
				this.round_selector.options = [];
				this.round_selector.totalMessages = 0;
				this.round_selector.roundTotal = 0;
				this.round_selector.currentOption = null;
				this.request_round_overview();
			},
			// Process the server's saved round list and refresh selectors
			receive_round_list: function(event) {
				this.round_overview.loading = false;
				if(!event || typeof event !== 'object') {
					this.round_overview.error = 'Unable to load saved rounds.';
					if(this.round_selector.visible) {
						this.round_selector.loading = false;
						this.round_selector.error = this.round_overview.error;
					}
					if(this.history_viewer.visible) {
						this.history_viewer.roundsLoading = false;
					}
					return;
				}

				let totalMessages = 0;
				if(typeof event.total_messages === 'number') {
					totalMessages = event.total_messages;
				} else if(typeof event.total_messages === 'string') {
					let parsedTotal = parseInt(event.total_messages, 10);
					totalMessages = isNaN(parsedTotal) ? 0 : parsedTotal;
				}

				let roundOptions = [];
				if(Array.isArray(event.rounds)) {
					roundOptions = event.rounds.map(function(entry) {
						if(!entry || typeof entry !== 'object') {
							return null;
						}
						let roundId = typeof entry.id === 'string' ? entry.id : '';
						let messageCount = entry.message_count;
						if(typeof messageCount === 'string') {
							messageCount = parseInt(messageCount, 10);
						}
						if(!isFinite(messageCount)) {
							messageCount = 0;
						}
						messageCount = Math.max(messageCount, 0);
						let startDisplay = typeof entry.start_display === 'string' && entry.start_display.length ? entry.start_display : null;
						let endDisplay = typeof entry.end_display === 'string' && entry.end_display.length ? entry.end_display : null;
						let isCurrent = entry.is_current === true || entry.is_current === 'true' || entry.is_current === 1;
						if(!isCurrent && typeof event.current_round_id === 'string' && roundId === event.current_round_id) {
							isCurrent = true;
						}
						let isOpen = entry.is_open === true || entry.is_open === 'true' || entry.is_open === 1;
						return {
							id: roundId,
							messageCount: messageCount,
							startDisplay: startDisplay,
							endDisplay: endDisplay,
							isCurrent: isCurrent,
							isOpen: isOpen
						};
					}).filter(function(option) { return option && option.id; });
				}

				this.round_overview.options = roundOptions;
				this.round_overview.totalMessages = totalMessages;
				this.round_overview.currentRoundId = typeof event.current_round_id === 'string' ? event.current_round_id : '';
				this.round_overview.error = typeof event.error === 'string' ? event.error : '';
				this.round_overview.loaded = true;
				this.on_round_overview_updated(this.round_overview.currentRoundId);

				if(this.round_selector.visible) {
					this.round_selector.loading = false;
					this.round_selector.error = '';
					this.round_selector.options = roundOptions;
					this.round_selector.currentOption = roundOptions.find(function(option) { return option && option.isCurrent; }) || null;
					this.round_selector.roundTotal = roundOptions.length;
					this.round_selector.totalMessages = totalMessages;
					if(this.round_overview.error) {
						this.round_selector.error = this.round_overview.error;
					} else if(!roundOptions.length) {
						this.round_selector.error = 'No saved rounds were found. You can still export the current round or enter an ID manually.';
					}
				}

				if(this.history_viewer.visible) {
					this.history_viewer.roundsLoading = false;
					this.history_viewer.roundLabel = this.resolve_history_round_label(this.history_viewer.roundId, this.history_viewer.resolvedRoundId);
				}
			},
			// Request an updated list of rounds the client can browse/export
			request_round_overview: function() {
				this.round_overview.loading = true;
				this.round_overview.error = '';
				push_Topic("request_rounds");
			},
			// Show the history viewer dialog and kick off initial data loads
			open_history_viewer: function() {
				if(this.history_viewer.visible)
					return;

				this.history_viewer.visible = true;
				this.history_viewer.loading = true;
				this.history_viewer.error = '';
				this.history_viewer.messages = [];
				this.history_viewer.roundLabel = '';
				this.history_viewer.roundId = '';
				this.history_viewer.requestedRound = '';
				this.history_viewer.messageCount = 0;
				this.history_viewer.roundsLoading = true;
				this.history_viewer.resolvedRoundId = '';

				this.request_round_overview();
				this.request_round_history('', 'viewer');
			},
			// Hide the history viewer and reset its state
			close_history_viewer: function() {
				this.history_viewer.visible = false;
				this.history_viewer.loading = false;
				this.history_viewer.error = '';
				this.history_viewer.messages = [];
				this.history_viewer.roundId = '';
				this.history_viewer.roundLabel = '';
				this.history_viewer.requestedRound = '';
				this.history_viewer.messageCount = 0;
				this.history_viewer.roundsLoading = false;
				this.history_viewer.resolvedRoundId = '';
			},
			// Switch the active round being inspected in the history modal
			change_history_round: function(event) {
				let selected = '';
				if(event && event.target) {
					selected = event.target.value;
				}
				this.history_viewer.roundId = selected;
				this.request_round_history(selected, 'viewer');
			},
			// Ask the server for chat messages tied to a specific round or all rounds
			request_round_history: function(roundId, source) {
				let requestSource = typeof source === 'string' ? source : 'viewer';
				let targetRound = typeof roundId === 'string' ? roundId : '';

				if(requestSource === 'viewer') {
					this.history_viewer.loading = true;
					this.history_viewer.error = '';
					this.history_viewer.messages = [];
					this.history_viewer.messageCount = 0;
					this.history_viewer.requestedRound = targetRound;
				}

				try {
					const payload = {
						round_id: targetRound,
						source: requestSource
					};
					push_Topic("request_history&param[data]=" + encodeURIComponent(JSON.stringify(payload)));
				} catch (err) {
					console.error(err);
					if(requestSource === 'viewer') {
						this.history_viewer.loading = false;
						this.history_viewer.error = 'Unable to request round history.';
					}
				}
			},
			// Handle round history payloads and feed the viewer or main log
			receive_round_history: function(event) {
				if(!event || typeof event !== 'object') {
					if(this.history_viewer.visible) {
						this.history_viewer.loading = false;
						this.history_viewer.error = 'Unable to load round history.';
					}
					return;
				}

				let source = typeof event.source === 'string' ? event.source : 'viewer';
				if(source === 'main') {
					this.pending_main_round_id = '';
					let resolved = this.resolve_event_round(event);
					if(this.active_round_id && resolved && resolved !== this.active_round_id)
						return;
					if(event.error && typeof event.error === 'string' && event.error.length) {
						this.reset_chat_log();
						this.internal_message(event.error);
						return;
					}
					this.load_main_history(event);
					return;
				}

				if(!this.history_viewer.visible) {
					return;
				}

				this.history_viewer.loading = false;

				let responseRound = '';
				if(event.use_all_rounds === true || event.use_all_rounds === 'true' || event.use_all_rounds === 1) {
					responseRound = 'all';
				} else if(typeof event.round_id === 'string' && event.round_id.length) {
					responseRound = event.round_id;
				}

				let expected = this.history_viewer.requestedRound || '';
				let normalizedResponse = responseRound;
				if((!normalizedResponse || normalizedResponse === '') && typeof event.current_round_id === 'string' && event.current_round_id.length) {
					normalizedResponse = event.current_round_id;
				}

				let matchesRequest = false;
				if(expected === normalizedResponse) {
					matchesRequest = true;
				} else if(expected === '' && normalizedResponse) {
					matchesRequest = true;
				} else if(expected === '' && !normalizedResponse) {
					matchesRequest = true;
				} else if(expected === 'all' && normalizedResponse === 'all') {
					matchesRequest = true;
				}

				if(!matchesRequest) {
					return;
				}

				this.history_viewer.roundId = expected;
				this.history_viewer.resolvedRoundId = normalizedResponse || '';

				if(event.error && typeof event.error === 'string' && event.error.length) {
					this.history_viewer.error = event.error;
					this.history_viewer.messages = [];
					this.history_viewer.messageCount = 0;
					this.history_viewer.roundLabel = this.resolve_history_round_label(expected, normalizedResponse);
					return;
				}

				let historyMessages = [];
				if(Array.isArray(event.messages)) {
					// Capture our Vue instance for use inside the map callback
					let self = this;
					historyMessages = event.messages.map(function(entry, index) {
						if(!entry || typeof entry !== 'object') {
							return null;
						}
						let content = typeof entry.content === 'string' ? entry.content : '';
						let loggedAt = entry.logged_at;
						if(typeof loggedAt === 'string') {
							let parsed = parseInt(loggedAt, 10);
							loggedAt = isNaN(parsed) ? 0 : parsed;
						}
						if(!isFinite(loggedAt)) {
							loggedAt = 0;
						}
						let worldtime = entry.worldtime;
						if(typeof worldtime === 'string') {
							let parsedWorld = parseInt(worldtime, 10);
							worldtime = isNaN(parsedWorld) ? 0 : parsedWorld;
						}
						if(!isFinite(worldtime)) {
							worldtime = 0;
						}
						// Resolve the same category flags used in live chat for consistent filtering
						let category = 'vc_unsorted';
						if(content) {
							let derivedCategory = self.get_category(content);
							if(typeof derivedCategory === 'string' && derivedCategory.length) {
								category = derivedCategory;
							}
						}
						return {
							id: index + 1,
							content: content,
							loggedAt: loggedAt,
							worldtime: worldtime,
							category: category
						};
					}).filter(function(item) { return item !== null; });
				}

				let messageCount = 0;
				if(typeof event.message_count === 'number') {
					messageCount = event.message_count;
				} else if(typeof event.message_count === 'string') {
					let parsedCount = parseInt(event.message_count, 10);
					messageCount = isNaN(parsedCount) ? historyMessages.length : parsedCount;
				} else {
					messageCount = historyMessages.length;
				}

					this.history_viewer.messages = historyMessages;
					this.history_viewer.messageCount = messageCount;
					this.history_viewer.roundLabel = this.resolve_history_round_label(expected, normalizedResponse);
					this.history_viewer.error = '';
			},
			// Create a label for the round currently being viewed
			resolve_history_round_label: function(roundId, fallbackRoundId) {
				if(roundId === 'all' || fallbackRoundId === 'all') {
					return 'All saved rounds';
				}
				let candidate = roundId;
				if((!candidate || candidate === '') && fallbackRoundId) {
					candidate = fallbackRoundId;
				}
				if(!candidate) {
					let currentId = this.round_overview.currentRoundId;
					if(currentId) {
						let currentMatch = this.round_overview.options.find(function(option) {
							return option && option.id === currentId;
						});
						if(currentMatch) {
							if(currentMatch.startDisplay && currentMatch.startDisplay.length) {
								return currentMatch.startDisplay;
							}
							return currentMatch.id;
						}
					}
					return 'Current round';
				}
				let match = this.round_overview.options.find(function(option) {
					return option && option.id === candidate;
				});
				if(match) {
					if(match.startDisplay && match.startDisplay.length) {
						return match.startDisplay;
					}
					return match.id;
				}
				return candidate;
			},
			//Export using one of the explicit round buttons in the selector
			select_round_option: function(option) {
				if(!option) {
					return;
				}
				let roundValue = option.use_all ? 'all' : option.id;
				if(!roundValue && roundValue !== '') {
					roundValue = '';
				}
				if(this.complete_chatlog_save(roundValue)) {
					this.close_round_selector();
				}
			},
			//Shortcut export helper for the currently running round
			select_current_round: function() {
				if(this.complete_chatlog_save('')) {
					this.close_round_selector();
				}
			},
			//Shortcut export helper that bundles every stored round
			select_all_rounds: function() {
				if(this.complete_chatlog_save('all')) {
					this.close_round_selector();
				}
			},
			//Perform the chatlog export locally if the server cannot handle it
			complete_chatlog_save: function(roundId) {
				if(!this.pending_chatlog) {
					return false;
				}
				const categories = Array.isArray(this.pending_chatlog.categories) ? this.pending_chatlog.categories.slice() : [];
				const filename = this.pending_chatlog.filename;
				let exportRound = typeof roundId === 'string' ? roundId : '';

				if(requestChatlogSave(filename, categories, exportRound)) {
					return true;
				}

				let textToSave = "<html><head><style>"+this.ext_styles+"</style></head><body>";
				const cats = categories;
				let messagesToSave = this.archived_messages.concat(this.messages);

				messagesToSave.forEach( function(message) {
					if(cats.length === 0 || (cats.indexOf(message.category) >= 0)) { //only in the active tab
						textToSave += message.content;
						if(message.repeats > 1) {
							textToSave += "(x"+message.repeats+")";
						}
						textToSave += "<br>\n";
					}
				});
				textToSave += "</body></html>";

				let blob = new Blob([textToSave], {type: 'text/html;charset=utf8;'});
				downloadBlob(blob, filename);
				return true;
			},
			//Close the round selector without exporting anything
			cancel_round_selection: function() {
				this.close_round_selector();
			},
			//Tear down the selector UI and optionally clear the pending export payload
			close_round_selector: function(resetPending) {
				if(typeof resetPending === 'undefined') {
					resetPending = true;
				}
				this.round_selector.visible = false;
				this.round_selector.loading = false;
				this.round_selector.options = [];
				this.round_selector.error = '';
				this.round_selector.totalMessages = 0;
				this.round_selector.roundTotal = 0;
				this.round_selector.currentOption = null;
				if(resetPending) {
					this.pending_chatlog = null;
				}
			},
			//RS Add End
			do_latency_test: function() {
				send_latency_check();
			},
			// RS Add: Reset font (Lira, September 2025)
			reset_fontfamily: function() {
				this.fontfamily = this.fontfamily_default;
			},
			blur_this: function(event) {
				event.target.blur();
			}
		}
	});
}

/***********
*
* Actual Methods
*
************/
function check_ping() {
	let time_ago = Date.now() - vchat_state.lastPingReceived;
	if(time_ago > vchat_opts.msBeforeDropped)
		vueapp.reconnecting = true;
}

//Send a 'ping' to byond
function send_latency_check() {
	if(vchat_state.latency_sent)
			return;

	vchat_state.latency_sent = Date.now();
	vueapp.latency = "?";
	push_Topic("ping");
	setTimeout(function() {
		if(vchat_state.latency_ms == "?") {
			vchat_state.latency_ms = 999;
		}
	}, 1000); // 1 second to reply otherwise we mark it as bad
	setTimeout(function() {
		vchat_state.latency_sent = 0;
		vueapp.latency = 0;
	}, 5000); //5 seconds to display ping time overall
}

function get_latency_check() {
	if(!vchat_state.latency_sent) {
		return; //Too late
	}

	vueapp.latency = Date.now() - vchat_state.latency_sent;
}

//We accept double-url-encoded JSON strings because Byond is garbage and UTF-8 encoded url_encode() text has crazy garbage in it.
function byondDecode(message) {

	//Byond encodes spaces as pluses?! This is 1998 I guess.
	message = message.replace(/\+/g, "%20");
	try {
		message = decodeURIComponent(message);
	} catch (err) {
		message = unescape(message+JSON.stringify(err));
	}
	return JSON.parse(message);
}

//This is the function byond actually communicates with using byond's client << output() method.
/* eslint-disable-next-line no-unused-vars */ // Called directly by byond
function putmessage(messages) {
	messages = byondDecode(messages);
	if (Array.isArray(messages)) {
		messages.forEach(function(message) {
			vueapp.add_message(message);
		});
	} else if (typeof messages === 'object') {
		vueapp.add_message(messages);
	}
}

//Send an internal message generated in the javascript
function system_message(message) {
	vueapp.internal_message(message);
}

//This is the other direction of communication, to push a Topic message back
function push_Topic(topic_uri) {
	window.location = '?_src_=chat&proc=' + topic_uri; //Yes that's really how it works.
}

// Send the showingnum back to byond
function push_Topic_showingnum(topic_num) {
	window.location = '?_src_=chat&showingnum=' + topic_num;
}

//Tells byond client to focus the main map window.
function focusMapWindow() {
	window.location = 'byond://winset?mapwindow.map.focus=true';
}

//Debug event
function send_debug(message) {
	push_Topic("debug&param[message]="+encodeURIComponent(message));
}

//A side-channel to send events over that aren't just chat messages, if necessary.
/* eslint-disable-next-line no-unused-vars */ // Called directly by byond
function get_event(event) {
	if(!vchat_state.ready) {
		push_Topic("not_ready");
		return;
	}

	let parsed_event = {evttype: 'internal_error', event: event};
	parsed_event = byondDecode(event);

	switch(parsed_event.evttype) {
		//We didn't parse it very well
		case 'internal_error':
			system_message("Event parse error: " + event);
			break;

		//They provided byond data.
		case 'byond_player':
			send_client_data();
			vueapp.is_admin = (parsed_event.admin === 'true');
			vchat_state.byond_ip = parsed_event.address;
			vchat_state.byond_cid = parsed_event.cid;
			vchat_state.byond_ckey = parsed_event.ckey;
			set_storage("ip",vchat_state.byond_ip);
			set_storage("cid",vchat_state.byond_cid);
			set_storage("ckey",vchat_state.byond_ckey);
			break;

		//Just a ping.
		case 'keepalive':
			vchat_state.lastPingReceived = Date.now();
			vueapp.reconnecting = false;
			break;

		//Response to a latency test.
		case 'pong':
			get_latency_check();
			break;

		//The server doesn't know if we're loaded or not (we bail above if we're not, so we must be).
		case 'availability':
			push_Topic("done_loading");
			break;

		// RS Add Start: Round list and history (Lira, September 2025)
		case 'round_list':
			if(vueapp && typeof vueapp.receive_round_list === 'function') {
				vueapp.receive_round_list(parsed_event);
			}
			break;

		case 'round_history':
			if(vueapp && typeof vueapp.receive_round_history === 'function') {
				vueapp.receive_round_history(parsed_event);
			}
			break;
		// RS Add End

		default:
			system_message("Didn't know what to do with event: " + event);
	}
}

//Send information retrieved from storage
function send_client_data() {
	let client_data = {
		ip: get_storage("ip"),
		cid: get_storage("cid"),
		ckey: get_storage("ckey")
	};
	push_Topic("ident&param[clientdata]="+JSON.stringify(client_data));
}

// The abstract methods.
function set_storage(key, value){
	if(!storage_system) return;
	storage_system.setItem(vchat_opts.cookiePrefix+key,value);
}

function get_storage(key, default_value){
	if(!storage_system) return default_value;
	let value = storage_system.getItem(vchat_opts.cookiePrefix+key);

	//localstorage only stores strings.
	if(value === "null" || value === null) {
		value = default_value;
	//Coerce bools back into their native forms
	} else if(value === "true") {
		value = true;
	} else if(value === "false") {
		value = false;
	//Coerce numbers back into numerical form
	} else if(!isNaN(value)) {
		value = +value;
	}
	return value;
}

function storageAvailable(type) {
	var storage;
	try {
		storage = window[type];
		var x = '__storage_test__';
		storage.setItem(x, x);
		storage.getItem(x);
		storage.removeItem(x);
		return true;
	}
	catch(e) {
		return e instanceof DOMException && (
			// everything except Firefox
			e.code === 22 ||
			// Firefox
			e.code === 1014 ||
			// test name field too, because code might not be present
			// everything except Firefox
			e.name === 'QuotaExceededError' ||
			// Firefox
			e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
			// acknowledge QuotaExceededError only if there's something already stored
			(storage && storage.length !== 0);
	}
}

function downloadBlob(blob, fileName) {
	if (
		(navigator.userAgent.indexOf("Trident") >= 0)
		&& navigator.msSaveOrOpenBlob
	) {
		// For old IE/Trident browsers
		navigator.msSaveOrOpenBlob(blob, fileName);
	} else {
		// For modern browsers
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = fileName; // RS Edit: Cleanup (Lira, September 2025)
		// Append to document to work in Firefox
		document.body.appendChild(a); // RS Edit: Cleanup (Lira, September 2025)
		a.click(); // RS Edit: Cleanup (Lira, September 2025)
		// Clean up
		setTimeout(function() {
		document.body.removeChild(a);
		URL.revokeObjectURL(url);
		}, 0);
	}
}

//RS Add: Save chatlog (Lira, September 2025)
function requestChatlogSave(fileName, categories, roundId) {
	try {
		const payload = {
			filename: fileName,
			categories: Array.isArray(categories) ? categories : [],
			round_id: typeof roundId === 'string' ? roundId : ''
		};
		push_Topic("save_chatlog&param[data]=" + encodeURIComponent(JSON.stringify(payload)));
		return true;
	} catch (err) {
		console.error(err);
		return false;
	}
}
