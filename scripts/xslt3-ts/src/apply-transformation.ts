#!/usr/bin/env node

declare var require: any
const process = require('process')

import * as SaxonJS from "saxon-js/SaxonJS2N.js";

/*inputs are files named on the cl */
const srcIn:  string = process.argv[2]
const xsltIn: string = process.argv[3]

// const implementationDir = '../../toolchains/xslt-M4'
const workingDir: string = process.cwd()
const BaseURL:    string = 'file:///' + workingDir + '/.'

/*
 * CL to compile hello-world.xsl as hello.sef.json
 * xslt3 -t -xsl:hello-world.xsl -export:hello.sef.json - nogo
*/

interface TransformRuntime {
    sourceFile: URL;
    sefFile:    URL;
    xsltBase:   URL
}

function executeTransform(runtime: TransformRuntime) {
    SaxonJS.transform({
        stylesheetFileName: runtime.sefFile.toString(),
        stylesheetBaseURI:  runtime.xsltBase.toString(),
        sourceFileName:     runtime.sourceFile.toString(),
        destination: "stdout"
        /*sourceText: helloString, - for testing */
        /*destination: "serialized",  - pick up from htmlout.principalResult */
        /* to write to file:
         * destination: "file",
         * baseOutputURI: resultFile*/
    })
}

// passing in arguments as absolute URLs resolved relative to working dir
// .sef.json is assumed here from .xsl suffix on xsltIn

let anyXMLanyXSLT = {
    sourceFile: new URL(srcIn,                                BaseURL),
    sefFile:    new URL(xsltIn.replace(/\.xsl$/,".sef.json"), BaseURL),
    xsltBase:   new URL(xsltIn,                               BaseURL)
}

// console.log( anyXMLanyXSLT )

executeTransform( anyXMLanyXSLT )

/*let resultFile: string = [sysPath, 'result.xml'].join('/')*/

/*API docs: http://www.saxonica.com/saxon-js/documentation/index.html#!api/transform */


/*console.log(htmlout.principalResult) - pick up serialized output*/

/*    .then(output) {
    response.writeHead(200, { 'Content-Type': 'application/xml' });
    response.write(output.principalResult);
    response.end();
});  */

/*let message: string = "Hello World"
console.log(message)*/