package org.DitaSemia.Diff;

import net.sf.saxon.lib.ExtensionFunctionCall;
import net.sf.saxon.lib.ExtensionFunctionDefinition;
import net.sf.saxon.om.StructuredQName;
import net.sf.saxon.value.SequenceType;

public class GetHashFromSequenceDef extends ExtensionFunctionDefinition {
	
	public static final String LOCAL_NAME	= "getHashFromSequence"; 

	@Override
		public SequenceType[] getArgumentTypes() {
			SequenceType[] sequenceType = {SequenceType.ANY_SEQUENCE};
			return sequenceType;
	}

	@Override
	public StructuredQName getFunctionQName() {
		return new StructuredQName(Const.NAMESPACE_PREFIX, Const.NAMESPACE_URI, LOCAL_NAME);
	}

	@Override
	public SequenceType getResultType(SequenceType[] suppliedArgumentTypes) {
		return SequenceType.SINGLE_INTEGER;
	}

	@Override
	public ExtensionFunctionCall makeCallExpression() {
		return new GetHashFromSequenceCall();
	}

}
