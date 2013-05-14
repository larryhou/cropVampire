package
{
	import com.larrio.dump.SWFile;
	import com.larrio.dump.tags.PlaceObject2Tag;
	import com.larrio.dump.tags.SWFTag;
	import com.larrio.dump.tags.SymbolClassTag;
	import com.larrio.dump.tags.TagType;
	import com.larrio.flow.ITaskKernel;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	
	public class CropKernal extends EventDispatcher implements ITaskKernel
	{
		private var _url:String;
		private var _result:Loader;
		
		private var _name:String;
		
		public function CropKernal()
		{
			
		}

		public function execute(data:Object):void
		{			
			_url = data as String;
			_name = String(_url.split("?").shift()).match(/\w+\.\w+$/)[0];
			
			_result = null;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			
			var request:URLRequest = new URLRequest(_url);
			request.requestHeaders.push(new URLRequestHeader("Referer", "http://user.qzone.qq.com/"));
			loader.addEventListener(Event.COMPLETE, assetHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, assetHandler);
			
			loader.load(request);
		}
		
		protected function assetHandler(e:Event):void
		{
			var target:URLLoader = e.currentTarget as URLLoader;
			target.removeEventListener(Event.COMPLETE, arguments.callee);
			target.removeEventListener(IOErrorEvent.IO_ERROR, arguments.callee);			
			
			if (e.type != Event.COMPLETE)
			{
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
				return;
			}
			
			var bytes:ByteArray = processSWF(target.data);			
			var file:File = new File(URL.DOWNLOADS.url + "/" + _name);
			
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			stream.writeBytes(bytes);
			stream.close();
			
			bytes = new ByteArray();
			stream.open(file, FileMode.READ);
			stream.readBytes(bytes);
			stream.close();
			
			var loader:Loader = new Loader();
			var context:LoaderContext = new LoaderContext();
			context.allowCodeImport = true;
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			loader.loadBytes(bytes, context);
		}
		
		// 去带代码并把素材放到舞台
		private function processSWF(bytes:ByteArray):ByteArray
		{
			var swf:SWFile = new SWFile(bytes, [TagType.SYMBOL_CLASS, TagType.SHOW_FRAME]);
			
			var list:Array = [];
			
			var tag:SWFTag;
			var symbol:SymbolClassTag;
			for (var i:int = 0, length:uint = swf.tags.length; i < length; i++)
			{
				tag = swf.tags[i];
				if (tag.type == TagType.DO_ABC)
				{
					swf.tags.splice(i, 1);
					length--; i--;
					continue;
				}
				
				if (tag.type == TagType.SYMBOL_CLASS)
				{
					symbol = tag as SymbolClassTag;
					swf.tags.splice(i, 1);
					length--; i--;
					
					var adder:PlaceObject2Tag;
					for (var j:uint = 0; j < symbol.ids.length; j++)
					{
						if (symbol.ids[j])
						{
							adder = new PlaceObject2Tag();
							adder.character = symbol.ids[j];
							adder.depth = list.length + 1;
							list.push(adder);						
						}
					}
					
				}
			}
			
			swf.tags.splice.apply(null, [-2, 0].concat(list));
			return swf.repack();
		}
		
		protected function completeHandler(e:Event):void
		{
			var target:LoaderInfo = e.currentTarget as LoaderInfo;
			target.removeEventListener(e.type, arguments.callee);
			
			_result = target.loader;
			dispatchEvent(new Event(Event.COMPLETE));
			
			target.loader.unloadAndStop(true);
		}
		
		public function get data():Object
		{
			return _url;
		}
		
		public function get result():Object
		{
			return _result;
		}

		public function get name():String
		{
			return _name;
		}
	}
}