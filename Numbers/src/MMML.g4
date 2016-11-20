grammar MMML;

@header {
package parser.src;
import java.util.*;
import java.util.Map.Entry;
}

@members {
	private Map<String, String> tabelaSimbolos = new HashMap<>();
	private List<String> warningMessages = new ArrayList<>();
	private List<String> errorMessages = new ArrayList<>();
	
	private NestedSymbolTable symbolTable = new NestedSymbolTable<Object>(); 
	
	private int callCount = 0;
	
	private <T, E> T getKeyByValue(Map<T, E> map, E value) {
    	for (Entry<T, E> entry : map.entrySet()) {
        	if (Objects.equals(value, entry.getValue())) {
            	return entry.getKey();
        	}
    	}
    	return null;
	}
	
	private void printErrors() {

		System.out.println(String.format("%d erros encontrados. ", errorMessages.size()));
		
		for (String str : errorMessages) {
			System.out.println(String.format("\t> %s%s", "[ ERROR ]", str));
		}
	}
	
	private void printWarnings() {

		System.out.println(String.format("%d warnings encontrados. ", warningMessages.size()));
		
		for (String str : warningMessages) {
			System.out.println(String.format("\t> %s%s", "[WARNING]", str));
		}
	}
	
	private String validarExponenciacao(String tL, String tR) {
		if ((tL.equals("i") && tR.equals("i")) ||
			(tL.equals("f") && tR.equals("i")) ||
			(tL.equals("i") && tR.equals("f")) ||
			(tL.equals("f") && tR.equals("f"))) {
			return "f";
		}
		else {
			errorMessages.add(String.format("Operação de exponenciação com tipo errados: %s ^ %s", tabelaSimbolos.get(tL), tabelaSimbolos.get(tR)));
			return "f";
		}
	}
	
	private String validarASDM(String tL, String tR) {
		if ((tL.equals("i") && tR.equals("i"))) {
			return "i";
		}
		else if ((tL.equals("f") && tR.equals("i")) ||
				 (tL.equals("i") && tR.equals("f")) ||
				 (tL.equals("f") && tR.equals("f"))) {
			return "f";
		}
		else {
			errorMessages.add(String.format("Operação aritmética com tipo errados: %s e %s", tabelaSimbolos.get(tL), tabelaSimbolos.get(tR)));
			
			if ((tL.equals("i") || tL.equals("f"))) {
				return tL;
			}
			else if ((tR.equals("i") || tR.equals("f"))) {
				return tR;
			}
			else {
				return tL;
			}
		}
	}
	
	private void adicionaSimbolo(NestedSymbolTable table, String symbolName, String tipo) {
	
		if (tipo.equals("i")) {
			NestedSymbolTable<Integer> nt = new NestedSymbolTable<Integer>(table);
			nt.store(symbolName, 0);
		}
		else if (tipo.equals("f")) {
			NestedSymbolTable<Float> nt = new NestedSymbolTable<Float>(table);
			nt.store(symbolName, 0f);
		}
		else if (tipo.equals("b")) {
			NestedSymbolTable<Boolean> nt = new NestedSymbolTable<Boolean>(table);
			nt.store(symbolName, true);
		}
		else if (tipo.equals("s")) {
			NestedSymbolTable<String> nt = new NestedSymbolTable<String>(table);
			nt.store(symbolName, "");
		}
		else if (tipo.equals("c")) {
			NestedSymbolTable<Character> nt = new NestedSymbolTable<Character>(table);
			nt.store(symbolName, ' ');
		}
	} 
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
            $plist.add($fdeclparam.pName);
        }
        fdeclparams_cont[$plist]

                                                     #fdeclparams_one_param_rule
    |                                                #fdeclparams_no_params
    ;

fdeclparams_cont[List<String> plist]
    : ',' fdeclparam
        {
            $plist.add($fdeclparam.pName);
        }
        fdeclparams_cont[$plist]
                                                     #fdeclparams_cont_rule
    |                                                #fdeclparams_end_rule
    ;

