import java.io.File;
import java.io.FileInputStream;

import org.antlr.v4.runtime.*; // class ANTLRInputStream , Token

import parser.src.NumbersLexer;

public class Numbers {
    public static void main(String[] args) {
        NumbersLexer lexer;
        Token tk;

        File file = new File("TesteE1.txt");
		FileInputStream fis = null;

        try {
        	fis = new FileInputStream(file);
        	
            lexer = new NumbersLexer(new ANTLRInputStream( fis ));
        } catch (Exception e) {
            // Pikachu!
            System.out.println("Erro:" + e);
            System.exit(1);
            return;
        }

        // Le da entrada padrao ateh chegar digitar CTRL-D (Linux/Mac)
        // ou CTRL-Z (Windows)

        do {
            tk = lexer.nextToken();
            switch(tk.getType()) {
                case NumbersLexer.BINARY:
                    System.out.println("bin: " + tk.getText());
                    break;

                
                case NumbersLexer.DECIMAL:
                    System.out.println("dec: " + tk.getText());
                    break;
                    
                case NumbersLexer.INTEGER:
                    System.out.println("int: " + tk.getText());
                    break;
                
                case NumbersLexer.HEX:
                    System.out.println("hex: " + tk.getText());
                    break;
            }
        } while (tk != null && tk.getType() != Token.EOF);

    }
}
