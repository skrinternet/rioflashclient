package rioflashclient2.player {
  import caurina.transitions.Tweener;
  
  import flash.events.ErrorEvent;
  import flash.events.Event;
  
  import org.osmf.elements.VideoElement;
  import org.osmf.events.LoadEvent;
  import org.osmf.events.TimeEvent;
  import org.osmf.layout.ScaleMode;
  import org.osmf.logging.Log;
  import org.osmf.logging.Logger;
  import org.osmf.media.MediaPlayerSprite;
  import org.osmf.media.URLResource;
  
  import rioflashclient2.configuration.Configuration;
  import rioflashclient2.event.EventBus;
  import rioflashclient2.event.PlayerEvent;
  import rioflashclient2.media.PlayerMediaFactory;
  import rioflashclient2.model.Lesson;
  import rioflashclient2.model.Video;
  import rioflashclient2.net.pseudostreaming.DefaultSeekDataStore;
  
  public class Player extends MediaPlayerSprite {
    private var logger:Logger = Log.getLogger('Player');
    
    public var lesson:Lesson;
    public var video:Video;
    private var seekDataStore:DefaultSeekDataStore;
    private var originalVideoURL:String;
    private var duration:Number = 0;
    private var hasDuration:Boolean = false;
    
    public function Player() {
      this.name = 'Player';
      super(null, null, new PlayerMediaFactory());
      
      if (!!stage) init();
      else addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    private function init(e:Event=null):void {
      setupMediaPlayer();
      setupInterface();
      setupBusDispatchers();
      setupBusListeners();
      setupEventListeners();
    }
    
    public function load(video:Video):void {
      this.video = video;
	  
      loadMedia(video.url());
      (this.media as VideoElement).client.addHandler("onMetaData", onMetadata);
      //resize();
    }

    public function loadMedia(url:String=""):void {
      if (!originalVideoURL) {
        originalVideoURL = url;
        logger.info('Loading video from url: ' + url);
      } else {
        logger.info('Seeking from url: ' + url);
      }

      this.resource = new URLResource(url);
    }

    public function onMetadata(info:Object):void
    {
      logger.info('Loading video metadata...');
      seekDataStore = DefaultSeekDataStore.create(info);
      seekDataStore.reset();
      EventBus.dispatch(new PlayerEvent(PlayerEvent.NEED_TO_KEEP_PLAYAHEAD_TIME, seekDataStore.needToKeepPlayAheadTime()));
    }
    
    public function play():void {
      logger.info('Playing...');

      fadeIn();
      this.mediaPlayer.play();
    }
    
    public function pause():void {
      logger.info('Paused...');

      this.mediaPlayer.pause();
    }
    
    public function stop():void {
      logger.info('Stopping...');

      this.mediaPlayer.stop();
      fadeOut();
    }
    
    private function onLoad(e:PlayerEvent):void {
      load(e.data.video);
    }
    
    private function onPlay(e:PlayerEvent):void {
      play();
    }
    
    private function onPause(e:PlayerEvent):void {
      pause();
    }
    
    private function onStop(e:PlayerEvent):void {
      stop();
    }
    
    private function onVolumeChange(e:PlayerEvent):void {
      logger.debug('Volume changed: ' + e.data);
      this.mediaPlayer.volume = e.data;
    }
    
    private function onMute(e:PlayerEvent):void {
      logger.debug('Volume muted.');
      this.mediaPlayer.muted = true;
    }
    
    private function onUnmute(e:PlayerEvent):void {
      logger.debug('Volume unmuted.');
      this.mediaPlayer.muted = false;
    }
    
    private function onVideoEnded(e:TimeEvent):void {
      logger.debug('Video ended.');

      EventBus.dispatch(new PlayerEvent(PlayerEvent.ENDED, { video: video }));
      stop();
    }
    
    private function onSeek(e:PlayerEvent):void {
      var seekPercentage:Number = (e.data as Number);
      var seekPosition:Number = calculatedSeekPositionGivenPercentage(seekPercentage);
      
      logger.info('Seeking to position {0} in seconds, given percentual {1}.', seekPosition, seekPercentage);
      
      this.mediaPlayer.seek(seekPosition);
    }

    private function onServerSeek(e:PlayerEvent):void {
      if (seekDataStore.allowRandomSeek()) {
        var seekPercentage:Number = (e.data as Number);
        var seekPosition:Number = calculatedSeekPositionGivenPercentage(seekPercentage);
      
        logger.info('Server Seeking to position {0} in seconds, given percentual {1}.', seekPosition, seekPercentage);

        loadMedia(appendQueryString(originalVideoURL, seekPosition));
        EventBus.dispatch(new PlayerEvent(PlayerEvent.PLAYAHEAD_TIME_CHANGED, seekDataStore.getQueryStringStartValue(seekPosition)));
        play();
      } else {
        logger.info('RandomSeek not supported by media element');
      }
    }

    private function onTopicsSeek(e:PlayerEvent):void {
      if (seekDataStore.allowRandomSeek()) {
        logger.info('Topics Seeking to position {0} in seconds.', e.data);

        loadMedia(appendQueryString(originalVideoURL, e.data));
        play();
      } else {
        logger.info('RandomSeek not supported by media element');
      }
    }

    private function onDurationChange(e:TimeEvent):void {
      if (e.time && e.time.toString() != '0' && !hasDuration) {
        duration = e.time;
        hasDuration = true;
      }
      if (hasDuration) {
        (this.media as VideoElement).defaultDuration = duration;
      }
    }

    private function onError(e:ErrorEvent):void {
      fadeOut();
    }
    
    private function calculatedSeekPositionGivenPercentage(seekPercentage:Number):Number {
      return seekPercentage * this.mediaPlayer.duration;
    }
    
    public function hasVideoLoaded():Boolean {
      return this.media != null;
    }
    
    public function fadeIn():void {
      Tweener.addTween(this, { time: 2, alpha: 1, onStart: show });
    }
    
    public function fadeOut():void {
      Tweener.addTween(this, { time: 2, alpha: 0, onComplete: hide });
    }
    
    public function show():void {
      visible = true;
    }
    
    public function hide():void {
      visible = false;
      alpha = 0;
    }
    
    private function setupMediaPlayer():void {
      this.mediaPlayer.autoPlay = Configuration.getInstance().autoPlay;
    }
    
    private function setupInterface():void {
      this.scaleMode = ScaleMode.LETTERBOX;
      resize();
    }
    
    public function resize(newWidth:Number = 320, newHeight:Number = 240):void {
      if (stage != null) {
        this.width = newWidth;
        this.height = newHeight;
      }
    }
    public function setSize(newWidth:Number = 320, newHeight:Number = 240):void{
		this.width = newWidth;
		this.height = newHeight;
	}
    private function setupBusDispatchers():void {
      this.mediaPlayer.addEventListener(TimeEvent.COMPLETE, EventBus.dispatch);
      this.mediaPlayer.addEventListener(TimeEvent.CURRENT_TIME_CHANGE, EventBus.dispatch);
      this.mediaPlayer.addEventListener(TimeEvent.DURATION_CHANGE, EventBus.dispatch);
      this.mediaPlayer.addEventListener(LoadEvent.BYTES_LOADED_CHANGE, EventBus.dispatch);
      this.mediaPlayer.addEventListener(LoadEvent.BYTES_TOTAL_CHANGE, EventBus.dispatch);
    }
    
    private function setupBusListeners():void {
      EventBus.addListener(PlayerEvent.LOAD, onLoad);
      EventBus.addListener(PlayerEvent.PLAY, onPlay);
      EventBus.addListener(PlayerEvent.PAUSE, onPause);
      EventBus.addListener(PlayerEvent.STOP, onStop);
      
      EventBus.addListener(TimeEvent.COMPLETE, onVideoEnded);
      EventBus.addListener(TimeEvent.DURATION_CHANGE, onDurationChange);
      
      EventBus.addListener(PlayerEvent.VOLUME_CHANGE, onVolumeChange);
      EventBus.addListener(PlayerEvent.MUTE, onMute);
      EventBus.addListener(PlayerEvent.UNMUTE, onUnmute);
      
      EventBus.addListener(PlayerEvent.SEEK, onSeek);
      EventBus.addListener(PlayerEvent.SERVER_SEEK, onServerSeek);
      EventBus.addListener(PlayerEvent.TOPICS_SEEK, onTopicsSeek);

      EventBus.addListener(ErrorEvent.ERROR, onError);
    }
    
    private function setupEventListeners():void {
      //stage.addEventListener(Event.RESIZE, resize);
    }

    private function appendQueryString(url:String, start:Number):String {
        logger.debug("seek requested to: " + start);

        if (start == 0) return url;

        logger.debug("seeking to: " + seekDataStore.getQueryStringStartValue(start));
        return url + (url.indexOf("?") >= 0 ? "&" : "?") + 
               "start=${start}".replace("${start}", seekDataStore.getQueryStringStartValue(start));
    }
  }
}