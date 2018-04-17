package org.DitaSemia.Diff;

import java.io.File;
import java.io.FileInputStream;
import java.net.URL;

import javax.xml.transform.Source;

import org.apache.commons.codec.digest.DigestUtils;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.IntegerValue;

public class GetHashFromFileCall extends ExtensionFunctionCall {

	@Override
	public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
		//logger.info("call");
		try { 

			final String 	uriString 	= arguments[0].head().getStringValue();
			final Source 	source 		= context.getURIResolver().resolve(uriString, "");
			final URL		url			= new URL(source.getSystemId());
			
			final FileInputStream 	fis = new FileInputStream(new File(url.getPath()));
			final String 			md5 = DigestUtils.md5Hex(fis);
			fis.close();
			
			return IntegerValue.makeIntegerValue(md5.hashCode()).asAtomic();
			
		} catch (Exception e) {
			throw new XPathException("ERROR in dsd:getHashFromFile(): " + e.getMessage());
		}
	}

}