fdeclparam
    returns [String pName, String pType]
    : symbol ':' type
        {
            $pName = $symbol.text;
            $pType = $type.text;
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
returns [String pTipo, String pValue]
	:
        ifexpr                                       #fbody_if_rule
    |   letexpr                                      #fbody_let_rule
    |   metaexpr { 
    		$pTipo = $metaexpr.pTipo;
    		$pValue = $metaexpr.pValue;
    	}  #fbody_expr_rule
    ;

ifexpr
    : 'if' funcbody 'then' funcbody 'else' funcbody  #ifexpression_rule
    ;

letexpr
    : 'let' letlist[symbolTable] 'in' funcbody                    #letexpression_rule
    ;

letlist[NestedSymbolTable sTable]
    : letvarexpr[sTable]  letlist_cont[sTable]                       #letlist_rule
    ;

letlist_cont[NestedSymbolTable sTable]
    : ',' letvarexpr[sTable] letlist_cont[sTable]                    #letlist_cont_rule
    |                                                #letlist_cont_end
    ;

letvarexpr[NestedSymbolTable sTable]
    :    symbol '=' funcbody { System.out.println(String.format("Adicionando: %s - %s", $symbol.text, $funcbody.pTipo)); adicionaSimbolo(sTable, $symbol.text, $funcbody.pTipo); }                        #letvarattr_rule
    |    '_'    '=' funcbody                         #letvarresult_ignore_rule
    |    symbol '::' symbol '=' funcbody             #letunpack_rule
    ;

metaexpr
returns [String pRule, String pTipo, String pValue, String pName]
@init {
    callCount++;
    
    if (tabelaSimbolos.isEmpty()) {//Se a tabela está vazia, carrega
    	tabelaSimbolos.put("i", "int");
    	tabelaSimbolos.put("f", "float");
    	tabelaSimbolos.put("s", "string");
    	tabelaSimbolos.put("c", "char");
    	tabelaSimbolos.put("b", "bool");
    	tabelaSimbolos.put("n", "null");
    }
        
    String tL = null;
    String tR = null;
    String vL = null;
    String vR = null;
    
    String vOperacao = null;
}
@after{
	
	callCount--;
	
	if ($pRule.equals("TOK_POWER")) {
		$pTipo = validarExponenciacao(tL, tR);
	}
	else if ($pRule.equals("TOK_DIV_OR_MUL") ||
			 $pRule.equals("TOK_PLUS_OR_MINUS")) {
		$pTipo = validarASDM(tL, tR);
	}
	else if ($pRule.equals("TOK_BOOL_AND_OR")) {
		$pTipo = "b";
		if (!tL.equals("b") || !tR.equals("b")) {
			errorMessages.add(String.format("Operação booleana entre tipos incompatíveis: %s %s %s", tabelaSimbolos.get(tL), vOperacao, tabelaSimbolos.get(tR)));
		}
	}
	else if ($pRule.equals("TOK_CMP_GT_LT") || $pRule.equals("TOK_CMP_EQ_DIFF")) {
		$pTipo = "b";
	}
	else if ($pRule.equals("TOK_CMP_GT_LT") || $pRule.equals("TOK_CMP_EQ_DIFF")) {
		$pTipo = "b";
	}
	else if ($pRule.equals("TOK_NEG")) {
		$pTipo = "b";
	}
	else if ($pRule.equals("TOK_CONCAT")) {
		if (!tL.equals("s") || !tR.equals("s")) {
			errorMessages.add(String.format("Operação de concatenação entre tipos incompatíveis: %s %s %s", tabelaSimbolos.get(tL), vOperacao, tabelaSimbolos.get(tR)));
		}
		$pTipo = "s";
	}
	
	
	if (callCount == 0) {
		System.out.println("------------------------------------------------------------");
		System.out.println("Tipo final: " + tabelaSimbolos.get($pTipo));
		System.out.println("------------------------------------------------------------");
		printErrors();
		printWarnings();
	}
}
    : '(' funcbody ')'                  { $pTipo = $funcbody.pTipo; $pRule = "(funcbody)"; }             #me_exprparens_rule     // Anything in parenthesis -- if, let, funcion call, etc
    | sequence_expr                                  #me_list_create_rule    // creates a list [x]
    | TOK_NEG symbol                    { $pRule = "TOK_NEG"; }             #me_boolneg_rule        // Negate a variable
    | TOK_NEG '(' funcbody ')'          { $pRule = "TOK_NEG"; $pTipo = $funcbody.pTipo; }             #me_boolnegparens_rule  //        or anything in between ( )
    | m1=metaexpr TOK_POWER m2=metaexpr { tL = $m1.pTipo; tR = $m2.pTipo; $pRule = "TOK_POWER"; }                  #me_exprpower_rule      // Exponentiation
    | m1=metaexpr TOK_CONCAT m2=metaexpr { tL = $m1.pTipo; tR = $m2.pTipo; $pRule = "TOK_CONCAT"; vOperacao = $TOK_CONCAT.text; }                   #me_listconcat_rule     // Sequence concatenation
    | m1=metaexpr TOK_DIV_OR_MUL m2=metaexpr { tL = $m1.pTipo; tR = $m2.pTipo; $pRule = "TOK_DIV_OR_MUL"; }   	               #me_exprmuldiv_rule     // Div and Mult are equal
    | m1=metaexpr TOK_PLUS_OR_MINUS m2=metaexpr { tL = $m1.pTipo; tR = $m2.pTipo; $pRule = "TOK_PLUS_OR_MINUS"; }            #me_exprplusminus_rule  // Sum and Sub are equal
    | m1=metaexpr TOK_CMP_GT_LT m2=metaexpr   { tL = $m1.pTipo; tR = $m2.pTipo; $pRule = "TOK_CMP_GT_LT"; }             #me_boolgtlt_rule       // < <= >= > are equal
    | m1=metaexpr TOK_CMP_EQ_DIFF m2=metaexpr { tL = $m1.pTipo; tR = $m2.pTipo; $pRule = "TOK_CMP_EQ_DIFF"; }             #me_booleqdiff_rule     // == and != are egual
    | m1=metaexpr TOK_BOOL_AND_OR m2=metaexpr { tL = $m1.pTipo; tR = $m2.pTipo; $pRule = "TOK_BOOL_AND_OR"; vOperacao = $TOK_BOOL_AND_OR.text; }             #me_boolandor_rule      // &&   and  ||  are equal
    | symbol  { $pName = $symbol.text; }                                       #me_exprsymbol_rule     // a single symbol
    | literal { $pTipo = $literal.pTipo; $pRule = "literal"; $pValue = $literal.pValue; }           #me_exprliteral_rule    // literal value
    | funcall                                        #me_exprfuncall_rule    // a funcion call
    | cast  { $pTipo = $cast.pTipo; $pRule = "cast"; $pValue = $cast.pValueDestino; }                                         #me_exprcast_rule       // cast a type to other
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
returns [String pTipo, String pValueOriginal, String pValueDestino]
@init {
	String ret = null;
	String vOriginal = null;
	String vDestino = null;
}
@after {

	String tipoDestino = getKeyByValue(tabelaSimbolos, $pTipo);
	
	if (tipoDestino.equals("f")) {
		if (!ret.equals("i") && !ret.equals("s")) {
			errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tabelaSimbolos.get(ret), vOriginal, $pTipo));
			
			vDestino = String.valueOf(Float.parseFloat("1"));
		}
		else {
			try {
				float f = Float.parseFloat(vOriginal);
				vDestino = String.format("%f", f);
			}
			catch (Exception e) {
				errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tabelaSimbolos.get(ret), vOriginal, $pTipo));
				vDestino = String.format("%f", 1);
			}	
		}
	}
	else if (tipoDestino.equals("i")) {
		if (ret.equals("f")) {
			double d = Double.parseDouble(vOriginal);
			int i = (int) d;
			vDestino = String.format("%d", i);
			warningMessages.add(String.format("Inteiro descartando parte fracionária! Pode perder precisão (%s -> %s).", vOriginal, vDestino));		
		}
		else if (ret.equals("c")) {
			char c = vOriginal.charAt(0);
			int i = (int) c;
			vDestino = String.format("%d", i);
		}
		else {
			try {
				int i = Integer.parseInt(vOriginal);
				vDestino = String.format("%d", i);
			}
			catch (Exception e) {
				errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tabelaSimbolos.get(ret), vOriginal, $pTipo));
				vDestino = String.format("%d", 1);
			}
		}
	}
	else if (tipoDestino.equals("s")) {
		vDestino = String.valueOf(vOriginal);	
	}
	else if (tipoDestino.equals("c")) {
		if (ret.equals("i")) {
			int i = Integer.parseInt(vOriginal);
			char c = (char) i;
			vDestino = String.format("%s", c);
		}
		else {
			errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tabelaSimbolos.get(ret), vOriginal, $pTipo));
			vDestino = "a";
		}	
	}
	else if (tipoDestino.equals("b")) {
		if (vOriginal == null)
			vDestino = "false";
		else
			vDestino = "true";
	}
	else {
		errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida! Tipos aceitos são {float, int, char, bool, str}.", tabelaSimbolos.get(ret), vOriginal, $pTipo));
		System.exit(0);
	}
	
	$pTipo = tipoDestino;
}
    : type vFunc=funcbody  { $pTipo = $type.text; ret = $vFunc.pTipo; vOriginal = $vFunc.pValue; }                                #cast_rule
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
returns [String pRule, String pTipo, String pValue] 
	: 
        'nil'   {$pTipo = "n"; $pRule = "nil"; $pValue = "nil";}                                        #literalnil_rule
    |   'true'  {$pTipo = "b"; $pRule = "true"; $pValue = "true";}                                        #literaltrue_rule
    |   'false' {$pTipo = "b"; $pRule = "false"; $pValue = "false";}                                         #literaltrue_rule
    |   number 	{$pTipo = $number.pTipo; $pRule = "number"; $pValue = $number.pValue;}	 									#literalnumber_rule
    |   strlit  {$pTipo = "s"; $pRule = "strlit"; $pValue = $strlit.pValue;}                                        #literalstring_rule
    |   charlit {$pTipo = "c";  $pRule = "charlit"; $pValue = $charlit.pValue;}                                        #literal_char_rule
    ;

strlit
returns [String pValue]
	: TOK_STR_LIT { $pValue = $TOK_STR_LIT.text.replaceAll("\"", ""); }
    ;

charlit
returns [String pValue]
    : TOK_CHAR_LIT { $pValue = $TOK_CHAR_LIT.text.replaceAll("'", ""); }
    ;

number
returns [String pRule, String pTipo, String pValue]
	:
        FLOAT {$pTipo = "f"; $pRule = "FLOAT"; $pValue = $FLOAT.text;} #numberfloat_rule
    |   DECIMAL {$pTipo = "i"; $pRule = "DECIMAL"; $pValue = $DECIMAL.text;} #numberdecimal_rule
    |   HEXADECIMAL {$pTipo = "i"; $pRule = "HEXADECIMAL"; $pValue = $HEXADECIMAL.text;} #numberhexadecimal_rule
    |   BINARY {$pTipo = "i"; $pRule = "BINARY"; $pValue = $BINARY.text;} #numberbinary_rule
    
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
DEC_DIGIT : [0-9];