package parser.src;

import org.antlr.v4.runtime.*;// class ANTLRInputStream , Token
import java.io.*;
import javax.swing.JFileChooser;
import javax.swing.filechooser.*;

public class ParserMMML {
	public static void main(String[] args) throws Exception {
		// ou recebe como argumento, depende de como preferir executar
		/*
		JFileChooser chooser=new JFileChooser();
		chooser.setFileFilter(new FileNameExtensionFilter("mimimil source code","mmm"));
		int retval = chooser.showOpenDialog(null);
		if (retval != JFileChooser.APPROVE_OPTION)
			return;
		*/
		try { 
			FileInputStream fin = new FileInputStream("/home/everton/gitrep/Compiladores-PMA/Numbers/src/MMMLTeste.mmm");//chooser.getSelectedFile());
			MMMLLexer lexer= new MMMLLexer(new ANTLRInputStream(fin));
			CommonTokenStream tokens = new CommonTokenStream(lexer);
			MMMLParser parser= new MMMLParser(tokens);
			parser.metaexpr();// Comecando dessa regra , poderia trocar// por .funcbody ou .metaexpr
		}
		catch (Exception e){
			// Pikachu!
			System.out.println("Erro: "+e);
			return;
		}
	}
}