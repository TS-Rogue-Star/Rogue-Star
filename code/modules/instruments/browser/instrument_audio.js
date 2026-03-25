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
		maxConcurrentSampleLoads: 2,
		sampleRetryBaseDelayMs: 150,
		sampleRetryMaxDelayMs: 1000,
		legacySoundHeightBias: 1,
		defaultSoundRolloff: 0.5,
		defaultSoundMaxDistance: 10000,
		context: null,
		ready: false,
		capable: false,
		songs: {},
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
			return !!AudioContextCtor && !!window.XMLHttpRequest && !!window.JSON && canPlayOgg;
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
					events: [],
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
			var needed = {};
			var pending = 0;
			var alias;
			var primeSerial;
			var self = this;
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
					song.loaded = false;
					song.loadFailed = true;
				}
				return;
			}
			song.events = payload.events || [];
			song.timelineKey = timelineKey || null;
			song.loaded = false;
			song.loadFailed = false;
			song.stopAfterActive = false;
			song.dropWhenStopped = false;
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
							self.reportSongReady(song);
						}
						self.maybeLaunch(song);
					}
				});
			}
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
			window.location.href = href;
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
