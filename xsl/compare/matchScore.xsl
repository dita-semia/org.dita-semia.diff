<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema"
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	
	<!--
		match score > 0: the nodes can be merged into a single node and the content will be compared
	-->
	
	<xsl:mode name="matchScore" on-no-match="fail" on-multiple-match="fail"/>
	
	<xsl:template match="*" mode="matchScore" as="xs:double" priority="100">
		<xsl:param name="compareNode" as="element()"/>
		
		<xsl:variable name="baseClass1"	as="xs:string?" select="tokenize(@class, '\s+')[2]"/>
		<xsl:variable name="baseClass2"	as="xs:string?" select="tokenize($compareNode/@class, '\s+')[2]"/>
		
		<xsl:choose>
			<xsl:when test="(empty($baseClass1) or empty($baseClass2)) and not(name(.) = name($compareNode))">
				<!-- elements without class attribute must match in name -->
				<!--<xsl:message>no match: {name(.)}, {name($compareNode)}</xsl:message>-->
				<xsl:sequence select="0.0"/>
			</xsl:when>
			<xsl:when test="(exists($baseClass1) or exists($baseClass2)) and not($baseClass1 = $baseClass2)">
				<!-- don't compare elements with different base class -->
				<!--<xsl:message>no match: {name(.)}, {name($compareNode)}</xsl:message>-->
				<xsl:sequence select="0.0"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:next-match>
					<xsl:with-param name="compareNode" select="$compareNode"/>
				</xsl:next-match>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[@dsd:hash]" mode="matchScore" as="xs:double" priority="40">
		<xsl:param name="compareNode" as="element()"/>
		
		<xsl:choose>
			<xsl:when test="@dsd:hash = $compareNode/@dsd:hash">
				<!-- perfect match! -->
				<xsl:sequence select="1.0"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:next-match>
					<xsl:with-param name="compareNode" select="$compareNode"/>
				</xsl:next-match>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_SVG_CONTAINER)]" mode="matchScore" as="xs:double" priority="30">
		<xsl:param name="compareNode" as="element()"/>
		
		<xsl:sequence select="0.0"/>	<!-- only matching when identical hash which has been checked with higher priority -->
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_DATA)]" mode="matchScore" as="xs:double" priority="30">
		<xsl:param name="compareNode" as="element()"/>
		
		<!-- name and value need to be identical - if present -->
		<xsl:choose>
			<xsl:when test="(string(@name) = string($compareNode/@name)) and (string(@value) = string($compareNode/@value))">
				<!-- match -->
				<xsl:sequence select="1.0"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="0.0"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_TOPICREF)]" mode="matchScore" as="xs:double" priority="30">
		<xsl:param name="compareNode" as="element()"/>
		
		<xsl:variable name="score" as="xs:double">
			<xsl:choose>
				<xsl:when test="@href = $compareNode/@href">
					<!-- Match! -->
					<xsl:sequence select="1.0"/>
				</xsl:when>
				<xsl:when test="@dsd:refId = $compareNode/@dsd:refId">
					<!-- Same topic-id -->
					<xsl:sequence select="0.01"/>
				</xsl:when>
				<xsl:when test="@navtitle = $compareNode/@navtitle">
					<!-- Same title! -->
					<xsl:sequence select="0.001"/>
				</xsl:when>
				<xsl:when test="(empty(@href)) and (empty($compareNode/@href)) and (name(.) = name($compareNode))">
					<!-- no reference and same element type -->
					<xsl:sequence select="0.001"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Don't match referencing elements referencing different targets! -->
					<xsl:sequence select="0.0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--<xsl:message>match-score: {@href}, {$compareNode/@href}: {$score}</xsl:message>-->
		<xsl:sequence select="$score"/>
	</xsl:template>
	
	
	<xsl:template match="*[contains(@class, $CLASS_IMAGE)][@href]" mode="matchScore" as="xs:double" priority="30">
		<xsl:param name="compareNode" as="element()"/>
		
		<xsl:choose>
			<xsl:when test="@dsd:refHashCode = $compareNode/@dsd:refHashCode">
				<!-- Match! -->
				<xsl:sequence select="1.0"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Don't match referencing elements referencing different targets! -->
				<xsl:sequence select="0.0"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[@dsd:mergeCode][not(self::dsd:text)]" mode="matchScore" as="xs:double" priority="25">
		<xsl:param name="compareNode" as="element()"/>
		
		<xsl:choose>
			<xsl:when test="@dsd:mergeCode = $compareNode/@dsd:mergeCode">
				<!-- recurse into content -->
				<!--<xsl:message select="."/>
				<xsl:message select="$compareNode"/>-->
				<xsl:apply-templates select="node()[1]" mode="#current">
					<xsl:with-param name="compareNode" select="$compareNode/node()[1]"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:next-match>
					<xsl:with-param name="compareNode" select="$compareNode"/>
				</xsl:next-match>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*" mode="matchScore" as="xs:double" priority="20">
		<xsl:param name="compareNode" 	as="element()"/>
		<xsl:param name="rootResult" 	as="document-node()?" tunnel="yes"/>
		
		<xsl:variable name="href1"	as="xs:string?" select="dsd:getFixedHref(dsd:getResolvedHref(@href), $rootResult)"/>
		<xsl:variable name="href2"	as="xs:string?" select="dsd:getFixedHref(dsd:getResolvedHref($compareNode/@href), $rootResult)"/>
		
		<xsl:variable name="score" as="xs:double">
			<xsl:choose>
				<xsl:when test="empty($href1) and empty($href2)">
					<!-- none of the elements are references -->
					<xsl:next-match>
						<xsl:with-param name="compareNode" select="$compareNode"/>
					</xsl:next-match>
				</xsl:when>
				<xsl:when test="$href1 = $href2">
					<!-- Match! -->
					<xsl:sequence select="1.0"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Don't match referencing elements referencing different targets! -->
					<xsl:sequence select="0.0"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!--<xsl:message>match-score: {@href}, {$compareNode/@href}: {$score}</xsl:message>-->
		<!--<xsl:message select="$compareNode"/>-->
		<xsl:sequence select="$score"/>
	</xsl:template>
	
	
	<xsl:template match="*[@id]" mode="matchScore" as="xs:double" priority="10">
		<xsl:param name="compareNode" as="element()"/>
		
		<xsl:choose>
			<xsl:when test="@dsd:id = $compareNode/@dsd:id">
				<!-- Match based on the original id! -->
				<xsl:sequence select="1.0"/>
			</xsl:when>
			<xsl:when test="empty(@dsd:id) and (@id = $compareNode/@id)">
				<!-- Match! (use @id only when there is no @dsd:id) -->
				<xsl:sequence select="1.0"/>
			</xsl:when>
			<xsl:when test="exists($compareNode/@id)">
				<!-- Don't match elements that have both an id that is different! -->
				<xsl:sequence select="0.0"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:next-match>
					<xsl:with-param name="compareNode" select="$compareNode"/>
				</xsl:next-match>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*" mode="matchScore" as="xs:double">
		<xsl:param name="compareNode" 	as="element()"/>
		<xsl:param name="isTextMode"	as="xs:boolean" select="false()" tunnel="yes"/>
		
		<xsl:choose>
			<xsl:when test="$isTextMode">
				<!-- don't match non-identical nodes in text mode. -->
				<xsl:sequence select="0.0"/>
			</xsl:when>
			<xsl:when test="(name(.) = name($compareNode)) and (string(@class) = string($compareNode/@class))">
				<!-- the element name matches, so the elements are comparable -->
				<xsl:sequence select="0.01"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="0.0"/>
			</xsl:otherwise>
		</xsl:choose> 
	</xsl:template>
	
	
</xsl:stylesheet>
