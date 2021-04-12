package org.DitaSemia.Diff;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.StringValue;

public class RelativizeHrefCall extends ExtensionFunctionCall {
	
	@Override
	public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
		String href	= "";
		String base = "";
		try {

			href	= arguments[0].head().getStringValue().replace('\\', '/');
			base 	= arguments[1].head().getStringValue().replace('\\', '/');

			return StringValue.makeStringValue(relativize(href, base)).asAtomic();
			
		} catch (Exception e) {
			throw new XPathException("ERROR in dsd:relativizeHref(" + href + ", " + base + "): " + e.getMessage());
		}
	}

	public static String relativize(String href, String base) throws URISyntaxException, MalformedURLException, UnsupportedEncodingException {
		
		final URI 	hrefUri 	= new URI(href);
		final URI	baseUri 	= new URI(base);
		
		final File 	hrefFile	= new File(hrefUri.toURL().getFile());
		final File 	baseFile	= new File(baseUri.toURL().getFile());
		
		final Path 	hrefPath	= Paths.get(hrefFile.getPath());
		final Path 	basePath	= Paths.get(baseFile.getParent());
		
		final Path 	relPath		= basePath.relativize(hrefPath);
		
		final String fragment 	= hrefUri.getRawFragment();
		final String suffix		= (fragment == null) ? ("") : ("#" + fragment); 
				
		//System.out.println("relativize - href: '" + href + "', base: '" + base + "'");
		
		return relPath.toString().replace('\\', '/') + suffix;
	}
}
