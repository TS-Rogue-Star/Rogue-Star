// ///////////////////////////////////////////////////////////////////////////////
// Created by Lira for Rogue Star March 2026 for browser-based instrument audio //
// ///////////////////////////////////////////////////////////////////////////////

(function () {
	var instrumentAudio = {
		scheduleAheadSeconds: 1.5,
		scheduleIntervalMs: 200,
		startLeadSeconds: 0.12,
		startBatchWindowMs: 60,
		minimumLaunchLeadSeconds: 0.02,
		sampleRequestBatchSize: 24,
		maxConcurrentSampleLoads: 2,
		sampleRetryBaseDelayMs: 150,
		sampleRetryMaxDelayMs: 1000,
		legacySoundHeightBias: 1,
		defaultSoundRolloff: 0.5,
		defaultSoundMaxDistance: 10000,
		generalMidiProgramNames: [
			'Acoustic Grand Piano', 'Bright Acoustic Piano', 'Electric Grand Piano', 'Honky-tonk Piano',
			'Electric Piano 1', 'Electric Piano 2', 'Harpsichord', 'Clavi',
			'Celesta', 'Glockenspiel', 'Music Box', 'Vibraphone',
			'Marimba', 'Xylophone', 'Tubular Bells', 'Dulcimer',
			'Drawbar Organ', 'Percussive Organ', 'Rock Organ', 'Church Organ',
			'Reed Organ', 'Accordion', 'Harmonica', 'Tango Accordion',
			'Acoustic Guitar (nylon)', 'Acoustic Guitar (steel)', 'Electric Guitar (jazz)', 'Electric Guitar (clean)',
			'Electric Guitar (muted)', 'Overdriven Guitar', 'Distortion Guitar', 'Guitar Harmonics',
			'Acoustic Bass', 'Electric Bass (finger)', 'Electric Bass (pick)', 'Fretless Bass',
			'Slap Bass 1', 'Slap Bass 2', 'Synth Bass 1', 'Synth Bass 2',
			'Violin', 'Viola', 'Cello', 'Contrabass',
			'Tremolo Strings', 'Pizzicato Strings', 'Orchestral Harp', 'Timpani',
			'String Ensemble 1', 'String Ensemble 2', 'Synth Strings 1', 'Synth Strings 2',
			'Choir Aahs', 'Voice Oohs', 'Synth Voice', 'Orchestra Hit',
			'Trumpet', 'Trombone', 'Tuba', 'Muted Trumpet',
			'French Horn', 'Brass Section', 'Synth Brass 1', 'Synth Brass 2',
			'Soprano Sax', 'Alto Sax', 'Tenor Sax', 'Baritone Sax',
			'Oboe', 'English Horn', 'Bassoon', 'Clarinet',
			'Piccolo', 'Flute', 'Recorder', 'Pan Flute',
			'Blown Bottle', 'Shakuhachi', 'Whistle', 'Ocarina',
			'Lead 1 (square)', 'Lead 2 (sawtooth)', 'Lead 3 (calliope)', 'Lead 4 (chiff)',
			'Lead 5 (charang)', 'Lead 6 (voice)', 'Lead 7 (fifths)', 'Lead 8 (bass + lead)',
			'Pad 1 (new age)', 'Pad 2 (warm)', 'Pad 3 (polysynth)', 'Pad 4 (choir)',
			'Pad 5 (bowed)', 'Pad 6 (metallic)', 'Pad 7 (halo)', 'Pad 8 (sweep)',
			'FX 1 (rain)', 'FX 2 (soundtrack)', 'FX 3 (crystal)', 'FX 4 (atmosphere)',
			'FX 5 (brightness)', 'FX 6 (goblins)', 'FX 7 (echoes)', 'FX 8 (sci-fi)',
			'Sitar', 'Banjo', 'Shamisen', 'Koto',
			'Kalimba', 'Bagpipe', 'Fiddle', 'Shanai',
			'Tinkle Bell', 'Agogo', 'Steel Drums', 'Woodblock',
			'Taiko Drum', 'Melodic Tom', 'Synth Drum', 'Reverse Cymbal',
			'Guitar Fret Noise', 'Breath Noise', 'Seashore', 'Bird Tweet',
			'Telephone Ring', 'Helicopter', 'Applause', 'Gunshot'
		],
		context: null,
		ready: false,
		capable: false,
		songs: {},
		binaryCache: {},
		binaryWaiters: {},
		sampleCache: {},
		sampleWaiters: {},
		sampleLoadQueue: [],
		activeSampleLoads: 0,
		queuedSamples: {},
		activeSampleRequests: {},
		startLaunchBatch: null,

		init: function () {
			this.capable = this.detectSupport();
			this.ready = true;
			this.reportStatus();
		},

		detectSupport: function () {
			var AudioContextCtor = window.AudioContext || window.webkitAudioContext;
			var audio = document.createElement('audio');
			var canPlayOgg = !!audio.canPlayType && audio.canPlayType('audio/ogg; codecs="vorbis"') !== '';
			return !!AudioContextCtor
				&& !!window.XMLHttpRequest
				&& !!window.JSON
				&& !!window.ArrayBuffer
				&& !!window.DataView
				&& !!window.Uint8Array
				&& canPlayOgg;
		},

		reportStatus: function () {
			var href = '?instrument_audio_ready=1&instrument_audio_capable=' + (this.capable ? '1' : '0');
			window.location.href = href;
		},

		ensureContext: function () {
			var AudioContextCtor;
			if (!this.capable) {
				return null;
			}
			if (!this.context) {
				AudioContextCtor = window.AudioContext || window.webkitAudioContext;
				if (!AudioContextCtor) {
					this.capable = false;
					this.reportStatus();
					return null;
				}
				this.context = new AudioContextCtor();
			}
			if (this.context.state === 'suspended' && this.context.resume) {
				try {
					this.context.resume();
				} catch (error) {
					void error;
				}
			}
			return this.context;
		},

		getSong: function (songId) {
			if (!this.songs[songId]) {
				this.songs[songId] = {
					id: songId,
					engine: 'timeline',
					events: [],
					payload: null,
					timelineKey: null,
					loaded: false,
					loadFailed: false,
					pendingStart: null,
					currentGain: 0,
					activeNodes: [],
					scheduleTimer: null,
					nextEventIndex: 0,
					timelineAnchor: 0,
					masterGain: null,
					positionX: 0,
					positionZ: 0,
					spatialNode: null,
					decodedDuration: 0,
					midiAlias: null,
					midiNoteMap: null,
					midiBuffer: null,
					midiInfo: null,
					primeSerial: 0,
					stopAfterActive: false,
					dropWhenStopped: false,
				};
			}
			return this.songs[songId];
		},

		isCurrentPrime: function (song, primeSerial) {
			return !!song && this.songs[song.id] === song && song.primeSerial === primeSerial;
		},

		prime: function (songId, encodedPayload, timelineKey) {
			var song = this.getSong(songId);
			var payload;
			var primeSerial;
			if (!this.capable) {
				return;
			}
			song.primeSerial += 1;
			primeSerial = song.primeSerial;
			try {
				payload = JSON.parse(decodeURIComponent(encodedPayload));
			} catch (error) {
				if (this.isCurrentPrime(song, primeSerial)) {
					song.events = [];
					song.payload = null;
					song.engine = 'timeline';
					song.loaded = false;
					song.loadFailed = true;
				}
				return;
			}
			song.engine = payload.engine || 'timeline';
			song.payload = payload || {};
			song.events = payload.events || [];
			song.timelineKey = timelineKey || null;
			song.loaded = false;
			song.loadFailed = false;
			song.decodedDuration = typeof payload.duration_seconds === 'number' ? payload.duration_seconds : 0;
			song.midiAlias = null;
			song.midiNoteMap = null;
			song.midiBuffer = null;
			song.midiInfo = null;
			song.stopAfterActive = false;
			song.dropWhenStopped = false;
			if (song.engine === 'midi_timeline') {
				this.primeMidiTimelineSong(song, primeSerial);
				return;
			}
			this.primeTimelineSong(song, primeSerial);
		},

		loadSample: function (alias, callback, attempt) {
			var waiters;
			if (!this.ensureContext()) {
				callback(false);
				return;
			}
			if (this.sampleCache[alias]) {
				callback(true);
				return;
			}
			waiters = this.sampleWaiters[alias];
			if (waiters) {
				waiters.push(callback);
				if (!this.queuedSamples[alias] && !this.activeSampleRequests[alias]) {
					this.enqueueSampleLoad(alias, attempt);
				}
				return;
			}
			this.sampleWaiters[alias] = [callback];
			this.enqueueSampleLoad(alias, attempt);
		},

		enqueueSampleLoad: function (alias, attempt) {
			if (this.sampleCache[alias] || this.queuedSamples[alias] || this.activeSampleRequests[alias]) {
				return;
			}
			this.queuedSamples[alias] = attempt || 0;
			this.sampleLoadQueue.push(alias);
			this.pumpSampleLoadQueue();
		},

		pumpSampleLoadQueue: function () {
			var alias;
			var attempt;
			while (this.activeSampleLoads < this.maxConcurrentSampleLoads && this.sampleLoadQueue.length) {
				alias = this.sampleLoadQueue.shift();
				attempt = this.queuedSamples[alias] || 0;
				delete this.queuedSamples[alias];
				this.beginSampleLoad(alias, attempt);
			}
		},

		beginSampleLoad: function (alias, attempt) {
			var self = this;
			var xhr;
			var context = this.ensureContext();
			if (!context) {
				this.finishSampleLoad(alias, false);
				return;
			}
			this.activeSampleLoads++;
			this.activeSampleRequests[alias] = true;
			xhr = new XMLHttpRequest();
			xhr.open('GET', alias, true);
			xhr.responseType = 'arraybuffer';
			xhr.onreadystatechange = function () {
				if (xhr.readyState !== 4) {
					return;
				}
				if (xhr.status !== 200 && xhr.status !== 0) {
					self.retrySample(alias, attempt);
					return;
				}
				context.decodeAudioData(xhr.response, function (buffer) {
					var callbacks = self.sampleWaiters[alias] || [];
					self.sampleCache[alias] = buffer;
					delete self.sampleWaiters[alias];
					self.finishSampleLoad(alias, true);
					for (var i = 0; i < callbacks.length; i++) {
						callbacks[i](true);
					}
				}, function () {
					self.retrySample(alias, attempt);
				});
			};
			xhr.onerror = function () {
				self.retrySample(alias, attempt);
			};
			xhr.send();
		},

		finishSampleLoad: function (alias, ok) {
			var callbacks;
			if (this.activeSampleRequests[alias]) {
				delete this.activeSampleRequests[alias];
				this.activeSampleLoads = Math.max(0, this.activeSampleLoads - 1);
			}
			if (!ok) {
				callbacks = this.sampleWaiters[alias] || [];
				delete this.sampleWaiters[alias];
				for (var i = 0; i < callbacks.length; i++) {
					callbacks[i](false);
				}
			}
			this.pumpSampleLoadQueue();
		},

		retrySample: function (alias, attempt) {
			var self = this;
			var nextAttempt = (attempt || 0) + 1;
			var retryDelay = Math.min(this.sampleRetryMaxDelayMs, this.sampleRetryBaseDelayMs * nextAttempt);
			if (this.activeSampleRequests[alias]) {
				delete this.activeSampleRequests[alias];
				this.activeSampleLoads = Math.max(0, this.activeSampleLoads - 1);
			}
			setTimeout(function () {
				var waiters = self.sampleWaiters[alias];
				if (self.sampleCache[alias]) {
					return;
				}
				if (!waiters || !waiters.length) {
					delete self.sampleWaiters[alias];
					self.pumpSampleLoadQueue();
					return;
				}
				self.enqueueSampleLoad(alias, nextAttempt);
			}, retryDelay);
		},

		primeTimelineSong: function (song, primeSerial) {
			var needed = {};
			var pending = 0;
			var alias;
			var self = this;
			for (var i = 0; i < song.events.length; i++) {
				alias = song.events[i].s;
				if (!alias || needed[alias]) {
					continue;
				}
				needed[alias] = true;
				pending++;
			}
			if (!pending) {
				if (!this.isCurrentPrime(song, primeSerial)) {
					return;
				}
				song.loaded = true;
				song.decodedDuration = this.getSongDuration(song);
				this.reportSongReady(song);
				this.maybeLaunch(song);
				return;
			}
			for (alias in needed) {
				if (!needed.hasOwnProperty(alias)) {
					continue;
				}
				this.loadSample(alias, function (ok) {
					if (!self.isCurrentPrime(song, primeSerial)) {
						return;
					}
					pending--;
					if (!ok) {
						song.loadFailed = true;
					}
					if (pending <= 0) {
						song.loaded = !song.loadFailed;
						if (song.loaded) {
							song.decodedDuration = self.getSongDuration(song);
							self.reportSongReady(song);
						}
						self.maybeLaunch(song);
					}
				});
			}
		},

		primeMidiTimelineSong: function (song, primeSerial) {
			var self = this;
			song.midiAlias = song.payload.midi_alias || null;
			song.midiNoteMap = song.payload.note_map || {};
			if (!song.midiAlias) {
				if (this.isCurrentPrime(song, primeSerial)) {
					song.loadFailed = true;
					this.maybeLaunch(song);
				}
				return;
			}
			this.loadBinary(song.midiAlias, function (ok, buffer) {
				var parsed;
				var neededAliases;
				var pendingAliases = [];
				var pending = 0;
				var i;
				if (!self.isCurrentPrime(song, primeSerial)) {
					return;
				}
				if (!ok || !buffer) {
					song.loadFailed = true;
					self.maybeLaunch(song);
					return;
				}
				song.midiBuffer = buffer;
				try {
					parsed = self.parseMidiTimeline(song.midiBuffer, song.midiNoteMap, song.payload);
				} catch (error) {
					void error;
					parsed = null;
				}
				if (!parsed) {
					song.loadFailed = true;
					self.maybeLaunch(song);
					return;
				}
				song.midiInfo = parsed;
				song.events = parsed.events || [];
				neededAliases = self.collectEventSampleAliases(song.events);
				for (i = 0; i < neededAliases.length; i++) {
					if (!self.sampleCache[neededAliases[i]]) {
						pendingAliases.push(neededAliases[i]);
					}
				}
				if (!pendingAliases.length) {
					song.decodedDuration = Math.max(
						(typeof parsed.durationSeconds === 'number' ? parsed.durationSeconds : 0),
						self.getSongDuration(song)
					);
					song.loaded = true;
					self.reportSongReady(song);
					self.maybeLaunch(song);
					return;
				}
				self.requestSongSamples(song, pendingAliases);
				pending = pendingAliases.length;
				for (i = 0; i < pendingAliases.length; i++) {
					self.loadSample(pendingAliases[i], function (sampleOk) {
						if (!self.isCurrentPrime(song, primeSerial)) {
							return;
						}
						pending--;
						if (!sampleOk) {
							song.loadFailed = true;
						}
						if (pending <= 0) {
							song.loaded = !song.loadFailed;
							if (song.loaded) {
								song.decodedDuration = Math.max(
									(typeof parsed.durationSeconds === 'number' ? parsed.durationSeconds : 0),
									self.getSongDuration(song)
								);
								self.reportSongReady(song);
							}
							self.maybeLaunch(song);
						}
					});
				}
			});
		},

		collectEventSampleAliases: function (events) {
			var seen = {};
			var aliases = [];
			var eventData;
			var alias;
			if (!events || !events.length) {
				return aliases;
			}
			for (var i = 0; i < events.length; i++) {
				eventData = events[i];
				alias = eventData && eventData.s;
				if (!alias || seen[alias]) {
					continue;
				}
				seen[alias] = true;
				aliases.push(alias);
			}
			return aliases;
		},

		requestSongSamples: function (song, aliases) {
			var self = this;
			var batch = [];
			var batchDelayMs = 0;
			if (!song || !song.id || !aliases || !aliases.length) {
				return;
			}
			for (var i = 0; i < aliases.length; i++) {
				if (!aliases[i]) {
					continue;
				}
				batch.push(aliases[i]);
				if (batch.length >= this.sampleRequestBatchSize) {
					self.queueSongSampleRequest(song.id, batch, batchDelayMs);
					batchDelayMs += 10;
					batch = [];
				}
			}
			if (batch.length) {
				self.queueSongSampleRequest(song.id, batch, batchDelayMs);
			}
		},

		queueSongSampleRequest: function (songId, aliases, delayMs) {
			var self = this;
			var queuedAliases = aliases ? aliases.slice(0) : [];
			setTimeout(function () {
				self.sendSongSampleRequest(songId, queuedAliases);
			}, delayMs || 0);
		},

		sendSongSampleRequest: function (songId, aliases) {
			var href;
			if (!songId || !aliases || !aliases.length) {
				return;
			}
			href = '?instrument_audio_request_samples=' + encodeURIComponent(songId)
				+ '&instrument_audio_aliases=' + encodeURIComponent(aliases.join(','));
			window.location.href = href;
		},

		inspectMidi: function (songId, midiAlias, midiSerial) {
			var self = this;
			if (!songId || !midiAlias) {
				return;
			}
			this.loadBinary(midiAlias, function (ok, buffer) {
				var parsed = null;
				var channels = [];
				if (ok && buffer) {
					try {
						parsed = self.parseMidiFile(buffer, true);
					} catch (error) {
						void error;
						parsed = null;
					}
				}
				if (parsed && parsed.noteEvents) {
					channels = self.describeMidiChannels(parsed.noteEvents, parsed.programEvents);
				}
				self.reportMidiChannels(songId, midiSerial, channels, !!parsed);
			});
		},

		describeMidiChannels: function (noteEvents, programEvents) {
			var channels = {};
			var summary = [];
			var sortedProgramEvents = programEvents ? programEvents.slice() : [];
			var currentPrograms = {};
			var programIndex = 0;
			var eventData;
			var programEvent;
			var channel;
			var channelData;
			var program;
			var keys;
			var i;
			if (!noteEvents || !noteEvents.length) {
				return summary;
			}
			noteEvents = noteEvents.slice();
			noteEvents.sort(function (left, right) {
				if (left.tick !== right.tick) {
					return left.tick - right.tick;
				}
				return (left.order || 0) - (right.order || 0);
			});
			sortedProgramEvents.sort(function (left, right) {
				if (left.tick !== right.tick) {
					return left.tick - right.tick;
				}
				return (left.order || 0) - (right.order || 0);
			});
			for (i = 0; i < noteEvents.length; i++) {
				eventData = noteEvents[i];
				if (!eventData || !eventData.on) {
					continue;
				}
				while (programIndex < sortedProgramEvents.length) {
					programEvent = sortedProgramEvents[programIndex];
					if (programEvent.tick > eventData.tick) {
						break;
					}
					if (programEvent.tick === eventData.tick && (programEvent.order || 0) > (eventData.order || 0)) {
						break;
					}
					currentPrograms[programEvent.channel] = programEvent.program;
					programIndex++;
				}
				channel = parseInt(eventData.channel, 10);
				if (!isFinite(channel) || channel < 0 || channel > 15) {
					continue;
				}
				channelData = channels[channel];
				if (!channelData) {
					channelData = {
						channel: channel,
						note_count: 0,
						program_counts: {},
						group_counts: {},
					};
					channels[channel] = channelData;
				}
				channelData.note_count += 1;
				if (channel === 9) {
					channelData.instrument_label = 'Percussion';
					channelData.group_counts.percussion = (channelData.group_counts.percussion || 0) + 1;
					continue;
				}
				program = currentPrograms.hasOwnProperty(channel) ? currentPrograms[channel] : 0;
				if (!isFinite(program) || program < 0 || program > 127) {
					program = 0;
				}
				channelData.program_counts[program] = (channelData.program_counts[program] || 0) + 1;
				var programGroup = this.getGeneralMidiProgramGroup(program);
				channelData.group_counts[programGroup.key] = (channelData.group_counts[programGroup.key] || 0) + 1;
			}
			keys = Object.keys(channels);
			keys.sort(function (left, right) {
				return (parseInt(left, 10) || 0) - (parseInt(right, 10) || 0);
			});
			for (i = 0; i < keys.length; i++) {
				channelData = channels[keys[i]];
				var primaryGroup = this.describeMidiChannelGroup(channelData);
				channelData.instrument_label = channelData.instrument_label || this.describeMidiChannelInstrument(channelData);
				summary.push({
					channel: channelData.channel,
					note_count: channelData.note_count,
					instrument_label: channelData.instrument_label,
					group_key: primaryGroup.key,
					group_label: primaryGroup.label,
				});
			}
			return summary;
		},

		describeMidiChannelInstrument: function (channelData) {
			var counts = channelData && channelData.program_counts ? channelData.program_counts : {};
			var programKeys = Object.keys(counts);
			var names = [];
			var i;
			if (channelData && channelData.channel === 9) {
				return 'Percussion';
			}
			programKeys.sort(function (left, right) {
				var leftCount = counts[left] || 0;
				var rightCount = counts[right] || 0;
				if (leftCount !== rightCount) {
					return rightCount - leftCount;
				}
				return (parseInt(left, 10) || 0) - (parseInt(right, 10) || 0);
			});
			for (i = 0; i < programKeys.length; i++) {
				names.push(this.getGeneralMidiProgramName(parseInt(programKeys[i], 10)));
			}
			if (!names.length) {
				return this.getGeneralMidiProgramName(0);
			}
			if (names.length <= 3) {
				return names.join(', ');
			}
			return names.slice(0, 3).join(', ') + ', +' + (names.length - 3) + ' more';
		},

		getGeneralMidiProgramName: function (program) {
			if (!isFinite(program) || program < 0 || program >= this.generalMidiProgramNames.length) {
				return 'Program ' + (parseInt(program, 10) + 1 || 1);
			}
			return this.generalMidiProgramNames[program];
		},

		getGeneralMidiProgramGroup: function (program) {
			if (!isFinite(program) || program < 0 || program > 127) {
				program = 0;
			}
			if (program <= 7) {
				return { key: 'piano', label: 'Piano' };
			}
			if (program <= 15) {
				return { key: 'percussion', label: 'Percussion' };
			}
			if (program <= 23) {
				return { key: 'organ', label: 'Organ' };
			}
			if (program <= 31) {
				return { key: 'guitar', label: 'Guitar' };
			}
			if (program <= 39) {
				return { key: 'bass', label: 'Bass' };
			}
			if (program <= 55) {
				return { key: 'strings', label: 'Strings' };
			}
			if (program <= 79) {
				return { key: 'wind', label: 'Wind' };
			}
			if (program <= 103) {
				return { key: 'synth', label: 'Synth' };
			}
			if (program <= 111) {
				return { key: 'ethnic', label: 'Ethnic' };
			}
			if (program <= 119) {
				return { key: 'percussion', label: 'Percussion' };
			}
			return { key: 'sfx', label: 'SFX' };
		},

		describeMidiChannelGroup: function (channelData) {
			var counts = channelData && channelData.group_counts ? channelData.group_counts : {};
			var groupKeys = Object.keys(counts);
			if (channelData && channelData.channel === 9) {
				return { key: 'percussion', label: 'Percussion' };
			}
			groupKeys.sort(function (left, right) {
				var leftCount = counts[left] || 0;
				var rightCount = counts[right] || 0;
				if (leftCount !== rightCount) {
					return rightCount - leftCount;
				}
				return left.localeCompare(right);
			});
			if (!groupKeys.length) {
				return this.getGeneralMidiProgramGroup(0);
			}
			return this.getGeneralMidiProgramGroupLabel(groupKeys[0]);
		},

		getGeneralMidiProgramGroupLabel: function (groupKey) {
			switch (groupKey) {
			case 'piano':
				return { key: 'piano', label: 'Piano' };
			case 'percussion':
				return { key: 'percussion', label: 'Percussion' };
			case 'organ':
				return { key: 'organ', label: 'Organ' };
			case 'guitar':
				return { key: 'guitar', label: 'Guitar' };
			case 'bass':
				return { key: 'bass', label: 'Bass' };
			case 'strings':
				return { key: 'strings', label: 'Strings' };
			case 'wind':
				return { key: 'wind', label: 'Wind' };
			case 'synth':
				return { key: 'synth', label: 'Synth' };
			case 'ethnic':
				return { key: 'ethnic', label: 'Ethnic' };
			case 'sfx':
				return { key: 'sfx', label: 'SFX' };
			default:
				return { key: 'other', label: 'Other' };
			}
		},

		loadBinary: function (alias, callback, attempt) {
			var waiters;
			if (this.binaryCache[alias]) {
				callback(true, this.binaryCache[alias]);
				return;
			}
			waiters = this.binaryWaiters[alias];
			if (waiters) {
				waiters.callbacks.push(callback);
				if (!waiters.loading && !waiters.retryTimer) {
					this.beginBinaryLoad(alias, waiters.attempt || 0);
				}
				return;
			}
			this.binaryWaiters[alias] = {
				attempt: attempt || 0,
				callbacks: [callback],
				loading: false,
				retryTimer: null,
			};
			this.beginBinaryLoad(alias, attempt || 0);
		},

		beginBinaryLoad: function (alias, attempt) {
			var xhr;
			var self = this;
			var waiters = this.binaryWaiters[alias];
			if (!waiters || waiters.loading) {
				return;
			}
			waiters.loading = true;
			waiters.attempt = attempt || 0;
			if (waiters.retryTimer) {
				clearTimeout(waiters.retryTimer);
				waiters.retryTimer = null;
			}
			xhr = new XMLHttpRequest();
			xhr.open('GET', alias, true);
			xhr.responseType = 'arraybuffer';
			xhr.onreadystatechange = function () {
				var callbacks;
				var currentWaiters = self.binaryWaiters[alias];
				if (xhr.readyState !== 4 || !currentWaiters) {
					return;
				}
				if ((xhr.status !== 200 && xhr.status !== 0) || !xhr.response) {
					currentWaiters.loading = false;
					self.retryBinary(alias, currentWaiters.attempt);
					return;
				}
				callbacks = currentWaiters.callbacks || [];
				delete self.binaryWaiters[alias];
				self.binaryCache[alias] = xhr.response;
				for (var i = 0; i < callbacks.length; i++) {
					callbacks[i](true, xhr.response);
				}
			};
			xhr.onerror = function () {
				var currentWaiters = self.binaryWaiters[alias];
				if (!currentWaiters) {
					return;
				}
				currentWaiters.loading = false;
				self.retryBinary(alias, currentWaiters.attempt);
			};
			xhr.send();
		},

		retryBinary: function (alias, attempt) {
			var self = this;
			var nextAttempt = (attempt || 0) + 1;
			var retryDelay;
			var waiters = this.binaryWaiters[alias];
			if (!waiters || waiters.retryTimer) {
				return;
			}
			waiters.attempt = nextAttempt;
			retryDelay = Math.min(this.sampleRetryMaxDelayMs, this.sampleRetryBaseDelayMs * nextAttempt);
			waiters.retryTimer = setTimeout(function () {
				var currentWaiters = self.binaryWaiters[alias];
				if (self.binaryCache[alias]) {
					delete self.binaryWaiters[alias];
					return;
				}
				if (!currentWaiters || !currentWaiters.callbacks || !currentWaiters.callbacks.length) {
					delete self.binaryWaiters[alias];
					return;
				}
				currentWaiters.retryTimer = null;
				self.beginBinaryLoad(alias, currentWaiters.attempt);
			}, retryDelay);
		},

		start: function (songId, elapsedSeconds, gain, positionX, positionZ) {
			var context = this.ensureContext();
			var song = this.getSong(songId);
			var parsedPositionX;
			var parsedPositionZ;
			if (!this.capable) {
				return;
			}
			parsedPositionX = parseFloat(positionX);
			parsedPositionZ = parseFloat(positionZ);
			song.pendingStart = {
				elapsed: parseFloat(elapsedSeconds) || 0,
				gain: parseFloat(gain) || 0,
				positionX: isNaN(parsedPositionX) ? song.positionX : parsedPositionX,
				positionZ: isNaN(parsedPositionZ) ? song.positionZ : parsedPositionZ,
				launchTime: this.reserveLaunchTime(context),
			};
			song.currentGain = song.pendingStart.gain;
			song.positionX = song.pendingStart.positionX;
			song.positionZ = song.pendingStart.positionZ;
			this.maybeLaunch(song);
		},

		maybeLaunch: function (song) {
			if (!song || !song.pendingStart || !song.loaded || song.loadFailed) {
				return;
			}
			this.launchSong(song);
		},

		getNowMs: function () {
			if (window.performance && typeof window.performance.now === 'function') {
				return window.performance.now();
			}
			return new Date().getTime();
		},

		reserveLaunchTime: function (context) {
			var nowMs;
			var batch = this.startLaunchBatch;
			if (!context) {
				return 0;
			}
			nowMs = this.getNowMs();
			if (!batch || nowMs > batch.expiresAtMs || batch.launchTime <= context.currentTime) {
				batch = {
					launchTime: context.currentTime + this.startLeadSeconds,
					expiresAtMs: nowMs + this.startBatchWindowMs,
				};
				this.startLaunchBatch = batch;
			}
			return batch.launchTime;
		},

		createSpatialNode: function (context) {
			var node;
			if (!context) {
				return null;
			}
			if (context.createStereoPanner) {
				return context.createStereoPanner();
			}
			if (context.createPanner) {
				node = context.createPanner();
				node.panningModel = 'HRTF';
				node.distanceModel = 'inverse';
				node.refDistance = 1;
				node.rolloffFactor = this.defaultSoundRolloff;
				node.maxDistance = this.defaultSoundMaxDistance;
				return node;
			}
			return null;
		},

		computeStereoPan: function (positionX, positionZ) {
			var distance = Math.sqrt(
				(positionX * positionX)
				+ (positionZ * positionZ)
				+ (this.legacySoundHeightBias * this.legacySoundHeightBias)
			);
			if (!distance) {
				return 0;
			}
			return Math.max(-1, Math.min(1, positionX / distance));
		},

		computeDistanceAttenuation: function (positionX, positionZ) {
			var distance = Math.sqrt(
				(positionX * positionX)
				+ (positionZ * positionZ)
				+ (this.legacySoundHeightBias * this.legacySoundHeightBias)
			);
			if (distance <= 1) {
				return 1;
			}
			return 1 / (1 + (this.defaultSoundRolloff * (distance - 1)));
		},

		computeOutputGain: function (song, gain) {
			if (!song || !isFinite(gain)) {
				return 0;
			}
			if (!song.spatialNode || (song.spatialNode.pan && song.spatialNode.pan.setValueAtTime)) {
				return gain * this.computeDistanceAttenuation(song.positionX, song.positionZ);
			}
			return gain;
		},

		updateSongPosition: function (song, positionX, positionZ) {
			var now;
			var panValue;
			if (!song) {
				return;
			}
			song.positionX = isFinite(positionX) ? positionX : 0;
			song.positionZ = isFinite(positionZ) ? positionZ : 0;
			if (!song.spatialNode) {
				return;
			}
			now = this.context ? this.context.currentTime : 0;
			if (song.spatialNode.pan && song.spatialNode.pan.setValueAtTime) {
				panValue = this.computeStereoPan(song.positionX, song.positionZ);
				song.spatialNode.pan.setValueAtTime(panValue, now);
				return;
			}
			if (song.spatialNode.positionX && song.spatialNode.positionX.setValueAtTime
				&& song.spatialNode.positionZ && song.spatialNode.positionZ.setValueAtTime) {
				song.spatialNode.positionX.setValueAtTime(song.positionX, now);
				song.spatialNode.positionY.setValueAtTime(this.legacySoundHeightBias, now);
				song.spatialNode.positionZ.setValueAtTime(-song.positionZ, now);
				return;
			}
			if (typeof song.spatialNode.setPosition === 'function') {
				song.spatialNode.setPosition(song.positionX, this.legacySoundHeightBias, -song.positionZ);
			}
		},

		disconnectSpatialNode: function (song) {
			if (!song || !song.spatialNode) {
				return;
			}
			try {
				song.spatialNode.disconnect();
			} catch (disconnectError) {
				void disconnectError;
			}
			song.spatialNode = null;
		},

		launchSong: function (song) {
			var context = this.ensureContext();
			var request = song.pendingStart;
			var launchTime;
			if (!context || !request) {
				return;
			}
			this.stop(song.id);
			song.pendingStart = null;
			launchTime = typeof request.launchTime === 'number' ? request.launchTime : 0;
			if (launchTime < (context.currentTime + this.minimumLaunchLeadSeconds)) {
				launchTime = context.currentTime + this.minimumLaunchLeadSeconds;
			}
			song.timelineAnchor = launchTime - request.elapsed;
			song.nextEventIndex = 0;
			song.masterGain = context.createGain();
			song.stopAfterActive = false;
			song.dropWhenStopped = false;
			song.positionX = request.positionX;
			song.positionZ = request.positionZ;
			song.spatialNode = this.createSpatialNode(context);
			song.masterGain.gain.value = this.computeOutputGain(song, request.gain);
			if (song.spatialNode) {
				song.masterGain.connect(song.spatialNode);
				song.spatialNode.connect(context.destination);
				this.updateSongPosition(song, song.positionX, song.positionZ);
			} else {
				song.masterGain.connect(context.destination);
			}
			song.currentGain = request.gain;
			song.activeNodes = [];
			this.scheduleSong(song);
		},

		scheduleSong: function (song) {
			var self = this;
			if (!song || !song.masterGain) {
				return;
			}
			this.scheduleWindow(song);
			if (song.scheduleTimer) {
				clearInterval(song.scheduleTimer);
			}
			song.scheduleTimer = setInterval(function () {
				self.scheduleWindow(song);
			}, this.scheduleIntervalMs);
		},

		scheduleWindow: function (song) {
			var context = this.ensureContext();
			var currentElapsed;
			var windowEnd;
			var eventData;
			if (!context || !song || !song.masterGain) {
				return;
			}
			currentElapsed = Math.max(0, context.currentTime - song.timelineAnchor);
			windowEnd = currentElapsed + this.scheduleAheadSeconds;
			while (song.nextEventIndex < song.events.length) {
				eventData = song.events[song.nextEventIndex];
				if (!eventData || typeof eventData.t !== 'number') {
					song.nextEventIndex++;
					continue;
				}
				if (eventData.t > windowEnd) {
					break;
				}
				song.nextEventIndex++;
				this.scheduleEvent(song, eventData, currentElapsed);
			}
			if (song.nextEventIndex >= song.events.length && song.activeNodes.length === 0 && !song.pendingStart) {
				if (song.scheduleTimer) {
					clearInterval(song.scheduleTimer);
					song.scheduleTimer = null;
				}
			}
		},

		scheduleEvent: function (song, eventData, currentElapsed) {
			var context = this.ensureContext();
			var buffer;
			var naturalStop;
			var startAt;
			var offset;
			var endAt;
			var source;
			var gainNode;
			var songGain;
			var nodeRecord;
			var self = this;
			if (!context || !song || !song.masterGain || !eventData) {
				return;
			}
			buffer = this.sampleCache[eventData.s];
			if (!buffer) {
				return;
			}
			naturalStop = this.getEventNaturalStop(eventData, buffer);
			if (currentElapsed >= naturalStop) {
				return;
			}
			startAt = song.timelineAnchor + eventData.t;
			offset = Math.max(0, currentElapsed - eventData.t) * (eventData.r || 1);
			if (offset >= buffer.duration) {
				return;
			}
			endAt = song.timelineAnchor + naturalStop;
			source = context.createBufferSource();
			source.buffer = buffer;
			source.playbackRate.value = eventData.r || 1;
			gainNode = context.createGain();
			songGain = gainNode.gain;
			source.connect(gainNode);
			gainNode.connect(song.masterGain);
			this.scheduleEnvelope(songGain, song.timelineAnchor + currentElapsed, currentElapsed, eventData, naturalStop);
			nodeRecord = {
				source: source,
				gainNode: gainNode,
				startAt: Math.max(context.currentTime, startAt),
			};
			source.onended = function () {
				self.cleanupNode(song, nodeRecord);
			};
			source.start(Math.max(context.currentTime, startAt), offset);
			if (isFinite(endAt)) {
				source.stop(endAt + 0.01);
			}
			song.activeNodes.push(nodeRecord);
		},

		cleanupNode: function (song, nodeRecord) {
			var index;
			if (!song || !nodeRecord || nodeRecord.cleaned) {
				return;
			}
			nodeRecord.cleaned = true;
			index = song.activeNodes.indexOf(nodeRecord);
			if (index !== -1) {
				song.activeNodes.splice(index, 1);
			}
			try {
				nodeRecord.gainNode.disconnect();
			} catch (disconnectError) {
				void disconnectError;
			}
			if (song.nextEventIndex >= song.events.length && song.activeNodes.length === 0 && song.scheduleTimer) {
				clearInterval(song.scheduleTimer);
				song.scheduleTimer = null;
			}
			if (song.stopAfterActive && song.activeNodes.length === 0) {
				this.finishGracefulStop(song);
			}
		},

		finishGracefulStop: function (song) {
			if (!song || song.activeNodes.length) {
				return;
			}
			song.stopAfterActive = false;
			if (song.masterGain) {
				try {
					song.masterGain.disconnect();
				} catch (disconnectError) {
					void disconnectError;
				}
			}
			this.disconnectSpatialNode(song);
			song.masterGain = null;
			if (song.dropWhenStopped) {
				delete this.songs[song.id];
			}
		},

		reportSongReady: function (song) {
			var href;
			if (!song || !song.id || !song.timelineKey) {
				return;
			}
			href = '?instrument_audio_song_ready=' + encodeURIComponent(song.id)
				+ '&instrument_audio_timeline_key=' + encodeURIComponent(song.timelineKey);
			if (song.decodedDuration && isFinite(song.decodedDuration)) {
				href += '&instrument_audio_duration=' + encodeURIComponent(song.decodedDuration);
			}
			window.location.href = href;
		},

		reportMidiChannels: function (songId, midiSerial, channels, successful) {
			var href;
			if (!songId) {
				return;
			}
			href = '?instrument_audio_midi_channels=' + encodeURIComponent(songId)
				+ '&instrument_audio_midi_serial=' + encodeURIComponent(midiSerial || 0)
				+ '&instrument_audio_midi_ok=' + encodeURIComponent(successful ? 1 : 0);
			if (channels) {
				href += '&instrument_audio_midi_data=' + encodeURIComponent(JSON.stringify(channels));
			}
			window.location.href = href;
		},

		getSongDuration: function (song) {
			var duration = 0;
			var eventData;
			var buffer;
			var stopAt;
			if (!song || !song.events) {
				return 0;
			}
			for (var i = 0; i < song.events.length; i++) {
				eventData = song.events[i];
				if (!eventData || typeof eventData.t !== 'number') {
					continue;
				}
				buffer = this.sampleCache[eventData.s];
				if (!buffer) {
					continue;
				}
				stopAt = this.getEventNaturalStop(eventData, buffer);
				if (stopAt > duration) {
					duration = stopAt;
				}
			}
			return duration;
		},

		getEventNaturalStop: function (eventData, buffer) {
			if (typeof eventData.e === 'number' && eventData.e >= 0) {
				return eventData.e;
			}
			return eventData.t + (buffer.duration / (eventData.r || 1));
		},

		scheduleEnvelope: function (gain, launchTime, elapsed, eventData, stopAt) {
			var startReference = Math.max(elapsed, eventData.t);
			var noteStartAt = launchTime + Math.max(0, eventData.t - elapsed);
			var decayStart = eventData.d;
			var baseGain = typeof eventData.v === 'number' ? Math.max(eventData.v, 0) : 1;
			var endGain = (typeof eventData.g === 'number' ? eventData.g : 1) * baseGain;
			var epsilon = 0.0001;
			var mode = eventData.m || 0;
			var currentGain;
			gain.cancelScheduledValues(launchTime);
			if (!mode || typeof decayStart !== 'number' || decayStart >= stopAt) {
				gain.setValueAtTime(baseGain, noteStartAt);
				return;
			}
			if (elapsed < decayStart) {
				gain.setValueAtTime(baseGain, noteStartAt);
				if (mode === 1) {
					gain.setValueAtTime(baseGain, noteStartAt + (decayStart - startReference));
					gain.linearRampToValueAtTime(endGain, launchTime + (stopAt - elapsed));
				} else {
					gain.setValueAtTime(Math.max(baseGain, epsilon), noteStartAt + (decayStart - startReference));
					gain.exponentialRampToValueAtTime(Math.max(endGain, epsilon), launchTime + (stopAt - elapsed));
				}
				return;
			}
			currentGain = this.getEnvelopeGain(eventData, elapsed, stopAt, baseGain);
			if (mode === 1) {
				gain.setValueAtTime(currentGain, noteStartAt);
				gain.linearRampToValueAtTime(endGain, launchTime + (stopAt - elapsed));
			} else {
				gain.setValueAtTime(Math.max(currentGain, epsilon), noteStartAt);
				gain.exponentialRampToValueAtTime(Math.max(endGain, epsilon), launchTime + (stopAt - elapsed));
			}
		},

		getEnvelopeGain: function (eventData, elapsed, stopAt, baseGain) {
			var decayStart = eventData.d;
			var startGain = typeof baseGain === 'number' ? Math.max(baseGain, 0) : 1;
			var endGain = (typeof eventData.g === 'number' ? eventData.g : 1) * startGain;
			var progress;
			if (elapsed <= decayStart || stopAt <= decayStart) {
				return startGain;
			}
			progress = (elapsed - decayStart) / (stopAt - decayStart);
			if (progress <= 0) {
				return startGain;
			}
			if (progress >= 1) {
				return endGain;
			}
			if ((eventData.m || 0) === 1) {
				return startGain - ((startGain - endGain) * progress);
			}
			if (startGain <= 0) {
				return 0;
			}
			if (endGain <= 0) {
				endGain = 0.0001;
			}
			return Math.exp(Math.log(endGain / Math.max(startGain, 0.0001)) * progress) * startGain;
		},

		parseMidiTimeline: function (buffer, noteMap, payload) {
			var midiData = this.parseMidiFile(buffer, true);
			if (!midiData) {
				return null;
			}
			midiData.events = this.buildMidiTimelineEvents(midiData, noteMap || {}, payload || {});
			return midiData;
		},

		parseMidiFile: function (buffer, includeNotes) {
			var view;
			var offset = 0;
			var headerLength;
			var trackCount;
			var division;
			var tempoEvents = [{ tick: 0, mpqn: 500000 }];
			var noteEvents = includeNotes ? [] : null;
			var programEvents = includeNotes ? [] : null;
			var totalTicks = 0;
			var trackIndex;
			var trackLength;
			var trackEnd;
			var tick;
			var runningStatus;
			var delta;
			var status;
			var metaType;
			var length;
			var highNibble;
			var channel;
			var data1;
			var data2;
			var sequence = 0;
			var midiInfo;
			if (!buffer || buffer.byteLength < 14) {
				return null;
			}
			view = new DataView(buffer);
			if (this.readAscii(view, 0, 4) !== 'MThd') {
				return null;
			}
			headerLength = view.getUint32(4, false);
			if (headerLength < 6 || (8 + headerLength) > view.byteLength) {
				return null;
			}
			trackCount = view.getUint16(10, false);
			division = view.getUint16(12, false);
			if ((division & 0x8000) !== 0) {
				return null;
			}
			offset = 8 + headerLength;
			for (trackIndex = 0; trackIndex < trackCount; trackIndex++) {
				if ((offset + 8) > view.byteLength || this.readAscii(view, offset, 4) !== 'MTrk') {
					return null;
				}
				trackLength = view.getUint32(offset + 4, false);
				offset += 8;
				trackEnd = offset + trackLength;
				if (trackEnd > view.byteLength) {
					return null;
				}
				tick = 0;
				runningStatus = 0;
				while (offset < trackEnd) {
					delta = this.readVarLen(view, offset);
					offset = delta.offset;
					tick += delta.value;
					if (tick > totalTicks) {
						totalTicks = tick;
					}
					if (offset >= trackEnd) {
						break;
					}
					status = view.getUint8(offset);
					if (status < 0x80) {
						if (!runningStatus) {
							return null;
						}
						status = runningStatus;
					} else {
						offset++;
						if (status < 0xF0) {
							runningStatus = status;
						}
					}
					if (status === 0xFF) {
						if (offset >= trackEnd) {
							return null;
						}
						metaType = view.getUint8(offset);
						offset++;
						delta = this.readVarLen(view, offset);
						offset = delta.offset;
						length = delta.value;
						if ((offset + length) > trackEnd) {
							return null;
						}
						if (metaType === 0x51 && length === 3) {
							tempoEvents.push({
								tick: tick,
								mpqn: (view.getUint8(offset) << 16) | (view.getUint8(offset + 1) << 8) | view.getUint8(offset + 2),
							});
						}
						offset += length;
						continue;
					}
					if (status === 0xF0 || status === 0xF7) {
						delta = this.readVarLen(view, offset);
						offset = delta.offset + delta.value;
						if (offset > trackEnd) {
							return null;
						}
						continue;
					}
					highNibble = status & 0xF0;
					channel = status & 0x0F;
					if (highNibble === 0xC0) {
						if (offset >= trackEnd) {
							return null;
						}
						data1 = view.getUint8(offset);
						offset += 1;
						if (includeNotes) {
							programEvents.push({
								tick: tick,
								order: sequence++,
								channel: channel,
								program: data1,
							});
						}
						continue;
					}
					if (highNibble === 0xD0) {
						if (offset >= trackEnd) {
							return null;
						}
						offset += 1;
						continue;
					}
					if ((offset + 1) >= trackEnd) {
						return null;
					}
					data1 = view.getUint8(offset);
					data2 = view.getUint8(offset + 1);
					offset += 2;
					if (!includeNotes) {
						continue;
					}
					if (highNibble === 0x80 || highNibble === 0x90) {
						noteEvents.push({
							tick: tick,
							order: sequence++,
							channel: channel,
							key: data1,
							velocity: data2,
							on: (highNibble === 0x90 && data2 > 0),
						});
					}
				}
				offset = trackEnd;
			}
			midiInfo = this.buildTempoMap(division, tempoEvents, totalTicks);
			if (!midiInfo) {
				return null;
			}
			if (includeNotes) {
				midiInfo.noteEvents = noteEvents;
				midiInfo.programEvents = programEvents;
			}
			return midiInfo;
		},

		buildMidiTimelineEvents: function (midiInfo, noteMap, payload) {
			var timelineEvents = [];
			var rawEvents = (midiInfo && midiInfo.noteEvents) ? midiInfo.noteEvents.slice() : [];
			var activeNotes = {};
			var enabledChannels = this.getEnabledMidiChannels(payload);
			var rawEvent;
			var queueKey;
			var queue;
			var activeEvent;
			var timelineEvent;
			var i;
			rawEvents.sort(function (a, b) {
				if (a.tick !== b.tick) {
					return a.tick - b.tick;
				}
				return (a.order || 0) - (b.order || 0);
			});
			for (i = 0; i < rawEvents.length; i++) {
				rawEvent = rawEvents[i];
				if (enabledChannels && !enabledChannels[rawEvent.channel]) {
					continue;
				}
				queueKey = rawEvent.channel + ':' + rawEvent.key;
				queue = activeNotes[queueKey];
				if (!queue) {
					queue = [];
					activeNotes[queueKey] = queue;
				}
				if (rawEvent.on) {
					queue.push({
						tick: rawEvent.tick,
						mapping: noteMap[rawEvent.key] || null,
					});
					continue;
				}
				if (!queue.length) {
					continue;
				}
				activeEvent = queue.shift();
				timelineEvent = this.createMidiTimelineEvents(midiInfo, activeEvent.mapping, activeEvent.tick, rawEvent.tick, payload);
				if (timelineEvent.length) {
					timelineEvents = timelineEvents.concat(timelineEvent);
				}
				if (!queue.length) {
					delete activeNotes[queueKey];
				}
			}
			for (queueKey in activeNotes) {
				if (!activeNotes.hasOwnProperty(queueKey)) {
					continue;
				}
				queue = activeNotes[queueKey];
				while (queue.length) {
					activeEvent = queue.shift();
					timelineEvent = this.createMidiTimelineEvents(midiInfo, activeEvent.mapping, activeEvent.tick, midiInfo.totalTicks, payload);
					if (timelineEvent.length) {
						timelineEvents = timelineEvents.concat(timelineEvent);
					}
				}
			}
			timelineEvents.sort(function (a, b) {
				if (a.t !== b.t) {
					return a.t - b.t;
				}
				return (a.e || 0) - (b.e || 0);
			});
			return timelineEvents;
		},

		getEnabledMidiChannels: function (payload) {
			var enabled = {};
			var raw = payload && payload.enabled_channels;
			var channel;
			var i;
			var hasEntries = false;
			if (!raw || !raw.length) {
				return null;
			}
			for (i = 0; i < raw.length; i++) {
				channel = parseInt(raw[i], 10);
				if (!isFinite(channel) || channel < 0 || channel > 15) {
					continue;
				}
				enabled[channel] = true;
				hasEntries = true;
			}
			return hasEntries ? enabled : null;
		},

		normalizeMidiMappings: function (mapping) {
			var mappings = [];
			var keys;
			var i;
			if (!mapping) {
				return mappings;
			}
			if (Array.isArray(mapping)) {
				return mapping;
			}
			if (mapping.s) {
				mappings.push(mapping);
				return mappings;
			}
			keys = Object.keys(mapping);
			keys.sort(function (left, right) {
				return (parseInt(left, 10) || 0) - (parseInt(right, 10) || 0);
			});
			for (i = 0; i < keys.length; i++) {
				if (mapping[keys[i]]) {
					mappings.push(mapping[keys[i]]);
				}
			}
			return mappings;
		},

		createMidiTimelineEvents: function (midiInfo, mapping, startTick, endTick, payload) {
			var mappings = this.normalizeMidiMappings(mapping);
			var events = [];
			var timelineEvent;
			for (var i = 0; i < mappings.length; i++) {
				timelineEvent = this.createMidiTimelineEvent(midiInfo, mappings[i], startTick, endTick, payload);
				if (timelineEvent) {
					events.push(timelineEvent);
				}
			}
			return events;
		},

		createMidiTimelineEvent: function (midiInfo, mapping, startTick, endTick, payload) {
			var startSeconds;
			var decaySeconds;
			var startOffsetSeconds;
			var eventData;
			if (!mapping || !mapping.s || !midiInfo) {
				return null;
			}
			startTick = Math.max(0, startTick || 0);
			endTick = Math.max(startTick, endTick || startTick);
			startOffsetSeconds = parseFloat(payload.start_offset_seconds);
			if (!isFinite(startOffsetSeconds) || startOffsetSeconds < 0) {
				startOffsetSeconds = 0;
			}
			startSeconds = this.secondsFromTicks(midiInfo, startTick) + startOffsetSeconds;
			decaySeconds = this.secondsFromTicks(midiInfo, endTick) + startOffsetSeconds;
			eventData = {
				s: mapping.s,
				t: Math.round(startSeconds * 1000) / 1000,
				r: mapping.r || 1,
			};
			if (typeof mapping.v === 'number' && isFinite(mapping.v) && Math.abs(mapping.v - 1) > 0.0001) {
				eventData.v = Math.max(mapping.v, 0);
			}
			return this.finalizeMidiTimelineEvent(eventData, decaySeconds, payload || {});
		},

		finalizeMidiTimelineEvent: function (eventData, decaySeconds, payload) {
			var mode = parseInt(payload.decay_mode, 10) || 0;
			var threshold = parseFloat(payload.dropoff_threshold);
			var linearDrop = parseFloat(payload.linear_drop_per_ds);
			var exponentialDropoff = parseFloat(payload.exponential_dropoff);
			var stopSeconds = decaySeconds;
			if (!eventData || typeof decaySeconds !== 'number') {
				return eventData;
			}
			threshold = Math.max(isNaN(threshold) ? 0 : threshold, 0.0001);
			linearDrop = Math.max(isNaN(linearDrop) ? 0 : linearDrop, 0);
			exponentialDropoff = Math.max(isNaN(exponentialDropoff) ? 0 : exponentialDropoff, 1.0001);
			if (mode === 1 && linearDrop > 0) {
				stopSeconds = decaySeconds + ((1 - threshold) / linearDrop) / 10;
			} else if (mode === 2) {
				stopSeconds = decaySeconds + (Math.log(1 / threshold) / Math.log(exponentialDropoff)) / 10;
			}
			stopSeconds = Math.max(decaySeconds, stopSeconds);
			eventData.e = Math.round(stopSeconds * 1000) / 1000;
			if (stopSeconds > decaySeconds + 0.0005) {
				eventData.d = Math.round(decaySeconds * 1000) / 1000;
				eventData.m = mode;
				eventData.g = Math.round(Math.max(0.0001, threshold) * 10000) / 10000;
			}
			return eventData;
		},

		buildTempoMap: function (division, tempoEvents, totalTicks) {
			var map = [];
			var seconds = 0;
			var previousTick = 0;
			var currentTempo = 500000;
			var event;
			tempoEvents.sort(function (a, b) {
				return a.tick - b.tick;
			});
			map.push({
				tick: 0,
				seconds: 0,
				mpqn: currentTempo,
			});
			for (var i = 0; i < tempoEvents.length; i++) {
				event = tempoEvents[i];
				if (!event || typeof event.tick !== 'number' || typeof event.mpqn !== 'number') {
					continue;
				}
				if (event.tick === previousTick) {
					currentTempo = event.mpqn;
					map[map.length - 1].mpqn = currentTempo;
					continue;
				}
				seconds += ((event.tick - previousTick) * currentTempo) / division / 1000000;
				currentTempo = event.mpqn;
				previousTick = event.tick;
				map.push({
					tick: event.tick,
					seconds: seconds,
					mpqn: currentTempo,
				});
			}
			seconds += ((totalTicks - previousTick) * currentTempo) / division / 1000000;
			return {
				division: division,
				tempoMap: map,
				totalTicks: totalTicks,
				durationSeconds: Math.max(0, seconds),
			};
		},

		secondsFromTicks: function (midiInfo, ticks) {
			var current;
			var next;
			if (!midiInfo || !midiInfo.tempoMap || !midiInfo.tempoMap.length || ticks <= 0) {
				return 0;
			}
			if (ticks >= midiInfo.totalTicks) {
				return midiInfo.durationSeconds;
			}
			for (var i = 0; i < midiInfo.tempoMap.length; i++) {
				current = midiInfo.tempoMap[i];
				next = midiInfo.tempoMap[i + 1];
				if (next && ticks >= next.tick) {
					continue;
				}
				return current.seconds + (((ticks - current.tick) * current.mpqn) / midiInfo.division / 1000000);
			}
			return midiInfo.durationSeconds;
		},

		readAscii: function (view, offset, length) {
			var result = '';
			for (var i = 0; i < length; i++) {
				result += String.fromCharCode(view.getUint8(offset + i));
			}
			return result;
		},

		readVarLen: function (view, offset) {
			var value = 0;
			var current;
			do {
				current = view.getUint8(offset);
				offset++;
				value = (value << 7) | (current & 0x7F);
			} while ((current & 0x80) !== 0);
			return {
				value: value,
				offset: offset,
			};
		},

		updateGain: function (songId, gain, positionX, positionZ) {
			var song = this.getSong(songId);
			var value = parseFloat(gain) || 0;
			var outputGain;
			var parsedPositionX = parseFloat(positionX);
			var parsedPositionZ = parseFloat(positionZ);
			song.currentGain = value;
			this.updateSongPosition(
				song,
				isNaN(parsedPositionX) ? song.positionX : parsedPositionX,
				isNaN(parsedPositionZ) ? song.positionZ : parsedPositionZ
			);
			outputGain = this.computeOutputGain(song, value);
			if (song.masterGain && this.context) {
				try {
					song.masterGain.gain.setTargetAtTime(outputGain, this.context.currentTime, 0.03);
				} catch (error) {
					song.masterGain.gain.value = outputGain;
				}
			}
		},

		stop: function (songId, preserveActive) {
			var song = this.songs[songId];
			var i;
			var activeNodes;
			var now;
			preserveActive = preserveActive === true || preserveActive === 1 || preserveActive === '1';
			if (!song) {
				return;
			}
			if (song.scheduleTimer) {
				clearInterval(song.scheduleTimer);
				song.scheduleTimer = null;
			}
			song.pendingStart = null;
			if (preserveActive && this.context && song.masterGain) {
				song.stopAfterActive = true;
				activeNodes = song.activeNodes.slice();
				now = this.context.currentTime + 0.01;
				for (i = 0; i < activeNodes.length; i++) {
					if (!activeNodes[i] || activeNodes[i].cleaned || activeNodes[i].startAt <= now) {
						continue;
					}
					try {
						activeNodes[i].source.stop(0);
					} catch (error) {
						void error;
					}
					this.cleanupNode(song, activeNodes[i]);
				}
				if (!song.activeNodes.length) {
					this.finishGracefulStop(song);
				}
				return;
			}
			song.stopAfterActive = false;
			song.dropWhenStopped = false;
			for (i = 0; i < song.activeNodes.length; i++) {
				try {
					song.activeNodes[i].source.stop(0);
				} catch (error) {
					void error;
				}
			}
			if (song.masterGain) {
				try {
					song.masterGain.disconnect();
				} catch (disconnectError) {
					void disconnectError;
				}
			}
			this.disconnectSpatialNode(song);
			song.activeNodes = [];
			song.masterGain = null;
		},

		drop: function (songId, preserveActive) {
			var song = this.songs[songId];
			preserveActive = preserveActive === true || preserveActive === 1 || preserveActive === '1';
			if (!song) {
				return;
			}
			song.dropWhenStopped = preserveActive;
			this.stop(songId, preserveActive);
			if (!preserveActive || !song.masterGain || !song.activeNodes.length) {
				delete this.songs[songId];
			}
		},

		flush: function () {
			for (var songId in this.songs) {
				if (this.songs.hasOwnProperty(songId)) {
					this.drop(songId);
				}
			}
		}
	};

	window.instrumentAudio = instrumentAudio;
	window.onload = function () {
		instrumentAudio.init();
	};
})();
