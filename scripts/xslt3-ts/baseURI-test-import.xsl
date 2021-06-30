<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="3.0">
    
    <!-- Test harness for XSLT URI-based dependencies - imported module -->
    
    <xsl:template match="*">
        <import-matched name="{name()}" namespace="{namespace-uri()}"/>
    </xsl:template>
    
</xsl:stylesheet>