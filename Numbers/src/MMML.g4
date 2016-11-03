grammar MMML;

@header {
package parser.src;
import java.util.*;
}

/*options {
   language=CSharp_v4_5;
}*/

/*
Programa: Declarações de funções e uma função main SEMPRE

def fun x = x + 1

def main =
  let x = read_int
  in
     print concat "Resultado" (string (fun x))
*/

WS : [ \r\t\u000C\n]+ -> channel(HIDDEN)
    ;

COMMENT : '//' ~('\n'|'\r')* '\r'? '\n' -> channel(HIDDEN);

program
    : fdecls maindecl {System.out.println("Parseou um programa!");}
    ;

fdecls
    : fdecl fdecls                                   #fdecls_one_decl_rule
    |                                                #fdecls_end_rule
    ;

maindecl: 'def' 'main' '=' funcbody                  #programmain_rule
    ;

fdecl: 'def' functionname fdeclparams '=' funcbody   #funcdef_rule
        /*{
            System.Console.WriteLine("Achou declaração: {0} com {1}", $functionname.text, $fdeclparams.plist.ToString());
        }*/
    ;

fdeclparams
returns [List<String> plist]
@init {
    $plist = new ArrayList<String>();
}
@after {
    for (String s : $plist) {
        System.out.println("Parametro: " + s);
    }
}
    :   fdeclparam
        {
            $plist.add($fdeclparam.pname);
        }
        fdeclparams_cont[$plist]

                                                     #fdeclparams_one_param_rule
    |                                                #fdeclparams_no_params
    ;

fdeclparams_cont[List<String> plist]
    : ',' fdeclparam
        {
            $plist.add($fdeclparam.pname);
        }
        fdeclparams_cont[$plist]
                                                     #fdeclparams_cont_rule
    |                                                #fdeclparams_end_rule
    ;

fdeclparam
    returns [String pname, String ptype]
    : symbol ':' type
        {
            $pname = $symbol.text;
            $ptype = $type.text;
        }
        #fdecl_param_rule
    ;

functionname: TOK_ID                                 #fdecl_funcname_rule
    ;

type:
        basic_type                                   #basictype_rule
    |   sequence_type
        /*
        {
            System.out.println("Variavel do tipo " + $sequence_type.base + " dimensao "+ $sequence_type.dimension);
        }
        */
                                                    #sequencetype_rule
    ;

basic_type
    : 'int'
    | 'bool'
    | 'str'
    | 'float'
    | 'char'
    ;

sequence_type
returns [int dimension=0, String base]
    :   basic_type '[]'
        {
            $dimension = 1;
            $base = $basic_type.text;
        }

                                                     #sequencetype_basetype_rule
    |   s=sequence_type '[]'
        {
            $dimension = $s.dimension + 1;
            $base = $s.base;
        }
                                                     #sequencetype_sequence_rule
    ;

funcbody
returns [String pTipoFinal]
@init {
    $pTipoFinal = "";
}
@after {
    System.out.println(" -> funcbody: " + $pTipoFinal);
}
	:
        ifexpr                                       #fbody_if_rule
    |   letexpr                                      #fbody_let_rule
    |   metaexpr 
    	{ 
    		$pTipoFinal = $metaexpr.pTipo;
    	}  #fbody_expr_rule
    ;

ifexpr
    : 'if' funcbody 'then' funcbody 'else' funcbody  #ifexpression_rule
    ;

letexpr
    : 'let' letlist 'in' funcbody                    #letexpression_rule
    ;

letlist
    : letvarexpr  letlist_cont                       #letlist_rule
    ;

letlist_cont
    : ',' letvarexpr letlist_cont                    #letlist_cont_rule
    |                                                #letlist_cont_end
    ;

letvarexpr
    :    symbol '=' funcbody                         #letvarattr_rule
    |    '_'    '=' funcbody                         #letvarresult_ignore_rule
    |    symbol '::' symbol '=' funcbody             #letunpack_rule
    ;

metaexpr_right
returns [String pTipo]
@after{
	System.out.println(" -> metaexpr_right: " + $pTipo);
}
	:	metaexpr { $pTipo = $metaexpr.pTipo; };

