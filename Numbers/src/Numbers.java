import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.antlr.v4.runtime.*; // class ANTLRInputStream , Token

import parser.src.NumbersLexer;

public class Numbers {
    
	public static void main(String[] args) {
        NumbersLexer lexer;
        Token tk;
        NPRCalc nprCalc = new NPRCalc();

        boolean sair = false;
        
        do{
	        try {
	        	System.out.print("$ >>");
	        	
	        	BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
	        	
	        	String line = br.readLine();
	        	
	        	if (line.equals("sair")) {
	        		System.out.println("Good bye");
	        		System.exit(0);
	        	}
	        	
	            lexer = new NumbersLexer(new ANTLRInputStream( new ByteArrayInputStream(line.getBytes()) ));
 
	            tk = lexer.nextToken();
            
	            switch(tk.getType()) {
	                case NumbersLexer.BINARY:
	                    //System.out.println("bin: " + tk.getText());
	                	String tmp = tk.getText().replace("b", "");
	                    nprCalc.add(tmp, tk.getType());
	                    break;
	
	                
	                case NumbersLexer.DECIMAL:
	                    //System.out.println("dec: " + tk.getText());
	                	nprCalc.add(tk.getText(), tk.getType());
	                    break;
	                    
	                case NumbersLexer.INTEGER:
	                    //System.out.println("int: " + tk.getText());
	                	nprCalc.add(tk.getText(), tk.getType());
	                    break;
	                
	                case NumbersLexer.HEX:
	                    //System.out.println("hex: " + tk.getText());
	                	String tmp1 = tk.getText().replace("0x", "");
	                	nprCalc.add(tmp1, tk.getType());
	                    break;
	                
	                case NumbersLexer.ADD_OPER:
	                	nprCalc.calc(tk.getText());
	                	break;
	
	                case NumbersLexer.SUB_OPER:
	                	nprCalc.calc(tk.getText());
	                	break;
	
	                case NumbersLexer.MUL_OPER:
	                	nprCalc.calc(tk.getText());
	                	break;
	
	                case NumbersLexer.DIV_OPER:
	                	nprCalc.calc(tk.getText());
	                	break;
	
	                case NumbersLexer.POW_OPER:
	                	nprCalc.calc(tk.getText());
	                	break;
	
	                case NumbersLexer.SHOW_STACK:
	                	nprCalc.print();
	                	break;
	
	                case NumbersLexer.RESET_STACK:
	                	nprCalc.reset();
	                	break;
	            }
	        } catch (Exception e) {
	            // Pikachu!
	            System.out.println("Erro:" + e);
	            System.out.println("");
	        }

        } while (!sair);
	        //} while (tk != null && tk.getType() != Token.EOF);
    }
}
