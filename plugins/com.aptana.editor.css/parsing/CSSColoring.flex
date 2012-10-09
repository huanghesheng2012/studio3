// $codepro.audit.disable
/**
 * Aptana Studio
 * Copyright (c) 2005-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the GNU Public License (GPL) v3 (with exceptions).
 * Please see the license.html included with this distribution for details.
 * Any modifications to this file must keep this entire header intact.
 */
package com.aptana.editor.css.parsing;

import java.io.Reader;
import java.io.StringReader;

import com.aptana.editor.css.parsing.lexer.CSSTokenTypeSymbol;
import com.aptana.editor.css.parsing.lexer.CSSTokenType;

import beaver.Scanner;


@SuppressWarnings({"unused", "nls"})
%%

%public
%class CSSColoringFlexScanner
%extends Scanner
%type CSSTokenTypeSymbol
%yylexthrow Scanner.Exception
%eofval{
	return newToken(CSSTokenType.EOF, "end-of-file");
%eofval}
%unicode
%ignorecase
%char

//%switch
//%table
//%pack

%{
	// last token used for look behind. Also needed when implementing the ITokenScanner interface
	private CSSTokenTypeSymbol _lastToken;
	private CSSTokenTypeSymbol lookAhead;

	// curly brace nesting level
	private int _nestingLevel;

	// a flag indicating we're inside of a @media block
	private boolean _inMedia;

	public CSSColoringFlexScanner()
	{
		this((Reader) null);
	}

	public CSSTokenTypeSymbol getLastToken()
	{
		return _lastToken;
	}


    private CSSTokenTypeSymbol newTokenAndLookAhead(CSSTokenType current, CSSTokenType next, int lookAheadLen)
    {
        int right = yychar + yylength() - 1 - lookAheadLen;
        CSSTokenTypeSymbol currentSymbol = new CSSTokenTypeSymbol(
            current, yychar, right, "");
        
        CSSTokenTypeSymbol nextSymbol = new CSSTokenTypeSymbol(
            next, right+1, right + lookAheadLen, "");
            
        lookAhead = nextSymbol;
        return currentSymbol;
    }
    
	private CSSTokenTypeSymbol newToken(CSSTokenType id, Object value)
	{
		return new CSSTokenTypeSymbol(id, yychar, yychar + yylength() - 1, value);
	}

	public CSSTokenTypeSymbol nextToken() throws java.io.IOException, Scanner.Exception
	{
	    if(lookAhead != null){
	       _lastToken = lookAhead;
	       lookAhead = null;
        }
        else{
    		try
    		{
    			// get next token
    			_lastToken = yylex();
    		} 
    		catch (Scanner.Exception e)
    		{
    			// create default token type
    			int end = yychar + yylength() - 1;
    
    			_lastToken = new CSSTokenTypeSymbol(CSSTokenType.EOF, yychar, end, "");
    		}
        }
		return _lastToken;
	}


	public void setSource(String source)
	{
		yyreset(new StringReader(source));

		// clear last token
		_lastToken = null;

		// reset nesting level
		_nestingLevel = 0;
	}
%}

hex							= [0-9a-fA-F]
nonascii					= [\240-\4177777]
unicode						= \\{hex}{1,6}
escape						= {unicode}|\\[^\r\n\f0-9a-fA-F]
nmstart						= [-_a-zA-Z]|{nonascii}|{escape}
nmchar						= [-_a-zA-Z0-9]|{nonascii}|{escape}
double_quoted_string		= \"([^\n\r\f\"]|\\{nl}|{escape})*\"
single_quoted_string		= \'([^\n\r\f\']|\\{nl}|{escape})*\'
bad_double_quoted_string	= \"([^\n\r\f\"]|\\{nl}|{escape})*\\?
bad_single_quoted_string	= \'([^\n\r\f\']|\\{nl}|{escape})*\\?
comment						= "/*" ~"*/"
base_identifier				= -?{nmstart}{nmchar}*
ms_identifier				= "progid:"{base_identifier}(\.{base_identifier})*
identifier					= {base_identifier}|{ms_identifier}
name						= {nmchar}+
num							= [-+]?([0-9]+|[0-9]*\.[0-9]+)
s							= [ \t\r\n\f]+
nl							= \r|\n|\r\n|\f

%%

<YYINITIAL> {
	{s}							{ /* ignore */ }
	{comment}					{ /* ignore */ }

	{single_quoted_string}		{ return newToken(CSSTokenType.SINGLE_QUOTED_STRING, ""); }
	{double_quoted_string}		{ return newToken(CSSTokenType.DOUBLE_QUOTED_STRING, ""); }
	{bad_single_quoted_string}	{ return newToken(CSSTokenType.SINGLE_QUOTED_STRING, ""); }
	{bad_double_quoted_string}	{ return newToken(CSSTokenType.DOUBLE_QUOTED_STRING, ""); }

	"not"                      { return newToken(CSSTokenType.NOT, ""); }
	
	{num}"em"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.EMS, 2); }
	{num}"ex"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.EXS, 2); }
	{num}"px"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.LENGTH, 2); }
	{num}"cm"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.LENGTH, 2); }
	{num}"mm"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.LENGTH, 2); }
	{num}"in"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.LENGTH, 2); }
	{num}"pt"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.LENGTH, 2); }
	{num}"pc"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.LENGTH, 2); }
	{num}"deg"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.ANGLE, 3); }
	{num}"rad"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.ANGLE, 3); }
	{num}"grad"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.ANGLE, 4); }
	{num}"ms"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.TIME, 2); }
	{num}"s"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.TIME, 1); }
	{num}"hz"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.FREQUENCY, 2); }
	{num}"khz"					{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.FREQUENCY, 3); }
