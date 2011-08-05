﻿/*   SoundManager 2: Javascript Sound for the Web   ----------------------------------------------   http://schillmania.com/projects/soundmanager2/   Copyright (c) 2008, Scott Schiller. All rights reserved.   Code licensed under the BSD License:   http://www.schillmania.com/projects/soundmanager2/license.txt   V2.90a.20081028   Flash 9 / ActionScript 3 version*/package {import flash.display.Sprite;import flash.display.StageAlign;import flash.display.StageScaleMode;import flash.system.Security;import flash.events.*;import flash.media.Sound;import flash.media.SoundChannel;import flash.media.SoundMixer;import flash.utils.setInterval;import flash.utils.clearInterval;import flash.utils.Dictionary;import flash.utils.Timer;import flash.net.URLLoader;import flash.net.URLRequest;import flash.xml.*;import flash.external.ExternalInterface; // woopublic class SoundManager2_AS3 extends Sprite {  // Cross-domain security exception stuffs  // HTML on foo.com loading .swf hosted on bar.com? Define your "HTML domain" here to allow JS+Flash communication to work.  // See http://livedocs.adobe.com/flash/9.0/ActionScriptLangRefV3/flash/system/Security.html#allowDomain()  // Security.allowDomain("foo.com");  public var self:Object = this;    public var DEBUG:Boolean = false;  // internal objects  public var sounds:Array = []; // indexed string array  public var soundObjects:Dictionary = new Dictionary(); // associative Sound() object Dictionary type  public var timerInterval:uint = 20;  public var timer:Timer = null;  public var pollingEnabled:Boolean = false; // polling (timer) flag - disabled by default, enabled by JS->Flash call  public var debugEnabled:Boolean = true;    // Flash debug output enabled by default, disabled by JS call  public var loaded:Boolean = false;  public var playerID:String;  public var secureDomain:String;  public var sID:String = "soundmgr2";  public function SoundManager2_AS3() {	stage.scaleMode = StageScaleMode.NO_SCALE; // SHOW_ALL vs. NO_SCALE vs. EXACT_FIT    stage.align	= StageAlign.TOP_LEFT;		playerID = loaderInfo.parameters.playerID;	secureDomain = (loaderInfo.parameters.secureDomain == undefined) ? "" : loaderInfo.parameters.secureDomain;	if (secureDomain != "")		Security.allowDomain(secureDomain);    if (ExternalInterface.available) {      ExternalInterface.addCallback('callMethod', callMethod);	  var timer:Timer = new Timer(20,0);  	  timer.addEventListener(TimerEvent.TIMER, function():void {        sendEvent("init", {state: 1,sandboxType:Security['sandboxType']});        timer.reset();      });      timer.start();	}  } // SoundManager2()  // methods  // -----------------------------------    public function sendEvent(event:String, object:Object):void {	if (!this.playerID) { return; }    ExternalInterface.call('apf.flash.callMethod', this.playerID || 1, 'event', event, object);  }  public function callJS(method:String, data:Object):void {	if (!this.playerID) { return; }    ExternalInterface.call('apf.flash.callMethod', this.playerID || 1, method, data);  }  public function callMethod():void {    var method:String = String(arguments.shift());	if (DEBUG) sendEvent('debug', {msg: 'callMethod() called - ' + method});	try {      this[method].apply(this, arguments);	} catch (e:Error) {		if (DEBUG) sendEvent('debug', {msg: 'callMethod - something went wrong: ' + e.toString()});	}  }  public function checkLoadProgress(e:Event):void {	try {		var oSound:Object = e.target;		var bL:int = oSound.bytesLoaded;		var bT:int = oSound.bytesTotal;		var nD:int = oSound.length||oSound.duration||0;		sendEvent("progress",{bytesLoaded:bL,totalBytes:bT,totalTime:nD});		if (bL && bT && bL != oSound.lastValues.bytes) {		  oSound.lastValues.bytes = bL;		  sendEvent("progress",{bytesLoaded:bL,totalBytes:bT,totalTime:nD});		}	} catch(e:Error) {}  }  public function checkProgress():void {    var bL:int = 0;    var bT:int = 0;    var nD:int = 0;    var nP:int = 0;    var lP:Number = 0;    var rP:Number = 0;    var oSound:SoundManager2_SMSound_AS3 = null;    var oSoundChannel:flash.media.SoundChannel = null;    var sMethod:String = null;    var newPeakData:Boolean = false;    var newWaveformData:Boolean = false;    var newEQData:Boolean = false;    for (var i:int = 0, j:int = sounds.length; i < j; i++) {      oSound = soundObjects[sounds[i]];      if (!oSound) continue; // if sounds are destructed within event handlers while this loop is running, may be null	  	  if (oSound.useNetstream) {        bL = oSound.ns.bytesLoaded;        bT = oSound.ns.bytesTotal;        nD = int(oSound.duration||0); // can sometimes be null with short MP3s? Wack.        nP = oSound.ns.time*1000;        if (oSound.loaded != true && nD > 0 && bL == bT) {          // non-MP3 has loaded          // if (DEBUG) sendEvent('debug', {msg:'ns: time/duration/bytesloaded,total: '+(oSound.ns.time*1000)+', '+oSound.duration+', '+oSound.ns.bytesLoaded+'/'+oSound.ns.bytesTotal});          oSound.loaded = true;          try {			sendEvent("progress", {bytesLoaded: oSound.ns.bytesLoaded, totalBytes: oSound.ns.bytesTotal, totalTime: nD});            sendEvent("complete", {state:oSound.duration>0?1:0});	  	  } catch(e:Error) {	        sendEvent('progress', {msg: '_whileLoading/_onload error: '+e.toString()});	      }        } else if (!oSound.loaded && bL && bT && bL != oSound.lastValues.bytes) {          oSound.lastValues.bytes = bL;		  sendEvent("progress", {bytesLoaded: bL, totalBytes: bT, totalTime: nD});        }      } else {		oSoundChannel = oSound.soundChannel;		bL = oSound.bytesLoaded;		bT = oSound.bytesTotal;		nD = int(oSound.length||0); // can sometimes be null with short MP3s? Wack.			if (oSoundChannel) {			nP = (oSoundChannel.position||0);			if (oSound.usePeakData) {			  lP = int((oSoundChannel.leftPeak)*1000)/1000;			  rP = int((oSoundChannel.rightPeak)*1000)/1000;			} else {			  lP = 0;			  rP = 0;			}		} else {			// stopped, not loaded or feature not used			nP = 0;		}			// loading progress		if (bL && bT && bL != oSound.lastValues.bytes) {			oSound.lastValues.bytes = bL;			sendEvent("progress", {bytesLoaded: bL, totalBytes: bT, totalTime: nD});		}	  }      // peak data      if (oSoundChannel && oSound.usePeakData) {        if (lP != oSound.lastValues.leftPeak) {          oSound.lastValues.leftPeak = lP;          newPeakData = true;        }        if (rP != oSound.lastValues.rightPeak) {          oSound.lastValues.rightPeak = rP;          newPeakData = true;        }      }      // raw waveform + EQ spectrum data      if (oSoundChannel) {        if (oSound.useWaveformData) {          try {            oSound.getWaveformData();          } catch(e:Error) {            oSound.useWaveformData = false;          }        }        if (oSound.useEQData) {          try {            oSound.getEQData();          } catch(e:Error) {            oSound.useEQData = false;          }        }        if (oSound.waveformDataArray != oSound.lastValues.waveformDataArray) {          oSound.lastValues.waveformDataArray = oSound.waveformDataArray;          newWaveformData = true;        }        if (oSound.eqDataArray != oSound.lastValues.eqDataArray) {          oSound.lastValues.eqDataArray = oSound.eqDataArray;          newEQData = true;        }      }      if (typeof nP != 'undefined' && nP != oSound.lastValues.position) {        oSound.lastValues.position = nP;        sendEvent("playheadUpdate",{          playheadTime: nP,          totalTime   : (oSound.useNetstream != true ? nD : null),          peakData    : (oSound.useNetstream != true && newPeakData ? {leftPeak: lP, rightPeak: rP} : null),          waveData    : (oSound.useNetstream != true && newWaveformData ? oSound.waveformDataArray : null),          eqData      : (oSound.useNetstream != true && newEQData ? oSound.eqDataArray : null)});        // if position changed, check for near-end        if (oSound.didJustBeforeFinish != true && oSound.loaded == true && oSound.justBeforeFinishOffset > 0 && nD-nP <= oSound.justBeforeFinishOffset) {          // fully-loaded, near end and haven't done this yet..          sendEvent("justbeforecomplete",{timeLeft: (nD-nP)});          oSound.didJustBeforeFinish = true;        }      }    }  }  public var counter:int = 0;    public function onLoadError(oSound:Object):void {	// something went wrong. 404, bad format etc.	sendEvent("complete", {state: 0});  }  public function onLoad(e:Event):void {    checkProgress(); // ensure progress stats are up-to-date    var oSound:Object = e.target;	if (!oSound.useNetstream) { // FLV must also have metadata      oSound.loaded = true;      // force duration update (doesn't seem to be always accurate)      sendEvent("progress",{bytesLoaded: oSound.bytesLoaded,totalBytes: oSound.bytesTotal,totalTime: oSound.length||oSound.duration});      // TODO: Determine if loaded or failed - bSuccess?      // ExternalInterface.call(baseJSObject+"['"+oSound.sID+"']._onload",bSuccess?1:0);      sendEvent("ready",{state: 1});	}  }  public function onID3(e:Event):void {    // --- NOTE: BUGGY? (Flash 8 only? Haven't really checked 9 + 10.) ---    // TODO: Investigate holes in ID3 parsing - for some reason, Album will be populated with Date if empty and date is provided. (?)    // ID3V1 seem to parse OK, but "holes" / blanks in ID3V2 data seem to get messed up (eg. missing album gets filled with date.)    // iTunes issues: onID3 was not called with a test MP3 encoded with iTunes 7.01, and what appeared to be valid ID3V2 data.    // May be related to thumbnails for album art included in MP3 file by iTunes. See http://mabblog.com/blog/?p=33	try {		var oSound:Object = e.target;			var id3Data:Array = [];		var id3Props:Array = [];		for (var prop:String in oSound.id3) {		  id3Props.push(prop);		  id3Data.push(oSound.id3[prop]);		  if (DEBUG) sendEvent('debug', {msg:'id3['+prop+']: '+oSound.id3[prop]});		}		sendEvent("id3",{properties: id3Props, data: id3Data});	} catch(e:Error) {		//unable to get ID3 info... fail silently...	}    // unhook own event handler, prevent second call (can fire twice as data is received - ID3V2 at beginning, ID3V1 at end.)    // Therefore if ID3V2 data is received, ID3V1 is ignored.    // soundObjects[oSound.sID].onID3 = null;    oSound.removeEventListener(Event.ID3,onID3);  }  public function registerOnComplete(sID:String):void {	if (soundObjects[sID] && soundObjects[sID].soundChannel) {      soundObjects[sID].soundChannel.addEventListener(Event.SOUND_COMPLETE, function():void {        this.didJustBeforeFinish = false; // reset        if (soundObjects[sID]) {          try {            soundObjects[sID].start(0,1); // go back to 0            soundObjects[sID].soundChannel.stop();          } catch(e:Error) {            // unable to set position          }        }        // checkProgress();        sendEvent("complete", {state: 1});      });    }  }    public function doSecurityError(oSound:SoundManager2_SMSound_AS3,e:SecurityErrorEvent):void {    //if (DEBUG) sendEvent('debug', {msg:'securityError: '+e.text});    // when this happens, you don't have security rights on the server containing the FLV file    // a crossdomain.xml file would fix the problem easily  }   public function doIOError(oSound:SoundManager2_SMSound_AS3,e:IOErrorEvent):void {    if (DEBUG) sendEvent('debug', {msg:'ioError: '+e.text});    // call checkProgress()?    sendEvent("complete", {state: 0}); // call onload, assume it failed.    // there was a connection drop, a loss of internet connection, or something else wrong. 404 error too.  }  public function doAsyncError(oSound:SoundManager2_SMSound_AS3,e:AsyncErrorEvent):void {    //if (DEBUG) sendEvent('debug', {msg:'asyncError: '+e.text});    // this is more related to streaming server from my experience, but you never know  }  public function doNetStatus(oSound:SoundManager2_SMSound_AS3,e:NetStatusEvent):void {    // this will eventually let us know what is going on.. is the stream loading, empty, full, stopped?    //if (e.info.code != "NetStream.Buffer.Full" && e.info.code != "NetStream.Buffer.Empty" && e.info.code != "NetStream.Seek.Notify") {      //if (DEBUG) sendEvent('debug', {msg:'netStatusEvent: '+e.info.code});    //}    if (e.info.code == "NetStream.Play.Stop") { // && !oSound.didFinish && oSound.loaded == true && nD == nP      // finished playing      // oSound.didFinish = true; // will be reset via JS callback      oSound.didJustBeforeFinish = false; // reset      //if (DEBUG) sendEvent('debug', {msg:'calling onfinish for a sound'});      // reset the sound      oSound.ns.pause();      oSound.ns.seek(0);      // whileplaying()?      sendEvent("complete", {state: 1});    }    if (e.info.code == "NetStream.Play.FileStructureInvalid" || e.info.code == "NetStream.Play.FileStructureInvalid" || e.info.code == "NetStream.Play.StreamNotFound") {	  this.onLoadError(oSound);    }  }  public function addNetstreamEvents(oSound:SoundManager2_SMSound_AS3):void {    oSound.ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, function(e:AsyncErrorEvent):void{doAsyncError(oSound,e)});    oSound.ns.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void{doNetStatus(oSound,e)});    oSound.ns.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void{doIOError(oSound,e)});    oSound.nc.addEventListener(NetStatusEvent.NET_STATUS, oSound.doNetStatus);  }  public function removeNetstreamEvents(oSound:SoundManager2_SMSound_AS3):void {    oSound.ns.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, function(e:AsyncErrorEvent):void{doAsyncError(oSound,e)});    oSound.ns.removeEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent):void{doNetStatus(oSound,e)});    oSound.ns.removeEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void{doIOError(oSound,e)});    oSound.nc.removeEventListener(NetStatusEvent.NET_STATUS, oSound.doNetStatus);  }  public function setPosition(nSecOffset:Number,isPaused:Boolean):void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];    if (!s) return void;    // stop current channel, start new one.    if (s.lastValues) {      s.lastValues.position = nSecOffset; // s.soundChannel.position;    }    if (s.useNetstream) {      s.ns.seek(nSecOffset/1000);      checkProgress(); // force UI update    } else {      if (s.soundChannel) {        s.soundChannel.stop();      }      try {        s.start(nSecOffset,s.lastValues.nLoops||1); // start playing at new position      } catch(e:Error) {        if (DEBUG) sendEvent('debug', {msg:'Warning: Could not set position on '+sID+': '+e.toString()});      }      checkProgress(); // force UI update	  try {	    registerOnComplete(sID);	  } catch(e:Error) {	    //if (DEBUG) sendEvent('debug', {msg:'_setPosition(): Could not register onComplete'});	  }      if (isPaused && s.soundChannel) {        s.soundChannel.stop();      }    }  }  public function loadSound(sURL:String,bStream:Boolean,bAutoPlay:Boolean):void {    if (typeof bAutoPlay == 'undefined') bAutoPlay = false;    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];	if (!s) return void;    var didRecreate:Boolean = false;    if (s.didLoad == true) {      // need to recreate sound      didRecreate = true;      var ns:Object = new Object();      ns.sID = s.sID;      ns.justBeforeFinishOffset = s.justBeforeFinishOffset;      ns.usePeakData = s.usePeakData;      ns.useWaveformData = s.useWaveformData;      ns.useEQData = s.useEQData;	  ns.useNetstream = s.useNetstream;      ns.useVideo = s.useVideo;      destroySound();      createSound(sURL,ns.justBeforeFinishOffset,ns.usePeakData,ns.useWaveformData,ns.useEQData,ns.useNetstream,ns.useVideo);      s = soundObjects[sID];    }    checkProgress();    if (!s.didLoad) {	  try {        s.addEventListener(Event.ID3, onID3);        s.addEventListener(Event.COMPLETE, onLoad);	  } catch(e:Error) {		//could not assign ID3/complete event handlers	  }    }    // s.addEventListener(ProgressEvent.PROGRESS, checkLoadProgress); // May be called often, potential CPU drain    // s.addEventListener(Event.FINISH, onFinish);	    // s.loaded = true; // TODO: Investigate - Flash 9 non-FLV bug??    // s.didLoad = true; // TODO: Investigate - bug?    // if (didRecreate || s.sURL != sURL) {    // don't try to load if same request already made    s.sURL = sURL;		if (s.useNetstream) {      try {		// s.ns.close();		this.addNetstreamEvents(s);		s.ns.play(sURL);      } catch(e:Error) {        if (DEBUG) sendEvent('debug', {msg:'_load(): error: '+e.toString()});      }    } else {      try {        s.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void{doIOError(s,e)});        s.loadSound(sURL,bStream);      } catch(e:Error) {        // oh well        if (DEBUG) sendEvent('debug', {msg:'_load: Error loading '+sURL+'. Flash error detail: '+e.toString()});      }    }    s.didJustBeforeFinish = false;    if (bAutoPlay != true) {      //s.soundChannel.stop(); // prevent default auto-play behaviour      //if (DEBUG) sendEvent('debug', 'auto-play stopped');    } else {      //if (DEBUG) sendEvent('debug', 'auto-play allowed');      //s.start(0,1);      //registerOnComplete();    }  }  public function unloadSound(sURL:String):void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];	if (!s) return void;    try {      removeEventListener(Event.ID3,onID3);      removeEventListener(Event.COMPLETE, onLoad);    } catch(e:Error) {      if (DEBUG) sendEvent('debug', {msg:'_unload() warn: Could not remove ID3/complete events'});    }    s.paused = false;    if (s.soundChannel) {      s.soundChannel.stop();    }    try {      if (s.didLoad != true && !s.useNetstream) s.close(); // close stream only if still loading?    } catch(e:Error) {      // stream may already have closed if sound loaded, etc.      if (DEBUG) sendEvent('debug', {msg:'sound._unload(): '+sID+' already unloaded?'});      // oh well    }    // destroy and recreate Flash sound object, try to reclaim memory    if (DEBUG) sendEvent('debug', {msg:'sound._unload(): recreating sound '+sID+' to free memory'});    if (s.useNetstream) {	  if (DEBUG) sendEvent('debug', {msg:'_unload(): closing netStream stuff'});      try {		this.removeNetstreamEvents(s);        s.ns.close();        s.nc.close();		// s.nc = null;		//s.ns = null;      } catch(e:Error) {		// oh well        if (DEBUG) sendEvent('debug', {msg:'_unload(): error during netConnection/netStream close'});      }      if (s.useVideo) {		if (DEBUG) sendEvent('debug', {msg:'_unload(): clearing video'});        s.oVideo.clear();        // s.oVideo = null;      }    }    var ns:Object = new Object();    ns.sID = s.sID;    ns.justBeforeFinishOffset = s.justBeforeFinishOffset;    ns.usePeakData = s.usePeakData;    ns.useWaveformData = s.useWaveformData;    ns.useEQData = s.useEQData;	ns.useNetstream = s.useNetstream;    ns.useVideo = s.useVideo;    destroySound();    createSound(sURL,ns.justBeforeFinishOffset,ns.usePeakData,ns.useWaveformData,ns.useEQData,ns.useNetstream,ns.useVideo);  }  public function createSound(sURL:String,justBeforeFinishOffset:int,usePeakData:Boolean,useWaveformData:Boolean,useEQData:Boolean,useNetstream:Boolean,useVideo:Boolean):void {    soundObjects[sID] = new SoundManager2_SMSound_AS3(this,sID,sURL,usePeakData,useWaveformData,useEQData,useNetstream,useVideo);    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];	if (!s) return void;    // s.setVolume(100);    s.didJustBeforeFinish = false;    s.sID = sID;    s.sURL = sURL;    s.paused = false;    s.loaded = false;    s.justBeforeFinishOffset = justBeforeFinishOffset||0;    s.lastValues = {      bytes: 0,      position: 0,      nLoops: 1,      leftPeak: 0,      rightPeak: 0    };    if (!(sID in sounds)) sounds.push(sID);    // sounds.push(sID);  }  public function destroySound():void {    // for the power of garbage collection! .. er, Greyskull!    var s:SoundManager2_SMSound_AS3 = (soundObjects[sID]||null);    if (!s) return void;    // try to unload the sound    for (var i:int=0, j:int=sounds.length; i<j; i++) {      if (sounds[i] == s) {	    sounds.splice(i,1);        continue;      }    }    if (s.soundChannel) {      s.soundChannel.stop();    }    this.stage.removeEventListener(Event.RESIZE, s.resizeHandler);    // if is a movie, remove that as well.    if (s.useNetstream) {      // s.nc.client = null;	  try {	    this.removeNetstreamEvents(s);	      // s.nc.removeEventListener(NetStatusEvent.NET_STATUS, s.doNetStatus);	    } catch(e:Error) {		  if (DEBUG) sendEvent('debug', {msg:'_destroySound(): Events already removed from netStream/netConnection?'});	    }        if (s.useVideo) {          try {            this.removeChild(s.oVideo);          } catch(e:Error) {	    	if (DEBUG) sendEvent('debug', {msg:'_destoySound(): could not remove video?'});          }        }        if (s.didLoad) {          try {            s.ns.close();	  	    s.nc.close();          } catch(e:Error) {	        // oh well            if (DEBUG) sendEvent('debug', {msg:'_destroySound(): error during netConnection/netStream close and null'});	  	  }      }    }    s = null;    soundObjects[sID] = null;    delete soundObjects[sID];  }  public function stopSound(bStopAll:Boolean):void {    // stop this particular instance (or "all", based on parameter)    if (bStopAll) {	  SoundMixer.stopAll();      //sendEvent('alert','Flash: need _stop for all sounds');      // SoundManager2_AS3.display.stage.stop(); // _root.stop();      // this.soundChannel.stop();      // soundMixer.stop();    } else {	  var s:SoundManager2_SMSound_AS3 = soundObjects[sID];	  if (!s) return void;      if (s.useNetstream) {        s.ns.pause();        if (s.oVideo) {          s.oVideo.visible = false;        }      } else {        s.soundChannel.stop();      }      s.paused = false;      s.didJustBeforeFinish = false;    }  }  public function startSound(nLoops:int=1,nMsecOffset:int=0):void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];	if (!s) return void;    s.lastValues.paused = false; // reset pause if applicable    s.lastValues.nLoops = (nLoops||1);    s.lastValues.position = nMsecOffset;    try {      s.start(nMsecOffset,nLoops);    } catch(e:Error) {      if (DEBUG) sendEvent('debug', {msg:'Could not start '+sID+': '+e.toString()});    }    try {      registerOnComplete(sID);    } catch(e:Error) {      if (DEBUG) sendEvent('debug', {msg:'_start(): registerOnComplete failed'});    }  }  public function pauseSound():void {    var s:SoundManager2_SMSound_AS3 = soundObjects[sID];	if (!s) return void;    if (!s.paused) {      s.paused = true;       if (DEBUG) sendEvent('debug', {msg:'_pause(): position: '+s.lastValues.position});      if (s.useNetstream) {	    s.lastValues.position = s.ns.time;        s.ns.pause();      } else {        if (s.soundChannel) {	      s.lastValues.position = s.soundChannel.position;          s.soundChannel.stop();        }      }    } else {      // resume playing from last position      if (DEBUG) sendEvent('debug', {msg:'resuming - playing at '+s.lastValues.position+', '+s.lastValues.nLoops+' times'});      s.paused = false;      if (s.useNetstream) {        s.ns.resume();      } else {        s.start(s.lastValues.position,s.lastValues.nLoops);      }      try {        registerOnComplete(sID);      } catch(e:Error) {        if (DEBUG) sendEvent('debug', {msg:'_pause(): registerOnComplete() failed'});      }    }  }  public function setPan(nPan:Number):void {	if (!soundObjects[sID]) return void;    soundObjects[sID].setPan(nPan);  }   public function setVolume(nVol:Number):void {	if (!soundObjects[sID]) return void;    soundObjects[sID].setVolume(nVol);  }  public function setPolling(bPolling:Boolean):void {    pollingEnabled = bPolling;    if (timer == null && pollingEnabled) {      if (DEBUG) sendEvent('debug', {msg:'Enabling polling'});      timer = new Timer(timerInterval,0);      timer.addEventListener(TimerEvent.TIMER, function():void{checkProgress();}); // direct reference eg. checkProgress doesn't work? .. odd.      timer.start();    } else if (timer && !pollingEnabled) {      // flash.utils.clearInterval(timer);      timer.reset();    }  }  // -----------------------------------  // end methods}// package}