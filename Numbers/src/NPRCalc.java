import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.Stack;

import parser.src.NumbersLexer;

/**
 * Calculadora NPR
 * 
 * @author Everton Thomas
 *
 */
public class NPRCalc {

	private String expressao;
	private Stack<BigDecimal> pilha;
	
	public NPRCalc() {
		this.pilha = new Stack<BigDecimal>();
	}
	
	public void add(String value, int tipo) {
		BigDecimal v = null;
		
		if (tipo == NumbersLexer.INTEGER)
			v = new BigDecimal(value);
		else if (tipo == NumbersLexer.DECIMAL)
			v = new BigDecimal(value);
		else if (tipo == NumbersLexer.HEX)
			v = new BigDecimal(new BigInteger(value, 16));
		else if (tipo == NumbersLexer.BINARY)
			v = new BigDecimal(new BigInteger(value, 2));
		
		pilha.push(v);
	}

	public void calc(String operador) throws Exception {
		BigDecimal v2 = getTopo();
		BigDecimal v1 = getTopo();
		
		if (operador.equals("+"))
			soma(v1,v2);
		else if (operador.equals("-"))
			subtrai(v1,v2);
		else if (operador.equals("*"))
			multiplica(v1,v2);
		else if (operador.equals("/"))
			divide(v1,v2);
		else if (operador.equals("^"))
			potencia(v1,v2);
		else
			throw new Exception(String.format("Operação [%s] não reconhecida!", operador));
	}
	
	
	public void print() {
		System.out.println("\t>> Pilha:");
		System.out.println("\t   ------------------------");
		System.out.print(String.format("\t  "));
		for (BigDecimal v : pilha) {
			System.out.print(String.format(" %s", v.toString()));
		}
		System.out.println("\n\t   ------------------------");
	}
	
	public void reset() {
		System.out.println("\t>> Reset na pilha...");
		pilha.clear();
		print();
	}
	
	private BigDecimal getTopo() throws Exception {
		if (pilha == null || pilha.empty())
			throw new Exception("Pilha está vazia!");
		
		return pilha.pop();
	}

	private void soma(BigDecimal v1, BigDecimal v2) {
		BigDecimal r = v1.add(v2);
		pilha.push(r);
	}
	
	private void subtrai(BigDecimal v1, BigDecimal v2) {
		BigDecimal r = v1.subtract(v2);
		pilha.push(r);
	}
	
	private void divide(BigDecimal v1, BigDecimal v2) {
		BigDecimal r = v1.divide(v2);
		pilha.push(r);
	}
	
	private void multiplica(BigDecimal v1, BigDecimal v2) {
		BigDecimal r = v1.multiply(v2);
		pilha.push(r);
	}
	
	private void potencia(BigDecimal v1, BigDecimal v2) {
		BigDecimal r = v1.pow(v2.intValue());
		pilha.push(r);
	}
}
