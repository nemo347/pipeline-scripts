<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0" name="dtbook-to-epub3" type="px:dtbook-to-epub3" xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:cx="http://xmlcalabash.com/ns/extensions"
    xmlns:cxo="http://xmlcalabash.com/ns/extensions/osutils" xmlns:px="http://www.daisy.org/ns/pipeline/xproc" xmlns:tmp="http://www.daisy.org/ns/pipeline/tmp"
    xmlns:dtbook="http://www.daisy.org/z3986/2005/dtbook/" xmlns:html="http://www.w3.org/1999/xhtml" xmlns:d="http://www.daisy.org/ns/pipeline/data" exclude-inline-prefixes="#all">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">DTBook to EPUB3</h1>
        <p px:role="desc">Converts multiple dtbooks to epub3 format</p>
    </p:documentation>

    <p:input port="source" primary="true" sequence="true" px:media-type="application/x-dtbook+xml">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">DTBook file(s)</h2>
            <p px:role="desc">One or more DTBook files to be transformed. In the case of multiple files, a merge will be performed.</p>
        </p:documentation>
    </p:input>

    <p:option name="language" required="false" px:type="string" select="''">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Language code</h2>
            <p px:role="desc">Language code of the input document.</p>
        </p:documentation>
    </p:option>

    <p:option name="output-dir" required="true" px:output="result" px:type="anyDirURI">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Output directory</h2>
            <p px:role="desc">Directory where both temp-files and the resulting EPUB3 publication is stored.</p>
        </p:documentation>
    </p:option>

    <p:option name="assert-valid" required="false" px:type="boolean" select="'true'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Assert validity</h2>
            <p px:role="desc">Whether to stop processing and raise an error on validation issues.</p>
        </p:documentation>
    </p:option>

    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-to-zedai/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/zedai-to-epub3/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/epub3-ocf-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/fileset-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-break-detection/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/ssml-to-audio/ssml-to-audio.xpl" />
    <p:import href="http://www.daisy.org/pipeline/modules/dtbook-to-ssml/dtbook-to-ssml.xpl" />
    <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

    <p:option name="audio" required="false" px:type="boolean" select="'false'">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<h2 px:role="name">Enable Text-To-Speech</h2>
	<p px:role="desc">Whether to use a speech synthesizer to produce audio files</p>
      </p:documentation>
    </p:option>

    <p:option name="aural-css" required="false" px:type="anyURI" select="''">
      <p:documentation xmlns="http://www.w3.org/1999/xhtml">
	<h2 px:role="name">Aural CSS sheet</h2>
	<p px:role="desc">Path of an Aural CSS stylesheet for the Text-To-Speech.</p>
      </p:documentation>
    </p:option>

    <p:split-sequence name="first-dtbook" test="position()=1" initial-only="true"/>
    <p:sink/>

    <p:xslt name="output-dir-uri">
        <p:with-param name="href" select="concat($output-dir,'/')"/>
        <p:input port="source">
            <p:inline>
                <d:file/>
            </p:inline>
        </p:input>
        <p:input port="stylesheet">
	  <p:inline>
                <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:pf="http://www.daisy.org/ns/pipeline/functions" version="2.0">
                    <xsl:import href="http://www.daisy.org/pipeline/modules/file-utils/uri-functions.xsl"/>
                    <xsl:param name="href" required="yes"/>
                    <xsl:template match="/*">
                        <xsl:copy>
                            <xsl:attribute name="href" select="pf:normalize-uri($href)"/>
                        </xsl:copy>
                    </xsl:template>
                </xsl:stylesheet>
            </p:inline>
        </p:input>
    </p:xslt>
    <p:sink/>

    <p:group>
        <p:variable name="output-name" select="replace(replace(base-uri(/),'^.*/([^/]+)$','$1'),'\.[^\.]*$','')">
            <p:pipe port="matched" step="first-dtbook"/>
        </p:variable>

        <p:variable name="output-dir-uri" select="/*/@href">
            <p:pipe port="result" step="output-dir-uri"/>
        </p:variable>
        <p:variable name="epub-file-uri" select="concat($output-dir-uri,$output-name,'.epub')"/>

        <px:dtbook-load name="load">
            <p:input port="source">
                <p:pipe port="source" step="dtbook-to-epub3"/>
            </p:input>
        </px:dtbook-load>

	<!-- ======= OPTIONAL CALL TO THE TTS MODULE ========	 -->
	<p:choose name="synthesize">
	  <p:when test="$audio = 'false'">
	    <p:output port="content">
	      <p:pipe port="in-memory.out" step="load"/>
	    </p:output>
	    <p:output port="audio-map">
	      <p:empty/>
	    </p:output>
	    <p:sink/>
	  </p:when>
	  <p:otherwise>
	    <p:output port="content">
	      <p:pipe port="result" step="unlex"/>
	    </p:output>
	    <p:output port="audio-map">
	      <p:pipe port="result" step="to-audio"/>
	    </p:output>
	    <p:for-each name="pre-synthesize">
	      <p:iteration-source>
		<p:pipe port="in-memory.out" step="load"/>
	      </p:iteration-source>
	      <p:output port="result">
		<p:pipe port="result" step="break"/>
	      </p:output>
	      <p:output port="ssml.out" primary="true" sequence="true">
		<p:pipe port="result" step="ssml-gen"/>
	      </p:output>
	      <px:dtbook-break-detect name="break"/>
	      <px:dtbook-to-ssml name="ssml-gen">
		<p:input port="sentence-ids">
		  <p:pipe port="sentence-ids" step="break"/>
		</p:input>
		<p:input port="fileset.in">
		  <p:pipe port="fileset.out" step="load"/>
		</p:input>
		<p:with-option name="css-sheet-uri" select="$aural-css"/>
	      </px:dtbook-to-ssml>
	    </p:for-each>
	    <px:ssml-to-audio name="to-audio"/>
	    <p:for-each name="unlex">
	      <p:output port="result"/>
	      <p:iteration-source>
		<p:pipe port="result" step="pre-synthesize"/>
	      </p:iteration-source>
	      <px:dtbook-unwrap-words/>
	    </p:for-each>
	  </p:otherwise>
	</p:choose>
	<!-- =================================================== -->

        <px:dtbook-to-zedai-convert name="convert.dtbook-to-zedai">
	  <p:input port="fileset.in">
	    <p:pipe port="fileset.out" step="load"/>
	  </p:input>
	  <p:input port="in-memory.in">
	      <p:pipe port="content" step="synthesize"/>
            </p:input>
            <p:with-option name="opt-output-dir" select="concat($output-dir-uri,'zedai/')"/>
            <p:with-option name="opt-zedai-filename" select="concat($output-name,'.xml')"/>
            <p:with-option name="opt-lang" select="$language"/>
            <p:with-option name="opt-assert-valid" select="$assert-valid"/>
        </px:dtbook-to-zedai-convert>

        <!--TODO better handle core media type filtering-->
        <!--TODO copy/translate CSS ?-->
        <p:delete name="filtered-zedai-fileset"
            match="d:file[not(@media-type=('application/z3998-auth+xml',
            'image/gif','image/jpeg','image/png','image/svg+xml',
            'application/pls+xml',
            'audio/mpeg','audio/mp4','text/javascript'))]"/>

        <px:zedai-to-epub3-convert name="convert.zedai-to-epub3">
            <p:input port="in-memory.in">
                <p:pipe port="in-memory.out" step="convert.dtbook-to-zedai"/>
            </p:input>
	    <p:input port="audio-map">
	      <p:pipe port="audio-map" step="synthesize"/>
	    </p:input>
            <p:with-option name="output-dir" select="$output-dir-uri"/>
        </px:zedai-to-epub3-convert>

        <px:epub3-store name="store">
            <p:input port="in-memory.in">
	      <p:pipe port="in-memory.out" step="convert.zedai-to-epub3"/>
            </p:input>
            <p:with-option name="href" select="$epub-file-uri"/>
        </px:epub3-store>

    </p:group>

</p:declare-step>
