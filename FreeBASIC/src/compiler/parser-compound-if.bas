''	FreeBASIC - 32-bit BASIC Compiler.
''	Copyright (C) 2004-2006 Andre Victor T. Vicentini (av1ctor@yahoo.com.br)
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


'' IF..ELSE..ELSEIF..END IF compound statement parsing (single and multi-line)
''
'' chng: sep/2004 written [v1ctor]

option explicit
option escape

#include once "inc\fb.bi"
#include once "inc\fbint.bi"
#include once "inc\parser.bi"
#include once "inc\ast.bi"

'':::::
''SingleIfStatement=  !(COMMENT|NEWLINE|STATSEP) NUM_LIT | Statement*)
''                    (ELSE Statement*)?
''
private function hIfSingleLine _
	( _
		byval stk as FB_CMPSTMTSTK ptr _
	) as integer

	dim as FBSYMBOL ptr l

	function = FALSE

	stk->if.issingle = TRUE

	'' NUM_LIT | Statement*
	if( lexGetClass( ) = FB_TKCLASS_NUMLITERAL ) then
		l = symbFindByClass( lexGetSymChain( ), FB_SYMBCLASS_LABEL )
		if( l = NULL ) then
			l = symbAddLabel( lexGetText( ), FALSE, TRUE )
		end if
		lexSkipToken( )

		astAdd( astNewBRANCH( AST_OP_JMP, l ) )

	elseif( cStatement( ) = FALSE ) then
		if( hGetLastError( ) <> FB_ERRMSG_OK ) then
			exit function
		end if
	end if

	'' (ELSE Statement*)?
	if( hMatch( FB_TK_ELSE ) ) then
		'' exit if stmt
		astAdd( astNewBRANCH( AST_OP_JMP, stk->if.endlabel ) )

		'' emit next label
		astAdd( astNewLABEL( stk->if.nxtlabel ) )

		'' Statement|IF*
		if( cStatement( ) = FALSE ) then
			exit function
		end if

		if( hGetLastError( ) <> FB_ERRMSG_OK ) then
			exit function
		end if

		'' emit end label
		astAdd( astNewLABEL( stk->if.endlabel ) )

	else
		'' emit next label
		astAdd( astNewLABEL( stk->if.nxtlabel ) )
	end if

	'' END IF? -- added to make complex macros easier to be done
	select case lexGetToken( )
	case FB_TK_END
		if( lexGetLookAhead(1) = FB_TK_IF ) then
			lexSkipToken( )
			lexSkipToken( )
		end if

	case FB_TK_ENDIF
		lexSkipToken( )
	end select

	'' pop from stmt stack
	cCompStmtPop( stk )

	function = TRUE

end function

