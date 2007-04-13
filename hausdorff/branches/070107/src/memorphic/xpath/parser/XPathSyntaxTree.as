package memorphic.xpath.parser
{
	import flash.errors.EOFError;

	import memorphic.parser.ParseError;
	import memorphic.parser.SyntaxTree;
	import memorphic.parser.SyntaxTreeItem;
	import memorphic.parser.SyntaxTreeState;
	import memorphic.parser.Token;
	import memorphic.parser.Tokenizer;
	import memorphic.parser.TokenizerState;
	import memorphic.xpath.XPathAxes;
	import memorphic.xpath.XPathNodeTypes;

	/**
	 * NOTE: All methods in the "rule" namespace are XPath lexical and grammar rules taken from
	 * W3C XPath 1.0 Recommendation at http://www.w3.org/TR/xpath
	 * or from the W3C XML Namesp	aces 1.0 recommendation http://www.w3.org/TR/REC-xml-names/
	 *
	 * The appropriate specification snippets are shown above each method
	 *
	 * TODO: some optimizations:
	 * 	- where logic is unaffected, re-order the tests to check most common (or quickest) matches first
	 */
	public class XPathSyntaxTree extends SyntaxTree
	{

		public namespace rule = "http://memorphic.com/ns/2007/xpath-grammar";


		// XPath tokens
		public static const LOCATION_PATH:String = "LocationPath";
		public static const ABSOLUTE_LOCATION_PATH:String = "AbsoluteLocationPath";
		public static const RELATIVE_LOCATION_PATH:String = "RelativeLocationPath";
		public static const STEP:String = "Step";
		public static const AXIS_SPECIFIER:String = "AxisSpecifier";
		public static const NODE_TEST:String = "NodeTest";
		public static const PREDICATE:String = "Predicate";
		public static const PREDICATE_EXPR:String = "PredicateExpr";
		public static const ABBREVIATED_ABSOLUTE_LOCATION_PATH:String = "AbbreviatedAbsoluteLocationPath";
		public static const ABBREVIATED_RELATIVE_LOCATION_PATH:String = "AbbreviatedRelativeLocationPath";
		public static const ABBREVIATED_STEP:String = "AbbreviatedStep";
		public static const ABBREVIATED_AXIS_SPECIFIER:String = "AbbreviatedAxisSpecifier";
		public static const EXPR:String = "Expr";
		public static const PRIMARY_EXPR:String = "PrimaryExpr";
		public static const FUNCTION_CALL:String = "FunctionCall";
		public static const ARGUMENT:String = "Argument";
		public static const UNION_EXPR:String = "UnionExpr";
		public static const PATH_EXPR:String = "PathExpr";
		public static const FILTER_EXPR:String = "FilterExpr";
		public static const OR_EXPR:String = "OrExpr";
		public static const AND_EXPR:String = "AndExpr";
		public static const EQUALITY_EXP:String = "EqualityExpr";
		public static const RELATIONAL_EXP:String = "RelationalExpr";
		public static const ADDITIVE_EXPR:String = "AdditiveExpr";
		public static const MULTIPLICATIVE_EXPR:String = "MultiplicativeExpr";
		public static const UNARY_EXPR:String = "UnaryExpr";

		public function XPathSyntaxTree(tokenizer:XPathTokenizer){
			super(tokenizer);
		}

		/**
		 *
		 *
		 */
		public override function getTree():SyntaxTreeItem
		{
			reset();
			var success:Boolean = rule::LocationPath();
			if(!success){
				throw new ParseError("", tokenizer.getTokenMetrics(stack[0]));
			}
			// throw errors if anything went wrong
			verifyTree();
			return super.getTree();
		}


		/**
		 * [1] LocationPath ::=
		 * 			RelativeLocationPath
		 * 			| AbsoluteLocationPath
		 */
		rule function LocationPath():Boolean
		{
			use namespace rule;
			startRule(LOCATION_PATH);
			if(RelativeLocationPath() || AbsoluteLocationPath()){
				return match();
			}
			return didntMatch();
		}




		/**
		 * [2] AbsoluteLocationPath ::=
		 * 			'/' RelativeLocationPath?
		 * 			| AbbreviatedAbsoluteLocationPath
		 */
		rule function AbsoluteLocationPath():Boolean
		{
			use namespace rule;
			startRule(ABSOLUTE_LOCATION_PATH);
			var state:SyntaxTreeState = getState();
			try{
				if(nextToken().value == "/"){
					if(RelativeLocationPath()){
						return match();
					}else{
						return match();
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			restoreState(state);
			if(AbbreviatedAbsoluteLocationPath()){
				return match();
			}
			return didntMatch();
		}




		/**
		 * [3]  RelativeLocationPath ::=
		 *    		Step
		 * 			| RelativeLocationPath '/' Step
		 * 			| AbbreviatedRelativeLocationPath
		 *
		 *
		 * which is equivalent to :
		 *    		(Step | AbbreviatedRelativeLocationPath) ('/' Step)*
		 *
		 * which is equivalent to:
		 *    		Step (('/' | '//') Step)*
		 *
		 */
		rule function RelativeLocationPath():Boolean
		{
			use namespace rule;
			startRule(RELATIVE_LOCATION_PATH);
			if(!Step()){
				return didntMatch();
			}
			var state:SyntaxTreeState;
			while(true){
				state = getState();
				try{
					nextToken();
				}catch(e:EOFError){
					break;
				}
				if((token.value == "/" || token.value == "//")
					&& Step())
				{
					// carry on
				}else{
					break;
				}
			}
			restoreState(state);
			return match();
		}



		/**
		 * [4] Step ::=
		 * 			AxisSpecifier NodeTest Predicate*
		 * 			| AbbreviatedStep
		 */
		rule function Step():Boolean
		{
			use namespace rule;
			startRule(STEP);
			//var state:SyntaxTreeState = getState();
			if(AxisSpecifier()){
				if(NodeTest()){
					while(true){
						if(!Predicate()){
							break;
						}
					}
					return match();
				}
			}
			restartRule(STEP);
			//restoreState(state);
			if(AbbreviatedStep()){
				return match();
			}
			return didntMatch();
		}


		/**
		 * [5] AxisSpecifier ::=
		 * 			AxisName '::'
		 * 			| AbbreviatedAxisSpecifier
		 */
		rule function AxisSpecifier():Boolean
		{
			use namespace rule;
			startRule(AXIS_SPECIFIER);
			//var state:SyntaxTreeState = getState();
			try {
				if(nextToken().tokenType == XPathToken.AXIS_NAME){
					if(nextToken().value == "::"){
						discardToken();
						return match();
					}else{
						throw new SyntaxError("Found Axis name '" + token.value + "' without '::'");
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			//restoreState(state);
			restartRule(AXIS_SPECIFIER);
			if(AbbreviatedAxisSpecifier()){
				return match();
			}
			return didntMatch();
		}






		/**
		 * [7] NodeTest ::=
		 * 			NameTest
		 * 			| NodeType '(' ')'
		 * 			| 'processing-instruction' '(' Literal ')'
		 */
		rule function NodeTest():Boolean
		{
			use namespace rule;
			startRule(NODE_TEST);
			try{
				nextToken();
				if(token.tokenType == XPathToken.NAME_TEST){
					return match();
				}
				if(token.tokenType == XPathToken.NODE_TYPE){
					if(nextToken().value == "("){
						discardToken();
						if(token.value == "processing-instruction"){
							// processing-instruction requires a literal argument
							if(nextToken().tokenType != XPathToken.LITERAL){
								return didntMatch();
							}
						}
						if(nextToken().value == ")"){
							discardToken();
							return match();
						}
					}
				}

			}catch(e:EOFError){
				// didn't match - carry on
			}
			return didntMatch();
		}




		/**
		 * [8] Predicate ::=
		 * 			'[' PredicateExpr ']'
		 */
		rule function Predicate():Boolean
		{
			use namespace rule;
			startRule(PREDICATE);
			try{
				if(nextToken().value == "["){
					discardToken();
					if(PredicateExpr()){
						if(nextToken().value == "]"){
							discardToken();
							return match();
						}
					}

				}

			}catch(e:EOFError){
				// continue - didn't match
		 	}
			return didntMatch();
		}




		/**
		 * [9] PredicateExpr ::=
		 * 			Expr
		 */
		rule function PredicateExpr():Boolean
		{
			use namespace rule;
			startRule(PREDICATE_EXPR);
			if(Expr()){
				return match();
			}
			return didntMatch();
		}



		/**
		 * [10] AbbreviatedAbsoluteLocationPath ::=
		 * 			'//' RelativeLocationPath
		 */
		rule function AbbreviatedAbsoluteLocationPath():Boolean
		{
			use namespace rule;
			startRule(ABBREVIATED_RELATIVE_LOCATION_PATH);
			try{
				if(nextToken().value == "//"){
					if(RelativeLocationPath()){
						return match();
					}
				}
			}catch(e:EOFError){
				// carry on - didn't match
			}
			return didntMatch();
		}


		/**
		 * [11] AbbreviatedRelativeLocationPath	::=
		 * 			RelativeLocationPath '//' Step
		 * 
		 * Note: This rule is merged into RelativeLocationPath() to workaround some circular references
		 * 
		 */
/*		rule function AbbreviatedRelativeLocationPath():Boolean
		{
			use namespace rule;
			startRule(ABBREVIATED_RELATIVE_LOCATION_PATH);
			try{
				if(RelativeLocationPath()){
					if(nextToken().value == "//"){
						if(Step()){
							return match();
						}
					}
				}
			}catch(e:EOFError){
				// carry on - didn't match
			}
			return didntMatch();
		}
*/

		/**
		 * [12] AbbreviatedStep ::=
		 * 		   	'.'
		 * 			| '..'
		 */
		rule function AbbreviatedStep():Boolean
		{
			startRule(ABBREVIATED_STEP);
			try {
				nextToken();
				if(token.value == "." || token.value == ".."){
					return match();
				}
			}catch(e:EOFError){
				// carry on...
			}
			return didntMatch();
		}


		/**
		 * [13] AbbreviatedAxisSpecifier ::=
		 * 		   	'@'?
		 *
		 */
		rule function AbbreviatedAxisSpecifier():Boolean
		{
			startRule(ABBREVIATED_AXIS_SPECIFIER);
			try {
				if(nextToken().value != "@"){
					restartRule(ABBREVIATED_AXIS_SPECIFIER);
				}
			}catch(e:EOFError){
				// carry on
			}
			return match();
		}



		/**
		 * [14] Expr ::=
		 * 			OrExpr
		 *
		 * TODO: Expr and OrExpr can probably be combined
		 */
		rule function Expr():Boolean
		{
			use namespace rule;
			startRule(EXPR);
			if(OrExpr()){
				return match();
			}
			return didntMatch();
		}



		/**
		 * [15] PrimaryExpr ::=
		 * 			VariableReference
		 * 			| '(' Expr ')'
		 * 			| Literal
		 * 			| Number
		 * 			| FunctionCall
		 */
		rule function PrimaryExpr():Boolean
		{
			use namespace rule;
			startRule(PRIMARY_EXPR);

			// changed the order to prevent the need for an extra state reset
			if(FunctionCall()){
				return match();
			}

			try {
				nextToken();
				if(token.tokenType == XPathToken.VARIABLE_REFERENCE){
					return match();
				}
			}catch(e:EOFError){
				return didntMatch();
			}
			if(token.value == "("){
				discardToken();
				try {
					if(Expr() && nextToken().value == ")"){
						discardToken();
						return match();
					}
				}catch(e:EOFError){
					// ran out of tokens so didn't match
				}
				return didntMatch();

			}else if(token.tokenType == XPathToken.LITERAL
				|| token.tokenType == XPathToken.NUMBER){
				return match();
			}
			return didntMatch();
		}



		/**
		 * [16] FunctionCall ::=
		 * 			FunctionName '(' ( Argument ( ',' Argument )* )? ')'
		 *
		 */
		rule function FunctionCall():Boolean
		{
			use namespace rule;
			startRule(FUNCTION_CALL);
			try {
				if(nextToken().tokenType == XPathToken.FUNCTION_NAME){
					if(nextToken().value == "("){
						discardToken();
						if(Argument()){
							while(true){
								// this does not need it's own try/catch because an
								// eof here also means there cannot be a matching ")"
								nextToken();
								if(token.value == "," && Argument()){

								}else{
									break;
								}
							}
						}else{
							nextToken();
						}
						if(token.value == ")"){
							discardToken();
							return match();
						}
					}
				}
			}catch(e:EOFError){
				// didn't match
			}
			return didntMatch();
		}



		/**
		 * [17] Argument ::=
		 * 			Expr
		 */
		rule function Argument():Boolean
		{
			use namespace rule;
			startRule(ARGUMENT);
			if(Expr()){
				return match();
			}
			return didntMatch();
		}


		/**
		 * [18] UnionExpr ::=
		 * 			PathExpr
		 * 			| UnionExpr '|' PathExpr
		 *
		 * which is equivalent to:
		 * 		PathExpr ('|' PathExpr)*
		 */
		rule function UnionExpr():Boolean
		{
			use namespace rule;
			startRule(UNION_EXPR);
			var state:SyntaxTreeState;
			if(!PathExpr()){
				return didntMatch();
			}
			try {
				while(true){
					state = getState();
					if(nextToken().value == "|" && PathExpr()){
					}else{
						break;
					}
				}
			}catch(e:EOFError){
				// no more "|", but it still matches
			}
			restoreState(state);
			return match();
		}


		/**
		 * [19] PathExpr ::=
		 * 			LocationPath
		 * 			| FilterExpr
		 * 			| FilterExpr '/' RelativeLocationPath
		 * 			| FilterExpr '//' RelativeLocationPath
		 *
		 * which is equivalent to:
		 * 			LocationPath
		 * 			| FilterExpr ( ('/' | '//' ) RelativeLocationPath )?
		 *
		 */
		rule function PathExpr():Boolean
		{
			use namespace rule;
			startRule(PATH_EXPR);
			if(LocationPath()){
				return match();
			}
			if(!FilterExpr()){
				return didntMatch();
			}
			var state:SyntaxTreeState = getState();
			try{
				nextToken();
				if(token.value == "/" || token.value == "//"){
					if(RelativeLocationPath()){
						return match();
					}
				}
			}catch(e:EOFError){
				// carry on
			}

			restoreState(state);
			return match();

		}



		/**
		 * [20] FilterExpr ::=
		 * 				PrimaryExpr
		 * 				| FilterExpr Predicate
		 *
		 * which is equivalent to:
		 * 		PrimaryExpr Predicate*
		 */
		rule function FilterExpr():Boolean
		{
			use namespace rule;
			startRule(FILTER_EXPR);
			if(PrimaryExpr()){
			}else{
				return didntMatch();
			}
			while(true){
				if(!Predicate()){
					break;
				}
			}
			return match();
		}



		/**
		 * [21] OrExpr ::=
		 * 			AndExpr
		 * 			| OrExpr 'or' AndExpr
		 *
		 * which is equivalent to:
		 * 			AndExpr ( 'or' AndExpr )*
		 */
		rule function OrExpr():Boolean
		{
			use namespace rule;
			startRule(OR_EXPR);
			if(!AndExpr()){
				return didntMatch();
			}
			var state:SyntaxTreeState;
			try{
				while(true){
					state = getState();
					if(nextToken().value == "or"){
						if(AndExpr() ){

						}else{
							break;
						}
					}else{
						break;
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			restoreState(state);
			return match();
		}



		/**
		 * [22] AndExpr ::=
		 * 			EqualityExpr
		 * 			| AndExpr 'and' EqualityExpr
		 *
		 * which is equivalent to:
		 * 			EqualityExpr ( 'and' EqualityExpr )*
		 */
		rule function AndExpr():Boolean
		{
			use namespace rule;
			startRule(AND_EXPR);
			if(!EqualityExpr()){
				return didntMatch();
			}
			var state:SyntaxTreeState;
			try{
				while(true){
					state = getState();
					if(nextToken().value == "and" && EqualityExpr() ){
					}else{
						break;
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			restoreState(state);
			return match();
		}


		/**
		 * [23] EqualityExpr ::=
		 * 			RelationalExpr
		 * 			| EqualityExpr '=' RelationalExpr
		 * 			| EqualityExpr '!=' RelationalExpr
		 *
		 * which is equivalent to:
		 * 			RelationalExpr ( ( '=' | '!=' ) RelationalExpr )*
		 */
		rule function EqualityExpr():Boolean
		{
			use namespace rule;
			startRule(EQUALITY_EXP);
			if(RelationalExpr()){
			}else{
				return didntMatch();
			}
			var state:SyntaxTreeState;
			try {
				while(true){
					state = getState();
					nextToken();
					if( (token.value == "=" || token.value == "!=")
						&& RelationalExpr()){
						//
					}else{
						break;
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			restoreState(state);
			return match();
		}



		/**
		 * [24] RelationalExpr ::=
		 * 			AdditiveExpr
		 * 			| RelationalExpr '<' AdditiveExpr
		 * 			| RelationalExpr '>' AdditiveExpr
		 * 			| RelationalExpr '<=' AdditiveExpr
		 * 			| RelationalExpr '>=' AdditiveExpr
		 *
		 * which is equivalent to:
		 * 			AdditiveExpr ( ( '<' | '>' | '<=' | '>=') AdditiveExpr)*
		 */
		rule function RelationalExpr():Boolean
		{
			use namespace rule;
			startRule(RELATIONAL_EXP);
			if(!AdditiveExpr()){
				return didntMatch();
			}
			var state:SyntaxTreeState;
			try{
				while(true){
					state = getState();
					nextToken();
					if( (token.value == "<" || token.value == ">" || token.value == "<=" || token.value == ">=")
						&& AdditiveExpr())
					{
					}else{
						break;
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			restoreState(state);
			return match();
		}



		/**
		 * [25] AdditiveExpr ::=
		 *    		MultiplicativeExpr
		 * 			| AdditiveExpr '+' MultiplicativeExpr
		 * 			| AdditiveExpr '-' MultiplicativeExpr
		 *
		 * which is equivalent to:
		 * 			MultiplicativeExpr ( ('+' | '-') MultiplicativeExpr)*
		 */
		rule function AdditiveExpr():Boolean
		{
			use namespace rule;
			startRule(ADDITIVE_EXPR);
			if(!MultiplicativeExpr()){
				return didntMatch();
			}
			var state:SyntaxTreeState;
			try{
				while(true){
					state = getState();
					nextToken();
					if( (token.value == "+" || token.value == "-")
						&& MultiplicativeExpr()){
						//
					}else{
						break;
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			restoreState(state);
			return match();
		}



		/**
		 * [26] MultiplicativeExpr ::=
		 * 			UnaryExpr
		 * 			| MultiplicativeExpr MultiplyOperator UnaryExpr
		 * 			| MultiplicativeExpr 'div' UnaryExpr
		 * 			| MultiplicativeExpr 'mod' UnaryExpr
		 *
		 * which is equivalent to:
		 * 			UnaryExpr ((MultiplyOperator | 'div' | 'mod') UnaryExpr)*
		 */
		rule function MultiplicativeExpr():Boolean
		{
			use namespace rule;
			startRule(MULTIPLICATIVE_EXPR);
			if(!UnaryExpr()){
				return didntMatch();
			}
			//condenseToken();
			var state:SyntaxTreeState;
			try {
				while(true){
					state = getState();
					nextToken();
					if(((/*token.tokenType == XPathToken.OPERATOR && */token.value == "*")
						|| token.value == "div"
						|| token.value == "mod" )
							&& UnaryExpr())
					{
						// condense the UnaryExpr (we only need it if has a "-");
						//condenseToken();
					//	carry on and maybe match more
					}else{
						break;
					}
				}
			}catch(e:EOFError){
				// carry on
			}
			restoreState(state);
			return match();
		}



		/**
		 * [27] UnaryExpr ::=
		 * 			UnionExpr
		 * 			| '-' UnaryExpr
		 *
		 * which is equivalent to:
		 * 			UnionExpr | '-' UnionExpr
		 *
		 * XXX: I am slightly not sure about this simplification - something feels dodgy...
		 */
		rule function UnaryExpr():Boolean
		{
			use namespace rule;
			startRule(UNARY_EXPR);
			if(UnionExpr()){
				return match();
			}
			try{
				if(nextToken().value == "-"){
					if(UnionExpr()){
					//	condenseToken();
						return match();
					}
				}
			}catch(e:EOFError){
				// didn't match so continue...
			}
			return didntMatch();
		}


		/**
		 *
		 */
		protected override function ruleMatched(item:SyntaxTreeItem):void
		{

		}

		/**
		 *
		 */
		protected override function createTreeItem(type:String, children:Array, sourceIndex:int):SyntaxTreeItem
		{
			// XXX: this causes a VerifyError (ie it's an AVM bug)
		//	switch(type){
		 	//case ABBREVIATED_ABSOLUTE_LOCATION_PATH:
		 //		break;
		 //	case ABBREVIATED_AXIS_SPECIFIER:
		 //		break;
		 //	case ABBREVIATED_RELATIVE_LOCATION_PATH:
		 //		break;
		 //	case STEP:
		 //		if(Token(children[0]).tokenType == ABBREVIATED_STEP){
		 //			return expandAbbreviatedStep(children, sourceIndex);
		 //		}
		//	}
			return super.createTreeItem(type, children, sourceIndex);
		}


	}
}