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
	
	private Stack<Object> pilhaValores = new Stack<Object>();
	private NestedSymbolTable<Object> symbolTable = new NestedSymbolTable<Object>(); 
	
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
		String vFinal = "1";
		
		if ((tL.equals("i") && tR.equals("i")) ||
			(tL.equals("f") && tR.equals("i")) ||
			(tL.equals("i") && tR.equals("f")) ||
			(tL.equals("f") && tR.equals("f"))) {
			
			printPilhaValores();
			
			String vR = pilhaValores.pop().toString().replace(",",".");
			String vL = pilhaValores.pop().toString().replace(",",".");
			
			double fR = Double.parseDouble(vR);
			double fL = Double.parseDouble(vL);
			
			vFinal = String.format("%f", Math.pow(fL,fR));
		}
		else {
			errorMessages.add(String.format("Operação de exponenciação com tipo errados: %s ^ %s", tabelaSimbolos.get(tL), tabelaSimbolos.get(tR)));
			return "f";
		}
		
		pilhaValores.push(vFinal);
		
		return "f";
	}
	
	private String validarConcatenacao(String tL, String tR) {
		
		printPilhaValores();
		
		String vR = pilhaValores.pop().toString();
		String vL = pilhaValores.pop().toString();

		if (!tL.equals("s") || !tR.equals("s")) {
			errorMessages.add(String.format("Operação de concatenação entre tipos incompatíveis: %s :: %s", tabelaSimbolos.get(tL), tabelaSimbolos.get(tR)));
			
			if (!tL.equals("s")) {
				vL = "";
			}
			
			if (!tR.equals("s")) {
				vR = "";
			}
		}
		
		pilhaValores.push(String.format("%s%s", vL, vR));
		
		return "s";
	}
	
	private String validarCast(String tipoDestino, String tipoOriginal, String vValue) {
		String tipo = tabelaSimbolos.get(tipoOriginal);
		
		String tipoDestinoKey = getKeyByValue(tabelaSimbolos, tipoDestino);
				
		String vFinal = pilhaValores.pop().toString();
		
		if (tipoDestino.equals(tipo)) {
			//Não faz nada
		}
		else if (tipoDestinoKey.equals("f")) {
			if (!tipoOriginal.equals("i") && !tipoOriginal.equals("s")) {
				errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tipo, vValue, tipoDestino));
			
				vFinal = "1";
			}
			else {
				try {
					float f = Float.parseFloat(vValue);
					vFinal = String.format("%f", f);
				}
				catch (Exception e) {
					errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tipo, vValue, tipoDestino));
					vFinal = "1";
				}	
			}
		}
		else if (tipoDestinoKey.equals("i")) {
			if (tipoOriginal.equals("f")) {
				double d = Double.parseDouble(vValue);
				int i = (int) d;
				vFinal = String.format("%d", i);
				
				warningMessages.add(String.format("Inteiro descartando parte fracionária! Pode perder precisão (%s).", vValue));		
			}
			else if (tipoOriginal.equals("c")) {
				char c = vValue.charAt(0);
				int i = (int) c;
				vFinal = String.format("%d", i);
			}
			else {
				try {
					int i = Integer.parseInt(vValue);
					vFinal = String.format("%d", i);
				}
				catch (Exception e) {
					errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tipo, vValue, tipoDestino));
					vFinal = "1";
				}
			}
		}
		else if (tipoDestinoKey.equals("s")) {
			vFinal = vValue;	
		}
		else if (tipoDestinoKey.equals("c")) {
			if (tipoOriginal.equals("i")) {
				int i = Integer.parseInt(vValue);
				char c = (char) i;
				vFinal = String.format("%s", c);
			}
			else {
				errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida!", tipo, vValue, tipoDestino));
				vFinal = " ";
			}	
		}
		else if (tipoDestinoKey.equals("b")) {
			if (vValue == null)
				vFinal = "false";
			else
				vFinal = "true";
		}
		else {
			errorMessages.add(String.format("Conversão de '%s'[%s] para '%s' inválida! Tipos aceitos são {float, int, char, bool, str}.", tipo, vValue, tipoDestino));
		}
		
		pilhaValores.push(vFinal);
		
		return getKeyByValue(tabelaSimbolos, tipoDestino);
	}
	
	private String validarGT_LT(String tL, String tR, String operacao) {
		String vFinal = "false";
		
		if (tL.equals("i") && tR.equals("i")) {
			int vR = Integer.parseInt(pilhaValores.pop().toString());
			int vL = Integer.parseInt(pilhaValores.pop().toString());
			
			if (operacao.equals(">")) {
				vFinal = String.valueOf(vL > vR);
			}
			else if (operacao.equals("<")) {
				vFinal = String.valueOf(vL < vR);
			}
			else if (operacao.equals(">=")) {
				vFinal = String.valueOf(vL >= vR);
			}
			else if (operacao.equals("<=")) {
				vFinal = String.valueOf(vL <= vR);
			}
		}
		else if (tL.equals("f") && tR.equals("f")) {
			float vR = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			float vL = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			
			if (operacao.equals(">")) {
				vFinal = String.valueOf(vL > vR);
			}
			else if (operacao.equals("<")) {
				vFinal = String.valueOf(vL < vR);
			}
			else if (operacao.equals(">=")) {
				vFinal = String.valueOf(vL >= vR);
			}
			else if (operacao.equals("<=")) {
				vFinal = String.valueOf(vL <= vR);
			}
		}
		else if (tL.equals("f") && tR.equals("i")) {
			int vR = Integer.parseInt(pilhaValores.pop().toString().replace(",","."));
			float vL = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			
			if (operacao.equals(">")) {
				vFinal = String.valueOf(vL > vR);
			}
			else if (operacao.equals("<")) {
				vFinal = String.valueOf(vL < vR);
			}
			else if (operacao.equals(">=")) {
				vFinal = String.valueOf(vL >= vR);
			}
			else if (operacao.equals("<=")) {
				vFinal = String.valueOf(vL <= vR);
			}
		}
		else if (tL.equals("i") && tR.equals("f")) {
			float vR = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			int vL = Integer.parseInt(pilhaValores.pop().toString().replace(",","."));
			
			if (operacao.equals(">")) {
				vFinal = String.valueOf(vL > vR);
			}
			else if (operacao.equals("<")) {
				vFinal = String.valueOf(vL < vR);
			}
			else if (operacao.equals(">=")) {
				vFinal = String.valueOf(vL >= vR);
			}
			else if (operacao.equals("<=")) {
				vFinal = String.valueOf(vL <= vR);
			}
		}
		else {
			String vR = pilhaValores.pop().toString();
			String vL = pilhaValores.pop().toString();
			
			vFinal = "false";
		}
		
		pilhaValores.push(vFinal); 
		
		return "b";
	}
	
	private String validarAND_OR(String tL, String tR, String operacao) {
	
		String vR = pilhaValores.pop().toString();
		String vL = pilhaValores.pop().toString();
	
		if (!tL.equals("b") || !tR.equals("b")) {
			errorMessages.add(String.format("Operador %s com tipos incompatíveis: %s e %s", operacao, tabelaSimbolos.get(tL), tabelaSimbolos.get(tR)));
			
			pilhaValores.push("false");
		}
		else {
			if (operacao.equals("&&")) {
				pilhaValores.push(String.valueOf(vL.equals("true") && vR.equals("true")));
			}
			else if (operacao.equals("||")) {
				pilhaValores.push(String.valueOf(vL.equals("true") || vR.equals("true")));
			}
		
		}
	
		return "b";
	}
	
	private String validarEQ_DIFF(String tL, String tR, String operacao) {
		String vFinal = "false";
		
		if (tL.equals("i") && tR.equals("i")) {
			int vR = Integer.parseInt(pilhaValores.pop().toString());
			int vL = Integer.parseInt(pilhaValores.pop().toString());
			
			if (operacao.equals("==")) {
				vFinal = String.valueOf(vL == vR);
			}
			else if (operacao.equals("!=")) {
				vFinal = String.valueOf(vL != vR);
			}
		}
		else if (tL.equals("f") && tR.equals("f")) {
			float vR = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			float vL = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			
			if (operacao.equals("==")) {
				vFinal = String.valueOf(vL == vR);
			}
			else if (operacao.equals("!=")) {
				vFinal = String.valueOf(vL != vR);
			}
		}
		else if (tL.equals("f") && tR.equals("i")) {
			int vR = Integer.parseInt(pilhaValores.pop().toString().replace(",","."));
			float vL = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			
			if (operacao.equals("==")) {
				vFinal = String.valueOf(vL == vR);
			}
			else if (operacao.equals("!=")) {
				vFinal = String.valueOf(vL != vR);
			}
		}
		else if (tL.equals("i") && tR.equals("f")) {
			float vR = Float.parseFloat(pilhaValores.pop().toString().replace(",","."));
			int vL = Integer.parseInt(pilhaValores.pop().toString().replace(",","."));
			
			if (operacao.equals("==")) {
				vFinal = String.valueOf(vL == vR);
			}
			else if (operacao.equals("!=")) {
				vFinal = String.valueOf(vL != vR);
			}
		}
		else if (tL.equals("c") && tR.equals("c")) {
			String vR = pilhaValores.pop().toString();
			String vL = pilhaValores.pop().toString();
			
			char cR = vR.charAt(0);
			char cL = vL.charAt(0);
			
			if (operacao.equals("==")) {
				vFinal = String.valueOf(cL == cR);
			}
			else if (operacao.equals("!=")) {
				vFinal = String.valueOf(cL != cR);
			}
		}
		else if (tL.equals("s") && tR.equals("s")) {
			
			String vR = pilhaValores.pop().toString();
			String vL = pilhaValores.pop().toString();
			
			if (operacao.equals("==")) {
				vFinal = String.valueOf(vL.equals(vR));
			}
			else if (operacao.equals("!=")) {
				vFinal = String.valueOf(!vL.equals(vR));
			}
		}
		else {
			String vR = pilhaValores.pop().toString();
			String vL = pilhaValores.pop().toString();
		
			vFinal = "false";
		}
		
		pilhaValores.push(vFinal); 
		
		return "b";
	}
	
	private String validarASDM(String tL, String tR, String operacao) {
		if ((tL.equals("i") && tR.equals("i"))) {
			
			int op2 = Integer.parseInt(pilhaValores.pop().toString());
			int op1 = Integer.parseInt(pilhaValores.pop().toString());
			
			if (operacao.equals("+")) {
				pilhaValores.push(op1 + op2);
			}
			else if (operacao.equals("-")) {
				pilhaValores.push(op1 - op2);
			}
			else if (operacao.equals("*")) {
				pilhaValores.push(op1 * op2);
			}
			else if (operacao.equals("/")) {
				pilhaValores.push(op1 / op2);
			}
			
			return "i";
		}
		else if ((tL.equals("f") && tR.equals("i")) ||
				 (tL.equals("i") && tR.equals("f")) ||
				 (tL.equals("f") && tR.equals("f"))) {
			
			double f2 = Double.parseDouble(pilhaValores.pop().toString().replace(",","."));
			double f1 = Double.parseDouble(pilhaValores.pop().toString().replace(",","."));
			
			if (operacao.equals("+")) {
				pilhaValores.push(f1 + f2);
			}
			else if (operacao.equals("-")) {
				pilhaValores.push(f1 - f2);
			}
			else if (operacao.equals("*")) {
				pilhaValores.push(f1 * f2);
			}
			else if (operacao.equals("/")) {
				pilhaValores.push(f1 / f2);
			}
			
			return "f";
		}
		else {
			errorMessages.add(String.format("Operação aritmética com tipo errados: %s e %s", tabelaSimbolos.get(tL), tabelaSimbolos.get(tR)));
			
			pilhaValores.push("1");
			
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
	
	private void adicionaSimbolo(String symbolName, String tipo, String value) {
		
		SymbolEntry<Object> s = symbolTable.lookup(symbolName);
		
		if (s != null) {
			errorMessages.add(String.format("Símbolo '%s' já foi declarado!", symbolName));
			printErrors();
			System.exit(0);
		}
		else {
			symbolTable.store(symbolName, tabelaSimbolos.get(tipo), value);
		}
	}
	
	private void printSymbolTable() {
		System.out.println("\nTabela de símbolos:");
		System.out.println("====================================");
		for (SymbolEntry<Object> entry : symbolTable.getEntries()) {
            System.out.println(entry);
        }
	}
	
	private void printPilhaValores() {
		System.out.println("\nPilha de Valores: ");
		System.out.println("====================================");
		for (int i = 0; i < pilhaValores.size(); i++) {
            Object o = pilhaValores.get(i);
            System.out.println(o.toString());
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
    |   letexpr { $pTipo = $letexpr.pTipo; $pValue = $letexpr.pValue; }         #fbody_let_rule
    |   metaexpr { 
    		$pTipo = $metaexpr.pTipo;
    		$pValue = $metaexpr.pValue;
    	}  #fbody_expr_rule
    ;

ifexpr
    : 'if' funcbody 'then' funcbody 'else' funcbody  #ifexpression_rule
    ;

letexpr
returns[String pTipo, String pValue]
@init {
    callCount++;
    
    if (tabelaSimbolos.isEmpty()) {//Se a tabela está vazia, carrega
    	tabelaSimbolos.put("i", "int");
    	tabelaSimbolos.put("f", "float");
    	tabelaSimbolos.put("s", "str");
    	tabelaSimbolos.put("c", "char");
    	tabelaSimbolos.put("b", "bool");
    	tabelaSimbolos.put("n", "null");
    }
}
@after {
	callCount--;
	
	if (callCount == 0) {
		System.out.println("--------------------------------------------------");
		printPilhaValores();
		System.out.println("--------------------------------------------------");
		printErrors();
		printWarnings();
	}
}
    : { symbolTable = new NestedSymbolTable<Object>(symbolTable); } 'let' letlist { printSymbolTable(); } 'in' funcbody { $pTipo = $funcbody.pTipo; symbolTable = symbolTable.getParent(); }                   #letexpression_rule
    ;

letlist
    : letvarexpr letlist_cont                       #letlist_rule
    ;

letlist_cont
    : ',' letvarexpr letlist_cont                    #letlist_cont_rule
    |                                                #letlist_cont_end
    ;

letvarexpr
    :    symbol '=' funcbody { adicionaSimbolo($symbol.text, $funcbody.pTipo, pilhaValores.pop().toString()); }  	#letvarattr_rule
    |    '_'    '=' funcbody { adicionaSimbolo("_", $funcbody.pTipo, pilhaValores.pop().toString());  }             #letvarresult_ignore_rule
    |    symbol '::' symbol '=' funcbody             #letunpack_rule
    ;

metaexpr
returns [String pRule, String pTipo, String pValue, String pName]
@init {
    String tL = null;
    String tR = null;
    String vL = null;
    String vR = null;
    
    String vOperacao = null;
    String tTipoOriginal = null;
}
@after{
	
	if ($pRule.equals("TOK_NEG")) {
		if ($pTipo != null && !$pTipo.equals("b")) {
			errorMessages.add(String.format("Operação de negação incompatível: %s", $pValue));
		}
		$pTipo = "b";
	}
}
    : '(' funcbody ')'                  { $pTipo = $funcbody.pTipo; $pRule = "(funcbody)"; $pValue = $funcbody.pValue; }             #me_exprparens_rule     // Anything in parenthesis -- if, let, funcion call, etc
    | sequence_expr                                  #me_list_create_rule    // creates a list [x]
    | TOK_NEG symbol                    { $pRule = "TOK_NEG"; }             #me_boolneg_rule        // Negate a variable
    | TOK_NEG '(' funcbody ')'          { $pRule = "TOK_NEG"; $pTipo = $funcbody.pTipo; $pValue = $funcbody.text; }             #me_boolnegparens_rule  //        or anything in between ( )
    | m1=metaexpr TOK_POWER m2=metaexpr 
    	{ 
    		$pRule = "TOK_POWER"; 
    		$pTipo = validarExponenciacao($m1.pTipo, $m2.pTipo); 
    	}                  #me_exprpower_rule      // Exponentiation
    | m1=metaexpr TOK_CONCAT m2=metaexpr 
    	{ 
    		$pRule = "TOK_CONCAT"; 
    		$pTipo = validarConcatenacao($m1.pTipo, $m2.pTipo);
    	}                   #me_listconcat_rule     // Sequence concatenation
    | m1=metaexpr TOK_DIV_OR_MUL m2=metaexpr 
    	{ 
    		$pRule = "TOK_DIV_OR_MUL"; 
    		$pTipo = validarASDM($m1.pTipo, $m2.pTipo, $TOK_DIV_OR_MUL.text); 
    	}   	               #me_exprmuldiv_rule     // Div and Mult are equal
    | m1=metaexpr TOK_PLUS_OR_MINUS m2=metaexpr 
    	{ 
    		$pRule = "TOK_PLUS_OR_MINUS"; 
    		$pTipo = validarASDM($m1.pTipo, $m2.pTipo, $TOK_PLUS_OR_MINUS.text);
    	}            #me_exprplusminus_rule  // Sum and Sub are equal
    | m1=metaexpr TOK_CMP_GT_LT m2=metaexpr   
    	{ 
    		$pRule = "TOK_CMP_GT_LT"; 
    		$pTipo = validarGT_LT($m1.pTipo, $m2.pTipo, $TOK_CMP_GT_LT.text);
    	}             #me_boolgtlt_rule       // < <= >= > are equal
    | m1=metaexpr TOK_CMP_EQ_DIFF m2=metaexpr 
    	{ 
    		$pRule = "TOK_CMP_EQ_DIFF"; 
    		$pTipo = validarEQ_DIFF($m1.pTipo, $m2.pTipo, $TOK_CMP_EQ_DIFF.text); 
    	}             #me_booleqdiff_rule     // == and != are egual
    | m1=metaexpr TOK_BOOL_AND_OR m2=metaexpr 
    	{ 
    		$pRule = "TOK_BOOL_AND_OR"; 
    		$pTipo = validarAND_OR($m1.pTipo, $m2.pTipo, $TOK_BOOL_AND_OR.text);
    	}             #me_boolandor_rule      // &&   and  ||  are equal
    | symbol  
    	{ 
    		$pName = $symbol.text;
    		SymbolEntry<Object> s = symbolTable.lookup($pName);
    		if (s != null) {
    			$pTipo = getKeyByValue(tabelaSimbolos, s.type);
    			$pValue = s.symbol.toString();
    			
    			pilhaValores.push(s.symbol);
    		}
    		else {
    			errorMessages.add(String.format("Símbolo '%s' não declarado!", $pName));
    		}
    		
    		$pRule = "symbol";
    	}                                       #me_exprsymbol_rule     // a single symbol
    | literal 
    	{ 
    		$pTipo = $literal.pTipo; 
    		$pRule = "literal"; 
    		$pValue = $literal.pValue;
    		
    		pilhaValores.push($literal.pValue);
    	}           #me_exprliteral_rule    // literal value
    | funcall                                        #me_exprfuncall_rule    // a funcion call
    | cast  
    	{ 
    		$pRule = "CAST"; 
    		$pValue = pilhaValores.peek().toString(); 
    		$pTipo = validarCast($cast.pTipo, $cast.pTipoOriginal, $pValue);
    	}                                         #me_exprcast_rule       // cast a type to other
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
returns [String pTipo, String pTipoOriginal, String pValue]
    : type vFunc=funcbody  { $pTipo = $type.text; $pTipoOriginal = $vFunc.pTipo; $pValue = $vFunc.pValue; }   #cast_rule
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
