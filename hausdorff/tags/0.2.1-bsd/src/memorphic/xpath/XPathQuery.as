/*
	Copyright (c) 2007 Memorphic Ltd. All rights reserved.
	
	Redistribution and use in source and binary forms, with or without 
	modification, are permitted provided that the following conditions 
	are met:
	
		* Redistributions of source code must retain the above copyright 
		notice, this list of conditions and the following disclaimer.
	    	
	    * Redistributions in binary form must reproduce the above 
	    copyright notice, this list of conditions and the following 
	    disclaimer in the documentation and/or other materials provided 
	    with the distribution.
	    	
	    * Neither the name of MEMORPHIC LTD nor the names of its 
	    contributors may be used to endorse or promote products derived 
	    from this software without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
	OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
	LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package memorphic.xpath
{
	
	import memorphic.xpath.model.LocationPath;
	import memorphic.xpath.parser.XPathParser;
	import memorphic.xpath.model.XPathContext;
	
	/**
	 *	
	 */
	public class XPathQuery
	{

		private var __path:String;
		
		private var locationPath:LocationPath;
		
		
		public static var defaultContext:XPathContext = new XPathContext();
	

		
		public var context:XPathContext;
		
		
		
		/**
		 * The XPath query to execute
		 */ 
		public function get path():String
		{
			return __path;
		}
		public function set path(src:String):void
		{
			if(src != __path){
				__path = src;
				locationPath = getParser().parseXPath(src);
			}
		}
		
		
		
		/**
		 * 
		 * @param path The XPath statement that will be executed when you call <code>exec</code>
		 * 
		 */		
		public function XPathQuery(path:String, context:XPathContext=null)
		{
			this.path = path;
			if(context == null){
				this.context = defaultContext.copy(true);
			}else{
				this.context = context;
			}
		}


		/**
		 * 
		 * Convenience method. Executes an XPath query on a context.
		 * If you plan to execute the same XPath query multiple times, it is more efficient to create an instance of
		 * <code>XPathQuery</code> and call <code>exec</code> each time, to prevent the path string being parsed
		 * each time.
		 * 
		 * @param xml The root document in which to execute the XPath query
		 * @param path The XPath query string
		 * 
		 * @return An XMLList object of nodes from the context XML, that were matched by the query
		 * 
		 */		
		public static function select(xml:XML, path:String):XMLList
		{
			var query:XPathQuery = new XPathQuery(path);
			return query.exec(xml);
			
		}

		/**
		 * 
		 * @param xml The root document in which to execute the XPath query
		 * @param context An optional context in which just this query will execute. You can use this to define namespaces, variables and functions
		 * 
		 * @return An XMLList object of nodes from the context XML, that were matched by the query
		 * 
		 */		
		public function exec(xml:XML, context:XPathContext=null):XMLList
		{
			if(!context){
				context = this.context;
			}
			return locationPath.execRoot(xml, context);
		}
		
		
		private static function getParser():XPathParser
		{
			// TODO: cache the parser (probably weakly), but some tricky testing is required to make sure it doesn't have side-effects
			var parser:XPathParser;
			//for each(parser in parserLimbo){
			//	
			//	return parser;
			//}
			parser = new XPathParser();
			//parserLimbo[parser] = true;
			return parser;
		}

	}
}