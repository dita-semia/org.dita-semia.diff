package org.DitaSemia.Diff;

import java.io.File;
import java.io.FileInputStream;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedList;
import java.util.List;

import javax.xml.transform.Source;

import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.om.Item;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.BooleanValue;
import net.sf.saxon.value.IntegerValue;
import net.sf.saxon.value.SequenceExtent;

public class GetHashFromFileCall extends ExtensionFunctionCall {

	@SuppressWarnings("unused")
	private static final Logger logger = Logger.getLogger(ExtensionFunctionCall.class.getName());

	@Override
	public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
		try { 

			final String 	uriString 	= arguments[0].head().getStringValue();
			final boolean 	normalizeNl	= ((BooleanValue)arguments[1].head()).getBooleanValue();
			
			final Source 	source 		= context.getURIResolver().resolve(uriString, "");
			final URL		url			= new URL(source.getSystemId());
			final String 	uriDecoded	= URLDecoder.decode(url.getPath(), "UTF-8");
			
			final FileInputStream 	fis = new FileInputStream(new File(uriDecoded));
			
			if (normalizeNl) {
				final String original 	= IOUtils.toString(fis, StandardCharsets.UTF_8);
				final String normalized = original.replaceAll("\\r\\n?", "\n");
				final String md5 		= DigestUtils.md5Hex(DigestUtils.md5Hex(normalized));
				logger.info(uriString + ": " + md5 + " (" + original.length() + "/" + normalized.length() + ")");
				fis.close();
				return IntegerValue.makeIntegerValue(md5.hashCode()).asAtomic();
				
			} else {
				final String 			md5 = DigestUtils.md5Hex(fis);
				fis.close();
				return IntegerValue.makeIntegerValue(md5.hashCode()).asAtomic();
			}
			
		} catch (Exception e) {
			throw new XPathException("ERROR in dsd:getHashFromFile(): " + e.getMessage());
		}
	}

}
