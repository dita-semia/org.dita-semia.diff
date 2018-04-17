package org.DitaSemia.Diff;

import java.io.StringWriter;
import java.util.Properties;

import javax.xml.transform.OutputKeys;
import javax.xml.transform.stream.StreamResult;

import net.sf.saxon.expr.XPathContext;
import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.om.NodeInfo;
import net.sf.saxon.om.Sequence;
import net.sf.saxon.query.QueryResult;
import net.sf.saxon.trans.XPathException;
import net.sf.saxon.value.StringValue;

public class SerializeCall extends ExtensionFunctionCall {

	private static final Properties serializationProperties = getSerializationProperties();
	
	@Override
	public Sequence call(XPathContext context, Sequence[] arguments) throws XPathException {
		//logger.info("call");
		try { 

			final NodeInfo	node 	= (NodeInfo)arguments[0].head();
			
			final StringWriter writer = new StringWriter();
			final StreamResult result = new StreamResult(writer);
			QueryResult.serialize(node, result, serializationProperties);
			
			return StringValue.makeStringValue(writer.getBuffer().toString()).asAtomic();
			
		} catch (Exception e) {
			throw new XPathException("ERROR in dsd:serialize(): " + e.getMessage());
		}
	}

	private static Properties getSerializationProperties() {
		Properties properties = new Properties();
		properties.setProperty(OutputKeys.INDENT, 					"no");
		properties.setProperty(OutputKeys.OMIT_XML_DECLARATION, 	"yes");
		return properties;
	}
	
}
