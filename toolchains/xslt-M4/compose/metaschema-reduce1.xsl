<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:m="http://csrc.nist.gov/ns/oscal/metaschema/1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xpath-default-namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0"
    exclude-result-prefixes="xs math m xsi" version="3.0">

    <xsl:output indent="yes"/>

    <xsl:strip-space
        elements="METASCHEMA define-flag define-field define-assembly remarks model choice"/>

    <xsl:variable name="show-warnings" as="xs:string">no</xsl:variable>
    <xsl:variable name="verbose" select="lower-case($show-warnings) = ('yes', 'y', '1', 'true')"/>

    <xsl:key name="assembly-definition-by-name" match="METASCHEMA/define-assembly" use="@name"/>
    <xsl:key name="field-definition-by-name"    match="METASCHEMA/define-field"    use="@name"/>
    <xsl:key name="flag-definition-by-name"     match="METASCHEMA/define-flag"     use="@name"/>
    
    <xsl:template match="/">
        <xsl:apply-templates mode="keep-eligible"/>
    </xsl:template>

    <!-- ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== -->
    <!-- Pass Two: filter definitions (1) - eligible definitions are the last-declared with their name
         but we keep everything else including all 'augments' (documentation) for the next pass.
    
    At present, 'reduction' means only removing declarations that should be ignored as inoperative. 
    At some point, more normalization may be called for (for example, rewriting global field declarations
    as local); presently this all happens in the next phase and this one simply removes unused declarations.
    -->
    
    <!-- We rely on document import order to determine which declaration is to be considered effective -
         namely (under present rules) the last one given. Since imported declarations are given in
         order, we can rely on the order presented for the last-in-wins determination. -->
    
    <xsl:template mode="keep-eligible" match="node() | @*">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates mode="#current" select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <!--<xsl:key name="flag-references"     match="flag" use="@ref"/>
    <xsl:key name="field-references"    match="field" use="@ref"/>
    <xsl:key name="assembly-references" match="assembly | model" use="@ref"/>-->
    
    <!--<xsl:template mode="keep-eligible" priority="13"
        match="METASCHEMA/define-field[empty(root-name|key('field-references',@name))]
        | METASCHEMA/define-flag[empty(root-name|key('flag-references',@name))]
        | METASCHEMA/define-assembly[empty(root-name|key('assembly-references',@name))]">
        <xsl:message expand-text="true">TOSSING definition for '{ @name }' {
            replace(local-name(),'^define-','')} from { ancestor::METASCHEMA[1]/@module
            }</xsl:message>
    </xsl:template>-->
    
    <xsl:template mode="keep-eligible" priority="12" match="METASCHEMA/define-field[. is key('field-definition-by-name', @name)[last()]]">
        <xsl:call-template name="warning">
            <xsl:with-param name="msg" expand-text="true">KEEPING definition for '{ @name }' field from { ancestor::METASCHEMA[1]/@module }: last given</xsl:with-param>
        </xsl:call-template>
        <xsl:copy-of select="." copy-namespaces="no"/>
    </xsl:template>
    
    <xsl:template mode="keep-eligible" priority="12"
        match="METASCHEMA/define-flag[. is key('flag-definition-by-name', @name)[last()]]">
        <xsl:call-template name="warning">
            <xsl:with-param name="msg" expand-text="true">KEEPING definition for '{ @name }' flag from { ancestor::METASCHEMA[1]/@module }: last given</xsl:with-param>
        </xsl:call-template>
        <xsl:copy-of select="." copy-namespaces="no"/>
    </xsl:template>
    
    <xsl:template mode="keep-eligible" priority="12"
        match="METASCHEMA/define-assembly[. is key('assembly-definition-by-name', @name)[last()]]">
        <xsl:call-template name="warning">
            <xsl:with-param name="msg" expand-text="true">KEEPING definition for '{ @name }' assembly from { ancestor::METASCHEMA[1]/@module }: last given</xsl:with-param>
        </xsl:call-template>
        <xsl:copy-of select="." copy-namespaces="no"/>
    </xsl:template>
    
    <!-- Tossing definitions we aren't keeping -->
    <xsl:template mode="keep-eligible"
        match="METASCHEMA/define-field | METASCHEMA/define-flag | METASCHEMA/define-assembly">
        <xsl:variable name="msg" expand-text="true">REMOVING superseded definition for '{ @name }' {
            replace(local-name(),'^define-','')} from { ancestor::METASCHEMA[1]/@module
            }</xsl:variable>
        <xsl:call-template name="comment">
            <xsl:with-param name="msg" select="$msg"/>
        </xsl:call-template>
        <xsl:call-template name="warning">
            <xsl:with-param name="msg" select="$msg"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="comment">
        <xsl:param name="msg"/>
        <xsl:if test="$verbose">
            <xsl:comment>
                <xsl:copy-of select="$msg"/>
            </xsl:comment>
        </xsl:if>
    </xsl:template>

    <xsl:template name="warning">
        <xsl:param name="msg"/>
        <xsl:if test="$verbose">
            <xsl:message>
                <xsl:copy-of select="$msg"/>
            </xsl:message>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>