//	{num}{identifier}			{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.DIMENSION, calculate??); }
	{num}%						{ return newTokenAndLookAhead(CSSTokenType.NUMBER, CSSTokenType.PERCENTAGE, 1); }
	{num}						{ return newToken(CSSTokenType.NUMBER, ""); }
	
	"."{name}					{
									CSSTokenType type;

									if ((_inMedia && _nestingLevel == 1) || _nestingLevel <= 0)
									{
										type = CSSTokenType.CLASS;
									}
									else
									{
										boolean numbers = true;
										String text = yytext();
										int len = text.length();

										for (int i = 1; i < len; i++)
										{
											char c = text.charAt(i);

											if (c < '0' || '9' < c)
											{
												numbers = false;
												break;
											}
										}

										type = (numbers) ? CSSTokenType.NUMBER : CSSTokenType.CLASS;
									}

									return newToken(type, "");
								}
	"#"{name}					{
									CSSTokenType type;

									if ((_inMedia && _nestingLevel == 1) || _nestingLevel <= 0)
									{
										type = CSSTokenType.ID;
									}
									else
									{
										boolean numbers = true;
										String text = yytext();
										int len = text.length();

										for (int i = 1; i < len; i++)
										{
											char c = text.charAt(i);

											if (!('0' <= c && c <= '9' || 'a' <= c && c <= 'f' || 'A' <= c && c <= 'F'))
											{
												numbers = false;
												break;
											}
										}

										type = (numbers) ? CSSTokenType.RGB : CSSTokenType.ID;
									}

									return newToken(type, "");
								}

	"@import"					{ return newToken(CSSTokenType.IMPORT, ""); }
	"@page"						{ return newToken(CSSTokenType.PAGE, ""); }
	"@media"					{ _inMedia = true; return newToken(CSSTokenType.MEDIA_KEYWORD, ""); }
	"@charset"					{ return newToken(CSSTokenType.CHARSET, ""); }
	"@font-face"				{ return newToken(CSSTokenType.FONTFACE, ""); }
	"@namespace"				{ return newToken(CSSTokenType.NAMESPACE, ""); }
	"@-moz-document"			{ return newToken(CSSTokenType.MOZ_DOCUMENT, ""); }
	"@"{name}					{ return newToken(CSSTokenType.AT_RULE, ""); }

	"!"({s}|{comment})*"important"	{ return newToken(CSSTokenType.IMPORTANT, ""); }

//	"<!--"						{ return newToken(CSSTokenType.CDO, ""); }
//	"-->"						{ return newToken(CSSTokenType.CDC, ""); }
	"~="						{ return newToken(CSSTokenType.INCLUDES, ""); }
	"|="						{ return newToken(CSSTokenType.DASHMATCH, ""); }
	"^="						{ return newToken(CSSTokenType.BEGINS_WITH, ""); }
	"$="						{ return newToken(CSSTokenType.ENDS_WITH, ""); }

	":"							{ return newToken(CSSTokenType.COLON, ""); }
	";"							{ return newToken(CSSTokenType.SEMICOLON, ""); }
	"{"							{
									_nestingLevel++;

									return newToken(CSSTokenType.LCURLY, "");
								}
	"}"							{
									_nestingLevel--;

									if (_nestingLevel == 0)
									{
										// reset (possibly set) media flag
										_inMedia = false;
									}

									return newToken(CSSTokenType.RCURLY, "");
								}
	"("							{ return newToken(CSSTokenType.LPAREN, ""); }
	")"							{ return newToken(CSSTokenType.RPAREN, ""); }
	"%"							{ return newToken(CSSTokenType.PERCENTAGE, ""); }
	"["							{ return newToken(CSSTokenType.LBRACKET, ""); }
	"]"							{ return newToken(CSSTokenType.RBRACKET, ""); }
	","							{ return newToken(CSSTokenType.COMMA, ""); }
	"+"							{ return newToken(CSSTokenType.PLUS, ""); }
	"*"							{ return newToken(CSSTokenType.STAR, ""); }
	">"							{ return newToken(CSSTokenType.GREATER, ""); }
	"/"							{ return newToken(CSSTokenType.SLASH, ""); }
	"="							{ return newToken(CSSTokenType.EQUAL, ""); }
	"-"							{ return newToken(CSSTokenType.MINUS, ""); }


	{identifier}				{ return newToken(CSSTokenType.IDENTIFIER, yytext()); }
}

.|\n	{ return newToken(CSSTokenType.ERROR, ""); }