'':::::
''IfStmtBegin	  =   IF Expression THEN (BlockIfStatement | SingleIfStatement) .
''
function cIfStmtBegin as integer
	dim as ASTNODE ptr expr
	dim as FBSYMBOL ptr nl, el
	dim as FB_CMPSTMTSTK ptr stk

	function = FALSE

	'' IF
	lexSkipToken( )

    '' Expression
    if( cExpression( expr ) = FALSE ) then
    	if( hReportError( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    		exit function
		else
			'' error recovery: fake an expr
			expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
		end if
    end if

	'' add end label (at ENDIF)
	el = symbAddLabel( NULL, FALSE )
	'' and next label (at ELSE/ELSEIF)
	nl = symbAddLabel( NULL, FALSE )

	'' branch
	expr = astUpdComp2Branch( expr, nl, FALSE )
	if( expr = NULL ) then
		if( hReportError( FB_ERRMSG_INVALIDDATATYPES ) = FALSE ) then
			exit function
		end if

	else
		astAdd( expr )
	end if

	'' push to stmt stack
	stk = cCompStmtPush( FB_TK_IF )
	stk->if.issingle = FALSE
	stk->if.nxtlabel = nl
	stk->if.endlabel = el
	stk->if.elsecnt = 0

	'' GOTO?
	if( lexGetToken( ) = FB_TK_GOTO ) then
		return hIfSingleLine( stk )
	end if

	'' THEN?
	if( lexGetToken( ) <> FB_TK_THEN ) then
		if( hReportError( FB_ERRMSG_EXPECTEDTHEN ) = FALSE ) then
			cCompStmtPop( stk )
			exit function
		end if
	else
		lexSkipToken( )
	end if

	select case lexGetToken( )
	'' COMMENT|NEWLINE?
	case FB_TK_COMMENTCHAR, FB_TK_REM, FB_TK_EOL, FB_TK_STATSEPCHAR

	case else
		return hIfSingleLine( stk )
	end select

	function = TRUE

end function

'':::::
''IfStmtNext	=     ELSEIF Expression THEN
''              |     ELSE .
''
function cIfStmtNext(  ) as integer
	dim as ASTNODE ptr expr
	dim as FB_CMPSTMTSTK ptr stk

	function = FALSE

	stk = cCompStmtGetTOS( FB_TK_IF, FALSE )
	if( stk = NULL ) then
		if( lexGetToken( ) = FB_TK_ELSEIF ) then
			hReportError( FB_ERRMSG_ELSEIFWITHOUTIF )
		else
			hReportError( FB_ERRMSG_ELSEWITHOUTIF )
		end if
		exit function
	end if

	'' single line? don't process
	if( stk->if.issingle ) then
		return TRUE
	end if

    '' ELSE already parsed?
    if( stk->if.elsecnt <> 0 ) then
    	if( hReportError( FB_ERRMSG_EXPECTEDENDIF ) = FALSE ) then
    		exit function
    	end if
    end if

	'' ELSEIF Expression THEN ?
    select case lexGetToken( )
    case FB_TK_ELSEIF
    	lexSkipToken( )

		'' exit last if stmt
		astAdd( astNewBRANCH( AST_OP_JMP, stk->if.endlabel ) )

		'' emit next label
		astAdd( astNewLABEL( stk->if.nxtlabel ) )

		'' add next label (at ELSE/ELSEIF)
		stk->if.nxtlabel = symbAddLabel( NULL, FALSE )

	    '' Expression
    	if( cExpression( expr ) = FALSE ) then
    		if( hReportError( FB_ERRMSG_EXPECTEDEXPRESSION ) = FALSE ) then
    			exit function
			else
				'' error recovery: fake an expr
				expr = astNewCONSTi( 0, FB_DATATYPE_INTEGER )
			end if
    	end if

		'' THEN
		if( hMatch( FB_TK_THEN ) = FALSE ) then
			if( hReportError( FB_ERRMSG_EXPECTEDTHEN ) = FALSE ) then
				exit function
			end if
		end if

		'' branch
		expr = astUpdComp2Branch( expr, stk->if.nxtlabel, FALSE )
		if( expr = NULL ) then
			if( hReportError( FB_ERRMSG_INVALIDDATATYPES ) = FALSE ) then
				exit function
			end if

		else
			astAdd( expr )
		end if

    '' ELSE?
    case FB_TK_ELSE
    	stk->if.elsecnt += 1

    	lexSkipToken( )

		'' exit last if stmt
		astAdd( astNewBRANCH( AST_OP_JMP, stk->if.endlabel ) )

		'' emit next label
		if( stk->if.nxtlabel <> NULL ) then
			astAdd( astNewLABEL( stk->if.nxtlabel ) )
			stk->if.nxtlabel = NULL
		end if

	end select

	function = TRUE

end function

'':::::
''IfStmtEnd	  =   END IF | ENDIF .
''
function cIfStmtEnd as integer
	dim as FB_CMPSTMTSTK ptr stk

	function = FALSE

	stk = cCompStmtGetTOS( FB_TK_IF )
	if( stk = NULL ) then
		exit function
	end if

	'' single line? don't process
	if( stk->if.issingle ) then
		return TRUE
	end if

	'' ENDIF or END IF
	if( lexGetToken() = FB_TK_END ) then
		lexSkipToken( )
	end if
	lexSkipToken( )

	'' emit next label
	if( stk->if.nxtlabel <> NULL ) then
		astAdd( astNewLABEL( stk->if.nxtlabel ) )
	end if

	'' emit end label
	astAdd( astNewLABEL( stk->if.endlabel ) )

	'' pop from stmt stack
	cCompStmtPop( stk )

end function
