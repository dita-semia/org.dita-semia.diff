package org.DitaSemia.Diff;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.IntegerValue;

public class GetHashFromStringCall extends ExtensionFunctionCall {

	@Override
	public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
		//logger.info("call");
		try {
			final String 	string 		= arguments[0].head().getStringValue();
			
			return IntegerValue.makeIntegerValue(string.hashCode()).asAtomic();
			
		} catch (Exception e) {
			throw new XPathException("ERROR in dsd:getHashFromString(): " + e.getMessage());
		}
	}

}
