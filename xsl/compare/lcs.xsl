<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
	xmlns:xsl	= "http://www.w3.org/1999/XSL/Transform"
	xmlns:xs	= "http://www.w3.org/2001/XMLSchema" 
	xmlns:dsd	= "http://www.dita-semia.org/diff"
	exclude-result-prefixes="#all"
	expand-text="true">
	
	<!-- algorithm: see https://en.wikipedia.org/wiki/Longest_common_subsequence_problem -->
	

	<xsl:template name="lcs">
		<xsl:param name="parent1"		as="node()"/>
		<xsl:param name="parent2"		as="node()"/>
		<xsl:param name="debugOutput"	as="xs:boolean" select="false()"/>
		<xsl:param name="isTextMode"	as="xs:boolean" select="false()" tunnel="yes"/>

		<xsl:variable name="matrix" as="document-node()">
			<xsl:document>
				<xsl:call-template name="lcsMatrixRows">
					<xsl:with-param name="prevRow"		select="()"/>	<!-- 1st row is empty -->
					<xsl:with-param name="nodes1"		select="$parent1/*"/>
					<xsl:with-param name="node2"		select="$parent2/*[not(@dsd:skip)][1]"/>
					<xsl:with-param name="fullMatrix"	select="$debugOutput"/>
				</xsl:call-template>
			</xsl:document>
		</xsl:variable>
		<xsl:variable name="lcs" as="element()" select="$matrix/row[last()]/lcs[last()]"/>
		
		<xsl:if test="$debugOutput">
			<matrix>
				<xsl:sequence select="$matrix/*"/>
			</matrix>
		</xsl:if>
		
		<xsl:choose>
			<xsl:when test="$isTextMode">
				<xsl:call-template name="simplifyTextLcs">
					<xsl:with-param name="lcs" 			select="$lcs"/>
					<xsl:with-param name="parent1"		select="$parent1"/>
					<xsl:with-param name="parent2"		select="$parent2"/>
					<xsl:with-param name="debugOutput"	select="$debugOutput"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$lcs"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template name="lcsMatrixRows">
		<xsl:param name="prevRow"		as="element(row)?"/>
		<xsl:param name="nodes1"		as="element()+"/>
		<xsl:param name="node2"			as="element()"/>
		<xsl:param name="fullMatrix"	as="xs:boolean"/>
		
		<xsl:variable name="row" as="element(row)">
			<row>
				<xsl:variable name="emptyLcs" as="element(lcs)">
					<lcs/>	
				</xsl:variable>
				
				<xsl:sequence select="$emptyLcs"/>
				
				<xsl:call-template name="lcsMatrixEntrys">
					<xsl:with-param name="prevRowPrevEntry"	select="$prevRow/*[not(@dsd:skip)][1]"/>
					<xsl:with-param name="prevEntry"		select="$emptyLcs"/>
					<xsl:with-param name="node1"			select="$nodes1[1]"/>
					<xsl:with-param name="node2"			select="$node2"/>
				</xsl:call-template>
				
			</row>
		</xsl:variable>
		
		
		<xsl:variable name="nextNode2"	as="element()?" select="$node2/following-sibling::element()[not(@dsd:skip)][1]"/>
		<xsl:choose>
			<xsl:when test="$nextNode2">
				<xsl:if test="$fullMatrix">
					<xsl:sequence select="$row"/>
				</xsl:if>
				<xsl:call-template name="lcsMatrixRows">
					<xsl:with-param name="prevRow"		select="$row"/>
					<xsl:with-param name="nodes1"		select="$nodes1"/>
					<xsl:with-param name="node2"		select="$nextNode2"/>
					<xsl:with-param name="fullMatrix"	select="$fullMatrix"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$row"/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	<xsl:template name="lcsMatrixEntrys">
		<xsl:param name="prevRowPrevEntry"	as="element(lcs)?"/>
		<xsl:param name="prevEntry"			as="element(lcs)"/>
		<xsl:param name="node1"				as="element()"/>
		<xsl:param name="node2"				as="element()"/>
		
		<xsl:variable name="prevRowEntry" as="element(lcs)?" select="$prevRowPrevEntry/following-sibling::*[not(@dsd:skip)][1]"/>
		<xsl:variable name="element" as="element(lcs)">
			<lcs>
				<xsl:variable name="matchScore" as="xs:double">
					<xsl:apply-templates select="$node1" mode="matchScore">
						<xsl:with-param name="compareNode" select="$node2"/>
					</xsl:apply-templates>
				</xsl:variable>
				<!-- give a slightly higher weight for adjacent matches -->
				<xsl:variable name="adjacent"	as="xs:double?"	select="if ($prevRowPrevEntry/@match) then 0.001 else 0"/>
				<xsl:variable name="thisWeight" as="xs:double" 	select="sum(($prevRowPrevEntry/@weight, (($node1/@dsd:size + $node2/@dsd:size) div 2.0 * $matchScore), $adjacent))"/>
				<xsl:variable name="prevWeight" as="xs:double" 	select="max(($prevEntry/@weight, $prevRowEntry/@weight, 0.0))"/>
				<xsl:variable name="thisPos1" 	as="xs:integer" select="(count($node1/preceding-sibling::node()) + 1)"/>
				<xsl:variable name="thisPos2" 	as="xs:integer" select="(count($node2/preceding-sibling::node()) + 1)"/>

				<xsl:choose>
					<xsl:when test="($matchScore gt 0) and ($thisWeight ge $prevWeight)">
						<!-- on same score adding a later node wins because this might increase the number of adjacent nodes --> 
						<xsl:attribute name="weight" 	select="$thisWeight"/>
						<xsl:attribute name="s1"		select="($prevRowPrevEntry/@s1, $thisPos1)"/>
						<xsl:attribute name="s2"		select="($prevRowPrevEntry/@s2, $thisPos2)"/>
						<xsl:attribute name="match"/>
					</xsl:when>
					<xsl:when test="number($prevEntry/@weight) gt max(($prevRowEntry/@weight, 0.0))">
						<xsl:copy-of select="$prevEntry/(@weight | @s1 | @s2)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$prevRowEntry/(@weight | @s1 | @s2)"/>
					</xsl:otherwise>
				</xsl:choose>
			</lcs>
		</xsl:variable>
		
		<xsl:sequence select="$element"/>
		
		<xsl:variable name="nextNode1"	as="element()?" select="$node1/following-sibling::element()[not(@dsd:skip)][1]"/>
		<xsl:if test="$nextNode1">
			<xsl:call-template name="lcsMatrixEntrys">
				<xsl:with-param name="prevRowPrevEntry"	select="$prevRowEntry"/>
				<xsl:with-param name="prevEntry"		select="$element"/>
				<xsl:with-param name="node1"			select="$nextNode1"/>
				<xsl:with-param name="node2"			select="$node2"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	
	
	<xsl:template name="simplifyTextLcs" as="element()+">
		<xsl:param name="lcs"			as="element(lcs)"/>
		<xsl:param name="parent1"		as="node()"/>
		<xsl:param name="parent2"		as="node()"/>
		<xsl:param name="debugOutput"	as="xs:boolean" select="false()"/>
		
		<xsl:variable name="s1" as="xs:integer+" select="(0, tokenize($lcs/@s1, '\s')!xs:integer(.), count($parent1/node()) + 1)"/>
		<xsl:variable name="s2" as="xs:integer+" select="(0, tokenize($lcs/@s2, '\s')!xs:integer(.), count($parent2/node()) + 1)"/>
		
		<xsl:variable name="list" as="element()*">
			<xsl:for-each select="2 to count($s1) - 1">
				<xsl:variable name="i1"	as="xs:integer" select="$s1[current() - 1]"/>
				<xsl:variable name="j1"	as="xs:integer" select="$s1[current()]"/>
				<xsl:variable name="i2"	as="xs:integer" select="$s2[current() - 1]"/>
				<xsl:variable name="j2"	as="xs:integer" select="$s2[current()]"/>
				<xsl:for-each select="$parent1/node()[(position() gt $i1) and (position() lt $j1)] | $parent2/node()[(position() gt $i2) and (position() lt $j2)]">
					<changed>
						<xsl:copy-of select="@dsd:size"/>
					</changed>
				</xsl:for-each>
				<match>
					<xsl:copy-of select="$parent1/node()[$j1]/@dsd:size"/>
					<xsl:attribute name="s1" select="$j1"/>
					<xsl:attribute name="s2" select="$j2"/>
				</match>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:variable name="filteredList" as="element()*">
			<xsl:call-template name="filterLcs">
				<xsl:with-param name="list" select="$list"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="simplifiedLcs" as="element()">
			<lcs>
				<xsl:attribute name="s1" select="$filteredList/@s1"/>
				<xsl:attribute name="s2" select="$filteredList/@s2"/>
			</lcs>
		</xsl:variable>
		
		<xsl:if test="$debugOutput">
			<simplifyTextLcs>
				<list>
					<xsl:sequence select="$list"/>
				</list>
				<filteredList>
					<xsl:sequence select="$filteredList"/>
				</filteredList>
			</simplifyTextLcs>	
		</xsl:if>
		
		<xsl:sequence select="$simplifiedLcs"/>
	</xsl:template>
	
	
	<xsl:template name="filterLcs">
		<xsl:param name="list" 					as="element()*"/>
		<xsl:param name="protectTextMatchSize"	as="xs:integer" tunnel="yes"/>
		<xsl:param name="protectTextMatchRatio"	as="xs:double" 	tunnel="yes"/>
		
		<xsl:variable name="groupedList" as="document-node()">
			<xsl:document>	<!-- common parent to support preceeding-sibling:: -->
				<xsl:for-each-group select="$list" group-adjacent="name(.)">
					<xsl:copy>
						<xsl:attribute name="dsd:size" select="sum(current-group()/@dsd:size)"/>
						<xsl:if test="self::match">
							<xsl:attribute name="s1" select="current-group()/@s1"/>
							<xsl:attribute name="s2" select="current-group()/@s2"/>
						</xsl:if>
					</xsl:copy>
				</xsl:for-each-group>
			</xsl:document>
		</xsl:variable>
		
		<xsl:variable name="filteredlist" as="element()*">
			<xsl:for-each select="$groupedList/*">
				<xsl:choose>
					<xsl:when test="self::match">
						<xsl:variable name="matchSize"		as="xs:double" 	select="@dsd:size"/>
						<xsl:variable name="changeSize"		as="xs:double?" select="sum((preceding-sibling::*[1]/@dsd:size, following-sibling::*[1]/@dsd:size))"/>
						<xsl:variable name="minMatchSize"	as="xs:double" 	select="min(($protectTextMatchSize, $changeSize * $protectTextMatchRatio))"/>
						<!--<xsl:message>matchSize: {$matchSize}, changeSize: {$changeSize}, minMatchSize: {$minMatchSize}</xsl:message>-->
						<xsl:choose>
							<xsl:when test="($matchSize ge $minMatchSize)">
								<!-- keep the match -->
								<xsl:copy-of select="."/>
							</xsl:when>
							<xsl:otherwise>
								<!-- filter the match -> convert it into change with double size (= added + deleted) -->
								<changed dsd:size="{2 * $matchSize}"/> 
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="count($filteredlist) lt count($list)">
				<!-- list has been filtered -> recurse for possible additional filtering -->
				<xsl:call-template name="filterLcs">
					<xsl:with-param name="list" select="$filteredlist"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<!-- abort recursion -->
				<xsl:sequence select="$filteredlist"/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
</xsl:stylesheet>
