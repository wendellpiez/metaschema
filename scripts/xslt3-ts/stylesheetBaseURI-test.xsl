<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <!-- Test harness for XSLT URI-based dependencies -->
    
    <xsl:output indent="yes"/>
    
    <xsl:import href="baseURI-test-import.xsl"/>
    
    <xsl:param as="xs:string" name="lookup">baseURI-test-import.xsl</xsl:param>
    
    <xsl:template match="/*">
        <xsl:variable name="me" select="."/>
        <stylesheet-base-URI-test>
            <xsl:if test="$lookup => resolve-uri() => doc-available()">
                <lookup href="{$lookup}">
                    <xsl:for-each select="document($lookup)/*">
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                        </xsl:copy>
                    </xsl:for-each>
                </lookup>
            </xsl:if>
            <import-test>
                <xsl:apply-imports/>
            </import-test>
            <transformation-test>
                <!--<xsl:variable name="me-by-name" select="document('')/document-uri()"/>-->
                <xsl:variable name="runtime-params" as="map(xs:QName,item()*)">
                    <xsl:map>
                        <!--<xsl:map-entry key="QName('','uri-stack-in')"       select="($uri-stack, document-uri($home))"/>-->
                    </xsl:map>
                </xsl:variable>
                <xsl:variable name="runtime" as="map(xs:string, item())">
                    <xsl:map>
                        <xsl:map-entry key="'xslt-version'"        select="3.0"/>
                        <xsl:map-entry key="'stylesheet-location'" select="$lookup"/>
                        <xsl:map-entry key="'source-node'"         select="$me"/>
                        <xsl:map-entry key="'stylesheet-params'"   select="$runtime-params"/>
                    </xsl:map>
                </xsl:variable>
                <!--<xsl:sequence select="$me-by-name"/>-->
                <xsl:sequence select="document($lookup)/xsl:*/ transform($runtime)?output"/>
            </transformation-test>
        </stylesheet-base-URI-test>
    </xsl:template>
    
</xsl:stylesheet>