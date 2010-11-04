package com.maccherone.mpv
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;

	public class MultiURLLoader extends EventDispatcher	{	
		
		public var urlInfo:Dictionary; // key: URLRequest passed into addURLRequest, value: URLInfo
		private var urlLoaders:Dictionary; // key: URLLoader, value: URLRequest (same as above)
		
		public function MultiURLLoader(target:IEventDispatcher=null) {
			super(target);
			urlInfo = new Dictionary();
			urlLoaders = new Dictionary();
		}
		
		public function load():void {
			var tempURLRequest:URLRequest;
			for (var urlLoader:* in urlLoaders) {
				tempURLRequest = urlLoaders[urlLoader];
				urlLoader.load(tempURLRequest);
			}
		}
		
		public function abort():void {
			var tempURLRequest:URLRequest;
			for (var urlLoader:* in urlLoaders) {
				tempURLRequest = urlLoaders[urlLoader];
				if (urlInfo[tempURLRequest].complete) {  // TODO: Shouldn't this be if (! urlInfo[...   ?
					try {
						urlLoader.close();
					} catch(event:Event) {
						
					}
				}
			}
		}
		
		public function addURLRequest(urlRequest:URLRequest):void {
			var tempURLInfo:URLInfo = new URLInfo();
			urlInfo[urlRequest] = tempURLInfo;
			var tempURLLoader:URLLoader = new URLLoader();
			tempURLLoader.addEventListener(Event.COMPLETE, onComplete);
			tempURLLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			urlLoaders[tempURLLoader] = urlRequest;
		}
		
		public function onIOError(event:Event):void {
			var tempURLRequest:URLRequest = urlLoaders[event.target]			
			var tempURLInfo:URLInfo = urlInfo[tempURLRequest];
			tempURLInfo.complete = true;
			tempURLInfo.happy = false;
			abort();
			dispatchEvent(new Event(flash.events.IOErrorEvent.IO_ERROR));
		}
		
		public function onComplete(event:Event):void {
			var tempURLRequest:URLRequest = urlLoaders[event.target]
			var tempURLInfo:URLInfo = urlInfo[tempURLRequest];
			tempURLInfo.complete = true;
			tempURLInfo.happy = true;
			tempURLInfo.data = event.target.data;
			var done:Boolean = true;
			for each (var urlInfoValue:URLInfo in urlInfo) {
				if (! urlInfoValue.complete) {
					done = false;
				}
			}
			if (done) {
				dispatchEvent(new Event(flash.events.Event.COMPLETE));
			}
		}

		
	}
}