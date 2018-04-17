package org.DitaSemia.Diff;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.om.Item;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.om.SequenceIterator;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.IntegerValue;

public class GetHashFromSequenceCall extends ExtensionFunctionCall {

	@Override
	public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
		//logger.info("call");
		try { 
			final SequenceIterator iterator = arguments[0].iterate();
			int 	hashCode 	= 0;
			Item 	item 		= iterator.next();
			while (item != null) {
				hashCode = (31 * hashCode) + item.getStringValue().hashCode();
				item = iterator.next();
			}
			return IntegerValue.makeIntegerValue(hashCode).asAtomic();
			
		} catch (Exception e) {
			throw new XPathException("ERROR in dsd:getHashFromSequence(): " + e.getMessage());
		}
	}

}