metaexpr
returns [String pRule, String pTipo]
@init {
    System.out.println("------------");
    String v1 = null;
    String v2 = null;
}
@after{
	System.out.println(" ## v1: " + v1);
	System.out.println(" ## v2: " + v2);

	if (v1 == null)
		v1 = $pTipo;
	if (v2 == null)
		v2 = "";
	
	if (v1.equals("string") || v2.equals("string")) {
		$pTipo = "string";
	}
	else if (v1.equals("char") || v2.equals("char")) {
		$pTipo = "char";
	}
	else if (v1.equals("bool") || v2.equals("bool")) {
		$pTipo = "bool";
	}
	else if (v1.equals("float") || v2.equals("float")) {
		$pTipo = "float";
	}
	else {
		$pTipo = v1;
	}

	System.out.println(" =>> metaexpr: " + $pRule + " : Tipo: " + $pTipo);
}
    : '(' funcbody ')'                  { v1 = $funcbody.pTipoFinal; $pRule = "(funcbody)"; }             #me_exprparens_rule     // Anything in parenthesis -- if, let, funcion call, etc
    | sequence_expr                                  #me_list_create_rule    // creates a list [x]
    | TOK_NEG symbol                    { v1 = "bool"; }             #me_boolneg_rule        // Negate a variable
    | TOK_NEG '(' funcbody ')'          { v1 = "bool"; }             #me_boolnegparens_rule  //        or anything in between ( )
    | metaexpr TOK_POWER metaexpr_right { v2 = $metaexpr_right.pTipo; $pTipo = v2;}                  #me_exprpower_rule      // Exponentiation
    | metaexpr TOK_CONCAT metaexpr_right                   #me_listconcat_rule     // Sequence concatenation
    | metaexpr TOK_DIV_OR_MUL metaexpr_right { v2 = $metaexpr_right.pTipo; $pTipo = v2;}   	               #me_exprmuldiv_rule     // Div and Mult are equal
    | metaexpr TOK_PLUS_OR_MINUS metaexpr_right { v2 = $metaexpr_right.pTipo; $pTipo = v2;}            #me_exprplusminus_rule  // Sum and Sub are equal
    | metaexpr TOK_CMP_GT_LT metaexpr_right   { v1 = "bool"; $pRule = "a TOK_CMP_GT_LT b"; }             #me_boolgtlt_rule       // < <= >= > are equal
    | metaexpr TOK_CMP_EQ_DIFF metaexpr_right { v1 = "bool"; $pRule = "a TOK_CMP_EQ_DIFF b"; }             #me_booleqdiff_rule     // == and != are egual
    | metaexpr TOK_BOOL_AND_OR metaexpr_right { v1 = "bool"; $pRule = "a TOK_BOOL_AND_OR b"; }             #me_boolandor_rule      // &&   and  ||  are equal
    | symbol                                         #me_exprsymbol_rule     // a single symbol
    | literal                           
    	{
    		if (v1 == null) {
    			v1 = $literal.pTipo;
    		}
    		else {
				v2 = $literal.pTipo;
    		}
    		
    		$pTipo = $literal.pTipo;
    	}             #me_exprliteral_rule    // literal value
    | funcall                                        #me_exprfuncall_rule    // a funcion call
    | cast  { v1 = $cast.pTipo; $pRule = "cast"; }                                         #me_exprcast_rule       // cast a type to other
    ;

sequence_expr
    : '[' funcbody ']'                               #se_create_seq
    ;

funcall: symbol funcall_params                       #funcall_rule
        /*{
            System.Console.WriteLine("Uma chamada de funcao! {0}", $symbol.text);
        }*/
    ;

cast
returns [String pTipo]
    : type funcbody  { $pTipo = $type.text; System.out.println(" -> cast: " + $pTipo); }                                #cast_rule
    ;

funcall_params
    :   metaexpr funcall_params_cont                    #funcallparams_rule
    |   '_'                                             #funcallnoparam_rule
    ;

funcall_params_cont
    : metaexpr funcall_params_cont                      #funcall_params_cont_rule
    |                                                   #funcall_params_end_rule
    ;

literal
returns [String pRule, String pTipo] 
@after {
	System.out.println(" =>> literal: " + $pRule + " : Tipo: " + $pTipo);
}
	: 
        'nil'   {$pTipo = "null"; $pRule = "nil";}                                        #literalnil_rule
    |   'true'  {$pTipo = "bool"; $pRule = "true";}                                        #literaltrue_rule
    |   'false' {$pTipo = "bool"; $pRule = "false";}                                         #literaltrue_rule
    |   number 	{$pTipo = $number.pTipo; $pRule = "number";}	 									#literalnumber_rule
    |   strlit  {$pTipo = "string"; $pRule = "strlit";}                                        #literalstring_rule
    |   charlit {$pTipo = "char";  $pRule = "charlit";}                                        #literal_char_rule
    ;

strlit: TOK_STR_LIT
    ;

charlit
    : TOK_CHAR_LIT
    ;

number
returns [String pRule, String pTipo]
@after {
	System.out.println(" =>> number: " + $pRule + " : Tipo: " + $pTipo);
}
	:
        FLOAT {$pTipo = "float"; $pRule = "FLOAT";} #numberfloat_rule
    |   DECIMAL {$pTipo = "int"; $pRule = "DECIMAL";} #numberdecimal_rule
    |   HEXADECIMAL {$pTipo = "int"; $pRule = "HEXADECIMAL";} #numberhexadecimal_rule
    |   BINARY {$pTipo = "int"; $pRule = "BINARY";} #numberbinary_rule
    
                ;

symbol: TOK_ID                                          #symbol_rule
    ;


// id: begins with a letter, follows letters, numbers or underscore
TOK_ID: [a-zA-Z]([a-zA-Z0-9_]*);

TOK_CONCAT: '::' ;
TOK_NEG: '!';
TOK_POWER: '^' ;
TOK_DIV_OR_MUL: ('/'|'*');
TOK_PLUS_OR_MINUS: ('+'|'-');
TOK_CMP_GT_LT: ('<='|'>='|'<'|'>');
TOK_CMP_EQ_DIFF: ('=='|'!=');
TOK_BOOL_AND_OR: ('&&'|'||');

TOK_REL_OP : ('>'|'<'|'=='|'>='|'<=') ;

TOK_STR_LIT
  : '"' (~[\"\\\r\n] | '\\' (. | EOF))* '"'
  ;


TOK_CHAR_LIT
    : '\'' (~[\'\n\r\\] | '\\' (. | EOF)) '\''
    ;

FLOAT : '-'? DEC_DIGIT+ '.' DEC_DIGIT+([eE][\+-]? DEC_DIGIT+)? ;

DECIMAL : '-'? DEC_DIGIT+ ;

HEXADECIMAL : '0' 'x' HEX_DIGIT+ ;

BINARY
: BIN_DIGIT+ 'b'; // Sequencia de digitos seguida de b  10100b

fragment
BIN_DIGIT : [01];

fragment
HEX_DIGIT : [0-9A-Fa-f];

fragment
DEC_DIGIT : [0-9] ;
