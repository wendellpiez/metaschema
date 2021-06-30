<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="3.0">
    
    <xsl:output indent="true"/>
    
    <xsl:template match="/" expand-text="true">
        <result>
            <msg>finding XSLT here: { document('')/base-uri(.) }</msg>
            <xsl:call-template name="include-msg"/>
        </result>
    </xsl:template>
    
    <xsl:include href="included-test-include.xsl"/>
    
</xsl:stylesheet>