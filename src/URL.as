package
{
	import flash.filesystem.File;

	public class URL
	{
		// 应用根目录
		public static function get ROOT():File
		{
			return new File(File.userDirectory.url + "/crops/");
		}
		
		// 日志文件
		public static function get DOWNLOADS():File
		{
			return new File(URL.ROOT.url + "/downloads/");
		}
		
		// 加载错误的文件
		public static function get ERRORS():File
		{
			return new File(URL.ROOT.url + "/errors/");
		}
	}
}